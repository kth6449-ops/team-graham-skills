# Hybrid V-Cycle Development Process — Team Graham v5.0
## Waterfall Phase Gate + Agile Sprint 혼합 개발 프로세스

**문서ID**: `BSL-STD-PROC-001`
**버전**: `v1.0.0`
**적용범위**: Team Graham의 모든 제품·솔루션·SI 프로젝트 (제조/비제조 SME 전 업종)
**근거표준**: ISO/IEC/IEEE 15288, VDA/ASPICE, IEC 62304, PMBOK 7th, Scrum Guide 2020

---

## 0. 왜 Hybrid V-Cycle인가

| 순수 Waterfall | 순수 Agile | **Hybrid V-Cycle (채택)** |
|---------------|-----------|--------------------------|
| 요구사항 고정 → 변경 대응 불가 | 문서 부족 → 고객 승인·감사 대응 불가 | 상위 게이트는 Waterfall로 고정, 구현은 Sprint로 유연 |
| 검증이 끝에 몰림 | 전체 아키텍처 일관성 저하 | 좌측 설계 ↔ 우측 검증 1:1 대응으로 추적성 확보 |
| SI/정부과제 정산에 유리 | 빠른 피드백에 유리 | **둘 다 확보** — 게이트 산출물로 정산, 스프린트로 속도 |

**Team Graham 판단 근거**
- BESOLT 고객은 SME이며, 정부지원사업·SI 계약이 매출의 상당 부분 → **단계별 산출물 증빙 필수**
- 동시에 MVP 검증 속도가 생존 요건 → **구현 단계는 1주 Scrum 유지**
- 결론: **바깥은 V-Model(게이트), 안쪽은 Scrum(스프린트)**

---

## 1. V-Cycle 전체 구조

```
   [정의·설계 계열 — Waterfall Gate]          [검증·확인 계열 — Waterfall Gate]

 G0  Concept / 사업타당성 ───────────────────── G6  Business Validation (사업성과 검증)
      │                                                       ▲
 G1  Requirements / 요구사항 정의 ─────────────── G5  UAT / 인수시험 (고객 승인)
      │                                                       ▲
 G2  Architecture / 아키텍처 설계 ─────────────── G4  System & Integration Test
      │                                                       ▲
 G3  Detailed Design / 상세설계 ───────────────── G3.5 Unit & Component Test
      │                                                       ▲
      └────────────► [ IMPLEMENTATION — Agile Sprint 1..N ] ───┘
                       1주 Scrum · Sam+Peter Pair · Tank 상시 QA
```

### 좌↔우 추적성 규칙 (Traceability)

**모든 좌측 산출물은 대응하는 우측 검증 산출물을 반드시 갖는다.**

| 좌측 (정의) | 산출물 | ↔ | 우측 (검증) | 산출물 |
|------------|--------|---|-----------|--------|
| G0 Concept | `concept-{proj}.md` | ↔ | G6 Business Validation | `biz-validation-{proj}.md` |
| G1 Requirements | `srs-{proj}.md` (요구사항 명세) | ↔ | G5 UAT | `uat-report-{proj}.md` |
| G2 Architecture | `architecture-{proj}.md` | ↔ | G4 System/Integration | `sit-report-{proj}.md` |
| G3 Detailed Design | `dd-{module}.md`, `api-spec-*.yaml` | ↔ | G3.5 Unit Test | `unit-test-report-{module}.md` |

**추적성 매트릭스(RTM)는 G1 종료 시 생성하고 매 게이트마다 갱신한다.**

```
docs/rtm-{proj}.md
| REQ-ID | 요구사항 | 설계문서 | 구현 모듈 | 테스트케이스 | 상태 |
|--------|---------|---------|----------|-------------|------|
| REQ-001 | OEE 실시간 산출 | ARCH-3.2 | oee_service.py | TC-012,013 | ✅ Verified |
```

---

## 2. 게이트별 상세 정의

### G0 — Concept Gate (개념·사업타당성)

| 항목 | 내용 |
|------|------|
| **주도** | Alex (사업) + Graham |
| **목적** | "이 제품/프로젝트를 할 가치가 있는가?" 판단 |
| **입력** | 고객 요청 / 시장 기회 / 정부공고 / 내부 아이디어 |
| **산출물** | `concept-{proj}.md`, `market-analysis-{seg}.md`, 초기 Business Case |
| **Entry 기준** | 기회 식별 완료, 초기 고객 접점 1건 이상 |
| **Exit 기준** | ① TAM/SAM/SOM 산정 완료 ② 개략 원가/수익 추정 ③ 기술 실현성 1차 확인(Sam) ④ **Graham Go/No-Go** |
| **승인권자** | Graham (필수) |
| **Baseline** | `BL-G0` 설정 → 이후 개념 변경은 변경요청(CR) 필요 |

### G1 — Requirements Gate (요구사항 정의)

| 항목 | 내용 |
|------|------|
| **주도** | Sam (기술 요구) + Alex (사업 요구) |
| **목적** | "무엇을 만들 것인가"를 검증 가능한 형태로 고정 |
| **산출물** | `srs-{proj}.md`, `prd-{feature}.md`, `rtm-{proj}.md` 초판, `risk-register-{proj}.md` |
| **Entry 기준** | G0 승인 완료, 고객 인터뷰 ≥ 3건 |
| **Exit 기준** | ① 모든 요구사항에 REQ-ID 부여 ② 각 요구사항이 **측정 가능한 인수기준** 보유 ③ RTM 초판 작성 ④ Tank가 시험 가능성(testability) 검토 완료 ⑤ **Graham 승인** |
| **승인권자** | Graham (필수), Tank 검토 의견 첨부 필수 |
| **Baseline** | `BL-G1` — 요구사항 기준선. **이후 요구사항 변경은 CR + 영향분석 필수** |

**요구사항 작성 규칙**
```
REQ-{도메인}-{번호}: {행위자}는 {조건}에서 {기능}을 {성능기준} 이내로 수행할 수 있어야 한다.
예) REQ-OEE-003: 시스템은 설비 1,000대 동시 수집 조건에서 OEE를 5초 이내로 갱신해야 한다.
    인수기준: k6 부하테스트 p95 < 5s, 24시간 연속 무중단
```

### G2 — Architecture Gate (아키텍처 설계)

| 항목 | 내용 |
|------|------|
| **주도** | Sam (아키텍처 리드) + Peter (인프라 타당성) |
| **목적** | 구조적 결정을 고정하고, 이후 변경 비용이 큰 사항을 확정 |
| **산출물** | `architecture-{proj}.md` (C4), `db-schema-{proj}.md`, `infra-design-{proj}.md`, `adr-{NNN}.md` (Architecture Decision Record) |
| **Entry 기준** | G1 승인, RTM 존재 |
| **Exit 기준** | ① C4 Level 1~3 완성 ② 비기능 요구(성능/가용성/보안) 대응 설계 명시 ③ 기술스택 확정 + ADR 기록 ④ Peter 인프라 견적 산출 ⑤ **Graham 승인** |
| **승인권자** | Graham, Sam·Peter 공동 서명 |
| **Baseline** | `BL-G2` — 아키텍처 기준선 |

### G3 — Detailed Design Gate (상세설계)

| 항목 | 내용 |
|------|------|
| **주도** | Sam (FE/AI 설계) + Peter (BE/Data 설계) |
| **목적** | 구현 착수 가능 수준의 상세도 확보 |
| **산출물** | `dd-{module}.md`, `api-spec-{feature}.yaml`, `fmea-{feature}.md`, Sprint Backlog 초판 |
| **Entry 기준** | G2 승인 |
| **Exit 기준** | ① 모든 API 명세(OpenAPI) 확정 ② 모듈별 상세설계서 작성 ③ FMEA 수행, RPN ≥ 100 항목 대응책 수립 ④ Tank가 테스트 설계 착수 가능 확인 ⑤ **Graham 승인** |
| **승인권자** | Graham |
| **Baseline** | `BL-G3` — 설계 기준선. **여기서부터 Agile 구간 진입** |

---

## 3. Implementation 구간 — Agile Sprint (V의 바닥)

G3 승인 후 ~ G3.5 이전까지는 **1주 Scrum**으로 운영한다.
게이트 문서는 Sprint 중 동결되며, 변경 필요 시 CR을 발행한다.

### 3-1. 스프린트 리듬 (1주)

```
월  Sprint Planning   Graham: 목표 확정 / Sam·Peter: Backlog 분해 / Tank: 테스트 설계
화  개발 Day1         Sam(FE·AI) + Peter(BE·Infra) Pair, 일 2회 sync
수  개발 Day2         Tank: 완성 모듈 단위테스트 착수
목  개발 Day3 + QA    기능 동결(Feature Freeze) 16:00 / Tank 통합 테스트 시작
금  Review & Retro    Tank 리포트 → Graham 리뷰 → Sprint Go/No-Go → 회고 → CM 기록
```

### 3-2. Sprint 내 변경 처리 규칙

| 변경 유형 | 처리 |
|----------|------|
| 상세설계 범위 내 구현 방식 변경 | Sam·Peter 자체 결정, `adr` 또는 Sprint Note 기록 (PATCH 버전) |
| 상세설계 변경 필요 | **CR 발행** → Graham 승인 → `BL-G3` 갱신 (MINOR 버전) |
| 아키텍처·요구사항 변경 필요 | **CR 발행 + 영향분석서** → Graham 승인 → 해당 게이트 재검토 (MAJOR 버전) |
| 긴급 결함 수정 | 즉시 수정 후 사후 CR 등록 (24시간 내) |

**Scope Creep 방어 (Graham 맹점 대응)**
> 스프린트 중 신규 요구가 들어오면 Alex/Sam은 **자동으로 다음을 제시한다**:
> ① 현재 Baseline 대비 범위 diff ② 추가 시 일정 영향(일 단위) ③ "Phase 2 이관" 옵션
> Graham이 명시적으로 선택하기 전까지 **백로그에만 등록하고 착수하지 않는다.**

---

## 4. 우측 검증 게이트

### G3.5 — Unit & Component Test

| 항목 | 내용 |
|------|------|
| **주도** | Tank (검증), Sam·Peter (수정) |
| **Exit 기준** | 커버리지 BE ≥ 80% / FE ≥ 75% / AI ≥ 70%, Critical·High 결함 0, 정적분석 통과 |
| **산출물** | `unit-test-report-{module}-{date}.md` |
| **대응 좌측** | G3 Detailed Design |

### G4 — System & Integration Test

| 항목 | 내용 |
|------|------|
| **주도** | Tank |
| **Exit 기준** | 통합 시나리오 100% 실행, 성능 SLA 충족(대시보드<200ms, API p95<500ms), 외부연동(MES/ERP/IoT) 정상, Critical 0 / High ≤ 2 (수정계획 첨부) |
| **산출물** | `sit-report-{proj}-{date}.md`, 성능 측정 로그 |
| **대응 좌측** | G2 Architecture |

### G5 — UAT / 인수시험

| 항목 | 내용 |
|------|------|
| **주도** | Graham + 고객, Tank 진행 지원, Alex 고객 커뮤니케이션 |
| **Exit 기준** | RTM의 모든 REQ가 Verified 상태, 고객 인수확인서 서명, 잔여 이슈 목록 합의 |
| **산출물** | `uat-report-{proj}-{date}.md`, 인수확인서, 잔여이슈 목록 |
| **대응 좌측** | G1 Requirements |

### G6 — Business Validation (사업성과 검증)

| 항목 | 내용 |
|------|------|
| **주도** | Alex |
| **목적** | G0에서 세운 사업 가설이 실제로 달성되었는가 |
| **Exit 기준** | 실제 원가 vs 계획 대비 분석, 고객 가치 지표(예: OEE 개선율, 원가절감액) 측정, 레퍼런스 자산화 여부 결정, 차기 제품 반영사항 도출 |
| **산출물** | `biz-validation-{proj}-{date}.md`, `lessons-learned-{proj}.md` |
| **대응 좌측** | G0 Concept |

---

## 5. 게이트 승인 절차 (Approval Workflow)

**모든 게이트는 아래 3단계를 반드시 거친다. 단계 생략 불가.**

```
[1단계] 작성 (Author)
   담당자가 산출물 작성 → 문서ID·버전·변경코드 부여 → 상태: DRAFT
        │
        ▼
[2단계] 내용 검토 (Peer Review)   ★ v5.0 신설 — 승인 전 필수 관문
   ├─ 기술 산출물 → 상호 교차검토 (Sam ↔ Peter) + Tank 시험가능성 검토
   ├─ 사업 산출물 → Alex 작성 시 Sam 기술타당성 검토 / Sam 작성 시 Alex 사업타당성 검토
   ├─ 검토 결과를 docs/cm-records/review-{문서ID}-{버전}.md 에 기록
   └─ 검토 의견 전건 조치(수정 또는 반박 사유 기재) → 상태: REVIEWED
        │
        ▼
[3단계] 승인 (Approval)
   Graham이 검토기록 + 산출물 함께 확인 → APPROVED / REJECTED / CONDITIONAL
   승인 시 Baseline 설정 및 형상항목 등록 → 상태: APPROVED (Baselined)
```

### 검토 기록 필수 항목

```markdown
## 검토 기록 (Review Record)
- 대상 문서: {문서ID} {버전}
- 검토자: {이름} / 검토일: {YYYY-MM-DD}
- 검토 관점: [정합성 / 완전성 / 실현가능성 / 시험가능성 / 사업타당성]

| No | 위치 | 지적사항 | 심각도 | 조치 | 조치결과 |
|----|------|---------|--------|------|---------|
| 1 | 3.2절 | 성능 목표에 측정조건 없음 | Major | 수정 | 부하조건 명시 완료 |

- 검토 결론: [승인권고 / 조건부승인권고 / 재작성요구]
- 미조치 항목 및 사유:
```

### 검토 심각도 기준

| 심각도 | 정의 | 처리 |
|-------|------|------|
| **Critical** | 이 상태로 진행 시 프로젝트 실패 | 반드시 수정, 재검토 |
| **Major** | 후속 단계에서 큰 재작업 유발 | 승인 전 수정 필수 |
| **Minor** | 품질 개선 사항 | 차기 개정 시 반영 가능 |
| **Comment** | 참고 의견 | 조치 선택 |

### Graham의 승인 판정 기준

| 판정 | 조건 | 후속 |
|------|------|------|
| **APPROVED** | Critical·Major 지적 전건 조치 완료, Exit 기준 100% 충족 | Baseline 설정, 다음 게이트 진행 |
| **CONDITIONAL** | Exit 기준 90% 이상, 잔여 항목에 명확한 완료 기한 존재 | 조건 명시 + 기한 설정, 병행 진행 허용 |
| **REJECTED** | Critical 미조치 또는 Exit 기준 미달 | 재작성, 게이트 재상정 |

**Graham 결정 지연 방지 규칙**
> 게이트 상정 후 **48시간 내 판정하지 않으면** 담당자는 Graham에게
> "Go/No-Go 체크리스트 + 최악 시나리오 + 롤백 플랜"을 자동 제시하고 결정을 요청한다.
> 3회 이상 동일 게이트가 재검토되면 "80% 완성도로 CONDITIONAL 승인 후 진행" 옵션을 명시적으로 제안한다.

---

## 6. 프로젝트 규모별 게이트 테일러링

모든 프로젝트가 7개 게이트를 다 거칠 필요는 없다. **규모에 따라 병합한다.**

| 규모 | 기준 | 적용 게이트 | 비고 |
|------|------|-----------|------|
| **XS** (기능 개선) | 5인일 미만 | G3 → Sprint → G3.5 | PRD 1장 + 테스트 리포트 |
| **S** (단일 모듈) | 5~20인일 | G1+G2 병합 → G3 → Sprint → G3.5+G4 병합 | 문서 4종 |
| **M** (제품 기능셋) | 20~60인일 | G0 생략, G1~G5 전체 | 표준 |
| **L** (신제품/SI 납품) | 60인일 초과 | G0~G6 전체 | 정부과제·고객 SI 필수 |
| **정부과제** | 규모 무관 | **G0~G6 전체 강제** | 정산 증빙 요구 |

**테일러링 결정은 G0 또는 프로젝트 착수 시 Graham이 승인하고 `tailoring-{proj}.md`에 기록한다.**

---

## 7. 게이트 산출물 마스터 목록

```
docs/
├── 00-concept/
│   ├── concept-{proj}.md                    [G0] Alex
│   ├── market-analysis-{seg}-{YYYYMM}.md    [G0] Alex
│   └── tailoring-{proj}.md                  [G0] Graham
├── 01-requirements/
│   ├── srs-{proj}.md                        [G1] Sam+Alex
│   ├── prd-{feature}.md                     [G1] Sam
│   ├── rtm-{proj}.md                        [G1~G5 갱신] Sam
│   └── risk-register-{proj}.md              [G1~G6 갱신] Graham
├── 02-architecture/
│   ├── architecture-{proj}.md               [G2] Sam
│   ├── db-schema-{proj}.md                  [G2] Peter
│   ├── infra-design-{proj}.md               [G2] Peter
│   └── adr/adr-{NNN}-{title}.md             [G2~] Sam
├── 03-design/
│   ├── dd-{module}.md                       [G3] Sam/Peter
│   ├── api-spec-{feature}.yaml              [G3] Sam
│   └── fmea-{feature}-{date}.md             [G3] Sam
├── 04-implementation/
│   ├── sprint-{NN}-plan.md                  [Sprint] Graham
│   └── sprint-{NN}-notes.md                 [Sprint] Sam+Peter
├── 05-verification/
│   ├── unit-test-report-{module}-{date}.md  [G3.5] Tank
│   ├── sit-report-{proj}-{date}.md          [G4] Tank
│   └── uat-report-{proj}-{date}.md          [G5] Tank+Graham
├── 06-validation/
│   ├── biz-validation-{proj}-{date}.md      [G6] Alex
│   └── lessons-learned-{proj}.md            [G6] 전원
└── cm-records/
    ├── cmdb-{proj}.md                       형상항목 대장
    ├── review-{문서ID}-{버전}.md             검토 기록
    └── cr-{YYYYMMDD}-{NNN}.md               변경 요청서
```

---

## 8. 역할별 게이트 책임 매트릭스 (RACI)

| 게이트 | Graham | Alex | Sam | Peter | Tank |
|--------|--------|------|-----|-------|------|
| G0 Concept | **A** | **R** | C | I | I |
| G1 Requirements | **A** | R | **R** | C | **C**(시험가능성) |
| G2 Architecture | **A** | C | **R** | **R** | C |
| G3 Detailed Design | **A** | I | **R** | **R** | C |
| Sprint 실행 | **A** | I | **R** | **R** | **R**(QA) |
| G3.5 Unit Test | A | I | C | C | **R** |
| G4 SIT | **A** | I | C | C | **R** |
| G5 UAT | **R/A** | **R**(고객) | C | C | **R** |
| G6 Biz Validation | **A** | **R** | C | C | I |

`R`=실행 `A`=승인 `C`=협의 `I`=통보

---

## 9. 게이트 체크리스트 템플릿

```markdown
# Gate Review Checklist — {게이트명}
문서ID: BSL-{PROJ}-GATE-{G번호} | 버전: v1.0.0 | 변경코드: CR-{YYYYMMDD}-{NNN}

## Entry 기준 확인
- [ ] 이전 게이트 APPROVED 상태
- [ ] 필수 입력 산출물 존재
- [ ] 담당자 지정 완료

## 산출물 확인
- [ ] {산출물1} — 문서ID 부여 / 버전 표기 / 검토기록 첨부
- [ ] {산출물2} — 〃

## Exit 기준 확인
- [ ] {기준1} ... 증빙: {링크/수치}
- [ ] {기준2} ... 증빙: {링크/수치}

## 검토 단계 확인 ★필수
- [ ] Peer Review 완료 (검토자: ______, 검토일: ______)
- [ ] Critical/Major 지적사항 전건 조치 완료
- [ ] 검토 기록 docs/cm-records/ 저장 완료

## 형상관리 확인 ★필수
- [ ] 모든 산출물에 문서ID·버전·변경코드 부여
- [ ] CMDB 대장 갱신
- [ ] 이전 버전 아카이브 보관

## 판정
Graham 판정: [ ] APPROVED  [ ] CONDITIONAL  [ ] REJECTED
조건/사유:
Baseline 설정: BL-{게이트}-{YYYYMMDD}
서명: Graham / {날짜}
```

---

## 10. 호출 예시

- "이 프로젝트 규모면 게이트 테일러링 어떻게 가져갈까?"
- "G2 아키텍처 게이트 체크리스트 만들어줘"
- "요구사항 변경 들어왔는데 어느 게이트로 되돌려야 해?"
- "Sprint 3 종료했으니 G3.5 진입 조건 점검해줘"
