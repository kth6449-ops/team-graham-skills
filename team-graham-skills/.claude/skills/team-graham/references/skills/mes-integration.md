# MES Integration Patterns — BESOLT

## ISA-95 계층 구조
```
Level 4: ERP (SAP, Oracle)        ← 생산계획, 자재, 원가
Level 3: MES                       ← 작업지시, 실적, 품질
Level 2: SCADA/DCS                 ← 공정 모니터링/제어
Level 1: PLC/Controller            ← 설비 직접 제어
Level 0: Field Devices (Sensors)   ← 데이터 수집
```

## MES ↔ SOLT-AI 연동 패턴

### 데이터 수신 (MES → SOLT-AI)
```python
# FastAPI endpoint for MES push
@router.post("/api/v1/mes/work-orders")
async def receive_work_order(wo: WorkOrderSchema):
    """MES에서 작업지시 수신"""
    await work_order_service.process(wo)
    return {"status": "received"}

# Polling pattern (MES pull)
async def poll_mes_data():
    """MES REST API 주기적 폴링"""
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.MES_BASE_URL}/api/production/orders",
            headers={"Authorization": f"Bearer {settings.MES_API_KEY}"},
            params={"status": "IN_PROGRESS", "updated_since": last_poll_time}
        )
    return response.json()
```

### 데이터 전송 (SOLT-AI → MES)
```python
# AI 분석 결과를 MES로 피드백
async def send_quality_result(inspection_result: dict):
    """품질 검사 결과 MES 전송"""
    payload = {
        "work_order": inspection_result["work_order"],
        "product_code": inspection_result["product_code"],
        "result": inspection_result["ai_decision"],  # PASS/FAIL
        "defect_code": inspection_result.get("defect_type"),
        "confidence": inspection_result["confidence_score"],
        "source": "SOLT-AI"
    }
    await mes_client.post("/api/quality/results", json=payload)
```

## OPC-UA 연동 패턴

```python
from asyncua import Client, ua

async def collect_opc_data(endpoint: str, node_ids: list[str]):
    """OPC-UA 서버에서 데이터 수집"""
    async with Client(url=endpoint) as client:
        # 인증서 설정
        await client.set_security_string(
            f"Basic256Sha256,SignAndEncrypt,{CERT_PATH},{KEY_PATH}"
        )
        
        # 구독 기반 실시간 수집
        subscription = await client.create_subscription(
            period=500,  # 500ms
            handler=DataChangeHandler()
        )
        
        nodes = [client.get_node(nid) for nid in node_ids]
        await subscription.subscribe_data_change(nodes)
        
        # 연결 유지
        while True:
            await asyncio.sleep(1)
```

## 에러 처리 패턴

```python
class MESIntegrationError(Exception):
    pass

async def safe_mes_call(func, *args, max_retries=3, **kwargs):
    """재시도 로직 포함 MES API 호출"""
    for attempt in range(max_retries):
        try:
            return await func(*args, **kwargs)
        except httpx.TimeoutException:
            if attempt == max_retries - 1:
                raise MESIntegrationError("MES timeout after retries")
            await asyncio.sleep(2 ** attempt)  # exponential backoff
        except httpx.HTTPStatusError as e:
            logger.error("mes_api_error", 
                        status=e.response.status_code,
                        endpoint=str(e.request.url))
            raise
```

## 데이터 매핑 (MES 필드 → SOLT-AI 표준)

```python
MES_TO_SOLT_MAPPING = {
    # 작업지시
    "WorkOrderNo": "work_order_id",
    "ItemCode": "product_code", 
    "PlanQty": "planned_quantity",
    "WorkCenterCode": "equipment_id",
    
    # 품질
    "InspResultCode": "quality_result",  # "OK" → "PASS", "NG" → "FAIL"
    "DefectCode": "defect_type",
    
    # 설비
    "MachineStatusCode": "equipment_status",
    "DowntimeReasonCode": "downtime_reason"
}
```
