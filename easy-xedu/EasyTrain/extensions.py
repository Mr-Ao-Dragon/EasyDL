from flask import Flask
from flask_cors import CORS
import os
import sys

from .apis.mmedu import mmedu_bp
from .apis.basenn import basenn_bp
from .apis.baseml import baseml_bp

app = Flask(__name__, static_url_path='/static')
app.config['JSON_AS_ASCII'] = False
CORS(app)

# Try to initialize real SocketIO, but if that fails (common in frozen builds
# where async backends may be unavailable), fall back to a dummy no-op object
# so the HTTP UI still works.
try:
    from flask_socketio import SocketIO
    # Let SocketIO choose the best async_mode; if this raises or later fails,
    # we catch below and provide a dummy.
    try:
        socketio = SocketIO(app, cors_allowed_origins="*")
    except Exception:
        # Re-raise to be caught by outer except and fall back to Dummy
        raise
except Exception:
    # Minimal dummy replacement for SocketIO used in frozen builds where
    # websocket/async backends may not be present. This supports the decorator
    # usage @socketio.on(...) and a no-op emit.
    class DummySocketIO:
        def on(self, *args, **kwargs):
            def decorator(f):
                return f
            return decorator

        def emit(self, *args, **kwargs):
            return None

        def run(self, *args, **kwargs):
            # In case some code tries to call socketio.run(app), delegate to
            # Flask's app.run to at least start an HTTP server.
            return app.run(*args, **kwargs)

    socketio = DummySocketIO()


app.register_blueprint(mmedu_bp)
app.register_blueprint(baseml_bp)
app.register_blueprint(basenn_bp)


def back2pwd(pwd, level):
    """
    返回上`level`数级目录的绝对路径
    """
    for i in range(level + 1):
        pwd = os.path.abspath(os.path.dirname(pwd))
    return pwd