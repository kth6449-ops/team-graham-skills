# Manufacturing Cost Analysis (OpEx) Skill — BESOLT

## 적용 범위
제조업 기반 운영비용(OpEx) 분석 및 제조원가 구조 분석.
SOLT-BI의 원가 기반 P&L 관리 모듈, 고객사 원가 컨설팅 시 활용.

---

## 1. 제조원가 구조 (Manufacturing Cost Structure)

### 1-1. 원가 3요소
```
제조원가 (Manufacturing Cost)
├── 직접재료비 (Direct Material Cost)      ← 제품에 직접 투입되는 원자재
├── 직접노무비 (Direct Labor Cost)         ← 생산직 직접 인건비
└── 제조간접비 (Manufacturing Overhead)
    ├── 간접재료비 (Indirect Material)      ← 소모품, 보조재료
    ├── 간접노무비 (Indirect Labor)         ← 관리직, 품질검사 인건비
    ├── 감가상각비 (Depreciation)
    ├── 설비유지비 (Maintenance)
    ├── 유틸리티 (Utility: 전기, 가스, 용수)
    └── 기타 (임차료, 보험, 물류 등)
```

### 1-2. 원가 흐름 (Cost Flow)
```
원재료비 → 재공품 → 제품 → 매출원가
  ↑              ↑
노무비 투입    제조간접비 배부
```

### 1-3. 원가 분류 기준

| 분류 기준 | 구분 | 내용 |
|-----------|------|------|
| 추적 가능성 | 직접비 / 간접비 | 제품별 직접 귀속 여부 |
| 생산량 변화 | 변동비 / 고정비 | 생산량 증감 시 비례 여부 |
| 통제 가능성 | 통제 가능 / 불가능 | 현장 관리자 의사결정 범위 |
| 관련성 | 관련 원가 / 매몰 원가 | 의사결정에 영향 여부 |

---

## 2. OpEx 분석 프레임워크

### 2-1. OpEx 핵심 항목 (제조업)

```python
OPEX_CATEGORIES = {
    "인건비": {
        "직접노무비": ["생산직 급여", "잔업수당", "복리후생"],
        "간접노무비": ["관리직 급여", "품질검사", "물류/창고"]
    },
    "재료비": {
        "직접재료": ["원자재", "부자재"],
        "간접재료": ["소모품", "포장재", "공구"]
    },
    "설비비용": {
        "감가상각": ["기계장치", "금형", "지그/픽스쳐"],
        "유지보수": ["예방정비(PM)", "수리비", "부품교체"],
        "임차료": ["설비 리스", "공장 임차"]
    },
    "유틸리티": {
        "에너지": ["전력", "가스", "스팀"],
        "용수": ["공업용수", "폐수처리"]
    },
    "품질비용": {
        "내부실패": ["불량 재작업", "스크랩"],
        "외부실패": ["클레임 대응", "리콜"],
        "예방비용": ["SPC 시스템", "검사장비"],
        "평가비용": ["검사인력", "시험비"]
    },
    "물류/창고": ["운반비", "보관비", "재고유지비용(ICC)"]
}
```

### 2-2. 단위원가 계산 (Unit Cost)

```python
def calculate_unit_cost(
    direct_material: float,    # 직접재료비
    direct_labor: float,       # 직접노무비
    overhead_rate: float,      # 제조간접비 배부율
    direct_labor_hours: float, # 직접노무 시간
    quantity: int              # 생산수량
) -> dict:
    """
    제품 단위원가 계산
    
    overhead_rate: 직접노무비 기준 배부율 (예: 150% → 1.5)
    """
    manufacturing_overhead = direct_labor * overhead_rate
    total_manufacturing_cost = (
        direct_material + direct_labor + manufacturing_overhead
    )
    unit_cost = total_manufacturing_cost / quantity
    
    return {
        "직접재료비": direct_material,
        "직접노무비": direct_labor,
        "제조간접비": manufacturing_overhead,
        "제조원가_합계": total_manufacturing_cost,
        "단위원가": unit_cost,
        "원가_구조비율": {
            "재료비_비율": direct_material / total_manufacturing_cost * 100,
            "노무비_비율": direct_labor / total_manufacturing_cost * 100,
            "간접비_비율": manufacturing_overhead / total_manufacturing_cost * 100
        }
    }
```

### 2-3. 손익분기점 분석 (BEP)

```python
def calculate_bep(
    fixed_cost: float,         # 고정비 합계
    selling_price: float,      # 판매단가
    variable_cost_per_unit: float  # 단위 변동비
) -> dict:
    """
    BEP (Break-Even Point) 분석
    공헌이익 = 판매가 - 변동비
    BEP 수량 = 고정비 / 공헌이익
    """
    contribution_margin = selling_price - variable_cost_per_unit
    contribution_margin_ratio = contribution_margin / selling_price
    
    bep_units = fixed_cost / contribution_margin
    bep_revenue = fixed_cost / contribution_margin_ratio
    
    return {
        "공헌이익_단위": contribution_margin,
        "공헌이익률": contribution_margin_ratio * 100,
        "BEP_수량": bep_units,
        "BEP_매출액": bep_revenue,
        "안전한계율": None  # (실제매출 - BEP매출) / 실제매출 × 100
    }
```

---

## 3. SOLT-BI 원가 분석 데이터 모델

### 3-1. DB 스키마 (PostgreSQL)

```sql
-- 원가 센터 (Cost Center)
CREATE TABLE cost_centers (
    id              SERIAL PRIMARY KEY,
    code            VARCHAR(20) UNIQUE NOT NULL,
    name            VARCHAR(100) NOT NULL,
    type            VARCHAR(20),  -- PRODUCTION / SUPPORT / ADMIN
    parent_id       INTEGER REFERENCES cost_centers(id),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 원가 항목 마스터
CREATE TABLE cost_items (
    id              SERIAL PRIMARY KEY,
    code            VARCHAR(30) UNIQUE NOT NULL,
    name            VARCHAR(100) NOT NULL,
    category        VARCHAR(30),  -- MATERIAL / LABOR / OVERHEAD / UTILITY / QUALITY
    sub_category    VARCHAR(30),
    cost_type       VARCHAR(20),  -- FIXED / VARIABLE / SEMI_VARIABLE
    unit            VARCHAR(20)   -- KRW / USD / KG / KWH / HR
);

-- 실제 원가 실적 (월별)
CREATE TABLE cost_actuals (
    id              SERIAL PRIMARY KEY,
    year_month      CHAR(7) NOT NULL,       -- 'YYYY-MM'
    cost_center_id  INTEGER REFERENCES cost_centers(id),
    cost_item_id    INTEGER REFERENCES cost_items(id),
    product_code    VARCHAR(50),            -- NULL = 간접비
    amount          DECIMAL(15,2) NOT NULL, -- 금액 (KRW)
    quantity        DECIMAL(12,4),          -- 수량 (해당 시)
    unit_price      DECIMAL(12,4),          -- 단가 (해당 시)
    source          VARCHAR(30),            -- ERP / MANUAL / MES
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 예산 (Budget)
CREATE TABLE cost_budgets (
    id              SERIAL PRIMARY KEY,
    fiscal_year     CHAR(4) NOT NULL,
    year_month      CHAR(7) NOT NULL,
    cost_center_id  INTEGER REFERENCES cost_centers(id),
    cost_item_id    INTEGER REFERENCES cost_items(id),
    budget_amount   DECIMAL(15,2) NOT NULL,
    revised_amount  DECIMAL(15,2),
    version         INTEGER DEFAULT 1
);
```

### 3-2. 원가 분석 쿼리 패턴

```sql
-- 월별 원가 실적 vs 예산 (예실차 분석)
SELECT
    a.year_month,
    ci.category,
    ci.name AS 원가항목,
    SUM(a.amount) AS 실적,
    SUM(b.budget_amount) AS 예산,
    SUM(a.amount) - SUM(b.budget_amount) AS 차이,
    ROUND((SUM(a.amount) - SUM(b.budget_amount)) 
          / NULLIF(SUM(b.budget_amount), 0) * 100, 1) AS 달성률_PCT
FROM cost_actuals a
JOIN cost_items ci ON ci.id = a.cost_item_id
LEFT JOIN cost_budgets b 
    ON b.year_month = a.year_month 
    AND b.cost_item_id = a.cost_item_id
WHERE a.year_month BETWEEN '2025-01' AND '2025-12'
GROUP BY a.year_month, ci.category, ci.name
ORDER BY a.year_month, ci.category;

-- 제품별 단위원가 트렌드
SELECT
    year_month,
    product_code,
    SUM(CASE WHEN ci.category = 'MATERIAL' THEN amount ELSE 0 END) AS 재료비,
    SUM(CASE WHEN ci.category = 'LABOR'    THEN amount ELSE 0 END) AS 노무비,
    SUM(CASE WHEN ci.category = 'OVERHEAD' THEN amount ELSE 0 END) AS 간접비,
    SUM(amount) AS 총원가
FROM cost_actuals a
JOIN cost_items ci ON ci.id = a.cost_item_id
WHERE product_code IS NOT NULL
GROUP BY year_month, product_code;
```

---

## 4. 품질원가 (CoQ: Cost of Quality) 분석

```python
COQ_FRAMEWORK = {
    "예방비용 (Prevention)": {
        "비율_목표": "2~5%",
        "항목": ["품질교육", "SPC 운영", "설계검토", "공급업체 관리", "예방정비"]
    },
    "평가비용 (Appraisal)": {
        "비율_목표": "3~5%",
        "항목": ["수입검사", "공정검사", "완제품검사", "시험장비 교정"]
    },
    "내부실패비용 (Internal Failure)": {
        "비율_목표": "< 5%",
        "항목": ["불량 스크랩", "재작업(Rework)", "재검사", "생산 지연"]
    },
    "외부실패비용 (External Failure)": {
        "비율_목표": "< 2%",
        "항목": ["클레임 처리", "보증수리", "반품", "리콜", "고객불만 대응"]
    }
}

def calculate_coq(actuals: dict) -> dict:
    """CoQ 비율 계산 및 개선 포인트 도출"""
    total_revenue = actuals["revenue"]
    total_coq = sum([
        actuals["prevention"],
        actuals["appraisal"],
        actuals["internal_failure"],
        actuals["external_failure"]
    ])
    
    return {
        "총_CoQ": total_coq,
        "CoQ_매출비율": total_coq / total_revenue * 100,
        "예방비율": actuals["prevention"] / total_coq * 100,
        "실패비용_비율": (actuals["internal_failure"] + 
                         actuals["external_failure"]) / total_coq * 100,
        "개선_레버리지": "예방비용 1원 투자 → 실패비용 10원 절감 (산업 평균)"
    }
```

---

## 5. 원가 절감 분석 프레임워크

### 5-1. 원가 절감 기회 분류

| 카테고리 | 분석 방법 | 기대 절감 |
|---------|----------|---------|
| 재료비 | 구매단가 분석, 대체재 검토, 수율 개선 | 5~15% |
| 에너지 | 설비별 전력소비 분석, Peak 관리 | 10~20% |
| 불량/재작업 | CoQ 분석, 불량 파레토 | 20~40% |
| 설비 가동률 | OEE 분석, 정지 원인 분류 | 10~25% |
| 재고 | 재고회전율, ICC(재고유지비용) | 15~30% |

### 5-2. 절감 효과 계산

```python
def calculate_cost_saving_impact(
    oee_improvement: float,      # OEE 개선률 (예: 0.05 = 5%p)
    current_fixed_cost: float,   # 현재 고정비
    current_production: int,     # 현재 생산량
    defect_rate_reduction: float # 불량률 감소 (예: 0.02 = 2%p)
) -> dict:
    """
    OEE 개선 + 불량률 감소에 따른 원가 절감 효과
    """
    # OEE 개선으로 단위 고정비 절감
    new_production = current_production * (1 + oee_improvement)
    unit_fixed_cost_saving = current_fixed_cost * oee_improvement / new_production
    
    return {
        "OEE개선_추가생산량": new_production - current_production,
        "단위_고정비_절감": unit_fixed_cost_saving,
        "불량감소_절감액": defect_rate_reduction * current_production,
        "연간_절감_추정": (unit_fixed_cost_saving * new_production + 
                          defect_rate_reduction * current_production * 12)
    }
```

---

## 6. AI 기반 원가 분석 활용 패턴

### 이상 원가 감지
```python
# 월별 원가 이상 감지 (전월 대비 급등)
def detect_cost_anomaly(cost_df, threshold_pct=0.15):
    cost_df["전월비_변화율"] = cost_df["amount"].pct_change()
    anomalies = cost_df[cost_df["전월비_변화율"].abs() > threshold_pct]
    return anomalies[["year_month", "cost_item", "amount", "전월비_변화율"]]
```

### 원가 예측 (Prophet)
```python
from prophet import Prophet

def forecast_cost(cost_history_df, periods=3):
    """월별 원가 3개월 예측"""
    df = cost_history_df.rename(columns={"year_month": "ds", "amount": "y"})
    model = Prophet(seasonality_mode="multiplicative", yearly_seasonality=True)
    model.fit(df)
    future = model.make_future_dataframe(periods=periods, freq="M")
    forecast = model.predict(future)
    return forecast[["ds", "yhat", "yhat_lower", "yhat_upper"]].tail(periods)
```

---

## 7. 산출물 형식

| 산출물 | 경로 | 포함 내용 |
|--------|------|----------|
| 원가 분석 보고서 | docs/cost-analysis-{YYYYMM}.md | 예실차, CoQ, 절감 기회 |
| 단위원가 테이블 | docs/unit-cost-{product}-{YYYYMM}.md | 제품별 원가 분해 |
| BEP 분석 | docs/bep-analysis-{scenario}.md | 시나리오별 손익분기 |
| 절감 효과 시뮬레이션 | docs/cost-saving-simulation.md | OEE/품질 개선 효과 |
