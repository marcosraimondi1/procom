"""
        En esta aplicacion se muestra como se puede capturar video desde una camara web y mediante una convolucion 2D se puede detectar los bordes 
        de los objetos que se encuentran en el video. La resolucion del video es de 640x480 pixeles.
"""

import cv2
import os 
from scipy import signal
import matplotlib.pyplot as plt
import numpy as np
from skimage.color import rgb2gray
from skimage import io

# Se crea un objeto de tipo VideoCapture para capturar el video de la camara web
cap = cv2.VideoCapture(0)

# Kernel para la convolucion 2D
kernel = np.array([[-1,-1,-1], [-1,8,-1], [-1,-1,-1]])

while(True):
    # Se captura frame por frame
    ret, frame = cap.read() 
    
    if not ret:
        print("Can't receive frame (stream end?). Exiting ...")
        break

    # Se redimensiona el frame a 640x480 pixeles 
    imagen = cv2.resize(frame, (640, 480))
    
    # Se convierte el frame a escala de grises
    frame_gray = cv2.cvtColor(imagen, cv2.COLOR_BGR2GRAY)
    
    
    
    # Se aplica la convolucion 2D
    frame_conv = signal.convolve2d(frame_gray, kernel, boundary='symm', mode='same')
    frame_conv[frame_conv > 255] = 255
    frame_conv[frame_conv < 0] = 0
    
    # Se convierte el frame a 8 bits (uint8)
    frame_conv = frame_conv.astype(np.uint8)
    
    
    # Se muestra el frame original
    cv2.imshow('frame',frame)
    
    # Se muestra el frame con la convolucion 2D
    cv2.imshow('frame_conv',frame_conv)
    
    # Si se presiona la tecla 'Enter' se termina la ejecucion
    if cv2.waitKey(1) & 0xFF == ord('\r'):
        break


"""
    Para llevar el modelo a una FPGA se debe tener en cuenta que
        - la imagen debe ser de 8 bits (uint8)
        - la imagen debe ser en escala de grises
        - la imagen debe ser de 640x480 pixeles
        - el kernel debe ser de 3x3
        - el kernel debe ser de 8 bits ¿signed o unsigned?
        - la imagen de salida debe ser de 8 bits (uint8) en un rango de 0 a 255
        - El resultado de la convolucion debe ser de mas de 8 bits y debemos saturar o truncar el resultado
        - Cuando estemos convolucionando no debemos atender otro frame hasta que terminemos de convolucionar y luego retomamos la captura de frame
        - ¿ Que hacemos con los bordes de la imagen ?
        - Que arquitetura vamos a usar para la FPGA
"""

