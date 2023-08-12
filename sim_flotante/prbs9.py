import numpy as np

def generar_prbs9(seed, N):
    """
    Genera una secuencia de bits con distribucion uniforne
    Arguments:
        - seed: semilla para el generador de numeros aleatorios
        - N: cantidad de bits a generar
    Returns:
        - secuencia de bits
    """
    np.random.seed(seed)

    # Generar la secuencia de Nbits
    bits = np.random.randint(0, 2, N)

    return bits


def generar_bpsk(bits):
    """
    Genera una secuencia de simbolos BPSK
    Arguments:
        - bits: bits a codificar
    Returns:
        - secuencia de simbolos BPSK
    """
    # Generar la secuencia de simbolos BPSK
    bpsk_sequence = [1 if bit == 1 else -1 for bit in bits]

    return bpsk_sequence

def deco_bpsk(symbols):
    """
    Decodifica una secuencia de simbolos BPSK
    Arguments:
        - symbols: simbolos a decodificar
    Returns:
        - secuencia de bits
    """
    # Generar la secuencia de bits
    bits = [1 if symbol > 0 else 0 for symbol in symbols]

    return bits