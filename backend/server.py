"""Run: python backend/server.py [--host 0.0.0.0] [--port 8000]."""
import argparse
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

DATA_FILE = Path(__file__).with_name('drills.json')


class Handler(BaseHTTPRequestHandler):
    def respond(self, status, data):
        body = json.dumps(data).encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = urlsplit(self.path).path
        if path == '/health':
            self.respond(200, {'status': 'ok'})
        elif path == '/api/drills':
            try:
                drills = json.loads(DATA_FILE.read_text(encoding='utf-8'))
                if not isinstance(drills, list):
                    raise ValueError('Expected list')
                self.respond(200, drills)
            except (OSError, ValueError):
                self.respond(500, {'error': 'Could not load drills'})
        else:
            self.respond(404, {'error': 'Not found'})

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--host', default='127.0.0.1')
    parser.add_argument('--port', type=int, default=8000)
    args = parser.parse_args()
    server = ThreadingHTTPServer((args.host, args.port), Handler)
    print(f'Drills API: http://{args.host}:{args.port}/api/drills', flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
