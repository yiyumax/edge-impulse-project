#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

CHECK_ENV="$SCRIPT_DIR/check_env.sh"
UPLOAD_DATA="$SCRIPT_DIR/upload_data.sh"
RETRAIN="$SCRIPT_DIR/retrain.sh"
WATCH_TRAINING="$SCRIPT_DIR/watch_training.sh"
update="$SCRIPT_DIR/update.sh"

pause () {
  echo
  read -p "按 Enter 繼續..."
}

while true; do
  clear
  echo "========================================"
  echo "  Edge Impulse ML Pipeline"
  echo "  完整機器學習工作流程"
  echo "========================================"
  echo
  echo "請選擇要執行的步驟："
  echo
  echo "1) 檢查環境設定"
  echo "2) 上傳新數據"
  echo "3) 觸發訓練"
  echo "4) 執行推論測試（下載最新模型）"
  echo "5) 完整流程（2 → 3 → 4）"
  echo "0) 離開"
  echo
  read -p "請輸入選項 [0-5]: " CHOICE
  echo

  case "$CHOICE" in
    1)
      echo "執行環境檢查..."
      "$CHECK_ENV"
      pause
      ;;
    2)
      echo "上傳新訓練資料..."
      echo
      read -p "請輸入資料標籤（label）: " LABEL
      read -p "請輸入圖片路徑（可使用萬用字元，例如 data/upload_test/coffee*.jpg）: " IMAGE_PATH
      if [ -z "$LABEL" ] || [ -z "$IMAGE_PATH" ]; then
        echo "ERROR: label 或 image path 不可為空"
        pause
        break
      fi
      $UPLOAD_DATA "$LABEL" $IMAGE_PATH
      pause
      ;;
    3)
      echo "觸發模型訓練..."
      JOB_ID=$("$RETRAIN")
      echo "Retrain job id: $JOB_ID"
      "$WATCH_TRAINING" "$JOB_ID"
      pause
      ;;
    4)
      echo "下載最新模型並準備推論..."
      "$updata	"
      pause
      ;;
    5)
      echo "執行完整流程..."
      echo
      "$UPLOAD_DATA"
      JOB_ID=$("$RETRAIN")
      echo "Retrain job id: $JOB_ID"
      "$WATCH_TRAINING" "$JOB_ID"
      "$updata"
      pause
      ;;
    0)
      echo "離開 ML Pipeline"
      exit 0
      ;;
    *)
      echo "無效選項，請重新選擇"
      pause
      ;;
  esac
done
