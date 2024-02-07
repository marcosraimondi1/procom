import socket
from typing import Tuple

class SocketClient:
    def __init__(self):
        pass

    def send_bytes(self, data:bytes, address:Tuple)->None:
        return

    def receive_bytes(self, size:int)->Tuple:
        return tuple()

class TcpSocketClient(SocketClient):
    def __init__(self, address):
        self.client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.address = address

        if (address[0] == ''):
            self.server = self.client
            with self.server:
                self.server.bind(address)
                self.server.listen(1)
                self.client, self.address = self.server.accept()
            
        else:
            try:
                self.client.connect(address)
            except Exception as e:
                print("Failed connecting")
                print(e)


    def send_bytes(self, data, address):
        try:
            self.client.sendall(data)
        except Exception as e:
            print("Failed sending")
            print(e)

    def receive_bytes(self, size):
        data = b''
        try:
            data = b''
            while len(data) < size:
                data += self.client.recv(size-len(data))
        except Exception as e:
            print("Failed receiving")
            print(e)
        return data, self.address


class UdpSocketClient(SocketClient):
    MAX_PACKET_SIZE = 61444
    RECEIVE_TIMEOUT_S = 0.1

    def __init__(self):
        self.client = socket.socket(socket.AF_INET, socket.SOCK_DGRAM) 

    def send_bytes(self, data, address):
        try:
            self.client.sendto(data, address)
        except Exception as e:
            print("Failed sending")
            print(e)

    def receive_bytes(self, size):
        address = ('', 0)
        frame = b''

        try:
            frame, address = self.client.recvfrom(size)
        except TimeoutError:
            pass
        except Exception as e:
            print("Failed receiving")
            print(e)

        return frame, address
