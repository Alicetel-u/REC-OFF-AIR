import json
import os

# パスの設定
base_dir = r"c:\Users\【RST-11】リバイブ新所沢\OneDrive\デスクトップ\プロジェクト\REC-OFF-AIR"
scenario_path = os.path.join(base_dir, "dialogue", "ch01_entrance.json")
sfx_dir = os.path.join(base_dir, "assets", "audio", "sfx")
output_html_path = os.path.join(base_dir, "tools", "sound-dashboard", "scenario_editor.html")

# シナリオの読み込み (5000行すべて)
with open(scenario_path, 'r', encoding='utf-8') as f:
    scenario = json.load(f)

# SFXファイルのスキャン
sfx_data = {}
categories = [d for d in os.listdir(sfx_dir) if os.path.isdir(os.path.join(sfx_dir, d))]
for cat in categories:
    cat_path = os.path.join(sfx_dir, cat)
    sfx_data[cat] = []
    for root, _, files in os.walk(cat_path):
        for file in files:
            if file.endswith(('.mp3', '.wav', '.ogg')):
                rel = os.path.relpath(os.path.join(root, file), cat_path).replace("\\", "/")
                sfx_data[cat].append(rel)

# HTMLテンプレートの作成（データを埋め込み）
html_content = f"""<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <title>REC-OFF-AIR シナリオ・エディタ (完全版)</title>
    <style>
        /* スタイルは既存のものを踏襲し、読みやすさを向上 */
        :root {{
            --bg-dark: #0a0a0c; --accent: #ff3e3e; --text-primary: #e0e0e6; --text-secondary: #9090a0;
            --border: rgba(255, 255, 255, 0.08); --card-bg: rgba(30, 30, 35, 0.5);
        }}
        body {{ font-family: sans-serif; background: var(--bg-dark); color: var(--text-primary); margin: 0; display: flex; flex-direction: column; height: 100vh; overflow: hidden; }}
        header {{ height: 60px; padding: 0 20px; border-bottom: 1px solid var(--border); display: flex; align-items: center; justify-content: space-between; }}
        main {{ display: flex; flex: 1; overflow: hidden; }}
        .timeline {{ flex: 2; border-right: 1px solid var(--border); overflow-y: auto; padding: 20px; }}
        .library {{ flex: 1; overflow-y: auto; padding: 20px; background: rgba(20, 20, 25, 0.5); }}
        .event-item {{ background: var(--card-bg); border: 1px solid var(--border); border-radius: 6px; padding: 10px; margin-bottom: 6px; display: flex; gap: 10px; cursor: pointer; }}
        .event-item:hover {{ border-color: var(--accent); }}
        .event-item.selected {{ border-color: var(--accent); background: rgba(255, 62, 62, 0.1); }}
        .type-label {{ font-size: 10px; background: #333; padding: 2px 4px; border-radius: 3px; min-width: 60px; text-align: center; }}
        .btn {{ background: var(--accent); color: white; border: none; padding: 8px 16px; border-radius: 4px; cursor: pointer; }}
        .btn-sm {{ padding: 2px 6px; font-size: 11px; }}
        .sound-card {{ padding: 8px; border: 1px solid var(--border); border-radius: 4px; margin-bottom: 4px; cursor: pointer; font-size: 12px; }}
        .sound-card:hover {{ background: #222; }}
    </style>
</head>
<body>
    <header>
        <div style="font-weight: bold;">REC-OFF-AIR シナリオ・エディタ</div>
        <button class="btn" onclick="saveData()">JSON保存</button>
    </header>
    <main>
        <div id="timeline" class="timeline"></div>
        <div class="library">
            <h3>サウンドライブラリ</h3>
            <div id="sound-categories" style="display:flex; flex-wrap:wrap; gap:5px; margin-bottom:15px;"></div>
            <div id="sound-grid"></div>
            <hr style="opacity:0.1; margin:20px 0;">
            <h3>イベント操作</h3>
            <div id="controls">
                <button class="btn" onclick="addEvent('sfx')">+ 音を追加</button>
                <button class="btn" onclick="addEvent('say')">+ セリフ追加</button>
                <button class="btn" onclick="addEvent('wait')">+ 待機追加</button>
            </div>
        </div>
    </main>

    <script>
        // 【全データを埋め込み】
        const SCENARIO_DATA = {json.dumps(scenario, ensure_ascii=False)};
        const SOUND_FILES = {json.dumps(sfx_data, ensure_ascii=False)};
        
        let selectedIdx = -1;

        function render() {{
            const container = document.getElementById('timeline');
            container.innerHTML = '';
            SCENARIO_DATA.events.forEach((ev, i) => {{
                const div = document.createElement('div');
                div.className = 'event-item' + (selectedIdx === i ? ' selected' : '');
                div.onclick = () => {{ selectedIdx = i; render(); }};
                
                let text = "";
                if (ev.type === "say") text = `<b>${{ev.text}}</b> (${{ev.voice}})`;
                else if (ev.type === "sfx") text = `<span style="color:#e2a04a">🔊 ${{ev.file || ev.sound}}</span>`;
                else if (ev.type === "wait") text = `⌛ ${{ev.sec}}s 待機`;
                else if (ev.type === "chat") text = `<small>${{ev.user}}:</small> ${{ev.msg}}`;
                else text = `[${{ev.type}}] 通過イベント`;

                div.innerHTML = `
                    <div class="type-label">${{ev.type}}</div>
                    <div style="flex:1">${{text}}</div>
                    <div style="display:flex; gap:2px">
                        <button class="btn-sm" onclick="move(${{i}}, -1); event.stopPropagation();">↑</button>
                        <button class="btn-sm" onclick="move(${{i}}, 1); event.stopPropagation();">↓</button>
                        <button class="btn-sm" onclick="remove(${{i}}); event.stopPropagation();">×</button>
                    </div>
                `;
                container.appendChild(div);
            }});
        }}

        function move(i, dir) {{
            const target = i + dir;
            if (target < 0 || target >= SCENARIO_DATA.events.length) return;
            const temp = SCENARIO_DATA.events[i];
            SCENARIO_DATA.events[i] = SCENARIO_DATA.events[target];
            SCENARIO_DATA.events[target] = temp;
            selectedIdx = target;
            render();
        }}

        function remove(i) {{
            SCENARIO_DATA.events.splice(i, 1);
            render();
        }}

        function addEvent(type) {{
            const ev = {{ type }};
            if (type === 'wait') ev.sec = 1.0;
            if (selectedIdx >= 0) SCENARIO_DATA.events.splice(selectedIdx + 1, 0, ev);
            else SCENARIO_DATA.events.push(ev);
            render();
        }}

        function renderLibrary() {{
            const cats = document.getElementById('sound-categories');
            Object.keys(SOUND_FILES).forEach(cat => {{
                const b = document.createElement('button');
                b.className = 'btn-sm';
                b.innerText = cat;
                b.onclick = () => {{
                    const grid = document.getElementById('sound-grid');
                    grid.innerHTML = '';
                    SOUND_FILES[cat].forEach(f => {{
                        const d = document.createElement('div');
                        d.className = 'sound-card';
                        d.innerText = f;
                        d.onclick = () => {{
                            const sfx = {{ type: "sfx", file: cat.toLowerCase() + "/" + f.split('.')[0] }};
                            if (selectedIdx >= 0) SCENARIO_DATA.events.splice(selectedIdx + 1, 0, sfx);
                            render();
                        }};
                        grid.appendChild(d);
                    }});
                }};
                cats.appendChild(b);
            }});
        }}

        function saveData() {{
            const blob = new Blob([JSON.stringify(SCENARIO_DATA, null, 4)], {{ type: 'application/json' }});
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'ch01_entrance_updated.json';
            a.click();
        }}

        renderLibrary();
        render();
    </script>
</body>
</html>
"""

with open(output_html_path, 'w', encoding='utf-8') as f:
    f.write(html_content)

print(f"Successfully generated self-contained HTML: {output_html_path}")
