import numpy as np
import cv2
from tool._fixedInt import *

# KERNELS
edges = np.array([[-1,-1,-1], [-1,8,-1], [-1,-1,-1]]) /8
gaussian_blur = np.array([[1,2,1], [2,4,2], [1,2,1]]) /16
sharpen = np.array([[0,-1,0], [-1,5,-1], [0,-1,0]])   /5
identity = np.array([[0,0,0], [0,1,0], [0,0,0]])

KERNELS = {
    "edges": edges,
    "gaussian_blur": gaussian_blur,
    "sharpen": sharpen,
    "identity": identity
 }

# IMAGE OPENCV FUNCTIONS
def load_frame(path):
    """Loads an image"""""
    image = cv2.imread(path)
    return image

def pre_process_frame(image):
    """Pre-processes a frame, change resolution, greyscale"""
    frame_width  = 200
    frame_height = 200

    # Convert the image to grayscale
    gray_image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Convert the OpenCV image to a NumPy array
    arr = np.array(gray_image)

    # Resize the frame
    resized = cv2.resize(arr, (frame_width, frame_height))
    
    return resized

def post_process_frame(frame, resolution=(640, 480)):
    """Post-processes a frame, change resolution"""
    
    # Resize the frame
    resized = cv2.resize(frame, resolution[::-1])

    return resized

def display_frame(frame, title="Frame"):
    """Displays a frame"""
    cv2.imshow(title, frame)
    cv2.waitKey(0)
