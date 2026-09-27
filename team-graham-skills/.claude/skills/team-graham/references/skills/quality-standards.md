# Quality Standards — BESOLT

## 코드 품질 기준

### 커버리지 요구사항
| 레이어 | 최소 커버리지 | 목표 |
|--------|-------------|------|
| Backend (Pytest) | 80% | 90% |
| Frontend (Jest) | 75% | 85% |
| AI 모델 | 70% | 80% |
| E2E (Playwright) | 핵심 플로우 100% | - |

### 성능 기준 (SLA)
| 항목 | 허용 | 목표 |
|------|------|------|
| Dashboard 로드 | < 200ms | < 100ms |
| API 응답 (p95) | < 500ms | < 200ms |
| AI 추론 | < 1000ms | < 300ms |
| 센서 데이터 지연 | < 5초 | < 2초 |
| 시스템 가용성 | 99.5% | 99.9% |

## 테스트 템플릿

### FastAPI 단위 테스트 (Pytest)
```python
import pytest
from httpx import AsyncClient
from app.main import app

@pytest.mark.asyncio
async def test_sensor_ingestion_success():
    """정상 센서 데이터 수신 테스트"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        payload = {
            "sensor_id": "LINE01-TEMP-001",
            "timestamp": "2025-01-01T00:00:00Z",
            "value": 85.3,
            "unit": "°C"
        }
        response = await client.post("/api/v1/sensors/readings", json=payload)
    
    assert response.status_code == 201
    assert response.json()["status"] == "received"

@pytest.mark.asyncio
async def test_sensor_invalid_value():
    """비정상값 처리 테스트"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post("/api/v1/sensors/readings", json={
            "sensor_id": "TEST-001",
            "value": None  # 필수값 누락
        })
    assert response.status_code == 422
```

### React 컴포넌트 테스트 (Jest)
```typescript
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { OEEDashboard } from './OEEDashboard';

describe('OEEDashboard', () => {
  it('OEE 값을 퍼센트로 표시한다', async () => {
    render(<OEEDashboard lineId="LINE01" />);
    await waitFor(() => {
      expect(screen.getByTestId('oee-value')).toHaveTextContent('%');
    });
  });

  it('이상감지 알림이 표시된다', async () => {
    render(<OEEDashboard lineId="LINE01" hasAnomaly={true} />);
    expect(screen.getByRole('alert')).toBeVisible();
  });
});
```

### E2E 테스트 (Playwright)
```typescript
import { test, expect } from '@playwright/test';

test('이상감지 알림 → 조치 플로우', async ({ page }) => {
  await page.goto('/dashboard/LINE01');
  
  // 이상 발생 시뮬레이션
  await page.evaluate(() => window.mockAnomaly('LINE01-TEMP-001'));
  
  // 알림 표시 확인
  await expect(page.locator('[data-testid="anomaly-alert"]')).toBeVisible();
  
  // 상세 조회
  await page.click('[data-testid="view-detail-btn"]');
  await expect(page.locator('[data-testid="anomaly-detail"]')).toBeVisible();
  
  // 조치 완료 처리
  await page.click('[data-testid="resolve-btn"]');
  await expect(page.locator('[data-testid="anomaly-alert"]')).not.toBeVisible();
});
```

## Go/No-Go 체크리스트

Graham 최종 승인 전 Tank가 확인:

```markdown
## Pre-Release Checklist

### 기능 품질
- [ ] 모든 PRD 요구사항 구현 확인
- [ ] 단위 테스트 커버리지 ≥ 80%
- [ ] E2E 핵심 플로우 100% 통과
- [ ] 0 Critical / 0 High 결함

### 성능
- [ ] Dashboard 로드 < 200ms
- [ ] API 응답 p95 < 500ms
- [ ] 부하 테스트 통과 (목표 TPS)

### 제조 도메인
- [ ] 센서 데이터 엣지케이스 처리 확인
- [ ] MES 연동 타임아웃/재시도 동작 확인
- [ ] OEE 계산 정확도 검증

### 보안
- [ ] 입력값 검증 (SQL Injection, XSS)
- [ ] 인증/인가 테스트
- [ ] API 키/시크릿 노출 없음

### 운영 준비
- [ ] 로그 구조화 확인 (structlog)
- [ ] 에러 처리 및 알림 동작 확인
- [ ] 롤백 절차 문서화
```

## 버그 보고서 템플릿 (Tank → Sam/Peter)

```markdown
## [BUG-{번호}] {제목}

**심각도**: Critical / High / Medium / Low  
**대상 엔지니어**: Sam / Peter  
**컴포넌트**: Frontend / Backend / AI Model  

### 재현 절차
1. 
2. 
3. 

### 기대 결과
{어떻게 동작해야 하는가}

### 실제 결과
{실제로 어떻게 동작하는가}

### 증거
```log
{에러 로그, 스크린샷 경로}
```

### 수정 가이드
{Sam/Peter에게 구체적인 수정 방향 제시}
```
