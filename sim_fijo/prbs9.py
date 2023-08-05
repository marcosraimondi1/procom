def prbs9(seed):
    """
    Genera una secuencia de bits PRBS9
    Arguments:
        - seed: semilla para el generador de numeros aleatorios
    Returns:
        - un generador de secuencia de bits PRBS9
    """

    if seed == 0:
        raise "La semilla no puede ser 0"

    # estado inicial del shift register = seed
    shift_register = seed & 0b111111111

    while True:
        # la salida es el bit 0 del shift register
        output_bit = shift_register & 1  # AND bit a bit

        # el feedback es el XOR de los bits 8 y 4
        feedback = ((shift_register >> 8) & 1) ^ ((shift_register >> 4) & 1)

        # Shift the register one position to the right and set the feedback bit
        shift_register = ((shift_register << 1) | feedback) & 0b111111111

        yield output_bit

def generar_prbs9(seed, N):
    """
    Genera una secuencia de bits PRBS9
    Arguments:
        - seed: semilla para el generador de numeros aleatorios
        - N: cantidad de bits a generar
    Returns:
        - secuencia de bits PRBS9
    """
    # Objeto Generador
    prbs_generator = prbs9(seed)

    # Generar la secuencia de Nbits
    prbs_sequence = [next(prbs_generator) for _ in range(N)]

    return prbs_sequence

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


def slicer(muestras):
    """
    Slicer estima los simbolos a partir de los valores detectados
    Arguments:
        - muestras: senal muestreada 
    Returns:
        - symbols_estimados: simbolos estimados
    """
    # Generar la secuencia de bits
    symbols_estimados = [1 if symbol > 0 else -1 for symbol in muestras]

    return symbols_estimados