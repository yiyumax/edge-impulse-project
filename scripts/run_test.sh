#!/bin/bash
# run_inference.sh - 進階版：彩色日誌 + 錯誤處理 + 結果儲存

set -e  # 遇到沒被處理的錯誤就立刻停止腳本

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color

# 日誌函數
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

# 主程式邏輯
main() {
    # 依照你的實際路徑調整
    local MODEL_PATH="models/model.eim"   # 例如 models/model.eim
    local SCRIPT_PATH="scripts/mix.py"     # 例如 scripts/mix.py

    # 1) 參數檢查
    if [ $# -lt 1 ]; then
        log_error "用法: $0 <圖片檔或資料夾路徑> [模型路徑]"
        log_info  "範例(單張): $0 images/test1.jpg"
        log_info  "範例(批次): $0 images"
        log_info  "範例(指定模型): $0 images models/new_model.eim"
        exit 1
    fi

    local TARGET_PATH="$1"

    # 若有給第二個參數，就覆蓋預設模型路徑
    if [ $# -ge 2 ]; then
        MODEL_PATH="$2"
    fi

    # 2) 檢查檔案是否存在
    if [ ! -f "$MODEL_PATH" ]; then
        log_error "找不到模型: $MODEL_PATH"
        exit 1
    fi

    if [ ! -e "$TARGET_PATH" ]; then
        log_error "找不到圖片檔或資料夾: $TARGET_PATH"
        exit 1
    fi

    # 3) 建立結果資料夾（加時間戳記）
    local TIMESTAMP
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    local OUTPUT_DIR="results/${TIMESTAMP}"
    mkdir -p "$OUTPUT_DIR"

    log_info "開始推論..."
    log_info "模型: $MODEL_PATH"
    log_info "目標: $TARGET_PATH"
    log_info "結果資料夾: $OUTPUT_DIR"

    # 4) 執行推論並將終端輸出存成 log
    #    tee 會一邊印在畫面，一邊寫到 inference_log.txt
    if python3 "$SCRIPT_PATH" "$MODEL_PATH" "$TARGET_PATH" \
        | tee "$OUTPUT_DIR/inference_log.txt"; then
        log_info "推論成功完成"
    else
        log_error "推論失敗"
        exit 1
    fi

    # 5) 複製輸入圖片 / 資料夾內容到結果資料夾
    if [ -f "$TARGET_PATH" ]; then
        # 單張圖片
        cp "$TARGET_PATH" "$OUTPUT_DIR"/
    elif [ -d "$TARGET_PATH" ]; then
        # 資料夾：嘗試把底下檔案複製過去
        # 如果沒有檔案可複製就給一個 warning，不讓腳本因為 cp 失敗中斷
        if ! cp "$TARGET_PATH"/* "$OUTPUT_DIR"/ 2>/dev/null; then
            log_warning "資料夾裡沒有可複製的檔案: $TARGET_PATH"
        fi
    fi

    log_info "結果已儲存到: $OUTPUT_DIR"
}

# 把所有命令列參數傳進 main
main "$@"
