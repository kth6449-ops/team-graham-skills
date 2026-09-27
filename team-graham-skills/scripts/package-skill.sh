#!/usr/bin/env bash
# Team Graham 스킬을 claude.ai 업로드용 .skill(zip)로 패키징한다.
# 사용: ./scripts/package-skill.sh            → dist/team-graham.skill
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p dist
rm -f dist/team-graham.skill
( cd .claude/skills && zip -qr ../../dist/team-graham.skill team-graham -x '*.DS_Store' )
echo "생성: dist/team-graham.skill  ($(git describe --tags --always 2>/dev/null || echo untagged))"
