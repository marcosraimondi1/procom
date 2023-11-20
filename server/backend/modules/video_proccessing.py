from aiortc import MediaStreamTrack
from av import VideoFrame
import numpy as np

# custom modules
from modules.globals import *
from modules.ipc import read_from_memory, write_to_memory

class VideoTransformTrack(MediaStreamTrack):
    """
    A video stream track that transforms frames from an another track.
    """

    kind = "video"

    def __init__(self, track, transform):
        super().__init__()  # don't forget this!
        self.track = track
        self.transform = transform

    async def recv(self):

        frame = await self.track.recv()
        img = frame.to_ndarray(format="gray")

        # send to process
        with SEM_2:
            write_to_memory(MEM_2, img.tobytes())

        # get processed
        with SEM_1:
            bytes = read_from_memory(MEM_1)

        new_img = np.frombuffer(bytes, dtype=np.uint8).reshape(RESOLUTION)

        new_frame = self.rebuildFrame(new_img, frame)

        return new_frame

    def rebuildFrame(self, img, frame):
        # rebuild a VideoFrame, preserving timing information
        new_frame = VideoFrame.from_ndarray(img, format="gray")
        new_frame.pts = frame.pts
        new_frame.time_base = frame.time_base
        return new_frame

