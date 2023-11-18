import cv2
import time

def edgeDetection(img):
    # perform edge detection
    img = cv2.Canny(img, 100, 200)

    return img

def rotate(img):
    # rotate image
    rows, cols = img.shape
    M = cv2.getRotationMatrix2D((cols / 2, rows / 2), time.time() * 45, 1)
    img = cv2.warpAffine(img, M, (cols, rows))

    return img
