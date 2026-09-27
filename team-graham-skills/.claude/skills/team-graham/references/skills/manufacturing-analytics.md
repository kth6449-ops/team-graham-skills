# Manufacturing Business Analytics Skill — BESOLT
## 데이터 분석·가공·전처리·예측·시뮬레이션

## 적용 범위
제조 데이터 파이프라인 구축, ML 기반 예측 분석, 시나리오 시뮬레이션.
SOLT-AI 플랫폼의 분석 엔진 설계 및 고객사 데이터 컨설팅.

---

## 1. 제조 데이터 파이프라인 아키텍처

### 1-1. 전체 흐름

```
[수집]           [전처리]          [특징추출]       [분석/예측]      [서비스]
센서(OPC-UA) →               →               →               →
MES 실적     →  Preprocessing →  Feature      →  ML Models   →  FastAPI
ERP 원가     →  & Validation  →  Engineering  →  Simulation  →  대시보드
품질 검사    →               →               →               →
```

### 1-2. Airflow DAG 패턴 (ETL 스케줄링)

```python
from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta

default_args = {
    "owner": "peter",
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "email_on_failure": True,
}

with DAG(
    dag_id="manufacturing_etl_daily",
    default_args=default_args,
    schedule_interval="0 6 * * *",  # 매일 오전 6시
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=["manufacturing", "etl"]
) as dag:

    extract_mes = PythonOperator(
        task_id="extract_mes_data",
        python_callable=extract_mes_production
    )
    extract_erp = PythonOperator(
        task_id="extract_erp_cost",
        python_callable=extract_erp_cost
    )
    preprocess = PythonOperator(
        task_id="preprocess_and_validate",
        python_callable=preprocess_manufacturing_data
    )
    load_dw = PythonOperator(
        task_id="load_to_data_warehouse",
        python_callable=load_to_postgres
    )
    update_aggregates = PythonOperator(
        task_id="refresh_materialized_views",
        python_callable=refresh_timescale_aggregates
    )

    [extract_mes, extract_erp] >> preprocess >> load_dw >> update_aggregates
```

---

## 2. 데이터 전처리 (Preprocessing)

### 2-1. 제조 데이터 표준 전처리 파이프라인

```python
import pandas as pd
import numpy as np
from typing import Optional

class ManufacturingDataPreprocessor:
    """
    제조 데이터 표준 전처리 클래스
    입력: 원시 MES/센서/품질 데이터
    출력: 분석 가능한 정제 데이터
    """
    
    def __init__(self, config: dict):
        self.config = config
        self.quality_report = {}
    
    def run(self, df: pd.DataFrame) -> pd.DataFrame:
        """전처리 파이프라인 순차 실행"""
        df = self._validate_schema(df)
        df = self._handle_missing(df)
        df = self._remove_outliers(df)
        df = self._fix_data_types(df)
        df = self._remove_duplicates(df)
        df = self._standardize_codes(df)
        self._generate_quality_report(df)
        return df
    
    def _handle_missing(self, df: pd.DataFrame) -> pd.DataFrame:
        """결측값 처리 전략"""
        for col, strategy in self.config.get("missing_strategy", {}).items():
            if col not in df.columns:
                continue
            if strategy == "forward_fill":
                df[col] = df[col].fillna(method="ffill", limit=5)
            elif strategy == "interpolate":
                df[col] = df[col].interpolate(method="time")
            elif strategy == "median":
                df[col] = df[col].fillna(df[col].median())
            elif strategy == "drop":
                df = df.dropna(subset=[col])
            elif strategy == "zero":
                df[col] = df[col].fillna(0)
        return df
    
    def _remove_outliers(self, df: pd.DataFrame, 
                         method: str = "iqr") -> pd.DataFrame:
        """이상값 제거 (IQR 또는 Z-score)"""
        numeric_cols = df.select_dtypes(include=[np.number]).columns
        
        for col in numeric_cols:
            if col in self.config.get("skip_outlier_cols", []):
                continue
            
            if method == "iqr":
                Q1 = df[col].quantile(0.25)
                Q3 = df[col].quantile(0.75)
                IQR = Q3 - Q1
                lower = Q1 - 1.5 * IQR
                upper = Q3 + 1.5 * IQR
                outlier_mask = (df[col] < lower) | (df[col] > upper)
                
            elif method == "zscore":
                z_scores = np.abs((df[col] - df[col].mean()) / df[col].std())
                outlier_mask = z_scores > 3
            
            self.quality_report[f"{col}_outliers"] = outlier_mask.sum()
            df = df[~outlier_mask]
        
        return df
    
    def _standardize_codes(self, df: pd.DataFrame) -> pd.DataFrame:
        """코드 표준화 (대소문자, 공백 등)"""
        code_cols = self.config.get("code_columns", [])
        for col in code_cols:
            if col in df.columns:
                df[col] = df[col].str.strip().str.upper()
        return df
    
    def _generate_quality_report(self, df: pd.DataFrame) -> None:
        """데이터 품질 보고서 생성"""
        self.quality_report.update({
            "total_rows": len(df),
            "missing_pct": (df.isnull().sum() / len(df) * 100).to_dict(),
            "duplicate_rows": df.duplicated().sum(),
            "data_types": df.dtypes.astype(str).to_dict()
        })
```

### 2-2. 시계열 데이터 전처리

```python
def preprocess_time_series(
    df: pd.DataFrame,
    time_col: str,
    value_col: str,
    freq: str = "1T",           # 1분 리샘플링
    interp_limit: int = 10,     # 최대 보간 포인트 수
    smooth_window: int = 5      # 이동평균 윈도우
) -> pd.DataFrame:
    """
    센서 시계열 데이터 표준 전처리
    
    1. 타임스탬프 정규화 → 2. 리샘플링 → 3. 보간 → 4. 스무딩
    """
    # 1. 타임스탬프 정규화
    df[time_col] = pd.to_datetime(df[time_col], utc=True)
    df = df.sort_values(time_col).set_index(time_col)
    
    # 2. 균일 시간 간격으로 리샘플링 (평균)
    df_resampled = df[[value_col]].resample(freq).mean()
    
    # 3. 선형 보간 (최대 interp_limit 포인트)
    df_resampled[value_col] = df_resampled[value_col].interpolate(
        method="time", limit=interp_limit
    )
    
    # 4. 이동평균 스무딩 (노이즈 제거)
    df_resampled[f"{value_col}_smooth"] = (
        df_resampled[value_col].rolling(window=smooth_window, center=True).mean()
    )
    
    # 5. 변화율 (Rate of Change)
    df_resampled[f"{value_col}_roc"] = df_resampled[value_col].pct_change()
    
    return df_resampled.reset_index()
```

---

## 3. 피처 엔지니어링 (Feature Engineering)

### 3-1. 제조 도메인 피처 세트

```python
def build_manufacturing_features(
    production_df: pd.DataFrame,
    sensor_df: pd.DataFrame,
    quality_df: pd.DataFrame
) -> pd.DataFrame:
    """
    ML 모델용 제조 피처 통합 생성
    """
    features = production_df.copy()
    
    # ── 생산 피처 ──────────────────────────────
    features["achievement_rate"] = (
        features["actual_qty"] / features["planned_qty"]
    )
    features["defect_rate"] = (
        features["defect_qty"] / features["actual_qty"].clip(lower=1)
    )
    features["cycle_time_ratio"] = (
        features["actual_cycle_time"] / features["std_cycle_time"]
    )
    
    # ── 설비 이력 피처 (롤링) ───────────────────
    features["downtime_7d"] = (
        features.groupby("equipment_id")["downtime_minutes"]
        .transform(lambda x: x.rolling(7, min_periods=1).sum())
    )
    features["mtbf_30d"] = (           # Mean Time Between Failures
        features.groupby("equipment_id")["operating_time"]
        .transform(lambda x: x.rolling(30, min_periods=1).mean())
    )
    
    # ── 시간 피처 ──────────────────────────────
    features["hour"] = pd.to_datetime(features["start_time"]).dt.hour
    features["day_of_week"] = pd.to_datetime(features["start_time"]).dt.dayofweek
    features["shift"] = features["hour"].apply(
        lambda h: "주간" if 6 <= h < 14 else "오후" if 14 <= h < 22 else "야간"
    )
    
    # ── 센서 집계 피처 (조인) ───────────────────
    sensor_agg = sensor_df.groupby(["equipment_id", "date"]).agg(
        temp_mean=("temperature", "mean"),
        temp_max=("temperature", "max"),
        vibration_rms=("vibration", lambda x: np.sqrt(np.mean(x**2))),
        pressure_std=("pressure", "std")
    ).reset_index()
    
    features = features.merge(sensor_agg, on=["equipment_id", "date"], how="left")
    
    return features
```

---

## 4. 예측 모델 패턴

### 4-1. 생산량 예측 (Prophet)

```python
from prophet import Prophet
import pandas as pd

def forecast_production(
    history_df: pd.DataFrame,    # columns: ds(date), y(생산량)
    periods: int = 30,           # 예측 기간 (일)
    include_holidays: bool = True
) -> pd.DataFrame:
    """
    생산량 시계열 예측 (Prophet)
    - 주별/월별 계절성 자동 반영
    - 공휴일 효과 포함
    """
    model = Prophet(
        seasonality_mode="multiplicative",
        yearly_seasonality=True,
        weekly_seasonality=True,
        daily_seasonality=False,
        changepoint_prior_scale=0.05  # 추세 변화 민감도
    )
    
    if include_holidays:
        # 한국 공휴일 추가
        from prophet.make_holidays import make_holidays_df
        kr_holidays = make_holidays_df(year_list=[2024, 2025, 2026], country="KR")
        model.add_country_holidays(country_name="KR")
    
    model.fit(history_df)
    
    future = model.make_future_dataframe(periods=periods, freq="D")
    forecast = model.predict(future)
    
    return forecast[["ds", "yhat", "yhat_lower", "yhat_upper"]].tail(periods)
```

### 4-2. 설비 고장 예측 (XGBoost)

```python
import xgboost as xgb
from sklearn.model_selection import TimeSeriesSplit
from sklearn.metrics import f1_score, roc_auc_score
import mlflow

def train_failure_prediction_model(
    features_df: pd.DataFrame,
    target_col: str = "failure_within_7d",
    model_name: str = "failure-predictor"
) -> dict:
    """
    설비 고장 예측 모델 (7일 내 고장 여부 분류)
    
    입력 피처: 진동, 온도, 압력, 가동시간, 정비 이력 등
    출력: 고장 확률 (0~1)
    """
    feature_cols = [c for c in features_df.columns 
                    if c not in [target_col, "equipment_id", "date"]]
    
    X = features_df[feature_cols]
    y = features_df[target_col]
    
    # 시계열 교차검증
    tscv = TimeSeriesSplit(n_splits=5)
    
    with mlflow.start_run(run_name=f"{model_name}-training"):
        mlflow.log_params({
            "model_type": "XGBoost",
            "n_features": len(feature_cols),
            "target": target_col,
            "cv_strategy": "TimeSeriesSplit(n_splits=5)"
        })
        
        params = {
            "max_depth": 6,
            "learning_rate": 0.1,
            "n_estimators": 300,
            "subsample": 0.8,
            "colsample_bytree": 0.8,
            "scale_pos_weight": (y == 0).sum() / (y == 1).sum(),  # 불균형 처리
            "eval_metric": "auc",
            "random_state": 42
        }
        
        model = xgb.XGBClassifier(**params)
        
        cv_aucs = []
        for train_idx, val_idx in tscv.split(X):
            model.fit(
                X.iloc[train_idx], y.iloc[train_idx],
                eval_set=[(X.iloc[val_idx], y.iloc[val_idx])],
                early_stopping_rounds=30,
                verbose=False
            )
            val_preds = model.predict_proba(X.iloc[val_idx])[:, 1]
            cv_aucs.append(roc_auc_score(y.iloc[val_idx], val_preds))
        
        avg_auc = np.mean(cv_aucs)
        mlflow.log_metric("cv_auc_mean", avg_auc)
        mlflow.sklearn.log_model(model, model_name)
        
        # 피처 중요도
        importance = pd.DataFrame({
            "feature": feature_cols,
            "importance": model.feature_importances_
        }).sort_values("importance", ascending=False)
        
        return {
            "model": model,
            "cv_auc": avg_auc,
            "feature_importance": importance,
            "model_uri": mlflow.get_artifact_uri(model_name)
        }
```

---

## 5. 시뮬레이션 패턴

### 5-1. OEE 개선 시나리오 시뮬레이션

```python
import numpy as np
from dataclasses import dataclass
from typing import List

@dataclass
class OEEScenario:
    name: str
    availability_delta: float   # 가용률 변화 (예: +0.05 = 5%p 개선)
    performance_delta: float    # 성능률 변화
    quality_delta: float        # 품질률 변화
    investment_krw: float       # 투자 비용 (원)

def simulate_oee_scenarios(
    current_oee: dict,                # {"availability": 0.85, "performance": 0.80, "quality": 0.97}
    scenarios: List[OEEScenario],
    annual_revenue_per_unit: float,   # 단위당 연간 매출 기여
    production_capacity: int          # 연간 최대 생산 가능량
) -> pd.DataFrame:
    """
    OEE 개선 시나리오별 재무 효과 시뮬레이션
    """
    results = []
    
    current_oee_val = (
        current_oee["availability"] * 
        current_oee["performance"] * 
        current_oee["quality"]
    )
    
    for s in scenarios:
        new_avail = min(current_oee["availability"] + s.availability_delta, 1.0)
        new_perf  = min(current_oee["performance"]  + s.performance_delta,  1.0)
        new_qual  = min(current_oee["quality"]       + s.quality_delta,      1.0)
        
        new_oee = new_avail * new_perf * new_qual
        oee_improvement = new_oee - current_oee_val
        
        # 추가 생산량 = 기존 설비로 더 만들 수 있는 수량
        additional_units = production_capacity * oee_improvement
        
        # 재무 효과
        revenue_increase = additional_units * annual_revenue_per_unit
        payback_months = (s.investment_krw / revenue_increase * 12 
                          if revenue_increase > 0 else float("inf"))
        roi_1yr = (revenue_increase - s.investment_krw) / s.investment_krw * 100
        
        results.append({
            "시나리오": s.name,
            "현재OEE": f"{current_oee_val:.1%}",
            "개선OEE": f"{new_oee:.1%}",
            "OEE개선폭": f"+{oee_improvement:.1%}",
            "추가생산량": int(additional_units),
            "연간매출증가": f"₩{revenue_increase:,.0f}",
            "투자비용": f"₩{s.investment_krw:,.0f}",
            "ROI(1년)": f"{roi_1yr:.0f}%",
            "투자회수기간": f"{payback_months:.1f}개월"
        })
    
    return pd.DataFrame(results)
```

### 5-2. 몬테카를로 시뮬레이션 (납기 리스크)

```python
def simulate_delivery_risk(
    planned_lead_time: int,       # 계획 리드타임 (일)
    process_steps: list,          # [{"name": str, "mean": float, "std": float}]
    n_simulations: int = 10000
) -> dict:
    """
    납기 리스크 몬테카를로 시뮬레이션
    각 공정의 소요시간 불확실성 → 전체 납기 분포 도출
    """
    total_times = np.zeros(n_simulations)
    
    for step in process_steps:
        # 정규분포로 각 공정 소요시간 샘플링
        step_times = np.random.normal(
            loc=step["mean"], 
            scale=step["std"], 
            size=n_simulations
        )
        step_times = np.clip(step_times, step["mean"] * 0.5, step["mean"] * 2.0)
        total_times += step_times
    
    on_time_rate = (total_times <= planned_lead_time).mean()
    
    return {
        "납기_준수_확률": f"{on_time_rate:.1%}",
        "예상_리드타임_평균": f"{total_times.mean():.1f}일",
        "P50_리드타임": f"{np.percentile(total_times, 50):.1f}일",
        "P80_리드타임": f"{np.percentile(total_times, 80):.1f}일",
        "P95_리드타임": f"{np.percentile(total_times, 95):.1f}일",
        "리스크_버퍼_권고": f"{np.percentile(total_times, 95) - planned_lead_time:.1f}일 추가",
        "분포_히스토그램": total_times  # 시각화용
    }
```

---

## 6. 분석 산출물 형식

| 산출물 | 경로 | 내용 |
|--------|------|------|
| EDA 노트북 | ai-models/notebooks/{feature}-eda.ipynb | 데이터 탐색, 분포, 상관관계 |
| 전처리 파이프라인 | ai-models/src/preprocessing/{feature}.py | 재현 가능한 전처리 코드 |
| 피처 스토어 정의 | docs/feature-store-{domain}.md | 피처 목록, 계산 방법, 출처 |
| 모델 카드 | ai-models/docs/model-card-{name}.md | 성능, 한계, 데이터 요구사항 |
| 시나리오 보고서 | docs/simulation-{scenario}-{date}.md | 시나리오별 효과 비교표 |
| 예측 결과 API | docs/api-spec-ml-{name}.yaml | 예측 서빙 API 명세 |

## 7. 최소 성능 기준

| 모델 유형 | 지표 | 최소 기준 |
|---------|------|---------|
| 고장 예측 (분류) | AUC-ROC | ≥ 0.85 |
| 고장 예측 (분류) | F1-Score (Failure class) | ≥ 0.70 |
| 생산량 예측 (회귀) | MAPE | ≤ 10% |
| 품질 예측 (회귀) | R² | ≥ 0.80 |
| 이상감지 | Precision | ≥ 0.80 (오경보 최소화) |
| 납기 예측 | MAE | ≤ 1일 |
