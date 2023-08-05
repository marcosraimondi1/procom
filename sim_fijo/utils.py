from tool._fixedInt import *
import numpy as np

def fixArray(NB, NBF, array, signedMode='S', roundMode='trunc', saturateMode='saturate'):
    """
    Transforma el arreglo a un arreglo de fixedInt
    """
    return arrayFixedInt(NB, NBF, array, signedMode, roundMode, saturateMode)

def floatArray(array):
    """
    Transforma el arreglo de fixedInt a un arreglo de float
    Arguments:
        - array: Arreglo de fixedInt
    Returns:
        - arreglo de float
    """
    return np.array([ e.fValue for e in array ])


