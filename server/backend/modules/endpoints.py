# system
import asyncio
import os
import uuid
import json

# web
from aiohttp import web
from aiortc import RTCPeerConnection, RTCSessionDescription
from aiortc.contrib.media import MediaRelay

# custom modules
from modules.video_proccessing import VideoTransformTrack

ROOT = os.path.dirname(__file__)
FRONTEND_PATH = os.path.join(ROOT, "../frontend/")
pcs = set()
relay = MediaRelay()

def addEndpoints(app):
    app.on_shutdown.append(on_shutdown)
    app.router.add_get("/", index)
    app.router.add_get("/client.js", javascript)
    app.router.add_get("/style.css", css)
    app.router.add_post("/offer", offer)

async def index(_):
    content = open(os.path.join(FRONTEND_PATH, "index.html"), "r").read()
    return web.Response(content_type="text/html", text=content)


async def javascript(_):
    content = open(os.path.join(FRONTEND_PATH, "client.js"), "r").read()
    return web.Response(content_type="application/javascript", text=content)

async def css(_):
    content = open(os.path.join(FRONTEND_PATH, "style.css"), "r").read()
    return web.Response(content_type="text/css", text=content)


async def offer(request):
    params = await request.json()
    offer = RTCSessionDescription(sdp=params["sdp"], type=params["type"])

    pc = RTCPeerConnection()
    pc_id = "PeerConnection(%s)" % uuid.uuid4()
    pcs.add(pc)

    print(f"new peer connection {pc_id}")

    @pc.on("connectionstatechange")
    async def on_connectionstatechange():
        print("Connection state is ", pc.connectionState)
        if pc.connectionState == "failed":
            await pc.close()
            pcs.discard(pc)

    @pc.on("track")
    def on_track(track):
        print("Track received", track.kind)

        if track.kind == "video":
            pc.addTrack(
                VideoTransformTrack(
                    relay.subscribe(track), transform=params["video_transform"]
                )
            )

        @track.on("ended")
        async def on_ended():
            print("Track ended", track.kind)

    # handle offer
    await pc.setRemoteDescription(offer)

    # send answer
    answer = await pc.createAnswer()

    if answer != None:
        await pc.setLocalDescription(answer)

    return web.Response(
        content_type="application/json",
        text=json.dumps(
            {"sdp": pc.localDescription.sdp, "type": pc.localDescription.type}
        ),
    )

async def on_shutdown(_):
    # close peer connections
    coros = [pc.close() for pc in pcs]
    await asyncio.gather(*coros)
    pcs.clear()
