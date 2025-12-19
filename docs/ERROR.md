# ERROR.md - 常見錯誤與處理紀錄

本文件整理在開發與整合 Edge Impulse ML Pipeline 過程中實際遇到的錯誤情境、成因分析與解決方式，作為後續維護與交接的重要參考文件。

---

## 錯誤一：Git 無法 push 至 GitHub

### 錯誤訊息範例

[rejected] main -> main (fetch first)
Updates were rejected because the remote contains work that you do not have locally

### 問題原因

GitHub 上的遠端儲存庫已經包含本機尚未同步的提交（commit），可能原因包含：

- 有組員已先行 push
- 在 GitHub 網站上直接新增或修改檔案（例如 README.md）
- 建立 repository 時 GitHub 自動產生初始檔案

Git 為避免直接覆蓋他人內容，因此拒絕 push。

### 解決方式（建議流程）

1. **先備份本地資料**
```bash
cp -r edge_impulse_demo edge_impulse_demo_backup
```
2. **同步遠端最新版本**

```bash
git pull origin main
```
3. **重新上傳**

```bash
git push origin main
```
## 錯誤二：Edge Impulse 指令無法使用
### 常見現象
ei 指令不存在

教學中的指令無法執行

CLI 行為與官方文件不一致

### 問題原因
Edge Impulse 在版本更新後，CLI 工具已拆分為多個獨立指令：

edge-impulse-uploader

edge-impulse-linux-runner

edge-impulse-daemon

大量網路教學仍使用舊版 ei 指令，導致混淆。

### 解決方式
安裝最新版工具：

```bash
sudo npm install -g edge-impulse-cli edge-impulse-linux
```
專案流程全面避免使用 ei 指令

## 錯誤三：本地端無法透過 API 存取 Edge Impulse
### 常見現象
API 回傳 Cannot GET / Cannot POST

curl 回傳 HTML

jq 顯示 Invalid numeric literal

### 問題原因
使用不存在或非公開 API

誤以為 Edge Impulse 支援 /jobs/{id} 查詢

嘗試用 REST API 下載模型

環境變數未正確設定

### 解決方式
觸發訓練僅使用：

```bash
POST /v1/api/{PROJECT_ID}/jobs/retrain
```
查詢狀態僅使用：

```bash
GET /v1/api/{PROJECT_ID}/jobs
```
模型下載一律使用：

```bash
edge-impulse-linux-runner --download models/model.eim
```

### 經驗總結

Git 問題多半是同步順序問題

Edge Impulse CLI 與 API 教學需注意版本差異

Edge Impulse 並非完整開放 REST API
