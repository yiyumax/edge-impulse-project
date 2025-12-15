#!/usr/bin/env python3
import sys
import os
import glob
import cv2
import numpy as np
from edge_impulse_linux.runner import ImpulseRunner


def preprocess(image_path, width, height):
    """讀圖 + 灰階 + resize + 攤平成一維陣列"""
    img = cv2.imread(image_path)
    if img is None:
        raise ValueError(f"讀不到圖片: {image_path}")

    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img_gray = cv2.cvtColor(img_rgb, cv2.COLOR_RGB2GRAY)
    img_resized = cv2.resize(img_gray, (width, height))

    img_float = img_resized.astype("float32")
    return img_float.flatten()


def print_result(result):
    """把推論結果印出來（物件偵測）"""
    if "bounding_boxes" in result["result"]:
        boxes = result["result"]["bounding_boxes"]
        print(f"偵測到 {len(boxes)} 個物件")
        for i, box in enumerate(boxes, start=1):
            print(f"物件{i}: {box['label']} ({box['value']:.2f})")
    else:
        print("結果中沒有 bounding_boxes，可以印 result 來看看：")
        print(result)


def main():
    if len(sys.argv) != 3:
        print("使用方式: python3 classify_od.py <model.eim> <圖片檔 或 資料夾>")
        print("  單張：python3 classify_od.py ./model.eim test.jpg")
        print("  批次：python3 classify_od.py ./model.eim images")
        sys.exit(1)

    model_path = sys.argv[1]
    target_path = sys.argv[2]

    print(f"載入模型: {model_path}")

    runner = ImpulseRunner(model_path)
    try:
        model_info = runner.init()
        print(f"模型標籤：{model_info['model_parameters']['labels']}\n")
        print("=== 推論開始 ===")

        # 取得模型需要的輸入尺寸
        width = model_info["model_parameters"]["image_input_width"]
        height = model_info["model_parameters"]["image_input_height"]

        # --------------------------------------------------
        # ① 如果第二個參數是「資料夾」，就批次處理裡面的 jpg
        # --------------------------------------------------
        if os.path.isdir(target_path):
            # 找出資料夾裡所有 jpg / jpeg / png
            image_files = []
            image_files += glob.glob(os.path.join(target_path, "*.jpg"))
            image_files += glob.glob(os.path.join(target_path, "*.jpeg"))
            image_files += glob.glob(os.path.join(target_path, "*.png"))

            if not image_files:
                print("這個資料夾裡沒有 jpg / jpeg / png 圖片")
                return

            # 一張一張處理
            for img_path in sorted(image_files):
                print(f"\n處理：{img_path}")
                img_processed = preprocess(img_path, width, height)
                result = runner.classify(img_processed)
                print_result(result)

        # --------------------------------------------------
        # ② 如果第二個參數是「單一圖片檔」，就只處理那一張
        # --------------------------------------------------
        else:
            print(f"載入圖片: {target_path}")
            img_processed = preprocess(target_path, width, height)
            result = runner.classify(img_processed)
            print_result(result)

    finally:
        runner.stop()


if __name__ == "__main__":
    main()
