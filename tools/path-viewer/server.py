"""統合ツールサーバー — パスビューア＋ダイアログエディター＋JSON保存API"""
import http.server, json, os, glob

PORT = 8090
ROOT = os.path.dirname(os.path.abspath(__file__))
TOOLS_ROOT = os.path.normpath(os.path.join(ROOT, ".."))
DIALOGUE = os.path.normpath(os.path.join(ROOT, "..", "..", "dialogue"))
CACHE_JS = os.path.join(ROOT, "dialogue_cache.js")

def rebuild_cache():
    """dialogue/*.json → dialogue_cache.js を再生成"""
    cache = {}
    for f in sorted(glob.glob(os.path.join(DIALOGUE, "*.json"))):
        name = os.path.splitext(os.path.basename(f))[0]
        with open(f, "r", encoding="utf-8") as fp:
            cache[name] = json.load(fp)
    out = "const DIALOGUE_CACHE = " + json.dumps(cache, ensure_ascii=False, separators=(",", ":")) + ";\n"
    with open(CACHE_JS, "w", encoding="utf-8") as fp:
        fp.write(out)
    print(f"  cache rebuilt: {len(cache)} files, {len(out)} bytes")

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=ROOT, **kw)

    def do_GET(self):
        # HTML/JSはキャッシュさせない
        if self.path in ("/", "/index.html", "/path-viewer/", "/path-viewer/index.html") or self.path.startswith("/index.html?"):
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
            self.send_header("Pragma", "no-cache")
            self.end_headers()
            html_path = os.path.join(ROOT, "index.html")
            with open(html_path, "rb") as f:
                self.wfile.write(f.read())
            return
        if self.path == "/dialogue_cache.js" or self.path.startswith("/dialogue_cache.js?"):
            self.send_response(200)
            self.send_header("Content-Type", "application/javascript; charset=utf-8")
            self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
            self.send_header("Pragma", "no-cache")
            self.end_headers()
            with open(CACHE_JS, "rb") as f:
                self.wfile.write(f.read())
            return
        # /api/list — dialogue/*.json のファイル一覧
        if self.path == "/api/list":
            files = sorted([os.path.basename(f) for f in glob.glob(os.path.join(DIALOGUE, "*.json"))])
            self._json(200, {"files": files})
            return
        # /api/load?name=xxx.json — JSONファイルを直接読み込み（常に最新）
        if self.path.startswith("/api/load"):
            from urllib.parse import urlparse, parse_qs
            qs = parse_qs(urlparse(self.path).query)
            name = qs.get("name", [""])[0]
            if not name.endswith(".json"):
                self._json(400, {"error": "invalid filename"})
                return
            fpath = os.path.join(DIALOGUE, os.path.basename(name))
            if not os.path.isfile(fpath):
                self._json(404, {"error": "not found: " + name})
                return
            with open(fpath, "r", encoding="utf-8") as f:
                data = json.load(f)
            self._json(200, data)
            return
        # /api/save — POST用だがGETで来た場合は405
        if self.path.startswith("/api/save"):
            self._json(405, {"error": "use POST"})
            return
        # /editor/ — dialogue-editor を配信
        if self.path == "/editor" or self.path.startswith("/editor/"):
            rel = self.path[len("/editor"):]
            if not rel or rel == "/":
                rel = "/index.html"
            fpath = os.path.join(TOOLS_ROOT, "dialogue-editor", rel.lstrip("/"))
            if os.path.isfile(fpath):
                self.send_response(200)
                ct = "text/html; charset=utf-8"
                if fpath.endswith(".js"):
                    ct = "application/javascript; charset=utf-8"
                elif fpath.endswith(".css"):
                    ct = "text/css; charset=utf-8"
                self.send_header("Content-Type", ct)
                self.send_header("Cache-Control", "no-store")
                self.end_headers()
                with open(fpath, "rb") as f:
                    self.wfile.write(f.read())
                return
            self._json(404, {"error": "not found"})
            return
        super().do_GET()

    def do_POST(self):
        if self.path in ("/save", "/api/save"):
            length = int(self.headers.get("Content-Length", 0))
            body = json.loads(self.rfile.read(length))
            name = os.path.basename(body.get("filename", ""))
            if not name.endswith(".json"):
                self._json(400, {"error": "invalid filename"})
                return
            path = os.path.join(DIALOGUE, name)
            with open(path, "w", encoding="utf-8") as f:
                f.write(body["content"])
            print(f"  saved → {path}")
            # キャッシュも自動再生成
            rebuild_cache()
            self._json(200, {"ok": True, "path": path})
        else:
            self._json(404, {"error": "not found"})

    def _json(self, code, obj):
        data = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()
        self.wfile.write(data)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def log_message(self, fmt, *args):
        if "POST" in str(args):
            super().log_message(fmt, *args)

if __name__ == "__main__":
    print(f"統合ツールサーバー起動")
    print(f"  パスビューア:    http://localhost:{PORT}/")
    print(f"  イベントエディタ: http://localhost:{PORT}/editor/")
    print(f"  保存先: {DIALOGUE}")
    # 起動時にキャッシュ再生成
    rebuild_cache()
    http.server.HTTPServer(("", PORT), Handler).serve_forever()
