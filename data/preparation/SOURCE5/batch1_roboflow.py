import os
from roboflow import Roboflow
from dotenv import load_dotenv

load_dotenv()

env = os.environ

rf = Roboflow(api_key=env.get('ROBOFLOW_KEY'))
workspace = rf.workspace()

workspace.upload_dataset(
    env.get('IMG_DIR'),
    env.get('PROJECT_ID'),
    num_workers=10,
    project_license="MIT",
    project_type="object-detection",
    batch_name=None,
    num_retries=0
)