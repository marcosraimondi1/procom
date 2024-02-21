from modules.globals import *

def process_data_channel(message:str)->None:
    TRANSFORMATION.write_bytes(TRANSFORMATION_OPTIONS[message])
