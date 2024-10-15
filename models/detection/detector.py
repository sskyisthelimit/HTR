from ultralytics import YOLO


class Detector:
    def __init__(self, model_pt_path):
        self.model = YOLO(model_pt_path)

    def generate_results(self, np_image,
                         image_size, device, max_det):
        
        return self.yolo_model.predict(
            source=np_image, imgsz=image_size,
            device=device, max_det=max_det
            )
