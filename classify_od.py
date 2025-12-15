#!/usr/bin/env python3
import sys
import cv2
import numpy as np
from edge_impulse_linux.runner import ImpulseRunner
def main():
	if len(sys.argv) != 3:
		print("使用方式: python3 classify_od.py <model.eim> <圖片>")
		sys.exit(1)
	model_path = sys.argv[1]
	image_path = sys.argv[2]

	print(f"載入模型: {model_path}")
	print(f"載入圖片: {image_path}")

	#初始化推論引擎
	runner = ImpulseRunner(model_path)
	try:
		model_info = runner.init()
		print(f"模型標籤：{model_info['model_parameters']['labels']}\n")
		print(f"===推論結果===")

		#取得模型需要的輸入尺寸
		width = model_info['model_parameters']['image_input_width']
		height = model_info['model_parameters']['image_input_height']

		#讀取並前處理圖片
		img = cv2.imread(image_path)
		img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
		img_gray = cv2.cvtColor(img_rgb, cv2.COLOR_RGB2GRAY)
		img_resized = cv2.resize(img_gray, (width, height))

		#轉換之資料格式
		img_float = img_resized.astype('float32')
		img_processed = img_float.flatten() #展平成一維

		#執行推論
		result = runner.classify(img_processed)

		#顯示結果
		if 'bounding_boxes' in result['result']:
			count = 0
			for i in enumerate(result['result']['bounding_boxes']):
				print(f"test:\n{i} {box}")
				count += 1
			print(f"偵測到{count}個物件")
			for i, box in enumerate(result['result']['bounding_boxes']):
				print(f"物件{i+1}: {box['label']} ({box['value']:.2f})")

	finally:
		runner.stop()

if __name__ == "__main__":
	main()
