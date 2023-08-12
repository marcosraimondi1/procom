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
        # primero shifteo y despues saco la salida con el registro actualizado

        # el feedback es el XOR de los bits 8 y 4
        feedback = ((shift_register >> 8) & 1) ^ ((shift_register >> 4) & 1)

        # hago el shifteo y agrego el feedback en el bit 0, despues hago and para que quede de 9 bits
        shift_register = ((shift_register << 1) | feedback) & 0b111111111

        # la salida es el bit 8 del shift register
        output_bit = shift_register >> 8
        
        yield output_bit