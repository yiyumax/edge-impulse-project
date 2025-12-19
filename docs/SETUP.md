# SETUP.md — 安裝指南

本文件說明 Edge Impulse ML Pipeline 專案的完整安裝與環境設定流程。請依序完成所有步驟，以確保資料上傳、模型訓練、訓練監控與模型更新（update）流程可正常執行。

---

## 系統需求

本專案建議於 Linux 環境下執行，需求如下：

作業系統：
- Linux（建議 Ubuntu 20.04 以上）

必要軟體與工具：
- Python 3.9 以上
- Node.js 16 以上
- npm
- curl
- jq
- git

---

## 安裝步驟

### Step 1：更新系統套件

```bash
    sudo apt update
    sudo apt upgrade -y
```

### Step 2：安裝基本工具

```bash
    sudo apt install -y curl jq git
```

### Step 3：安裝 Node.js 與 npm

```bash
    sudo apt install -y nodejs npm
```
 #確認版本：
```bash
    node -v
    npm -v
```

### Step 4：安裝 Edge Impulse 相關工具

```bash
    sudo npm install -g edge-impulse-cli
    sudo npm install -g edge-impulse-linux
```
 #確認是否安裝成功：
```bash
    edge-impulse-linux-runner --version
```


## 環境變數設定
本專案需使用 Edge Impulse API Key 與 Project ID

```bash
    export EI_API_KEY=ei_xxxxxxxxxxxxxxxxx
    export PROJECT_ID=123456
```
  #確認是否設定成功：
```bash  
    echo $EI_API_KEY
    echo $PROJECT_ID
```

## 專案權限設定
進入專案根目錄後，設定所有腳本為可執行：

```bash
    chmod +x scripts/*.sh
```
模型下載後需具備執行權限：

```bash
    chmod +x models/*.eim
```
此動作已在 update.sh 中自動處理，但仍建議確認

## 驗證安裝
執行環境檢查腳本以確認所有設定是否完成：

```bash
    ./scripts/check_env.sh
```

若所有檢查項目皆顯示通過，代表安裝與設定成功。

## 常見問題
問題一：edge-impulse-linux-runner 找不到指令
    請確認 npm global bin 路徑是否已加入 PATH。

問題二：Model file is not executable
    請確認模型檔案具有執行權限：
```bash
    chmod +x models/model.eim
```

問題三：API 回傳 Cannot GET 或 Cannot POST
    請確認 PROJECT_ID 與 EI_API_KEY 是否正確，且仍為有效金鑰。
