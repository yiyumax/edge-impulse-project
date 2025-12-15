#!/usr/bin/env python3
import sys
import os
import glob
import cv2
import numpy as np
from edge_impulse_linux.runner import ImpulseRunner


def load_and_preprocess(image_path, width, height):
    """讀取圖片並依模型需求做前處理，回傳 features 以及原圖 (給畫框用)"""
    img_bgr = cv2.imread(image_path)
    if img_bgr is None:
        raise RuntimeError(f"讀不到圖片：{image_path}")

    # 先轉 RGB 再 resize（跟 Edge Impulse 範例一致）
    img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
    img_resized = cv2.resize(img_rgb, (width, height))

    # 這裡用灰階當輸入
    img_gray = cv2.cvtColor(img_resized, cv2.COLOR_RGB2GRAY)
    img_gray = img_gray.astype(np.float32)

    # 攤平成一維陣列當作模型 input
    features = img_gray.flatten()
    return img_bgr, features


def draw_bounding_boxes(orig_img, boxes, model_w, model_h, save_path):
    """把 bounding box 畫在原圖上並存檔"""
    h, w = orig_img.shape[:2]
    # 模型輸入尺寸 -> 原圖尺寸 的縮放比例
    scale_x = w / float(model_w)
    scale_y = h / float(model_h)

    for box in boxes:
        x = int(box["x"] * scale_x)
        y = int(box["y"] * scale_y)
        bw = int(box["width"] * scale_x)
        bh = int(box["height"] * scale_y)

        label = box["label"]
        score = box["value"]

        # 畫框
        cv2.rectangle(orig_img, (x, y), (x + bw, y + bh), (0, 255, 0), 2)
        # 畫標籤文字
        text = f"{label} {score:.2f}"
        cv2.putText(
            orig_img,
            text,
            (x, max(0, y - 10)),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.6,
            (0, 255, 0),
            2,
            cv2.LINE_AA,
        )

    os.makedirs(os.path.dirname(save_path), exist_ok=True)
    cv2.imwrite(save_path, orig_img)
    print(f"已將偵測結果存成：{save_path}")


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
        labels = model_info["model_parameters"]["labels"]
        width = model_info["model_parameters"]["image_input_width"]
        height = model_info["model_parameters"]["image_input_height"]
        print(f"模型標籤：{labels}")
        print(f"模型輸入尺寸：{width} x {height}")
        print("=== 推論開始 ===")

        # --------------------------------------------------
        # ① 如果第二個參數是「資料夾」，就批次處理裡面的 jpg/jpeg/png
        # --------------------------------------------------
        if os.path.isdir(target_path):
            image_files = []
            image_files += glob.glob(os.path.join(target_path, "*.jpg"))
            image_files += glob.glob(os.path.join(target_path, "*.jpeg"))
            image_files += glob.glob(os.path.join(target_path, "*.png"))

            if not image_files:
                print("這個資料夾裡沒有 jpg / jpeg / png 圖片")
                return

            for img_path in sorted(image_files):
                print(f"\n處理：{img_path}")
                orig_img, features = load_and_preprocess(img_path, width, height)
                result = runner.classify(features)
                print_result(result)

                # 視覺化：每張圖各自存成 <原檔名>_detected.ext
                if "bounding_boxes" in result["result"]:
                    base = os.path.basename(img_path)
                    name, ext = os.path.splitext(base)
                    out_dir = "results"
                    save_path = os.path.join(out_dir, f"{name}_detected{ext}")
                    draw_bounding_boxes(
                        orig_img,
                        result["result"]["bounding_boxes"],
                        width,
                        height,
                        save_path,
                    )

        # --------------------------------------------------
        # ② 如果第二個參數是「單一圖片檔」，就只處理那一張
        # --------------------------------------------------
        else:
            print(f"載入圖片: {target_path}")
            orig_img, features = load_and_preprocess(target_path, width, height)
            result = runner.classify(features)
            print_result(result)

            if "bounding_boxes" in result["result"]:
                base = os.path.basename(target_path)
                name, ext = os.path.splitext(base)
                out_dir = "results"
                save_path = os.path.join(out_dir, f"{name}_detected{ext}")
                draw_bounding_boxes(
                    orig_img,
                    result["result"]["bounding_boxes"],
                    width,
                    height,
                    save_path,
                )

    finally:
        runner.stop()


if __name__ == "__main__":
    main()
