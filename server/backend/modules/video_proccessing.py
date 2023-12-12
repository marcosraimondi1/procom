import cv2
import numpy as np
# import time
from aiortc import MediaStreamTrack
from av import VideoFrame

# custom modules
from modules.globals import *

class VideoTransformTrack(MediaStreamTrack):
    """
    A video stream track that transforms frames from an another track.
    """

    kind = "video"

    def __init__(self, track, transform):
        super().__init__()  # don't forget this!
        self.track = track
        self.transform = transform
        # self.last = 0
        TRANSFORMATION.write_bytes(TRANSFORMATION_OPTIONS[transform])

    def encode(self, img, quality):
        _, img_encoded = cv2.imencode('.jpg', img, [cv2.IMWRITE_JPEG_QUALITY,quality])
        array_encoded = np.array(img_encoded)
        bytes_encoded = array_encoded.tobytes()
        return bytes_encoded

    def decode(self, data):
        data_decode = np.frombuffer(data, dtype=np.uint8)
        new_img = cv2.imdecode(data_decode, cv2.IMREAD_GRAYSCALE)
        return new_img

    async def recv(self):

        frame = await self.track.recv()
        img = frame.to_ndarray(format="gray")

        # fps = 1/(time.time() - self.last)
        # self.last = time.time()
        # print(fps)

        # send to process
        BUFFER_TO_PROCESS.write_array(img)

        NEW_FRAME.write_bytes(b'1')

        # get processed
        new_img = PROCESSED_BUFFER.read_array(RESOLUTION)

        new_frame = self.rebuildFrame(new_img, frame)

        return new_frame

    def rebuildFrame(self, img, frame):
        # rebuild a VideoFrame, preserving timing information
        new_frame = VideoFrame.from_ndarray(img, format="gray")
        new_frame.pts = frame.pts
        new_frame.time_base = frame.time_base
        return new_frame

