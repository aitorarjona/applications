import time
import builtins
import torch.optim
import torch.nn.parallel
import os
import uuid
from torch import save, load
from torch.nn import functional as F
from torchvision.models import resnet50


from utils import extract_frames
from models import load_transform, load_categories, modify_resnets

# import multiprocessing as mp
import lithops.multiprocessing as mp
from lithops.storage.cloud_proxy import os, open

weights_location = '/tmp/model_weights'

INPUT_DATA_DIR = os.path.abspath('/momentsintime/input_data')

video_locations = [os.path.join(INPUT_DATA_DIR, name) for name in os.listdir(INPUT_DATA_DIR)]

video_locations = [video_locations[0]]

print(video_locations)

NUM_SEGMENTS = 64

# Get dataset categories
categories = load_categories()

# Load the video frame transform
transform = load_transform()

def load_model(model_location):
    # Load pretrained resnet50 model
    global model
    model = resnet50(num_classes=339)
    with open(model_location, 'rb') as weight_file: # Load checkpoint
        checkpoint = torch.load(weight_file, map_location=lambda storage, loc: storage)  # Load on cpu
    state_dict = {str.replace(str(k), 'module.', ''): v for k, v in checkpoint['state_dict'].items()}
    model.load_state_dict(state_dict)
    model = modify_resnets(model)
    model.eval()


def predict_video(video_location):
    global model

    # Obtain video frames
    frames = extract_frames(video_location, NUM_SEGMENTS)

    # Prepare input tensor [num_frames, 3, 224, 224]
    input_v = torch.stack([transform(frame) for frame in frames])

    # Make video prediction
    start = time.time()
    with torch.no_grad():
        logits = model(input_v)
        h_x = F.softmax(logits, 1).mean(dim=0)
        probs, idx = h_x.sort(0, True)

    # Output the prediction
    result = {
        'key': video_location,
        'prediction': (idx[0], round(float(probs[0]), 5)),
        'category': categories[idx[0]],
        'time_elapsed': time.time() - start
    }

    return result


# for vid_loc in video_locations:
#     result = predict_video(vid_loc)
#     print(result)

with mp.Pool(initializer=load_model, initargs=(weights_location,), processes=1) as pool:
    res = pool.map(predict_video, video_locations)

print(res)






