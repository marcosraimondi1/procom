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
        TRANSFORMATION.write_bytes(TRANSFORMATION_OPTIONS[transform])

    async def recv(self):

        frame = await self.track.recv()
        img = frame.to_ndarray(format="gray")


        # send to process
        BUFFER_TO_PROCESS.write_array(img)

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

