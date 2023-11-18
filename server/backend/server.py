# system
import argparse

# multiprocessing
import multiprocessing as mp
from multiprocessing import Process

# Custom Modules
from web import runApp
from eth_process import ethInterface


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
