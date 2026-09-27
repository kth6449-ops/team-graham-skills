# Manufacturing Business Intelligence (BI) Skill — BESOLT
## 제조업 기반 데이터 분석 · 시각화 · 레포팅

## 적용 범위
SOLT-BI 대시보드 설계, 제조 경영 KPI 시각화, 경영진/현장 레포팅 자동화.
고객사 BI 구축 컨설팅 및 데이터 스토리텔링.

---

## 1. 제조 BI 데이터 아키텍처

### 1-1. 레이어 구조

```
[데이터 소스]          [수집/적재]        [저장]            [서비스]
MES 실적 데이터   →                  →  DW (PostgreSQL) →  SOLT-BI 대시보드
ERP 원가/자재     →  ETL Pipeline   →  Data Mart       →  경영진 리포트
센서/OPC-UA       →  (Airflow)      →  TimescaleDB     →  현장 모니터링
품질 검사 데이터  →                  →  Redis Cache    →  API (FastAPI)
```

### 1-2. Data Mart 스키마 (Star Schema)

```sql
-- 팩트 테이블: 생산 실적
CREATE TABLE fact_production (
    production_key    BIGSERIAL PRIMARY KEY,
    date_key          INTEGER REFERENCES dim_date(date_key),
    shift_key         INTEGER REFERENCES dim_shift(shift_key),
    equipment_key     INTEGER REFERENCES dim_equipment(equipment_key),
    product_key       INTEGER REFERENCES dim_product(product_key),
    work_order        VARCHAR(50),
    
    -- 생산 지표
    planned_qty       INTEGER,
    actual_qty        INTEGER,
    good_qty          INTEGER,
    defect_qty        INTEGER,
    
    -- 시간 지표 (분 단위)
    planned_time      INTEGER,
    operating_time    INTEGER,
    downtime_planned  INTEGER,
    downtime_unplanned INTEGER,
    
    -- 파생 지표 (계산 컬럼)
    oee               DECIMAL(5,4) GENERATED ALWAYS AS (
        CASE WHEN planned_time > 0 THEN
            (operating_time::DECIMAL / planned_time) *
            (CASE WHEN operating_time > 0 THEN actual_qty::DECIMAL * cycle_time_std / (operating_time * 60) ELSE 0 END) *
            (CASE WHEN actual_qty > 0 THEN good_qty::DECIMAL / actual_qty ELSE 0 END)
        ELSE 0 END
    ) STORED,
    
    cycle_time_std    DECIMAL(8,3)  -- 표준 사이클 타임 (초)
);

-- 차원 테이블: 날짜
CREATE TABLE dim_date (
    date_key          INTEGER PRIMARY KEY,  -- YYYYMMDD
    full_date         DATE,
    year              SMALLINT,
    quarter           SMALLINT,
    month             SMALLINT,
    week              SMALLINT,
    day_of_week       SMALLINT,
    is_holiday        BOOLEAN,
    fiscal_year       SMALLINT,
    fiscal_quarter    SMALLINT
);

-- 차원 테이블: 설비
CREATE TABLE dim_equipment (
    equipment_key     SERIAL PRIMARY KEY,
    equipment_id      VARCHAR(50) UNIQUE,
    equipment_name    VARCHAR(100),
    equipment_type    VARCHAR(50),    -- PRESS / LATHE / WELDER 등
    line_id           VARCHAR(20),
    factory_id        VARCHAR(20),
    capacity_per_hour INTEGER,
    installed_date    DATE,
    is_active         BOOLEAN DEFAULT TRUE
);
```

---

## 2. 제조 KPI 체계

### 2-1. 경영 계층별 KPI

```python
MANUFACTURING_KPI_HIERARCHY = {
    
    # Level 1: 경영진 (월별)
    "경영 대시보드": {
        "매출_원가율": "매출원가 / 매출액 × 100 (목표: < 70%)",
        "영업이익률": "영업이익 / 매출액 × 100",
        "납기_준수율 (OTD)": "정시 납품 건수 / 전체 납품 건수 (목표: ≥ 98%)",
        "고객_클레임_발생률": "클레임 건수 / 출하수량 × 1,000,000 (PPM)",
        "전사_OEE": "전체 설비 평균 OEE (목표: ≥ 75%)",
        "재고_회전율": "매출원가 / 평균재고액 (목표: ≥ 12회/년)",
    },
    
    # Level 2: 생산관리자 (주별)
    "생산 대시보드": {
        "라인별_OEE": "설비/라인별 OEE",
        "계획_달성률": "실제생산량 / 계획생산량 × 100",
        "불량률_PPM": "불량수량 / 생산수량 × 1,000,000",
        "설비_가동률": "실가동시간 / 부하시간 × 100",
        "정지_TOP5": "정지 원인별 시간 파레토",
        "Takt_Time_달성": "실사이클타임 vs 표준Takt",
    },
    
    # Level 3: 현장 작업자 (실시간)
    "현장 모니터 (Andon)": {
        "현재_생산량_vs_목표": "실시간 생산 카운터",
        "현재_불량": "최근 1시간 불량 발생",
        "설비_상태": "가동/정지/경보",
        "품질_이상_알림": "SPC 관리이탈 즉시 표시",
    }
}
```

### 2-2. KPI 계산 쿼리 패턴

```sql
-- 월별 OEE 트렌드 (라인별)
SELECT
    TO_CHAR(d.full_date, 'YYYY-MM') AS year_month,
    e.line_id,
    ROUND(AVG(p.oee) * 100, 1) AS avg_oee_pct,
    ROUND(AVG(p.operating_time::DECIMAL / NULLIF(p.planned_time, 0)) * 100, 1) AS availability_pct,
    SUM(p.good_qty) AS total_good_qty,
    SUM(p.defect_qty) AS total_defect_qty,
    ROUND(SUM(p.defect_qty)::DECIMAL / NULLIF(SUM(p.actual_qty), 0) * 1000000, 0) AS defect_ppm
FROM fact_production p
JOIN dim_date d ON d.date_key = p.date_key
JOIN dim_equipment e ON e.equipment_key = p.equipment_key
WHERE d.full_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY TO_CHAR(d.full_date, 'YYYY-MM'), e.line_id
ORDER BY year_month, e.line_id;

-- 불량 파레토 분석
SELECT
    defect_type,
    COUNT(*) AS 발생건수,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS 비율_PCT,
    ROUND(SUM(COUNT(*)) OVER (ORDER BY COUNT(*) DESC) * 100.0 
          / SUM(COUNT(*)) OVER (), 1) AS 누적비율_PCT
FROM defect_records
WHERE occur_date >= CURRENT_DATE - INTERVAL '3 months'
GROUP BY defect_type
ORDER BY 발생건수 DESC;
```

---

## 3. 시각화 설계 패턴 (React + Recharts)

### 3-1. OEE 게이지 차트

```typescript
// OEE Gauge Component
import { PieChart, Pie, Cell, ResponsiveContainer } from 'recharts';

const OEEGauge: React.FC<{ value: number; target: number }> = ({ value, target }) => {
  const color = value >= target ? '#22c55e' : value >= target * 0.9 ? '#f59e0b' : '#ef4444';
  
  const data = [
    { name: 'OEE', value },
    { name: 'remaining', value: 100 - value }
  ];
  
  return (
    <div className="relative w-48 h-48">
      <ResponsiveContainer>
        <PieChart>
          <Pie data={data} cx="50%" cy="50%" innerRadius={60} outerRadius={80}
               startAngle={180} endAngle={0} dataKey="value">
            <Cell fill={color} />
            <Cell fill="#e5e7eb" />
          </Pie>
        </PieChart>
      </ResponsiveContainer>
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <span className="text-3xl font-bold" style={{ color }}>{value}%</span>
        <span className="text-xs text-gray-500">목표: {target}%</span>
      </div>
    </div>
  );
};
```

### 3-2. 다중 KPI 트렌드 (콤보 차트)

```typescript
import { ComposedChart, Bar, Line, XAxis, YAxis, CartesianGrid, 
         Tooltip, Legend, ResponsiveContainer } from 'recharts';

const ProductionTrendChart: React.FC<{ data: ProductionData[] }> = ({ data }) => (
  <ResponsiveContainer width="100%" height={300}>
    <ComposedChart data={data}>
      <CartesianGrid strokeDasharray="3 3" />
      <XAxis dataKey="month" />
      <YAxis yAxisId="qty" orientation="left" />
      <YAxis yAxisId="rate" orientation="right" unit="%" />
      <Tooltip formatter={(val, name) => 
        name === 'defect_ppm' ? [`${val} PPM`, '불량률'] : [val, name]} />
      <Legend />
      <Bar yAxisId="qty" dataKey="good_qty" fill="#3b82f6" name="양품수량" />
      <Bar yAxisId="qty" dataKey="defect_qty" fill="#ef4444" name="불량수량" />
      <Line yAxisId="rate" type="monotone" dataKey="oee_pct" 
            stroke="#f59e0b" strokeWidth={2} name="OEE (%)" dot={{ r: 4 }} />
    </ComposedChart>
  </ResponsiveContainer>
);
```

### 3-3. 파레토 차트 (불량 분석)

```typescript
const ParetoChart: React.FC<{ data: DefectData[] }> = ({ data }) => {
  const sorted = [...data].sort((a, b) => b.count - a.count);
  let cumulative = 0;
  const totalCount = sorted.reduce((sum, d) => sum + d.count, 0);
  const chartData = sorted.map(d => {
    cumulative += d.count;
    return { ...d, cumulative_pct: (cumulative / totalCount) * 100 };
  });

  return (
    <ResponsiveContainer width="100%" height={300}>
      <ComposedChart data={chartData}>
        <Bar dataKey="count" fill="#3b82f6" name="발생건수" />
        <Line type="monotone" dataKey="cumulative_pct" 
              stroke="#ef4444" strokeWidth={2} 
              yAxisId="right" name="누적비율(%)" />
        {/* 80% 기준선 */}
        <ReferenceLine y={80} yAxisId="right" stroke="#f59e0b" 
                       strokeDasharray="5 5" label="80%" />
      </ComposedChart>
    </ResponsiveContainer>
  );
};
```

---

## 4. 자동 레포팅 시스템

### 4-1. 월간 경영 보고서 자동 생성

```python
from jinja2 import Template
from datetime import datetime, timedelta
import pandas as pd

MONTHLY_REPORT_TEMPLATE = """
# 월간 생산 경영 보고서
**기준월**: {{ year_month }}  **작성일**: {{ created_at }}

## 1. 핵심 KPI 요약
| KPI | 실적 | 목표 | 전월 | 달성여부 |
|-----|------|------|------|---------|
{% for kpi in kpi_summary %}
| {{ kpi.name }} | {{ kpi.actual }} | {{ kpi.target }} | {{ kpi.prev }} | {{ '✅' if kpi.achieved else '❌' }} |
{% endfor %}

## 2. OEE 분석
- 전사 평균 OEE: **{{ oee_avg }}%** (목표: {{ oee_target }}%)
- 최고 라인: {{ best_line }} ({{ best_oee }}%)
- 개선 필요: {{ worst_line }} ({{ worst_oee }}%)

## 3. 불량/품질
- 전체 불량률: **{{ defect_ppm }} PPM**
- Top 3 불량 원인: {{ top_defects }}

## 4. 주요 이슈 및 조치
{{ issues_and_actions }}

## 5. 익월 중점 과제
{{ next_month_focus }}
"""

async def generate_monthly_report(year_month: str) -> str:
    """월간 보고서 자동 생성"""
    kpi_data = await fetch_monthly_kpis(year_month)
    template = Template(MONTHLY_REPORT_TEMPLATE)
    return template.render(**kpi_data)
```

### 4-2. 실시간 알림 트리거

```python
# KPI 임계치 기반 알림
KPI_ALERT_RULES = [
    {"kpi": "oee", "operator": "<", "threshold": 0.65, "severity": "HIGH",
     "message": "OEE {value:.1%} — 목표 대비 심각 저하. 즉시 점검 요망."},
    {"kpi": "defect_ppm", "operator": ">", "threshold": 5000, "severity": "CRITICAL",
     "message": "불량률 {value:,.0f} PPM 초과 — 라인 중단 검토 필요."},
    {"kpi": "otd_rate", "operator": "<", "threshold": 0.95, "severity": "HIGH",
     "message": "납기준수율 {value:.1%} — 고객 영향 발생 위험."},
]
```

---

## 5. BI 대시보드 설계 원칙

### 5-1. 제조 현장 UI/UX 규칙
- **컬러 코딩 통일**: 🟢 정상(≥목표), 🟡 주의(90~99%), 🔴 이상(<90%)
- **폰트 크기**: 현장 대형 모니터 기준 — 핵심 수치 48px 이상
- **갱신 주기**: 실시간(센서) 3초, 집계 KPI 1분, 경영 보고 1시간
- **모바일 대응**: Graham 이동 중 확인용 반응형 필수
- **다크모드**: 야간 현장 모니터 눈부심 방지

### 5-2. 정보 계층 (Information Hierarchy)
```
화면 상단: 가장 중요한 단일 지표 (OEE 또는 알림 카운트)
중간 영역: 3~5개 핵심 KPI 카드
하단 영역: 트렌드 차트, 상세 테이블
사이드바: 필터 (날짜, 라인, 제품)
```

---

## 6. 산출물 형식

| 산출물 | 경로 | 갱신 주기 |
|--------|------|---------|
| 실시간 대시보드 | src/frontend/features/bi-dashboard/ | 실시간 |
| 월간 경영 보고서 | docs/reports/monthly-{YYYYMM}.md | 월 1회 자동 |
| KPI 정의서 | docs/kpi-definition.md | 변경 시 |
| 대시보드 설계서 | docs/bi-dashboard-spec.md | 변경 시 |
