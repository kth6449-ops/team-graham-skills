# B2B Project Management Workflow Skill — BESOLT
## 근거 표준: IATF 16949 / PMBOK 7th / ASPICE (Optional) / VDA 6.3

## 적용 범위
제조업 B2B 프로젝트 기획, 실행, 품질 프로세스 수립.
고객사 프로젝트 관리, SOLT-AI 제품 납품 프로젝트, 내부 개발 프로세스 거버넌스.

---

## 1. 표준별 핵심 개념 요약

### 1-1. IATF 16949 (자동차 품질경영시스템)

```
핵심 요구사항:
├── APQP (Advanced Product Quality Planning)  ← 제품 개발 전 품질 기획
├── PPAP (Production Part Approval Process)   ← 양산 부품 승인
├── FMEA (Failure Mode & Effects Analysis)    ← 잠재 고장 분석
├── Control Plan                               ← 공정 관리 계획서
├── MSA (Measurement System Analysis)         ← 측정시스템 분석
└── SPC (Statistical Process Control)         ← 통계적 공정 관리
```

**APQP 5단계 + PPAP 연계:**
```
Phase 1: 계획 및 정의 (Plan & Define)
  → 고객 요구사항, VOC, 설계목표, 예비 BOM/공정흐름도

Phase 2: 제품 설계 및 개발 (Product Design & Dev)
  → DFMEA, 설계검증계획(DVP&R), 도면/사양서, 시제품

Phase 3: 공정 설계 및 개발 (Process Design & Dev)
  → PFMEA, Control Plan, 공정흐름도, MSA 계획

Phase 4: 제품 및 공정 유효성 확인 (Product & Process Validation)
  → 시생산(Trial Run), SPC, MSA, PPAP 제출

Phase 5: 피드백, 평가 및 시정조치 (Launch & Feedback)
  → 양산 이관, 고객 피드백, 지속개선 (Kaizen)
```

### 1-2. PMBOK 7th (프로젝트 관리 지식체계)

**12가지 원칙 (PMBOK 7th):**
1. 스튜어드십 (Stewardship)
2. 팀 (Team)
3. 이해관계자 참여 (Stakeholders)
4. 가치 (Value)
5. 시스템 사고 (Systems Thinking)
6. 리더십 (Leadership)
7. 조정 (Tailoring)
8. 품질 (Quality)
9. 복잡성 (Complexity)
10. 리스크 (Risk)
11. 적응성과 회복력 (Adaptability & Resiliency)
12. 변화 (Change)

**8가지 성과 영역 (Performance Domains):**
```python
PMBOK_DOMAINS = {
    "이해관계자": "식별, 분석, 참여 전략",
    "팀": "팀 구성, 역량 개발, 협업",
    "개발방식_및_생명주기": "Waterfall / Agile / Hybrid 선택",
    "기획": "범위, 일정, 원가, 자원 기획",
    "프로젝트작업": "실행, 의사소통, 변경관리",
    "인도": "요구사항 충족, 인도물 품질",
    "측정": "KPI, EVM, 성과 모니터링",
    "불확실성": "리스크, 불확실성 대응"
}
```

### 1-3. ASPICE (Automotive SPICE) — Optional

```
Process Areas (PA) 핵심:
├── SWE.1: 소프트웨어 요구사항 분석
├── SWE.2: 소프트웨어 아키텍처 설계
├── SWE.3: 소프트웨어 상세 설계 및 구현
├── SWE.4: 소프트웨어 단위 검증
├── SWE.5: 소프트웨어 통합 및 통합 테스트
├── SWE.6: 소프트웨어 적격성 테스트
├── MAN.3: 프로젝트 관리
└── SUP.1: 품질 보증

Capability Levels:
  0: Incomplete → 1: Performed → 2: Managed → 
  3: Established → 4: Predictable → 5: Optimizing

BESOLT 목표: Level 2 (Managed) — 계획되고 추적되는 프로세스
```

### 1-4. VDA 6.3 (프로세스 심사)

```
심사 영역 (P1~P7):
P1: 잠재적 분석 (사전 심사)
P2: 프로젝트 관리
P3: 제품/공정 개발 기획
P4: 공급업체 관리
P5: 입고자재 관리 / 창고
P6: 생산 공정 분석
P7: 고객 관리 (납품 및 서비스)

VDA 점수 체계:
  A (≥90%): 적합
  B (80~89%): 조건부 적합 (개선계획 필요)
  C (<80%): 부적합 (즉시 조치 필요)
```

---

## 2. BESOLT B2B 프로젝트 관리 프로세스

### 2-1. 통합 프로젝트 생명주기 (Hybrid: Waterfall Gate + Agile Sprint)

```
┌─────────────────────────────────────────────────────┐
│  PHASE 0: 기회 발굴 (Opportunity)                    │
│  - 고객 VOC 수집, RFQ/RFP 분석                       │
│  - 사전 타당성 (기술/원가/일정)                       │
│  Gate 0: Graham 승인 → 제안 진행 여부                │
└─────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────┐
│  PHASE 1: 제안 및 계약 (Proposal & Contract)         │
│  - 솔루션 아키텍처 제안 (Sam)                         │
│  - 원가 산정 → 견적서 작성                            │
│  - 계약 조건 협의 (납기, 인도물, 품질 기준)           │
│  Gate 1: Graham 승인 → 계약 체결                     │
└─────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────┐
│  PHASE 2: 기획 (Planning) — PMBOK 기획 영역          │
│  - WBS 작성, 마일스톤 정의                            │
│  - 리스크 등록부 (Risk Register) 작성                │
│  - 이해관계자 등록부 작성                             │
│  - APQP Phase 1 병행 (품질 기획)                     │
│  Gate 2: Graham + 고객 킥오프 승인                   │
└─────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────┐
│  PHASE 3~4: 실행 (Execution) — Agile 1주 스프린트   │
│  - Sam+Peter Pair 개발                               │
│  - 스프린트 리뷰: Graham + 고객 데모                 │
│  - FMEA, Control Plan 병행 작성                      │
│  - Tank QA 매 스프린트 종료 시                       │
│  Gate 3: 중간 인도물 승인 (고객)                     │
└─────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────┐
│  PHASE 5: 검증 및 인도 (Validation & Delivery)       │
│  - UAT (User Acceptance Test) — 고객 주도            │
│  - PPAP 준비 (해당 시)                               │
│  - 인수인계 문서 패키지 작성                          │
│  Gate 4: Graham + 고객 최종 승인 → 납품              │
└─────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────┐
│  PHASE 6: 사후 관리 (Post-Launch)                    │
│  - 하자보수 기간 운영                                 │
│  - Lessons Learned 작성                              │
│  - 성과 측정 (KPI 달성률)                            │
└─────────────────────────────────────────────────────┘
```

### 2-2. WBS 템플릿 (제조 AI B2B 프로젝트)

```markdown
# WBS: {프로젝트명}

## 1.0 프로젝트 관리
  1.1 킥오프 미팅
  1.2 주간 진도 보고
  1.3 리스크 관리
  1.4 변경관리

## 2.0 요구사항 및 설계
  2.1 현장 실사 및 VOC 수집
  2.2 요구사항 정의서 (SRS)
  2.3 시스템 아키텍처 설계
  2.4 API 명세서
  2.5 DB 스키마 설계
  2.6 UI/UX 프로토타입

## 3.0 개발 구현
  3.1 Backend API 개발 (Peter)
  3.2 Frontend 대시보드 개발 (Sam)
  3.3 AI/ML 모델 개발 (Sam+Peter)
  3.4 MES/OPC-UA 연동 개발 (Peter)
  3.5 단위 테스트

## 4.0 테스트 및 검증
  4.1 통합 테스트 (Tank)
  4.2 성능 테스트
  4.3 보안 테스트
  4.4 UAT 지원

## 5.0 배포 및 인도
  5.1 고객 환경 배포
  5.2 사용자 교육
  5.3 인수인계 문서
  5.4 Go-Live 지원

## 6.0 사후 지원
  6.1 하자보수 대응
  6.2 성과 측정 보고
```

---

## 3. FMEA 적용 (제조 AI 시스템)

```python
FMEA_TEMPLATE = {
    # 시스템 기능
    "기능": "OEE 실시간 이상 감지",
    
    # 잠재 고장 모드
    "고장모드": [
        {
            "고장모드": "센서 데이터 수신 지연",
            "고장영향": "OEE 계산 오류, 현장 의사결정 지연",
            "심각도_S": 7,          # 1~10
            "잠재원인": "MQTT 브로커 과부하, 네트워크 장애",
            "발생도_O": 4,          # 1~10
            "현재예방조치": "연결 타임아웃 설정, 재시도 로직",
            "검출도_D": 3,          # 1~10
            "RPN": None,            # S × O × D (자동계산)
            "권고조치": "Heartbeat 모니터링, 알림 추가",
            "담당자": "Peter",
            "완료목표일": "2025-02-01"
        }
    ]
}

def calculate_rpn(severity, occurrence, detection):
    """RPN = 심각도 × 발생도 × 검출도 (최대 1000)"""
    rpn = severity * occurrence * detection
    priority = "높음" if rpn >= 200 else "중간" if rpn >= 100 else "낮음"
    return {"RPN": rpn, "우선순위": priority}
```

---

## 4. 리스크 관리 (PMBOK 기반)

```python
RISK_REGISTER_TEMPLATE = {
    "columns": ["ID", "리스크명", "카테고리", "확률(1-5)", "영향(1-5)", 
                "위험도", "대응전략", "담당자", "상태"],
    "categories": ["기술", "일정", "원가", "품질", "외부(고객/공급업체)", "조직"],
    "response_strategies": {
        "회피(Avoid)": "리스크 원인 제거",
        "완화(Mitigate)": "확률 또는 영향 감소",
        "전가(Transfer)": "계약/보험으로 이전",
        "수용(Accept)": "비상계획 수립 후 허용"
    }
}

# B2B 제조 AI 프로젝트 공통 리스크
COMMON_RISKS = [
    {"리스크": "고객 현장 OPC-UA 접근 제한", "확률": 4, "영향": 4, "전략": "회피"},
    {"리스크": "MES 연동 API 미지원", "확률": 3, "영향": 5, "전략": "완화"},
    {"리스크": "센서 데이터 품질 불량", "확률": 3, "영향": 4, "전략": "완화"},
    {"리스크": "요구사항 변경 (범위 크리프)", "확률": 4, "영향": 3, "전략": "완화"},
    {"리스크": "고객 IT 보안 정책 충돌", "확률": 3, "영향": 4, "전략": "전가"},
]
```

---

## 5. 핵심 KPI (프로젝트 성과 측정)

```python
B2B_PROJECT_KPIS = {
    "일정 준수": {
        "SPI": "Schedule Performance Index = EV / PV (목표: ≥ 0.95)",
        "납기_준수율": "계획 대비 실제 납기일 (목표: 100%)"
    },
    "원가 통제": {
        "CPI": "Cost Performance Index = EV / AC (목표: ≥ 0.95)",
        "예산_초과율": "실제원가 / 예산 (목표: ≤ 105%)"
    },
    "품질": {
        "재작업률": "재작업 발생 건수 / 전체 인도물 (목표: < 5%)",
        "고객_결함_보고": "UAT 후 발생 결함수 (목표: Critical 0건)",
        "고객_만족도": "NPS 또는 5점 척도 (목표: ≥ 4.0)"
    },
    "범위": {
        "범위_변경률": "승인된 변경 건수 (목표: ≤ 3건/프로젝트)"
    }
}
```

---

## 6. 산출물 체계 (인도물 패키지)

| 단계 | 산출물 | 표준 근거 | 담당 |
|------|--------|----------|------|
| 기획 | 프로젝트 헌장 | PMBOK | Graham |
| 기획 | WBS + 마일스톤 | PMBOK | Sam |
| 기획 | 리스크 등록부 | PMBOK | Sam |
| 기획 | APQP Phase 1 체크리스트 | IATF 16949 | Sam |
| 설계 | DFMEA / PFMEA | IATF 16949 | Sam+Peter |
| 설계 | Control Plan | IATF 16949 | Peter |
| 개발 | SW 요구사항 명세서 | ASPICE SWE.1 | Sam |
| 개발 | 아키텍처 설계서 | ASPICE SWE.2 | Sam |
| 검증 | 테스트 계획서 | ASPICE SWE.4~6 | Tank |
| 검증 | QA 보고서 | IATF 16949 | Tank |
| 인도 | 인수인계 패키지 | PMBOK | Graham |
| 인도 | Lessons Learned | PMBOK | 전체 |

```
docs/
├── project-charter-{project}.md
├── wbs-{project}.md
├── risk-register-{project}.md
├── apqp-checklist-{project}.md
├── fmea-{feature}-{date}.md
├── control-plan-{project}.md
└── lessons-learned-{project}.md
```
