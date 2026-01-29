"""Launcher for packaging: starts the EasyTrain server in a background thread,
then opens the default browser to the web UI.

This script is meant to be the PyInstaller entry point (launcher.py -> easytrain.exe).
"""
import threading
import time
import webbrowser
import socket
import argparse

# Import the run module which exposes main()
from EasyTrain import run


def wait_for_port(host: str, port: int, timeout: float = 10.0, interval: float = 0.25) -> bool:
    """Wait until TCP port is accepting connections or timeout.

    Returns True if port is ready before timeout, otherwise False.
    """
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with socket.create_connection((host, port), timeout=interval):
                return True
        except OSError:
            time.sleep(interval)
    return False


def main(argv=None):
    parser = argparse.ArgumentParser(description='EasyTrain launcher')
    parser.add_argument('--workfolder', default='.', help='workfolder path (default: current path)')
    parser.add_argument('--host', default='127.0.0.1', help='host to bind/open (default: 127.0.0.1)')
    parser.add_argument('--port', type=int, default=5000, help='port to bind/open (default: 5000)')
    parser.add_argument('--no-browser', action='store_true', help="Don't open the browser automatically")
    args = parser.parse_args(argv)

    # Start the server in a daemon thread so the launcher can open the browser
    def run_server():
        run.get_args = lambda: type('Args', (), {'workfolder': args.workfolder})()
        run.main()

    server_thread = threading.Thread(target=run_server, daemon=True)
    server_thread.start()

    # Wait for port to be ready
    ready = wait_for_port(args.host, args.port, timeout=15.0)
    url = f'http://{args.host}:{args.port}/'
    if ready and not args.no_browser:
        try:
            webbrowser.open(url)
        except Exception:
            print(f"Open your browser and visit {url}")
    elif not ready:
        print(f"Warning: server did not appear on {args.host}:{args.port} after timeout. Check logs.")

    # Wait for server thread to finish (this will block until the server stops)
    try:
        server_thread.join()
    except KeyboardInterrupt:
        print("Shutting down")


if __name__ == '__main__':
    main()
