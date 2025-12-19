# USAGE.md — 使用說明
本文件說明 Edge Impulse ML Pipeline 的實際使用方式，包含互動式 Pipeline 操作、單一腳本的獨立使用方法、實際工作流程範例，以及使用上的最佳實踐建議。

---

## 一、互動式 Pipeline 使用
本專案提供 `ml_pipeline.sh` 作為主控腳本，使用者可透過互動式選單執行完整的機器學習流程。

### 啟動方式

```bash
    chmod +x scripts/ml_pipeline.sh
    ./scripts/ml_pipeline.sh
```
### 選單說明
啟動後將顯示以下選項：

1)檢查環境設定
2)上傳新數據
3)觸發訓練
4)執行推論測試（update：下載最新模型）
5)完整流程（2 → 3 → 4）
0)離開

使用者可依需求選擇單一步驟或執行完整流程。

##  二、單獨使用各腳本
除主控腳本外，每個流程步驟皆可獨立執行，適合進行除錯或自動化整合。

    1. 上傳新訓練資料
```bash
    ./scripts/upload_data.sh <label> <image1> [image2 ...]
```
        範例：
```bash
    ./scripts/upload_data.sh coffee data/coffee/*.jpg
```
    2. 觸發模型訓練
```bash
    ./scripts/retrain.sh
```此指令將透過 Edge Impulse API 觸發 retrain，並回傳訓練 job ID。

    3. 監控訓練進度
```bash
    ./scripts/watch_training.sh <job_id>
```
        範例：
```bash
    ./scripts/watch_training.sh 41901093
```當訓練完成時，腳本將顯示訓練結束狀態。

    4. 更新本地模型（update）
```bash
    ./scripts/update.sh
```此步驟會下載最新的 Unoptimized（float32）模型至 models/ 目錄，並自動設定執行權限。

## 三、實際工作流程範例
    範例一：新增資料並重新訓練模型
        上傳新圖片資料

        觸發模型訓練

        等待訓練完成

        更新本地模型

    範例二：定期模型更新
        僅執行模型更新步驟以下載最新模型：
        ```bash
            ./scripts/update.sh
        ```
    範例三：訓練失敗後重新嘗試
        修正資料或標註
        重新執行 retrain.sh
        使用 watch_training.sh 追蹤狀態

## 四、最佳實踐建議
>上傳資料前先檢查資料品質與標註正確性

>每次訓練完成後立即更新本地模型

>將 models/ 納入版本管理或定期備份

>訓練前確認環境變數已正確設定

>發生錯誤時，先單獨執行對應腳本進行除錯
