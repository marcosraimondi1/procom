from tool._fixedInt import *
import numpy as np

def fixArray(NB, NBF, array, signedMode='S', roundMode='trunc', saturateMode='saturate'):
    """
    Cuantiza un arreglo flotante con la librearia fixedInt y retorna el arreglo cuantizado en flotante.
    """
    fixedIntArray = arrayFixedInt(NB, NBF, array, signedMode, roundMode, saturateMode)
    return np.array([ e.fValue for e in fixedIntArray ])

def fixNumber(NB, NBF, number, signedMode='S', roundMode='trunc', saturateMode='saturate'):
    """
    Cuantiza un numero flotante con la librearia fixedInt y retorna el numero cuantizado en flotante.
    """
    fixedIntNumber = DeFixedInt(NB,NBF,signedMode,roundMode,saturateMode)
    fixedIntNumber.value = number
    return fixedIntNumber.fValue