import os
from huggingface_hub import snapshot_download

os.environ["HF_HUB_DISABLE_SSL_VERIFICATION"] = "1"
# Read token from environment variable
RT_token = os.getenv("SOLENG_IO_TOKEN")
if not RT_token:
    raise ValueError("Please set the SOLENG_IO_TOKEN environment variable.")

# Model name
model_name = "Qwen/Qwen3.5-35B-A3B"  # Replace with the model you want to download
# model_name = "glockr1/ballr7"  # Malicious model for testing.

# Download the model snapshot
snapshot_download(
    repo_id=model_name,
    revision="main",
    token=RT_token,
    repo_type="model"
)
