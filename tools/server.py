"""REC-OFF-AIR 統合ツールサーバー
全ツールが dialogue/*.json を直接読み書きする共通バックエンド

Usage: python tools/server.py
URL:   http://localhost:8090/
"""
import http.server, json, os, glob, urllib.parse

PORT = 8090
TOOLS_ROOT = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.normpath(os.path.join(TOOLS_ROOT, ".."))
DIALOGUE = os.path.join(PROJECT_ROOT, "dialogue")

# キャッシュ不要ヘッダー
NO_CACHE = [
    ("Cache-Control", "no-store, no-cache, must-revalidate"),
    ("Pragma", "no-cache"),
]

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=TOOLS_ROOT, **kw)

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        qs = urllib.parse.parse_qs(parsed.query)

        # === API: ファイル一覧 ===
        if path == "/api/list":
            files = sorted([
                os.path.basename(f)
                for f in glob.glob(os.path.join(DIALOGUE, "*.json"))
            ])
            self._json(200, {"files": files})
            return

        # === API: ファイル読み込み ===
        if path == "/api/load":
            name = qs.get("name", [""])[0]
            if not name.endswith(".json") or "/" in name or "\\" in name:
                self._json(400, {"error": "invalid filename"})
                return
            fpath = os.path.join(DIALOGUE, name)
            if not os.path.isfile(fpath):
                self._json(404, {"error": "file not found"})
                return
            with open(fpath, "r", encoding="utf-8") as f:
                data = json.load(f)
            self._json(200, data)
            return

        # === ルート → ダッシュボード ===
        if path == "/":
            self._redirect("/index.html")
            return

        # === 静的ファイル配信（キャッシュ無効） ===
        if path.endswith((".html", ".js", ".css")):
            file_path = os.path.join(TOOLS_ROOT, path.lstrip("/").replace("/", os.sep))
            if os.path.isfile(file_path):
                ct = "text/html" if path.endswith(".html") else \
                     "application/javascript" if path.endswith(".js") else "text/css"
                self.send_response(200)
                self.send_header("Content-Type", f"{ct}; charset=utf-8")
                for h, v in NO_CACHE:
                    self.send_header(h, v)
                self.end_headers()
                with open(file_path, "rb") as f:
                    self.wfile.write(f.read())
                return

        super().do_GET()

    def do_POST(self):
        if self.path == "/api/save":
            length = int(self.headers.get("Content-Length", 0))
            body = json.loads(self.rfile.read(length))
            name = os.path.basename(body.get("filename", ""))
            if not name.endswith(".json"):
                self._json(400, {"error": "invalid filename"})
                return
            content = body.get("content", "")
            fpath = os.path.join(DIALOGUE, name)
            with open(fpath, "w", encoding="utf-8") as f:
                f.write(content)
            print(f"  saved -> {fpath}")
            self._json(200, {"ok": True, "path": fpath})
        else:
            self._json(404, {"error": "not found"})

    def _json(self, code, obj):
        data = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        for h, v in NO_CACHE:
            self.send_header(h, v)
        self.end_headers()
        self.wfile.write(data)

    def _redirect(self, location):
        self.send_response(302)
        self.send_header("Location", location)
        self.end_headers()

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def log_message(self, fmt, *args):
        msg = str(args)
        if "POST" in msg or "api" in msg:
            super().log_message(fmt, *args)

if __name__ == "__main__":
    files = sorted(glob.glob(os.path.join(DIALOGUE, "*.json")))
    print(f"REC-OFF-AIR 統合ツールサーバー")
    print(f"  http://localhost:{PORT}/")
    print(f"  http://localhost:{PORT}/path-viewer/")
    print(f"  http://localhost:{PORT}/dialogue-editor/")
    print(f"  dialogue: {DIALOGUE} ({len(files)} files)")
    print(f"  API: /api/list, /api/load?name=xxx.json, POST /api/save")
    http.server.HTTPServer(("", PORT), Handler).serve_forever()
