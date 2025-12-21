#!/bin/bash
# upload_data.sh - 批次上傳圖片到 Edge Impulse (固定用 training)

set -e

# 顏色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()   { echo -e "${GREEN}[INFO]${NC} $*"; }
log_error()  { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_warning(){ echo -e "${YELLOW}[WARN]${NC} $*"; }

# 檢查 EI_API_KEY
if [ -z "$EI_API_KEY" ]; then
  log_error 'EI_API_KEY 尚未設定。請先在終端機輸入：'
  log_error '  export EI_API_KEY="你的API金鑰"'
  exit 1
fi

# 解析參數：現在只做最簡單版
# 用法：upload_data.sh <label> <image1> [image2 ...]
if [ $# -lt 2 ]; then
  log_error "參數不足！用法：$0 <label> <image1> [image2 ...]"
  log_info  "範例：$0 coffee data/new_data/coffee*.jpg"
  exit 1
fi

LABEL="$1"
shift
IMAGES=("$@")

# 檢查檔案存在
for img in "${IMAGES[@]}"; do
  if [ ! -f "$img" ]; then
    log_error "找不到圖片檔：$img"
    exit 1
  fi
done

# log 資料夾
LOG_DIR="logs"
mkdir -p "$LOG_DIR"
TS=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="../$LOG_DIR/upload_${LABEL}_${TS}.log"

log_info "開始上傳：label=${LABEL}，類別固定為 training"
log_info "圖片數量：${#IMAGES[@]}"
log_info "log 檔：${LOG_FILE}"

# 這裡固定用 --category training，避免 test/testing 造成 404
if edge-impulse-uploader \
    --api-key "$EI_API_KEY" \
    --category split \
    --label "$LABEL" \
    "${IMAGES[@]}" | tee "$LOG_FILE"; then
  log_info "上傳完成，成功的檔案請到 Studio 的 Dataset / Training 查看"
else
  log_error "上傳失敗，請查看 log 檔：$LOG_FILE"
  exit 1
fi
