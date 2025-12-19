#!/bin/bash
# test_all.sh - 一鍵跑完整個專案的基本測試
#
# 測試項目：
# 1) 環境檢查：執行 check_env.sh 驗證環境設定
# 2) 推論功能測試：使用一張測試圖片執行推論
# 3) API 連接測試：測試與 Edge Impulse Studio API 的連線
# 4) 腳本執行權限：檢查 scripts/*.sh 是否可執行
# 5) 目錄結構檢查：確認必要目錄存在

set -u

# -----------------------------
# helpers
# -----------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[FAIL]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

PASS=0
FAIL=0

FIX_PERMS=0
CUSTOM_IMAGE=""

usage() {
  cat <<EOF
用法：
  $0 [--fix-perms] [--image /path/to/img.jpg]

選項：
  --fix-perms   自動把 scripts/*.sh chmod +x
  --image PATH  指定推論要用的測試圖片（預設會自動找 data/ 底下的第一張 jpg/png）
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fix-perms)
      FIX_PERMS=1
      shift
      ;;
    --image)
      CUSTOM_IMAGE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log_warn "未知參數：$1"
      usage
      exit 2
      ;;
  esac
done

run_case() {
  local name="$1"; shift
  echo
  echo "===== ${name} ====="
  if "$@"; then
    log_info "${name} OK"
    PASS=$((PASS+1))
    return 0
  else
    log_error "${name} FAILED"
    FAIL=$((FAIL+1))
    return 1
  fi
}

is_json() {
  # 用 jq 判斷是否為 JSON（如果 jq 不存在就用簡單字串判斷）
  local s="$1"
  if command -v jq >/dev/null 2>&1; then
    echo "$s" | jq . >/dev/null 2>&1
  else
    [[ "$s" == \{* || "$s" == \[* ]]
  fi
}

# -----------------------------
# 5) 目錄結構檢查
# -----------------------------
check_dirs() {
  local required=("scripts" "docs" "models" "data" "logs")
  local missing=()
  for d in "${required[@]}"; do
    if [[ ! -d "${ROOT_DIR}/${d}" ]]; then
      missing+=("$d")
    fi
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    log_error "缺少必要目錄：${missing[*]}"
    return 1
  fi
  return 0
}

# -----------------------------
# 4) 腳本執行權限
# -----------------------------
check_script_perms() {
  local bad=()
  while IFS= read -r -d '' f; do
    if [[ ! -x "$f" ]]; then
      bad+=("$(basename "$f")")
      if [[ $FIX_PERMS -eq 1 ]]; then
        chmod +x "$f" || true
      fi
    fi
  done < <(find "${SCRIPT_DIR}" -maxdepth 1 -type f -name "*.sh" -print0)

  if [[ ${#bad[@]} -gt 0 ]]; then
    if [[ $FIX_PERMS -eq 1 ]]; then
      log_warn "以下腳本原本不可執行，已自動 chmod +x：${bad[*]}"
      return 0
    fi
    log_error "以下腳本沒有執行權限（可用 --fix-perms 自動修正）：${bad[*]}"
    return 1
  fi
  return 0
}

# -----------------------------
# 1) 環境檢查
# -----------------------------
env_check() {
  # check_env.sh 可能會要求 EI_API_KEY / PROJECT_ID
  (cd "${SCRIPT_DIR}" && ./check_env.sh)
}

# -----------------------------
# 2) 推論功能測試
# -----------------------------
find_test_image() {
  if [[ -n "$CUSTOM_IMAGE" ]]; then
    echo "$CUSTOM_IMAGE"
    return 0
  fi

  local candidates=(
    "${ROOT_DIR}/data/test"
    "${ROOT_DIR}/data/testing"
    "${ROOT_DIR}/data/upload_test"
    "${ROOT_DIR}/data/collected"
    "${ROOT_DIR}/data/train"
    "${ROOT_DIR}/data/training"
  )

  local img=""
  for dir in "${candidates[@]}"; do
    if [[ -d "$dir" ]]; then
      img=$(find "$dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | head -n 1 || true)
      if [[ -n "$img" ]]; then
        echo "$img"
        return 0
      fi
    fi
  done

  return 1
}

inference_test() {
  local model="${ROOT_DIR}/models/model.eim"
  if [[ ! -f "$model" ]]; then
    log_warn "找不到 models/model.eim，嘗試用 scripts/update.sh 下載（需要 EI_API_KEY 與 edge-impulse-linux-runner）"
    if (cd "${SCRIPT_DIR}" && ./update.sh); then
      :
    else
      log_error "模型不存在且自動下載失敗"
      return 1
    fi
  fi

  local img
  img=$(find_test_image) || {
    log_error "找不到測試圖片。請放一張到 data/test 或用 --image 指定"
    return 1
  }
  if [[ ! -f "$img" ]]; then
    log_error "測試圖片不存在：$img"
    return 1
  fi

  mkdir -p "${ROOT_DIR}/results"

  local base
  base="$(basename "$img")"
  local expected="${ROOT_DIR}/results/detected/${base%.*}_detected.jpg"
  rm -f "$expected" >/dev/null 2>&1 || true

  log_info "使用測試圖片：$img"
  (cd "${SCRIPT_DIR}" && ./run_test.sh "$img")

  if [[ -f "$expected" ]]; then
    log_info "推論結果已產生：$expected"
    return 0
  fi

  # 有些版本可能把輸出放在 timestamp 資料夾內，這裡做備援檢查
  if ls "${ROOT_DIR}/results"/*_detected.jpg >/dev/null 2>&1; then
    log_warn "找不到預期檔名，但 results/ 底下有 detected 圖片，視為推論成功"
    return 0
  fi

  log_error "推論腳本執行完畢，但沒有產生 detected 圖片"
  return 1
}

# -----------------------------
# 3) API 連接測試
# -----------------------------
api_test() {
  if [[ -z "${EI_API_KEY:-}" ]]; then
    log_error "EI_API_KEY 未設定，無法做 API 測試"
    return 1
  fi

  local resp
  resp=$(curl -fsS "https://studio.edgeimpulse.com/v1/api/projects" \
    -H "x-api-key: ${EI_API_KEY}" \
    -H "accept: application/json" )

  if ! is_json "$resp"; then
    log_error "API 回傳不是 JSON（可能拿到 HTML / 錯誤頁）"
    echo "$resp" | head -n 20
    return 1
  fi

  if command -v jq >/dev/null 2>&1; then
    local n
    n=$(echo "$resp" | jq '.projects | length' 2>/dev/null || echo 0)
    log_info "projects 回傳 OK（projects 數量：$n）"
  else
    log_info "projects 回傳 OK（已確認為 JSON）"
  fi

  # 若有 PROJECT_ID，再多測一個 impulse 端點（可選）
  if [[ -n "${PROJECT_ID:-}" ]]; then
    local r2
    r2=$(curl -fsS "https://studio.edgeimpulse.com/v1/api/${PROJECT_ID}/impulse" \
      -H "x-api-key: ${EI_API_KEY}" \
      -H "accept: application/json" )
    if is_json "$r2"; then
      log_info "impulse 端點回傳 OK（PROJECT_ID=${PROJECT_ID}）"
    else
      log_warn "impulse 端點回傳不是 JSON（但 projects 端點 OK）"
    fi
  else
    log_warn "未設定 PROJECT_ID，略過 impulse 端點測試"
  fi

  return 0
}

# -----------------------------
# main
# -----------------------------
echo "=== test_all.sh：開始測試 ==="
echo "ROOT_DIR=${ROOT_DIR}"

run_case "目錄結構檢查" check_dirs
run_case "腳本執行權限檢查" check_script_perms
run_case "環境檢查" env_check
run_case "推論功能測試" inference_test
run_case "API 連接測試" api_test

echo
echo "=== 測試完成 ==="
echo -e "通過：${GREEN}${PASS}${NC}  失敗：${RED}${FAIL}${NC}"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
exit 0
