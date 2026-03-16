// データの読み込み確認
if (typeof SCENARIO_DATA === 'undefined') {
    console.error("data.js が読み込まれていないか、データが不正です。");
    // フォールバック用の空データ
    var SCENARIO_DATA = { events: [] };
    var SOUND_CATEGORIES = {};
    var SOUND_FILES = {};
}

class ScenarioEditor {
    constructor() {
        this.currentAudio = null;
        this.activeSound = null;
        this.selectedEventIdx = -1;
        this.currentCategory = "環境音（風）";
        window.app = this; // Global access for inline onclick
        this.init();
    }

    init() {
        this.renderCategories();
        this.renderEvents();
        this.setupEventListeners();
        this.switchCategory(this.currentCategory);
    }

    renderCategories() {
        const nav = document.getElementById('category-list');
        nav.innerHTML = '';
        Object.keys(SOUND_CATEGORIES).forEach(cat => {
            const btn = document.createElement('button');
            btn.className = `btn-icon ${cat === this.currentCategory ? 'active' : ''}`;
            btn.innerText = cat;
            btn.onclick = () => this.switchCategory(cat);
            nav.appendChild(btn);
        });
    }

    switchCategory(cat) {
        this.currentCategory = cat;
        this.renderSoundGrid(cat);
    }

    renderSoundGrid(cat) {
        const grid = document.getElementById('sound-grid');
        grid.innerHTML = '';
        const files = SOUND_FILES[cat] || [];
        files.forEach(file => {
            const card = document.createElement('div');
            card.className = 'sound-card';
            card.style.padding = '10px';
            card.innerHTML = `<div class="sound-name" style="font-size:0.75rem">${file}</div>`;
            card.onclick = () => this.selectSound(cat, file);
            grid.appendChild(card);
        });
    }

    renderEvents() {
        const list = document.getElementById('event-list');
        list.innerHTML = '';
        SCENARIO_DATA.events.forEach((ev, idx) => {
            const item = document.createElement('div');
            item.className = `event-item event-${ev.type} ${this.selectedEventIdx === idx ? 'selected' : ''}`;
            if (this.selectedEventIdx === idx) item.style.borderColor = 'var(--accent)';

            let content = '';
            switch (ev.type) {
                case 'say': content = `<strong>${ev.text}</strong> <span style="color:#666">(${ev.voice})</span>`; break;
                case 'sfx': content = `<span style="color:var(--accent)">🔊 ${ev.file || ev.sound}</span> (Vol: ${ev.vol || 0}dB)`; break;
                case 'wait': content = `⌛ ${ev.sec}秒 待機`; break;
                case 'chat': content = `<span style="color:#4ae2a0">💬 ${ev.user}:</span> ${ev.msg}`; break;
                default: content = `[${ev.type}] 通過イベント`;
            }

            item.innerHTML = `
                <div class="event-type">${ev.type}</div>
                <div class="event-content">${content}</div>
                <div class="event-controls">
                    <button class="btn-icon" onclick="app.moveEvent(${idx}, -1)">↑</button>
                    <button class="btn-icon" onclick="app.moveEvent(${idx}, 1)">↓</button>
                    <button class="btn-icon" onclick="app.removeEvent(${idx})">×</button>
                </div>
            `;
            item.onclick = (e) => {
                if (e.target.tagName !== 'BUTTON') this.selectEvent(idx);
            };
            list.appendChild(item);
        });
    }

    selectEvent(idx) {
        this.selectedEventIdx = idx;
        this.renderEvents();
    }

    selectSound(cat, file) {
        this.activeSound = { cat, file };
        document.getElementById('active-sound-info').innerHTML = `
            <div style="font-weight:600">${file}</div>
            <div style="font-size:0.7rem; color:#888">${cat}</div>
        `;
        // Preview play...
    }

    addEvent(type) {
        const newEvent = { type: type };
        if (type === 'wait') newEvent.sec = 1.0;
        if (type === 'say') { newEvent.text = "新しいセリフ"; newEvent.voice = ""; }

        if (this.selectedEventIdx >= 0) {
            SCENARIO_DATA.events.splice(this.selectedEventIdx + 1, 0, newEvent);
        } else {
            SCENARIO_DATA.events.push(newEvent);
        }
        this.renderEvents();
    }

    moveEvent(idx, dir) {
        const target = idx + dir;
        if (target < 0 || target >= SCENARIO_DATA.events.size) return;
        const temp = SCENARIO_DATA.events[idx];
        SCENARIO_DATA.events[idx] = SCENARIO_DATA.events[target];
        SCENARIO_DATA.events[target] = temp;
        this.selectedEventIdx = target;
        this.renderEvents();
    }

    removeEvent(idx) {
        SCENARIO_DATA.events.splice(idx, 1);
        this.selectedEventIdx = -1;
        this.renderEvents();
    }

    setupEventListeners() {
        document.getElementById('insert-sound').onclick = () => {
            if (!this.activeSound) {
                this.showToast("サウンドを選択してください");
                return;
            }
            const fileBase = this.activeSound.cat.toLowerCase().replace(' ', '_') + "/" + this.activeSound.file.split('.')[0];
            const newSfx = {
                "type": "sfx",
                "file": fileBase,
                "vol": parseFloat(document.getElementById('prop-vol').value)
            };
            if (this.selectedEventIdx >= 0) {
                SCENARIO_DATA.events.splice(this.selectedEventIdx + 1, 0, newSfx);
            } else {
                SCENARIO_DATA.events.push(newSfx);
            }
            this.renderEvents();
            this.showToast("イベントを挿入しました");
        };

        document.getElementById('save-json').onclick = () => {
            const dataStr = JSON.stringify(SCENARIO_DATA, null, 4);
            const blob = new Blob([dataStr], { type: 'application/json' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'ch01_entrance_updated.json';
            a.click();
            this.showToast("JSONファイルをエクスポートしました");
        };
    }

    showToast(msg) {
        const container = document.getElementById('toast-container');
        const toast = document.createElement('div');
        toast.className = 'toast';
        toast.innerText = msg;
        container.appendChild(toast);
        setTimeout(() => toast.remove(), 3000);
    }
}

window.onload = () => new ScenarioEditor();
