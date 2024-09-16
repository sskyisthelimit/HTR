from transformers import T5TokenizerFast, AutoImageProcessor

from PIL import Image
from typing import List, Union
from config import DTrOCRConfig
from data import DTrOCRProcessorOutput


class DTrOCRProcessor:
    def __init__(self, config: DTrOCRConfig, add_bos_token: bool = False,
                 add_eos_token: bool = False):
        self.vit_processor = AutoImageProcessor.from_pretrained(
            config.vit_hf_model,
            size={
                "height": config.image_size[0],
                'width': config.image_size[1]
            },
            use_fast=True
        )

        self.tokenizer = T5TokenizerFast.from_pretrained(
            config.t5_model,
            model_max_length=config.max_position_embeddings - int(
                (config.image_size[0] / config.patch_size[0]) *
                (config.image_size[1] / config.patch_size[1])
            )
        )

        self.add_bos_token = add_bos_token
        self.add_eos_token = add_eos_token

        self.tokenizer.pad_token = self.tokenizer.eos_token

    def __call__(
        self,
        images: Union[Image.Image, List[Image.Image]] = None,
        texts: Union[str, List[str]] = None,
        return_labels: bool = False,
        input_data_format: str = 'channels_last',
        padding: Union[bool, str] = False,
        *args,
        **kwargs
    ) -> DTrOCRProcessorOutput:
        text_inputs = self.tokeniser(
            texts, padding=padding, add_special_tokens=True,
            *args, **kwargs
        ) if texts is not None else None

        image_inputs = self.vit_processor(
            images, return_tensors="pt", input_data_format=input_data_format,
            *args, **kwargs
        ) if images is not None else None

        return DTrOCRProcessorOutput(
            pixel_values=image_inputs["pixel_values"] 
            if images is not None else None,
            
            input_ids=text_inputs['input_ids']
            if texts is not None else None,
            
            attention_mask=text_inputs['attention_mask']
            if texts is not None else None,
            
            labels=text_inputs['input_ids']
            if texts is not None and return_labels else None
        )
