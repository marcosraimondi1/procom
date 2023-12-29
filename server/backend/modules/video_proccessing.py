from datetime import datetime
import cv2

# import time
from aiortc import MediaStreamTrack
from av import VideoFrame

# custom modules
from modules.globals import *

def getTimeStamp():
    current_datetime = datetime.now()
    timestamp = current_datetime.strftime("%H:%M:%S.%f")
    return timestamp

def addText(img, text, position, scale):
    font = cv2.FONT_HERSHEY_SIMPLEX
    font_thickness = 2
    font_color = (0, 0, 0)
    cv2.putText(img, text, position, font, scale, font_color, font_thickness)
    return img

def addTimeStamp(title, img, position, scale):
    timestamp = getTimeStamp()
    return addText(img, title+timestamp, position, scale)


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

    async def recv(self):

        frame = await self.track.recv()

        img = frame.to_ndarray(format="gray")
        
        img = addTimeStamp("received ", img, (50,50), 0.7)

        # send to process
        BUFFER_TO_PROCESS.write_array(img)

        NEW_FRAME.write_bytes(b'1')

        # get processed
        new_img = PROCESSED_BUFFER.read_array(RESOLUTION)
        new_img = addTimeStamp("sent ", new_img, (50,75), 0.7)

        new_frame = self.rebuildFrame(new_img, frame)

        return new_frame

    def rebuildFrame(self, img, frame):
        # rebuild a VideoFrame, preserving timing information
        new_frame = VideoFrame.from_ndarray(img, format="gray")
        new_frame.pts = frame.pts
        new_frame.time_base = frame.time_base
        return new_frame

