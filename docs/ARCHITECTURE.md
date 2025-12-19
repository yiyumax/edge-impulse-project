# ARCHITECTURE.md - 系統架構說明

本文件說明 **Edge Impulse ML Pipeline 專案** 的整體系統架構設計，包含各模組的職責、資料流向、腳本之間的關係，以及整體設計理念。\
本架構目標為：**可自動化、可重現、可維護、可交付他人使用**。

---

## 整體設計目標

本專案的系統架構設計遵循以下原則：

1. **模組化（Modular）** 
   每個步驟由獨立腳本負責，避免單一腳本過度複雜。

2. **自動化（Automated）** 
   所有操作皆可透過 Shell 腳本與 API 完成，不依賴 Web UI。

3. **可追蹤（Observable）** 
   訓練狀態可即時監控。

4. **可擴充（Extensible）** 
   可輕易替換模型類型、資料來源或部署方式。

---

## 專案目錄結構

edge_impulse_demo/
├─ scripts/
│ ├─ check_env.sh
│ ├─ upload_data.sh
│ ├─ retrain.sh
│ ├─ watch_training.sh
│ ├─ update.sh
│ └─ ml_pipeline.sh
│
├─ models/
│ └─ model.eim
│
├─ docs/
│ ├─ SETUP.md
│ ├─ USAGE.md
│ ├─ API.md
│ ├─ ARCHITECTURE.md
│ └─ TROUBLESHOOTING.md
│
├─ logs/
│
├─ data/
│
├─ results/
│
└─ README.md

---

## 系統元件說明

### 1. scripts/（流程控制層）

此資料夾負責 **所有自動化流程邏輯**。

#### check_env.sh
- 功能：環境驗證
- 檢查項目：
  - 必要指令是否存在（python, node, curl, jq 等）
  - 環境變數是否設定（EI_API_KEY, PROJECT_ID）

#### upload_data.sh
- 功能：上傳訓練資料
- 使用工具：
  - edge-impulse-uploader
- 責任：
  - 將本地資料送至 Edge Impulse 專案

#### retrain.sh
- 功能：觸發模型訓練
- 使用 API：
  - POST /jobs/retrain
- 輸出：
  - retrain job ID

#### watch_training.sh
- 功能：監控訓練狀態
- 使用 API：
  - GET /jobs
- 設計重點：
  - Edge Impulse 不提供穩定的單一 job status API
  - 以輪詢 jobs 清單判斷訓練是否仍在進行

#### update.sh
- 功能：下載最新模型
- 使用工具：
  - edge-impulse-linux-runner --download
- 責任：
  - 下載最新 `.eim` 模型
  - 設定模型為可執行檔

#### ml_pipeline.sh
- 功能：主控制腳本
- 提供：
  - 互動式選單
  - 串接所有子腳本
- 支援流程：
  - 單步執行
  - 完整流程（Upload → Retrain → Watch → Update）

---

### 2. models/（模型層）

- 儲存由 Edge Impulse 產生的 `.eim` 模型檔
- 模型特性：
  - Unoptimized（float32）
  - 可直接由 edge-impulse-linux-runner 或 Python Runner 使用
- 權限需求：
  - 必須為 executable

---

### 3. docs/（文件層）

文件依職責拆分，避免單一文件過於龐大：

| 文件 | 用途 |
|----|----|
| README.md | 專案總覽 |
| SETUP.md | 安裝與環境設定 |
| USAGE.md | 使用方式與流程 |
| API.md | API 說明 |
| ARCHITECTURE.md | 系統架構 |
| TROUBLESHOOTING.md | 問題排查 |

---

## 資料與控制流程（Flow）

使用者
↓
ml_pipeline.sh
↓
check_env.sh
↓
upload_data.sh
↓
retrain.sh
↓
watch_training.sh
↓
update.sh
↓
models/model.eim

yaml
複製程式碼

---

## 為何不直接指定 Learning Block 訓練

設計上選擇：

POST /jobs/retrain

複製程式碼

而非：

/jobs/train/keras/{id}

原因：
- retrain 為官方穩定入口
- retrain 會自動處理 feature generation 與多 block 依賴
- 可避免 API 版本變動造成失效

---

## 架構限制與注意事項

1. 無法可靠取得單一 job 的 finished 狀態  
   → 需透過 jobs 清單是否仍存在判斷

2. 無法透過 REST API 直接下載模型  
   → 必須使用官方 runner 工具

3. Edge Impulse job 會拆分為多個子任務  
   → retrain job 並非唯一 training job

---

## 架構適用場景

- 課程作業與評分
- 小型研究專案
- 自動化 ML Pipeline 示範
- Headless Server 環境
