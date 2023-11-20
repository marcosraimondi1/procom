# system
import argparse
import atexit
import signal

# multiprocessing
import multiprocessing as mp
from multiprocessing import Process

# Custom Modules
import modules.globals as globals
from modules.web import runApp
from modules.eth_process import ethInterface
from modules.ipc import unlink_mem, unlink_sem


def parseArguments():
    parser = argparse.ArgumentParser(
        description="WebRTC video processing"
    )
    parser.add_argument("--cert-file", help="SSL certificate file (for HTTPS)")
    parser.add_argument("--key-file", help="SSL key file (for HTTPS)")
    parser.add_argument(
        "--host", default="0.0.0.0", help="Host for HTTP server (default: 0.0.0.0)"
    )
    parser.add_argument(
        "--port", type=int, default=8080, help="Port for HTTP server (default: 8080)"
    )
    parser.add_argument("--verbose", "-v", action="count")
    args = parser.parse_args()

    return args

if __name__ == "__main__":
    # define memory keys and sizes

    mp.set_start_method('fork')
    p = Process(target=ethInterface, daemon=True)
    p.start()
    args = parseArguments();
    runApp(args)


def cleanup():
    unlink_mem(globals.MEM_1)
    unlink_mem(globals.MEM_2)
    unlink_sem(globals.SEM_1)
    unlink_sem(globals.SEM_2)

def sigint_handler(signum, frame):
    exit(1)

atexit.register(cleanup)
signal.signal(signal.SIGINT, sigint_handler)
