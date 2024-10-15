from config import DTrOCRConfig
from data import DTrOCRProcessorOutput
from processor import DTrOCRProcessor 
from model import DTrOCRLMHeadModel

import numpy as np


class Recognizer:
    def __init__(self, device, model_ckpt_path):
        config = DTrOCRConfig()
        self.test_processor = DTrOCRProcessor(config)

        self.recognition_model = DTrOCRLMHeadModel.load_from_checkpoint(
            model_ckpt_path, config=config)

        self.config = config

        self.recognition_model.to(device)

    def generate_prediction(self, image):
        inputs = self.test_processor(
            images=np.array(image),
            texts=self.test_processor.tokeniser.bos_token,
            return_tensors='pt'
        )

        inputs = DTrOCRProcessorOutput(
            pixel_values=inputs.pixel_values.to(
                self.recognition_model.device),

            input_ids=inputs.input_ids.to(
                self.recognition_model.device),

            attention_mask=inputs.attention_mask.to(
                self.recognition_model.device),

            labels=inputs.labels
        )

        model_output = self.recognition_model.generate(
            inputs,
            self.test_processor,
            num_beams=3
        )

        predicted_text = self.test_processor.tokeniser.decode(
            model_output[0], skip_special_tokens=True)

        return predicted_text
