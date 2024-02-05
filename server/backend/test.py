from modules.ethernet.eth_process import preprocess, postprocess
import numpy as np
import cv2

def load_frame(path):
    """Loads an image"""""
    image = cv2.imread(path)

    gray_image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Convert the OpenCV image to a NumPy array
    arr = np.array(gray_image)

    resized = cv2.resize(arr, (640, 480))
    return resized

def display_frame(frame, title="Frame"):
    """Displays a frame"""
    cv2.imshow(title, frame)
    cv2.waitKey(0)

print("Loading image...")
img = load_frame("")
print("preprocessing")
preprocessed = preprocess(img)
print("postprocessing")
postprocessed = postprocess(preprocessed)
print("displaying")

print(postprocessed.shape)
print(img.shape)

