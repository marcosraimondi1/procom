import numpy as np
from utils import fixArray, floatArray
from tool._fixedInt import *

a = np.array([0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,0.10])
b = np.array([0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,0.10])

a = fixArray(8, 7, a, 'S', 'round', 'saturate')
b = fixArray(8, 7, b, 'S', 'round', 'saturate')

c = np.convolve(a,b)

print(c)

c = np.convolve(floatArray(a),floatArray(b))

print(c)