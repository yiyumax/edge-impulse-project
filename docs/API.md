# API.md - Edge Impulse API 使用說明

本文件說明本專案中實際使用到的 **Edge Impulse REST API**，並解釋各 API 在 ML Pipeline 中的角色、呼叫方式與回傳格式。本專案僅使用官方且穩定的 API，不依賴 Web UI 操作。

---

## 基本資訊

### API Base URL

https://studio.edgeimpulse.com/v1/api

### 必要認證

所有 API 皆需在 Header 中提供 API Key：
    x-api-key: <EI_API_KEY>
    本專案透過環境變數提供：
```bash
    export EI_API_KEY=ei_xxxxxxxxxxxxxxxxx
    export PROJECT_ID=123456
```

        API 一覽（Pipeline 對應）
        Pipeline 步驟	API	用途
        Step 2	Upload API	上傳訓練資料
        Step 3	Retrain API	觸發模型訓練
        Step 3	Jobs API	查詢訓練狀態
        Step 4	Deployment API	下載最新模型`

**1. 上傳訓練資料（Upload）**\
本專案透過 edge-impulse-uploader CLI 上傳資料，該工具底層即呼叫官方 Upload API。

實際使用方式
```bash
edge-impulse-uploader \
  --label coffee \
  image1.jpg image2.jpg
```
此步驟由 upload_data.sh 封裝，不直接手動呼叫 API。

**2. 觸發模型訓練（Retrain)**\
API Endpoint
```bash
POST /{PROJECT_ID}/jobs/retrain
```

_完整 URL 範例_
```bash
https://studio.edgeimpulse.com/v1/api/123456/jobs/retrain
```

_Request Headers_
```
x-api-key: EI_API_KEY
Content-Type: application/json
```

_Request Body_
```
{}
```
_Response 範例（成功）_
```
{
  "success": true,
  "id": 41900414
}
```
_說明_
>id 為 retrain job ID\
>retrain 會觸發一連串子任務（features、training 等)\
>此 API 為 唯一官方建議的自動化訓練入口\

    本專案由 retrain.sh 呼叫此 API。

**3. 查詢任務列表（Jobs）**\
API Endpoint
```bash
GET /{PROJECT_ID}/jobs
```
_完整 URL 範例_
```bash
https://studio.edgeimpulse.com/v1/api/123456/jobs
```
_Response 範例_
```
{
  "success": true,
  "jobs": [
    {
      "id": 41900416,
      "category": "Retraining model (Impulse #2)",
      "categoryKey": "retrain",
      "created": "2025-12-19T11:03:28.990Z",
      "started": "2025-12-19T11:03:28.994Z"
    }
  ]
}
```
_說明_
>Edge Impulse 不提供穩定的單一 job status API\
>正確做法是輪詢 /jobs 清單\
>依 categoryKey 判斷訓練是否仍存在\
>任務消失即代表訓練完成或失敗\

    本專案由 watch_training.sh 監控此 API。

**4. 下載最新模型（Deployment / Update）**\
_說明_\
Edge Impulse 不支援直接用 REST API 下載 .eim 模型檔。\
正確且官方支援方式為使用 edge-impulse-linux-runner。\

官方下載方式（建議）
```bash
edge-impulse-linux-runner \
  --api-key $EI_API_KEY \
  --download models/model.eim
```

模型權限設定
下載完成後需設定執行權限：

```bash
chmod +x models/model.eim
```
    此步驟已在 update.sh 中自動完成。

### 常見 API 錯誤說明
**1. Cannot GET / Cannot POST**\
    原因：
        - URL 錯誤
        - PROJECT_ID 錯誤
        - 使用了不存在的 API 路徑
        
    解法：
        - 確認 API 路徑是否存在於本文件
        - 確認 PROJECT_ID 是否正確

**2. Not updated configuration. No settable property found**\
    原因：
        - 嘗試使用 /jobs/train/keras/{id} 等非公開 API
        
    解法：
        - 一律使用 /jobs/retrain\
        - 不指定 learning block ID

**3. API 回傳 HTML 而非 JSON**\
    原因：
        - API 路徑不存在
        - Edge Impulse 回傳錯誤頁面
        
    解法：
        - 使用 /jobs 檢查是否為合法 endpoint
        - 不使用未列於本文件的 API

###  設計原則
    >僅使用官方穩定 API
    >不依賴 UI
    >可用於自動化
