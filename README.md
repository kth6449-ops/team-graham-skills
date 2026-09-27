# Team Graham Skills

BESOLT의 **Team Graham** 에이전트 페르소나·스킬 저장소입니다.
SME(중소·중견기업) 제품·사업 개발을 위한 4인 전문가 팀을 Claude Code와 claude.ai에서 같은 규칙으로 운영합니다.

> **현재 버전**: v5.0.0 · **관리자**: Graham Kim (BESOLT)

---

## 팀 구성

| 이름 | 역할 | 주요 업무 | 주도 게이트 |
|------|------|----------|-----------|
| **Graham** | PM · 최종 승인자 (사용자) | 게이트 승인, Go/No-Go 결정 | 전 게이트 승인 |
| **Alex** | 시니어 비즈니스 컨설턴트 | 사업 진단, 시장분석, 사업계획서, 정부지원사업, IR, GTM | G0 · G6 |
| **Sam** | 아키텍트 / 프론트엔드·AI 리드 | SRS·RTM, 아키텍처, 상세설계, API, 프론트엔드, AI/ML, BI | G1 · G2 · G3 |
| **Peter** | 백엔드 / 인프라·데이터 리드 | FastAPI, DB, 인프라, MES·ERP 연동, ETL, 비용·SLA 산출 | G2 · G3 · Sprint |
| **Tank** | QA / V&V 리드 | 시험가능성 검토, 단위·통합·인수 시험, 품질 판정 | G3.5 · G4 · G5 |

## 운영 원칙

**Hybrid V-Cycle** — 게이트 기반으로 정의·설계(좌측)와 검증(우측)을 짝지어 진행합니다.

```
G0 사업타당성 ── Alex ─────────────── G6 사업성과검증 ── Alex
G1 요구사항 ─── Sam(+Tank 검토) ───── G5 인수시험 ───── Tank+Graham
G2 아키텍처 ─── Sam+Peter ─────────── G4 통합시험 ───── Tank
G3 상세설계 ─── Sam+Peter ─────────── G3.5 단위시험 ─── Tank
        └────── Sprint (1주) Sam+Peter ──────┘
```

- **승인 3단계**: 작성(DRAFT) → 검토(REVIEWED) → Graham 승인(APPROVED). 검토 없이 승인 요청하지 않습니다.
- **형상관리**: 모든 산출물에 문서ID `BSL-{PROJ}-{TYPE}-{SEQ}`, 버전, 변경코드 `CR-{YYYYMMDD}-{NNN}`를 부여합니다. 변경코드 없는 산출물은 무효입니다.
- **맹점 대응**: 결정 지연·과잉 모델링·범위 확장·프레임워크 과다 사용을 감지하면 자동으로 경고하고 대안을 제시합니다.

---

## 사용 방법

### Claude Code

```powershell
git clone https://github.com/kth6449-ops/team-graham-skills.git
cd team-graham-skills
claude
```

- `/agents` — alex, sam, peter, tank 4개 서브에이전트 확인
- 역할 호출 — `Alex, 대구 지역 제조 AX 시장 진단해줘` / `Sam, 이 기능 SRS 작성해줘` / `Tank, G1 시험가능성 검토해줘`
- 역할을 부르지 않아도 업무 성격에 따라 알맞은 역할이 배정됩니다 (`CLAUDE.md` 라우팅 규칙).

다른 프로젝트에서 쓰려면 `.claude/` 폴더와 `CLAUDE.md`를 그 프로젝트 루트에 복사합니다.

### claude.ai

1. Git Bash에서 `./scripts/package-skill.sh` 실행 → `dist/team-graham.skill` 생성
2. claude.ai 스킬 설정에서 업로드 (기존 `team-graham`이 있으면 교체)

---

## 폴더 구조

```
team-graham-skills/
├── README.md
├── CLAUDE.md                       Claude Code 운영 규칙 (자동 로드)
├── .claude/
│   ├── agents/                     서브에이전트 진입점 (도구·모델 설정)
│   │   ├── alex.md  sam.md  peter.md  tank.md
│   └── skills/team-graham/         ★ 페르소나·스킬 단일 원본 (claude.ai와 공용)
│       ├── SKILL.md                라우팅·공통 규칙
│       └── references/
│           ├── agents/             페르소나 상세 지침 4종
│           ├── skills/             도메인 스킬 16종
│           └── templates/          형상관리 서식 4종 (CR·검토기록·게이트·CMDB)
├── docs/git-workflow.md            Git 관리 절차
└── scripts/package-skill.sh        claude.ai 업로드용 패키지 생성
```

### 도메인 스킬 (16종)

| 구분 | 스킬 |
|------|------|
| 공통 | hybrid-v-cycle-process · configuration-management · workflow-management · sme-domain-expertise |
| 사업 (Alex) | consulting-engagement-method · business-ideation-and-analysis · corporate-business-planning · b2b-business-planning |
| 기술 (Sam·Peter) | manufacturing-glossary · mes-integration · sensor-data-patterns · manufacturing-cost-analysis · manufacturing-bi · manufacturing-analytics · b2b-project-management |
| 품질 (Tank) | quality-standards |

---

## 수정·버전 관리

- 페르소나는 **`.claude/skills/team-graham/references/agents/`에서만** 수정합니다. `.claude/agents/`는 진입점이라 도구·모델을 바꿀 때만 수정합니다.
- 브랜치는 `main` 하나, 버전은 태그(`v5.0.0`, `v5.1.0` …)로 관리합니다.

```powershell
git pull
git add -A
git commit -m "feat(tank): 성능시험 기준 추가" -m "Change-Code: CR-20261005-001"
git push
git tag -a v5.1.0 -m "요약"; git push origin v5.1.0     # 버전 올릴 때만
```

| 변경 내용 | 버전 |
|----------|------|
| 역할 추가·삭제, 게이트·승인 규칙 변경 | MAJOR (v6.0.0) |
| 페르소나 보완, 도메인 스킬 추가 | MINOR (v5.1.0) |
| 오탈자·경로 수정 | PATCH (v5.0.1) |

상세 절차: [`docs/git-workflow.md`](docs/git-workflow.md)

---

## 버전 이력

| 버전 | 일자 | 주요 변경 |
|------|------|----------|
| v5.0.0 | 2026-09-27 | 스킬 단일 원본화, 서브에이전트 진입점화, Hybrid V-Cycle·형상관리 규칙 도입, 도메인 스킬 16종, 새 레포로 이전 |
| v4.0 | 2026-03-29 | Alex(사업전략) 합류 |
| v3.0 | 2026-03 | Sam·Peter·Tank 서브에이전트 + 제조 도메인 스킬 |
