#!/usr/bin/env bash
# scripts/stats.sh - 專案數據統計

set -euo pipefail

# 切回專案根目錄
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

########## Git 統計 ##########
if command -v git >/dev/null 2>&1; then
  COMMITS=$(git rev-list --count HEAD 2>/dev/null || echo 0)
  CONTRIBUTORS=$(git log --format='%aN' | sort -u | wc -l | tr -d ' ')
else
  COMMITS=0
  CONTRIBUTORS=0
fi

########## 程式碼統計 ##########
# 只算 scripts/ 裡面的 .sh / .py
SHELL_COUNT=$(find scripts -maxdepth 1 -type f -name "*.sh" | wc -l | tr -d ' ')
PYTHON_COUNT=$(find scripts -maxdepth 1 -type f -name "*.py" | wc -l | tr -d ' ')

# 用 git ls-files 算整個專案的總行數（不含 .git）
if command -v git >/dev/null 2>&1; then
  TOTAL_LINES=$(git ls-files | xargs -r wc -l | tail -n1 | awk '{print $1}')
else
  TOTAL_LINES=$(find . -type f \( -name "*.sh" -o -name "*.py" \) -print0 \
    | xargs -0 -r cat | wc -l | awk '{print $1}')
fi

########## 數據統計 ##########
TRAIN_IMAGES=0
TEST_IMAGES=0

# 情況 1：如果你有 data/train、data/test 這種資料夾，就用它們
if [ -d "data/train" ] || [ -d "data/test" ]; then
  if [ -d "data/train" ]; then
    TRAIN_IMAGES=$(find data/train -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
      | wc -l | tr -d ' ')
  fi
  if [ -d "data/test" ]; then
    TEST_IMAGES=$(find data/test -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
      | wc -l | tr -d ' ')
  fi

# 情況 2：像你現在這個專案，用 data/collected 底下的圖
elif [ -d "data/collected" ]; then
  # 把 data/collected/not 當成「測試圖」，其它當「訓練圖」
  TRAIN_IMAGES=$(find data/collected \
    -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
    ! -path "*/not/*" | wc -l | tr -d ' ')
  if [ -d "data/collected/not" ]; then
    TEST_IMAGES=$(find data/collected/not \
      -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
      | wc -l | tr -d ' ')
  fi
fi

########## 輸出 ##########
cat <<EOF
=== 專案統計 ===

Git 統計:
  Commits: ${COMMITS}
  Contributors: ${CONTRIBUTORS}

程式碼統計:
  Shell 腳本: ${SHELL_COUNT} 個
  Python 腳本: ${PYTHON_COUNT} 個
  總行數: ${TOTAL_LINES}

數據統計:
  訓練圖片: ${TRAIN_IMAGES}
  測試圖片: ${TEST_IMAGES}
EOF
