import numpy as np


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
    shift_register = np.array(binary_to_list(seed))

    while True:
        # primero shifteo y despues saco la salida con el registro actualizado

        # el feedback es el XOR de los bits 8 y 4
        feedback = shift_register[8] ^ shift_register[4]

        # hago el shifteo y agrego el feedback en el bit 0
        shift_register = np.roll(shift_register, 1)

        shift_register[0] = feedback

        # la salida es el bit 8 del shift register
        output_bit = shift_register[8]

        yield output_bit


def binary_to_list(binary_number, length=9):
    binary_string = bin(binary_number)[2:]  # Convert to binary and remove '0b' prefix
    binary_list = [int(bit) for bit in binary_string]
    if len(binary_list) < length:
        binary_list = [0] * (length - len(binary_list)) + binary_list
    return binary_list


# seed = 0x1AA
# prbs9_gen = prbs9(seed)

# for i in range(1022):
#     print("1'b" + str(next(prbs9_gen)), end=",")
