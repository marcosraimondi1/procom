import time
import socket

# custom modules
from modules.globals import MEM_1, MEM_2, HOST, PORT, RESOLUTION
from modules.transformations import *

class UdpSocketClient:
    MAX_PACKET_SIZE = 61440
    RECEIVE_TIMEOUT_S = 0.05  

    def __init__(self):
        self.client = socket.socket(socket.AF_INET, socket.SOCK_DGRAM) 
        self.client.settimeout(self.RECEIVE_TIMEOUT_S)

    def chunk_bytes(self, bytes):
        chunks = [bytes[i:i + self.MAX_PACKET_SIZE] for i in range(0, len(bytes), self.MAX_PACKET_SIZE)]
        return chunks

    def send_bytes(self, data, address):
        chunks = self.chunk_bytes(data)
        for chunk in chunks:
            try:
                self.client.sendto(chunk, address)
            except Exception as e:
                print("Failed sending")
                print(e)
                break

    def receive_bytes(self, size):
        address = ('', 0)
        data = b''
        try:
            while len(data) < size:
                data_bytes, address = self.client.recvfrom(size-len(data))
                data += data_bytes

        except TimeoutError:
            pass

        except Exception as e:
            print("Failed receiving")
            print(e)

        return data, address

IMG_SIZE = RESOLUTION[0]*RESOLUTION[1]

def ethInterface():
    print("Subprocess Started ...")

    udp = UdpSocketClient()

    dropped_frames = 0
    with udp.client:

        while (True):
            print(f"dropped {dropped_frames}")
            # get image to process
            bytes = MEM_2.read_bytes()

            # send image to socket
            udp.send_bytes(bytes, (HOST,PORT))

            # get image from socket
            data, _ = udp.receive_bytes(IMG_SIZE)

            if (len(data) != IMG_SIZE):
                dropped_frames += 1
                continue

            # send processed image
            MEM_1.write_bytes(data)

            time.sleep(.002)



