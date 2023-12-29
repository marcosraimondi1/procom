import os
from scipy import signal
import matplotlib.pyplot as plt
import numpy as np
from skimage.color import rgb2gray
from skimage import ioi


def convolve2d(image, kernel):
    m, n = kernel.shape
    y, x = image.shape

    output = np.zeros_like(image)

    pad_height = m // 2
    pad_width  = n // 2
    padded_image = np.pad(image, ((pad_height, pad_height), (pad_width, pad_width)))

    for i in range(y):
        for j in range(x):
            output[i, j] = (kernel * padded_image[i:i+m, j:j+n]).sum()

    return output


# Kernel para la deteccion de bordes
kernel = np.array([[-1, -1, -1],
                   [-1,  8, -1],
                   [-1, -1, -1]])

# Cargamos la imagen 
filename = os.path.join(os.path.dirname(__file__), 'zebra.jpg')
imagen = io.imread(filename)

# Pasamos la imagen a escala de grises
frame_gray = rgb2gray(imagen)

# Se aplica la convolucion 2D
frame_conv = convolve2d(frame_gray, kernel)
frame_conv[frame_conv > 255] = 255
frame_conv[frame_conv < 0] = 0

# Se convierte el frame a 8 bits (uint8)
#frame_conv = frame_conv.astype(np.uint8)

# Se muestra el frame original
plt.subplot(1, 2, 1)
plt.imshow(imagen, cmap='gray')
plt.title('Original')
plt.axis('off')

# Se muestra el frame con la convolucion 2D
plt.subplot(1, 2, 2)
plt.imshow(frame_conv, cmap='gray')
plt.title('Convolucionada')
plt.axis('off')

plt.show()
