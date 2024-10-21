from fastapi import FastAPI, File, UploadFile
from PIL import Image
import numpy as np
from io import BytesIO
from models.detection.detector import Detector
from models.recognition.recognizer import Recognizer
from scripts.utils.utils import (sort_lines_by_top,
                                 sort_words_by_left,
                                 intersection_area)

# TODO: tests, etc.

app = FastAPI()


@app.on_event("startup")
async def startup_event():
    global line_detector, word_detector, recognizer
    line_detector = Detector("models/detection/weights/lines.pt", 
                             "models/detection/weights/lines_config.yaml")
    word_detector = Detector("models/detection/weights/words.pt", 
                             "models/detection/weights/words_config.yaml")
    recognizer = Recognizer('cuda:0',
                            "models/recognition/weights/model.ckpt")


@app.post("/predict/")
async def predict(file: UploadFile = File(...)):
    image_data = await file.read()
    img = Image.open(BytesIO(image_data)).convert('RGB')
    img_np = np.array(img)

    lines_results = line_detector.generate_results(
        np_image=img_np, image_size=946, device='cuda:0', max_det=100, iou=0.6
    )[0]

    words_results = word_detector.generate_results(
        np_image=img_np, image_size=946, device='cuda:0', max_det=500, iou=0.5
    )[0]

    sorted_lines = sort_lines_by_top(lines_results.boxes)
    mapped_boxes = {}

    for word_box in words_results.boxes:
        best_line_idx = max(
            range(len(sorted_lines)),
            key=lambda line_idx: intersection_area(
                word_box.xyxy[0].cpu().numpy(),
                sorted_lines[line_idx].xyxy[0].cpu().numpy()
            )
        )
        line_key = f"line_{best_line_idx}"
        if line_key not in mapped_boxes:
            mapped_boxes[line_key] = []
        mapped_boxes[line_key].append(word_box)

    sorted_boxes = []
    for line_idx in range(len(mapped_boxes)):
        line_key = f"line_{line_idx}"
        if line_key in mapped_boxes:
            sorted_boxes += sort_words_by_left(mapped_boxes[line_key])

    async def generate_responses():
        for word_box in sorted_boxes:
            x1, y1, x2, y2 = map(int, word_box.xyxy[0].cpu().numpy())
            word_image_pil = Image.fromarray(img_np[y1:y2, x1:x2])
            predicted_text = recognizer.generate_prediction(word_image_pil)
            yield {"predicted_word": predicted_text}

    return generate_responses()
