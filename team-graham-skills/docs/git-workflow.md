---
문서ID: BSL-STD-PROC-003
제목: Team Graham 스킬·페르소나 Git 관리 절차 (단순 운영)
버전: v2.0.0
상태: APPROVED
작성자: Claude (Graham 요청)
검토자: Graham
승인자: Graham
최초작성일: 2026-09-27
최종변경일: 2026-09-27
최종변경코드: CR-20260927-003
---

# Team Graham 스킬 Git 관리 절차 — main + 태그

원칙: **브랜치는 main 하나, 버전은 태그로.** 이것만 지키면 된다.

## 1. 어디를 고치는가

| 무엇 | 위치 |
|------|------|
| 페르소나 본문 | `.claude/skills/team-graham/references/agents/{이름}.md` ← 여기만 고친다 |
| 도메인 스킬 | `.claude/skills/team-graham/references/skills/*.md` (추가 시 SKILL.md [3] 표에도 등록) |
| 라우팅·공통 규칙 | `.claude/skills/team-graham/SKILL.md` |
| 서브에이전트 설정 (도구·모델) | `.claude/agents/{이름}.md` |
| Claude Code 운영 규칙 | `CLAUDE.md` |

## 2. 평소 수정 (3줄)

```powershell
git pull
# 파일 수정 후
git add -A
git commit -m "feat(tank): 성능시험 기준 추가" -m "Change-Code: CR-20261005-001"
git push
```

## 3. 버전 올리기 (릴리스)

| 바꾼 것 | 버전 |
|---------|------|
| 역할 추가·삭제, 게이트·승인 규칙 변경 | MAJOR `v6.0.0` |
| 페르소나 보완, 도메인 스킬 추가 | MINOR `v5.1.0` |
| 오탈자·경로 수정 | PATCH `v5.0.2` |

```powershell
git tag -a v5.1.0 -m "Tank 성능시험 기준 추가"
git push origin v5.1.0
```

claude.ai에도 반영하려면 Git Bash에서 `./scripts/package-skill.sh` → `dist/team-graham.skill`을 claude.ai 스킬에 업로드(기존 team-graham 교체).

## 4. 되돌리기·비교

```powershell
git tag                                   # 버전 목록
git diff v5.0.0 v5.1.0 --stat             # 버전 간 바뀐 파일
git restore --source v5.0.0 -- .claude/skills/team-graham/references/agents/tank.md   # 파일 하나만 옛 버전으로
```

## 5. 큰 변경을 시험하고 싶을 때만 (선택)

```powershell
git switch -c try/새역할-추가     # 임시 브랜치
# 수정·커밋 … 괜찮으면
git switch main; git merge try/새역할-추가; git push
git branch -d try/새역할-추가
```

## 변경 이력 (Change History)

| 변경코드 | 버전 | 변경일 | 변경자 | 변경 유형 | 변경 내용 | 영향 범위 | 검토자 | 승인자 |
|---------|------|--------|--------|----------|----------|----------|--------|--------|
| CR-20260927-001 | v1.0.0 | 2026-09-27 | Claude | 신규 | 최초 작성 (main/develop/cr 브랜치 체계) | - | Graham | Graham |
| CR-20260927-003 | v2.0.0 | 2026-09-27 | Claude | 대체 | 새 레포 이전, main+태그 단순 운영으로 전면 개정 | 전체 | Graham | Graham |
