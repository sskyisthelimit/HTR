from typing import Optional, Tuple, List


class DTrOCRConfig:
    def __init__(
        self,
        t5_model: str = 't5-small',
        vocab_size: Optional[int] = 32128,
        max_position_embeddings: Optional[int] = 256,
        hidden_size: Optional[int] = 512,
        num_hidden_layers: Optional[int] = 12,
        feed_forward_proj: str = "gated-gelu",
        num_attention_heads: Optional[int] = 12,
        patch_size: Tuple[int] = (4, 8),  # (h, w)
        image_size: Tuple[int] = (32, 128),  # (h, w)
        num_channels: Optional[int] = 3,
        resid_pdrop: Optional[float] = 0.1,
        embd_pdrop: Optional[float] = 0.1,
        attn_pdrop: Optional[float] = 0.1,
        layer_norm_epsilon: Optional[float] = 1e-5,
        attn_implementation: str = 'flash_attention_2'
    ):

        self.hidden_size = hidden_size
        self.num_hidden_layers = num_hidden_layers
        self.num_attention_heads = num_attention_heads
        self.patch_size = patch_size
        self.image_size = image_size
        self.num_channels = num_channels
        self.vocab_size = vocab_size
        self.max_position_embeddings = max_position_embeddings
        self.resid_pdrop = resid_pdrop
        self.embd_pdrop = embd_pdrop
        self.attn_pdrop = attn_pdrop
        self.layer_norm_epsilon = layer_norm_epsilon
        self._attn_implementation = attn_implementation

        # T5 config values
        self.t5_model = t5_model
        self.feed_forward_proj = feed_forward_proj
