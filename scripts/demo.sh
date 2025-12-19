#!/bin/bash
clear
echo "=== Edge Impulse ML Pipeline 展示 ==="
sleep 2
echo ""
echo "步驟1:檢查環境"
sleep 1
./check_env.sh
sleep 3
echo ""
echo "步驟2:執行推論"
sleep 1
./run_test.sh data/test/demo.jpg
sleep 5
echo ""
echo "展示完成"
