---
문서ID: BSL-STD-PROC-002
제목: 워크플로우 관리
버전: v2.0.0
상태: REVIEWED
작성자: Graham
검토자: Sam, Peter, Tank, Alex
최종변경일: 2026-08-09
최종변경코드: CR-20260809-005
---

# Workflow Management — Team Graham v5.0
## Hybrid V-Cycle 기반 일상 운영 규칙

> 전체 프로세스 정의는 `references/skills/hybrid-v-cycle-process.md` 참조.
> 본 문서는 **일상 운영 리듬과 핸드오프 규칙**을 다룬다.

---

## 1. 게이트 구간 vs 스프린트 구간

Team Graham의 작업은 항상 둘 중 하나의 구간에 있다. **현재 구간을 먼저 확인하고 작업한다.**

| 구간 | 대상 게이트 | 리듬 | 산출물 |
|------|-----------|------|--------|
| **게이트 구간** | G0, G1, G2, G3, G3.5, G4, G5, G6 | 게이트 단위 (수일~수주) | 문서 중심 |
| **스프린트 구간** | G3 승인 후 ~ G3.5 이전 | 1주 Scrum | 코드 중심 |

```
작업 시작 시 항상 명시:
"현재 구간: [게이트 G2 진행 중] 또는 [Sprint 4 진행 중]"
```

---

## 2. 게이트 구간 운영

### 2-1. 게이트 진행 절차

```
Day 1     Graham: 게이트 착수 지시 + Entry 기준 확인
Day 2~N   담당자: 산출물 작성 (DRAFT) → 문서ID·버전·변경코드 부여
Day N+1   검토자: Peer Review → 검토기록 작성 (REVIEWED)
          → Critical/Major 전건 조치
Day N+2   Graham: 게이트 체크리스트 확인 → 판정
          → Baseline 설정, CMDB 갱신
```

### 2-2. 게이트별 검토자 지정 규칙

| 산출물 유형 | 작성자 | **필수 검토자** |
|-----------|--------|---------------|
| 사업기회·시장분석 (G0) | Alex | Sam (기술 실현성) |
| 사업계획서 (기술 내용 포함) | Alex | Sam / (비용·SLA 포함 시) Peter |
| 요구사항 명세 SRS (G1) | Sam | Peter + **Tank (시험가능성)** |
| 아키텍처 (G2) | Sam | Peter + Tank |
| DB·인프라 설계 (G2) | Peter | Sam |
| 상세설계·API (G3) | Sam/Peter | 상대방 + Tank |
| 검증 보고서 (G3.5~G5) | Tank | Sam + Peter (결함 확인) |
| 사업성과 검증 (G6) | Alex | Graham |

---

## 3. 스프린트 구간 운영 (1주 Scrum)

```
월  Sprint Planning
    Graham: 스프린트 목표 확정 (G3 Baseline 범위 내)
    Sam·Peter: Backlog 분해, 태스크 배정
    Tank: 테스트 설계 착수

화  개발 Day 1        Sam(FE·AI) + Peter(BE·Infra) Pair, 일 2회 sync
수  개발 Day 2        Tank: 완성 모듈 단위 테스트 착수
목  개발 Day 3        16:00 기능 동결 → Tank 통합 테스트
금  Review & Retro    Tank 리포트 → Graham 리뷰 → Sprint Go/No-Go
                     회고 → 형상관리 기록 갱신 (Sprint Baseline)
```

### 3-1. 스프린트 중 변경 처리

| 변경 유형 | 처리 | 버전 |
|----------|------|------|
| 상세설계 범위 내 구현 방식 변경 | Sam·Peter 자체 결정, Sprint Note 기록 | PATCH |
| 상세설계 변경 필요 | **CR 발행 → Graham 승인** → BL-G3 갱신 | MINOR |
| 아키텍처·요구사항 변경 필요 | **CR + 영향분석 → Graham 승인** → 게이트 재검토 | MAJOR |
| 긴급 결함 수정 | 즉시 수정 후 24시간 내 사후 CR 등록 | PATCH |

### 3-2. 신규 요구 유입 시 자동 대응 (Graham 맹점 대응)

```
스프린트 중 신규 요구 발생
    ↓
Sam/Alex가 자동으로 제시:
  ① 현재 Baseline 대비 범위 diff
  ② 추가 시 일정 영향 (일 단위)
  ③ "Phase 2 이관" 옵션
    ↓
Graham이 명시적으로 선택하기 전까지 → 백로그 등록만, 착수 금지
```

---

## 4. 작업 핸드오프 흐름 (v5.0)

```
Graham: "기능 X 필요"
    ↓
[G1] Sam: srs-X.md + rtm-X.md 작성 (DRAFT)
     Tank: 시험가능성 검토 → 측정불가 요구사항 반려
     Peter: 데이터 가용성 검증
     → 검토기록 (REVIEWED) → Graham 승인 → BL-G1
    ↓
[G2] Sam: architecture-X.md / Peter: db-schema-X.md, infra-design-X.md
     교차검토 → 검토기록 → Graham 승인 → BL-G2
    ↓
[G3] Sam: dd-X.md, api-spec-X.yaml, fmea-X.md / Peter: dd-X-backend.md
     교차검토 + Tank 검토 → Graham 승인 → BL-G3
    ↓
[Sprint] Sam: Frontend + AI / Peter: Backend + Infra (동시, 일 2회 sync)
    ↓
[G3.5] Tank: 단위시험 → 커버리지·결함 판정
[G4]   Tank: 통합·시스템 시험 → SLA 판정
[G5]   Tank + Graham + 고객: 인수시험 → RTM 100% Verified
    ↓
[G6]   Alex: 사업성과 검증 → 레퍼런스 자산화 판단
```

---

## 5. 일일 커뮤니케이션 규칙

### 5-1. 작업 선언 형식 (모든 에이전트 필수)
```
{이름} here. [현재 구간: Gate G{N} / Sprint {N}] {작업명} 진행합니다.
```

### 5-2. 완료 보고 형식
```
{이름}: [Gate G{N}] {작업명} 완료
- 산출물: {문서ID} {버전} (변경코드: CR-...)
- 검토 요청: {검토자} — {검토 관점}
- Graham 확인 필요 사항: {있으면 명시}
```

### 5-3. 블로커 보고
```
{이름}: 블로커 발생
- 내용 / 영향(일정·범위) / 필요 결정
- 제안 옵션: A) ... B) ... (권고: A)
```

---

## 6. 주간 리듬

| 요일 | 활동 | 주관 |
|------|------|------|
| 월 | 주간 계획 / 스프린트 플래닝 / 게이트 착수 | Graham |
| 화~목 | 실행 (개발 또는 문서 작성) | Sam·Peter·Alex |
| 목 | 기능 동결 / 검토 착수 | Tank |
| 금 오전 | 검토 완료, 검토기록 작성 | 검토자 |
| 금 오후 | Graham 리뷰 → 판정 → CMDB 갱신 → 회고 | Graham |

---

## 7. 정기 점검 항목

### 주간 (매주 금)
- [ ] 미승인 산출물 대기 일수 확인 (48시간 초과 시 에스컬레이션)
- [ ] CMDB 대장 갱신
- [ ] RTM 갱신 상태 확인
- [ ] 미처리 CR 확인

### 게이트 종료 시
- [ ] Baseline 설정 및 Git 태그
- [ ] 구버전 아카이브
- [ ] 다음 게이트 Entry 기준 확인
- [ ] 리스크 등록부 갱신

### 프로젝트 종료 시 (G6)
- [ ] 전체 형상항목 최종 스냅샷
- [ ] Lessons Learned 작성
- [ ] 재사용 가능 자산 식별 (템플릿·모듈·레퍼런스)

---

## 변경 이력

| 변경코드 | 버전 | 변경일 | 변경자 | 변경유형 | 변경내용 | 검토자 | 승인자 |
|---------|------|--------|--------|---------|---------|--------|--------|
| - | v1.0.0 | 2026-03-08 | Graham | 신규 | 1주 Scrum 기반 워크플로우 | - | Graham |
| CR-20260809-005 | v2.0.0 | 2026-08-09 | Graham | 대체 | Hybrid V-Cycle 반영, 검토 게이트·형상관리 절차 추가 | Sam, Peter, Tank, Alex | Graham 승인 대기 |
