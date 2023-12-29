import numpy as np
import cv2

def getImage(size, path):   
    img = cv2.imread(path)

    # Se convierte el frame a escala de grises
    frame_gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # Se redimensiona el frame
    out = cv2.resize(frame_gray, size)
 
    return out


def showImage(image):
    cv2.imshow('image',image)
    cv2.waitKey(5000)

# Kernel para la convolucion 2D
kernel = np.array([[-1,-1,-1], [-1,8,-1], [-1,-1,-1]])

# convolucion2d(imagen,kernel)