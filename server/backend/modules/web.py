# system
import ssl

# web
from aiohttp import web

# custom modules
from modules.endpoints import addEndpoints

def runApp(args):
    if args.cert_file:
        ssl_context = ssl.SSLContext()
        ssl_context.load_cert_chain(args.cert_file, args.key_file)
    else:
        ssl_context = None

    app = web.Application()

    addEndpoints(app)

    web.run_app(
        app, access_log=None, host=args.host, port=args.port, ssl_context=ssl_context
    )
