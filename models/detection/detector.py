from ultralytics import YOLO
import torch


class Detector:
    def __init__(self, model_pt_path, yaml_config_path):
        if not torch.cuda.is_available():
            raise ValueError(
                "CUDA is not available, detector WON'T BE initialized")
        
        try:
            self.model = YOLO(model_pt_path, stream=True)
            self.model.overrides['data'] = yaml_config_path
        except Exception as e:
            print(f"Error loading model: {e}")

    def generate_results(self, np_image, image_size, device,
                         max_det, **kwargs):

        return self.model.predict(
            source=np_image,
            imgsz=image_size,
            device=device,
            max_det=max_det,
            **kwargs
        )
