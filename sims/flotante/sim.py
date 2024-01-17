import numpy as np
import cv2
from scipy import signal

# KERNELS
edges = np.array([[-1,-1,-1], [-1,8,-1], [-1,-1,-1]])
gaussian_blur = np.array([[1,2,1], [2,4,2], [1,2,1]]) / 16
sharpen = np.array([[0,-1,0], [-1,5,-1], [0,-1,0]])
identity = np.array([[0,0,0], [0,1,0], [0,0,0]])

kernel = gaussian_blur

# FRAME
car = "./car.jpg"
gioconda = "./gioconda.jpg"
path = car

def convolve_frame(frame, kernel):
    """Convolves a frame with a kernel using zero padding, returns result of same size as input frame"""
    result = signal.convolve2d(frame, kernel, mode='same', boundary='fill', fillvalue=0)

    return np.array(result, dtype=np.uint8)

def load_frame(path):
    """Loads an image"""""
    image = cv2.imread(path)
    return image

def pre_process_frame(image):
    """Pre-processes a frame, change resolution, greyscale"""
    # Convert the image to grayscale
    gray_image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Convert the OpenCV image to a NumPy array
    arr = np.array(gray_image)

    # Resize the frame
    resized = cv2.resize(arr, (200, 200))
    
    return resized

def post_process_frame(frame):
    """Post-processes a frame, change resolution"""
    
    # Resize the frame
    resized = cv2.resize(frame, (480, 640))

    return resized

def display_frame(frame, title="Frame"):
    """Displays a frame"""
    cv2.imshow(title, frame)
    cv2.waitKey(0)

def main():
    """Main function"""
    original = load_frame(path)
    pre_processed = pre_process_frame(original)
    processed = convolve_frame(pre_processed, kernel)
    post_processed = post_process_frame(processed)

    display_frame(pre_processed, "Pre-processed")
    display_frame(processed, "Processed")

if __name__ == "__main__":
    main()
