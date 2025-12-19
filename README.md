# Edge Impulse ML Pipeline

本專案實作一套以 Edge Impulse 為核心的機器學習自動化流程， 
透過 Shell Script 串接資料上傳、模型訓練、訓練監控與模型同步更新（update）， 
建立一個可重複執行、可維護的 ML Pipeline。

---

## 功能特色

- 互動式主控腳本（ml_pipeline.sh）
- 使用 Edge Impulse Public API 觸發模型 retrain
- 自動監控訓練進度
- 使用官方工具同步下載最新模型（model.eim）
- Step 4 明確命名為 update（更新本地模型）
- 支援 Unoptimized（float32）模型
- 支援 Linux runner 與 Python inference

---

## 專案結構

edge_impulse_demo/\
├─ scripts/\
│  ├─ check_env.sh\
│  ├─ upload_data.sh\
│  ├─ retrain.sh\
│  ├─ watch_training.sh\
│  ├─ update.sh\
│  └─ ml_pipeline.sh\
├─ models/\
│  └─ model.eim\
├─ docs/\
│  ├─ SETUP.md\
│  ├─ USAGE.md\
│  ├─ API.md\
│  ├─ ARCHITECTURE.md\
│  └─ TROUBLESHOOTING.md\
└─ README.md\

---

## 快速開始

### 1. 環境設定

請先依照 docs/SETUP.md 完成所有必要工具與套件的安裝， 
並設定以下環境變數：

export EI_API_KEY=ei_xxxxxxxxx 
export PROJECT_ID=123456

---

### 2. 啟動主控腳本

chmod +x scripts/*.sh 
./scripts/ml_pipeline.sh

---

## Pipeline Steps 說明

1. 檢查環境設定 
2. 上傳新訓練資料 
3. 觸發模型訓練 
4. 更新本地模型（update） 
5. 完整流程（2 → 3 → 4）

---

## 模型權限設定（重要）

下載完成的 .eim 模型在 Linux 環境中必須具有 executable 權限，  
否則在使用 edge-impulse-linux-runner 或 Python runner 時將無法載入模型。

chmod +x models/model.eim

注意：update.sh 已在下載完成後自動設定模型執行權限。

---




