# Sensor Data Patterns — BESOLT

## TimescaleDB 스키마 (시계열 표준)

```sql
-- 센서 원시 데이터 (Hypertable)
CREATE TABLE sensor_readings (
    time        TIMESTAMPTZ NOT NULL,
    sensor_id   VARCHAR(50) NOT NULL,
    equipment_id VARCHAR(50) NOT NULL,
    line_id     VARCHAR(20) NOT NULL,
    value       DOUBLE PRECISION,
    unit        VARCHAR(20),
    quality     VARCHAR(10) DEFAULT 'GOOD',  -- GOOD/BAD/UNCERTAIN
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

SELECT create_hypertable('sensor_readings', 'time');
CREATE INDEX ON sensor_readings (sensor_id, time DESC);

-- 집계 (Continuous Aggregate - 1분 평균)
CREATE MATERIALIZED VIEW sensor_1min
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 minute', time) AS bucket,
    sensor_id,
    AVG(value) AS avg_value,
    MAX(value) AS max_value,
    MIN(value) AS min_value,
    STDDEV(value) AS std_value,
    COUNT(*) AS sample_count
FROM sensor_readings
GROUP BY bucket, sensor_id;
```

## 데이터 수집 파이프라인

```python
# MQTT → FastAPI → TimescaleDB
import json
from asyncio_mqtt import Client as MQTTClient

async def mqtt_ingestion_loop():
    """센서 데이터 MQTT 수신 루프"""
    async with MQTTClient(settings.MQTT_BROKER) as client:
        await client.subscribe("factory/+/sensor/+/data")
        async for message in client.messages:
            payload = json.loads(message.payload)
            topic_parts = str(message.topic).split("/")
            
            reading = SensorReading(
                time=datetime.fromisoformat(payload["timestamp"]),
                sensor_id=topic_parts[3],
                equipment_id=payload.get("equipment_id"),
                line_id=topic_parts[1],
                value=float(payload["value"]),
                unit=payload.get("unit"),
                quality=payload.get("quality", "GOOD")
            )
            await sensor_service.ingest(reading)
```

## AI 모델 피처 엔지니어링

```python
import pandas as pd
import numpy as np

def extract_time_features(df: pd.DataFrame, 
                           window_sizes: list = [10, 30, 60]) -> pd.DataFrame:
    """
    센서 시계열에서 통계적 피처 추출
    
    window_sizes: 분 단위 롤링 윈도우
    """
    features = df.copy()
    
    for w in window_sizes:
        col_prefix = f"w{w}"
        features[f"{col_prefix}_mean"] = df["value"].rolling(w).mean()
        features[f"{col_prefix}_std"] = df["value"].rolling(w).std()
        features[f"{col_prefix}_max"] = df["value"].rolling(w).max()
        features[f"{col_prefix}_min"] = df["value"].rolling(w).min()
        features[f"{col_prefix}_range"] = (
            features[f"{col_prefix}_max"] - features[f"{col_prefix}_min"]
        )
        # 변화율
        features[f"{col_prefix}_rate"] = df["value"].diff(w) / w
    
    # 시간대 피처
    features["hour"] = df.index.hour
    features["day_of_week"] = df.index.dayofweek
    features["is_night_shift"] = features["hour"].between(22, 6)
    
    return features.dropna()
```

## 이상감지 구현 패턴

```python
from sklearn.ensemble import IsolationForest
import numpy as np

class SensorAnomalyDetector:
    """실시간 센서 이상감지"""
    
    def __init__(self, contamination: float = 0.05):
        self.model = IsolationForest(
            contamination=contamination,
            random_state=42,
            n_estimators=100
        )
        self.threshold_upper: float = None
        self.threshold_lower: float = None
    
    def fit(self, X: np.ndarray) -> None:
        self.model.fit(X)
        # 통계적 임계치도 함께 설정
        self.threshold_upper = np.mean(X) + 3 * np.std(X)
        self.threshold_lower = np.mean(X) - 3 * np.std(X)
    
    def predict(self, X: np.ndarray) -> dict:
        """
        Returns:
            {"is_anomaly": bool, "score": float, "reason": str}
        """
        score = self.model.score_samples(X.reshape(1, -1))[0]
        stat_anomaly = (X[-1] > self.threshold_upper or 
                       X[-1] < self.threshold_lower)
        ml_anomaly = self.model.predict(X.reshape(1, -1))[0] == -1
        
        is_anomaly = stat_anomaly or ml_anomaly
        reason = []
        if stat_anomaly:
            reason.append(f"3σ 임계치 초과: {X[-1]:.2f}")
        if ml_anomaly:
            reason.append(f"패턴 이상 (score: {score:.3f})")
        
        return {
            "is_anomaly": is_anomaly,
            "anomaly_score": float(score),
            "reason": ", ".join(reason) if reason else "정상"
        }
```

## 엣지 케이스 처리

```python
def clean_sensor_data(df: pd.DataFrame) -> pd.DataFrame:
    """센서 데이터 품질 정제"""
    
    # 1. GOOD 품질만 사용
    df = df[df["quality"] == "GOOD"].copy()
    
    # 2. 물리적 불가능값 제거 (음수 온도 등)
    df = df[df["value"].between(df["value"].quantile(0.001), 
                                df["value"].quantile(0.999))]
    
    # 3. 중복 타임스탬프 처리
    df = df.drop_duplicates(subset=["time", "sensor_id"]).sort_values("time")
    
    # 4. 결측값 보간 (최대 5분 갭까지)
    df = df.set_index("time").resample("1T").mean()
    df["value"] = df["value"].interpolate(method="time", limit=5)
    
    # 5. 고착값 감지 (동일값 연속 10회 이상)
    df["is_stuck"] = (df["value"].diff().abs() < 0.001).rolling(10).sum() >= 10
    df = df[~df["is_stuck"]]
    
    return df.reset_index()
```
