# Manufacturing Glossary — BESOLT 제조 도메인 용어 사전

## 핵심 KPI 지표

### OEE (Overall Equipment Effectiveness / 설비종합효율)
- **공식**: OEE = 가용률(Availability) × 성능률(Performance) × 품질률(Quality)
- **목표**: World-class ≥ 85%, 일반 제조 60~70%
- **데이터 소스**: PLC, MES 가동 이력
- **계산 예시**:
  ```
  가용률 = 실제 가동시간 / 계획 가동시간
  성능률 = (실제 생산량 × 이상적 사이클 타임) / 실제 가동시간
  품질률 = 양품 수량 / 전체 생산 수량
  ```

### Takt Time (택트 타임)
- **공식**: Takt Time = 가용 생산시간 / 고객 수요량
- **용도**: 라인 밸런싱, 병목 공정 식별
- **단위**: 초/개 또는 분/개

### Yield Rate (수율)
- **공식**: Yield = 양품 / (양품 + 불량품) × 100%
- **유형**: First Pass Yield (FPY), Rolled Throughput Yield (RTY)

### Cpk / Ppk (공정능력지수)
- **Cpk**: 단기 공정능력 (공정이 안정적일 때)
- **Ppk**: 장기 공정능력 (전체 산포 포함)
- **기준**: Cpk ≥ 1.33 (4σ), Cpk ≥ 1.67 (5σ) 요구 시
- **공식**: Cpk = min[(USL-μ)/3σ, (μ-LSL)/3σ]

---

## 시스템 용어

### MES (Manufacturing Execution System)
- 생산 실행 관리 시스템
- 주요 기능: 작업지시, 실적집계, 품질관리, 설비관리
- 연동 대상: ERP(상위), PLC/SCADA(하위)
- 표준: ISA-95, ISA-88

### ERP (Enterprise Resource Planning)
- SAP, Oracle 등
- MES와 ISA-95 인터페이스로 연동
- 생산계획 → MES 작업지시 하달

### SCADA (Supervisory Control and Data Acquisition)
- 현장 설비 모니터링 및 제어
- 데이터 수집 주기: 100ms ~ 1sec
- OPC-UA/Modbus로 데이터 추출

### PLC (Programmable Logic Controller)
- 설비 직접 제어 장치
- 데이터: I/O 상태, 카운터, 타이머, 아날로그 값

### OPC-UA (Open Platform Communications Unified Architecture)
- 산업용 M2M 통신 프로토콜
- 보안: X.509 인증서 기반
- 포트: 기본 4840
- 구독 모델: Subscription → MonitoredItem → Notification

### MQTT (Message Queuing Telemetry Transport)
- IoT 센서 데이터 전송 경량 프로토콜
- QoS 0(최선), 1(최소 1회), 2(정확 1회)
- Topic 구조 예: `factory/{line_id}/sensor/{sensor_id}/data`

---

## 공정 용어

### 정밀 판금 (Precision Sheet Metal)
- 소재: SPCC, SUS304, AL5052 등
- 공정: 레이저 절단 → 벤딩 → 용접 → 표면처리
- 품질 지표: 치수 정밀도(±0.1mm), 표면조도(Ra)
- 주요 불량: 버(burr), 뒤틀림, 치수 초과

### 반도체 세정/코팅 (Semiconductor Cleaning/Coating)
- 세정 공정: 파티클 제거, 화학물 세정, 건조
- 코팅 공정: CVD, PVD, 스핀코팅
- 핵심 파라미터: 온도, 압력, 유량, 시간
- 품질 지표: 파티클 수, 막 두께 균일도, 접착력

### 이상감지 (Anomaly Detection) 패턴
- **포인트 이상**: 단일 센서값 임계치 초과
- **맥락 이상**: 값은 정상이나 패턴 비정상 (LSTM/Autoencoder)
- **집단 이상**: 여러 센서 동시 이상 (상관관계 기반)

### 예지보전 (Predictive Maintenance)
- **RUL (Remaining Useful Life)**: 설비 잔여 수명 예측
- **PHM (Prognostics and Health Management)**: 건강 상태 모니터링
- 모델: 생존분석(Survival Analysis), LSTM, XGBoost
- 입력: 진동, 온도, 전류, 압력 센서 시계열

---

## 데이터 타입

### 센서 데이터
```json
{
  "sensor_id": "LINE01-TEMP-001",
  "timestamp": "2025-01-01T00:00:00.000Z",
  "value": 85.3,
  "unit": "°C",
  "quality": "GOOD",
  "line_id": "LINE01",
  "equipment_id": "PRESS-001"
}
```

### 품질 검사 데이터
```json
{
  "inspection_id": "INS-2025-001",
  "work_order": "WO-001",
  "product_code": "P-001",
  "measurement": {"dimension_a": 10.05, "dimension_b": 5.02},
  "spec": {"dimension_a": {"nominal": 10.0, "usl": 10.1, "lsl": 9.9}},
  "result": "PASS",
  "inspector": "AUTO"
}
```

### 설비 가동 이벤트
```json
{
  "equipment_id": "PRESS-001",
  "event_type": "DOWNTIME_START",
  "reason_code": "MAINT-PM",
  "timestamp": "2025-01-01T08:00:00Z",
  "planned": true
}
```
