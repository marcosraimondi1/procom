// get DOM elements
// UI
let startButton        = document.getElementById('start');
let stopButton         = document.getElementById('stop');
let transformInput     = document.getElementById('video-transform');
let resolutionInput    = document.getElementById('video-resolution');
// video
let videoProcessed     = document.getElementById('video-processed');
let videoOriginal      = document.getElementById('video-original');
let media              = document.getElementById('media');
// status
let iceConnectionLog   = document.getElementById('ice-connection-state');
let iceGatheringLog    = document.getElementById('ice-gathering-state');
let signalingLog       = document.getElementById('signaling-state');

// peer connection
var pc = null;

function createPeerConnection() {
    const servers = {
        sdpSemantics: 'unified-plan',
        iceServers: [
            {
                urls: ['stun:stun1.l.google.com:19302', 'stun:stun2.l.google.com:19302'],
            },
        ],
        iceCandidatePoolSize: 10,
    };
    pc = new RTCPeerConnection(servers);

    // register some listeners to help debugging
    pc.addEventListener('icegatheringstatechange', function() {
        iceGatheringLog.textContent += ' -> ' + pc.iceGatheringState;
    }, false);
    iceGatheringLog.textContent = pc.iceGatheringState;

    pc.addEventListener('iceconnectionstatechange', function() {
        iceConnectionLog.textContent += ' -> ' + pc.iceConnectionState;
    }, false);
    iceConnectionLog.textContent = pc.iceConnectionState;

    pc.addEventListener('signalingstatechange', function() {
        signalingLog.textContent += ' -> ' + pc.signalingState;
    }, false);
    signalingLog.textContent = pc.signalingState;

    // connect video
    pc.addEventListener('track', function(evt) {
        if (evt.track.kind == 'video')
            videoProcessed.srcObject = evt.streams[0];
    });

    return pc;
}

function negotiate() {
    return pc.createOffer().then(function(offer) {
        return pc.setLocalDescription(offer);
    }).then(function() {
        // wait for ICE gathering to complete
        return new Promise(function(resolve) {
            if (pc.iceGatheringState === 'complete') {
                resolve();
            } else {
                function checkState() {
                    if (pc.iceGatheringState === 'complete') {
                        pc.removeEventListener('icegatheringstatechange', checkState);
                        resolve();
                    }
                }
                pc.addEventListener('icegatheringstatechange', checkState);
            }
        });
    }).then(function() {
        var offer = pc.localDescription;

        return fetch('/offer', {
            body: JSON.stringify({
                sdp: offer.sdp,
                type: offer.type,
                video_transform: transformInput.value
            }),
            headers: {
                'Content-Type': 'application/json'
            },
            method: 'POST'
        });
    }).then(function(response) {
        return response.json();
    }).then(function(answer) {
        return pc.setRemoteDescription(answer);
    }).catch(function(e) {
        alert(e);
    });
}

function start() {
    startButton.style.display = 'none';
    media.style.display = 'block';
    stopButton.style.display = 'inline-block';
    resolutionInput.disabled = true;
    transformInput.disabled = true;

    pc = createPeerConnection();

    var constraints = {
        audio: false,
        video: true
    };

    var resolution = resolutionInput.value;
    if (resolution) {
        resolution = resolution.split('x');
        constraints.video = {
            width: parseInt(resolution[0], 0),
            height: parseInt(resolution[1], 0)
        };
    }
    
    navigator.mediaDevices.getUserMedia(constraints).then(function(stream) {

        // show original video
        videoOriginal.srcObject = stream;

        // stream to peer connection
        stream.getTracks().forEach(function(track) {
            pc.addTrack(track, stream);
        });

        return negotiate();
    
    }, function(err) {
        alert('Could not acquire media: ' + err);
    });

}

function stop() {
    stopButton.style.display = 'none';
    startButton.style.display = 'block';
    media.style.display = 'none';
    resolutionInput.disabled = false;
    transformInput.disabled = false;

    // close transceivers
    if (pc.getTransceivers) {
        pc.getTransceivers().forEach(function(transceiver) {
            if (transceiver.stop) {
                transceiver.stop();
            }
        });
    }

    // close local audio / video
    pc.getSenders().forEach(function(sender) {
        sender.track.stop();
    });

    // close peer connection
    setTimeout(function() {
        pc.close();
    }, 500);
}
