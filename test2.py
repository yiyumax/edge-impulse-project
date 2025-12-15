#!/usr/bin/env python3
import sys
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
    return img_bgr, features, img_resized.shape[1], img_resized.shape[0]


def draw_bounding_boxes(orig_img, boxes, model_w, model_h, save_path="result.jpg"):
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

    cv2.imwrite(save_path, orig_img)
    print(f"已將偵測結果存成：{save_path}")


def main():
    if len(sys.argv) != 3:
        print("使用方式: python3 classify_od.py <model.eim> <圖片檔>")
        print("  範例:   python3 classify_od.py ./model.eim test.jpg")
        sys.exit(1)

    model_path = sys.argv[1]
    image_path = sys.argv[2]

    print(f"載入模型: {model_path}")
    print(f"載入圖片: {image_path}")

    runner = ImpulseRunner(model_path)

    try:
        # 初始化模型
        model_info = runner.init()
        labels = model_info["model_parameters"]["labels"]
        model_w = model_info["model_parameters"]["image_input_width"]
        model_h = model_info["model_parameters"]["image_input_height"]
        print(f"模型標籤：{labels}")
        print(f"模型輸入尺寸：{model_w} x {model_h}")

        # 讀圖 + 前處理
        orig_img, features, _, _ = load_and_preprocess(image_path, model_w, model_h)

        # 推論
        result = runner.classify(features)

        # 文字列印結果
        if "bounding_boxes" in result["result"]:
            boxes = result["result"]["bounding_boxes"]
            print(f"偵測到 {len(boxes)} 個物件：")
            for i, box in enumerate(boxes, start=1):
                print(f"物件{i}: {box['label']} ({box['value']:.2f})")
        else:
            print("結果中沒有 bounding_boxes 欄位：")
            print(result)

        # 🔍 視覺化：畫框 + 存成 result.jpg
        if "bounding_boxes" in result["result"]:
            draw_bounding_boxes(
                orig_img,
                result["result"]["bounding_boxes"],
                model_w,
                model_h,
                "results/result.jpg",
            )

    finally:
        runner.stop()


if __name__ == "__main__":
    main()
