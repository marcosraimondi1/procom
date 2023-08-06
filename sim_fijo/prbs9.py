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