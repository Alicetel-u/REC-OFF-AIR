"""
CP1 ボイス生成スクリプト（差分生成対応・マルチエンジン）
VOICEVOX / Style-Bert-VITS2 API でセリフ音声を生成する
- voice_hash で変更検出 → 変更分だけ再生成
- reading フィールド対応（読み指定があればそちらを使用）
- 末尾の無音を自動トリミング
- 生成後に fix_voice_wait.py を自動実行して wait 時間を最適化

使い方:
  python tools/generate_voice_ch01.py                  # VOICEVOX（デフォルト）
  python tools/generate_voice_ch01.py --engine sbv2     # Style-Bert-VITS2
  python tools/generate_voice_ch01.py --engine sbv2 --model jvnv-M1-jp --style Neutral
  python tools/generate_voice_ch01.py --force           # 全再生成
"""

import json
import hashlib
import requests
import sys
import os
import io
import subprocess
import argparse
from wav_utils import trim_trailing_silence as _trim_wav

# Windows コンソールの文字化け対策
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

# ═══════════════════════════════════════════════════
# VOICEVOX 設定
# ═══════════════════════════════════════════════════
VOICEVOX_URL = "http://127.0.0.1:50021"
SPEAKER_ID = 20

# 音声パラメータ（テンション高め・流暢・早口）
SPEED_SCALE = 1.25         # 速度アップ
INTONATION_SCALE = 1.5     # 抑揚強め（テンション高い感じ）
PITCH_SCALE = 0.02         # ほんの少しピッチ上げ

# VOICEVOXポーズ制御
MAX_PAUSE_LENGTH = 0.15     # 句読点ポーズの最大長（秒）
PRE_PHONEME_LENGTH = 0.05   # 文頭ポーズ（秒）
POST_PHONEME_LENGTH = 0.05  # 文末ポーズ（秒）

# ═══════════════════════════════════════════════════
# Style-Bert-VITS2 設定
# ═══════════════════════════════════════════════════
SBV2_URL = "http://127.0.0.1:5000"
SBV2_MODEL = "jvnv-F2-jp"   # デフォルトモデル（model_assets/ 内のディレクトリ名）
SBV2_STYLE = "Fear"          # デフォルトスタイル（Neutral/Happy/Sad/Angry/Fear等）
SBV2_LENGTH = 0.8            # 話速（1.0基準、小さい=速い）
SBV2_SDP_RATIO = 0.2        # SDP/DP比（トーンのばらつき）
SBV2_NOISE = 0.6            # サンプルノイズ
SBV2_NOISEW = 0.8           # SDPノイズ

# ═══════════════════════════════════════════════════
# 共通設定
# ═══════════════════════════════════════════════════
DIALOGUE_PATH = os.path.join(os.path.dirname(__file__), "..", "dialogue", "ch01_entrance.json")
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "voice", "ch01")
HASH_PATH = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "voice", "ch01", ".voice_hashes.json")

# 末尾無音トリミング設定
SILENCE_THRESHOLD = 2000    # この振幅以下を無音とみなす（微小音もカット）
TAIL_MARGIN_MS = 40         # トリミング後に残す余白（ミリ秒）

# 発音修正テーブル
PRONUNCIATION_FIXES = {
    "TIKTOK": "ティックトック",
    "TikTok": "ティックトック",
    "tiktok": "ティックトック",
    "廃村": "はいそん",
    "お札": "おふだ",
    "柵": "さく",
    "萎え": "なえー",
}


def compute_voice_hash(text: str, reading: str = "") -> str:
    """音声生成に使うテキストのハッシュ（reading優先）"""
    source = reading if reading else text
    return hashlib.md5(source.encode("utf-8")).hexdigest()[:12]


def fix_pronunciation(text: str) -> str:
    """VOICEVOX用にテキストの発音を修正"""
    for original, fixed in PRONUNCIATION_FIXES.items():
        text = text.replace(original, fixed)
    return text


def trim_trailing_silence(wav_path: str) -> float:
    """WAVファイルの末尾の無音を除去し、トリミング後の秒数を返す"""
    return _trim_wav(wav_path, threshold=SILENCE_THRESHOLD, margin_ms=TAIL_MARGIN_MS)


def generate_voice_voicevox(text: str, speaker_id: int, output_path: str) -> tuple:
    """VOICEVOX APIで音声を生成してWAVファイルに保存（末尾無音トリミング付き）"""
    try:
        tts_text = fix_pronunciation(text)

        # 音声合成用のクエリを作成
        query_res = requests.post(
            f"{VOICEVOX_URL}/audio_query",
            params={"text": tts_text, "speaker": speaker_id},
            timeout=30
        )
        query_res.raise_for_status()
        query_data = query_res.json()

        # パラメータ調整（テンション高め・早口・流暢）
        query_data["speedScale"] = SPEED_SCALE
        query_data["intonationScale"] = INTONATION_SCALE
        query_data["pitchScale"] = PITCH_SCALE
        query_data["prePhonemeLength"] = PRE_PHONEME_LENGTH
        query_data["postPhonemeLength"] = POST_PHONEME_LENGTH

        # 句読点ポーズを短縮（長すぎる無音を防止）
        for phrase in query_data.get("accent_phrases", []):
            if phrase.get("pause_mora") is not None:
                vl = phrase["pause_mora"].get("vowel_length", 0)
                phrase["pause_mora"]["vowel_length"] = min(vl, MAX_PAUSE_LENGTH)

        # 音声合成
        synth_res = requests.post(
            f"{VOICEVOX_URL}/synthesis",
            params={"speaker": speaker_id},
            json=query_data,
            timeout=60
        )
        synth_res.raise_for_status()

        with open(output_path, "wb") as f:
            f.write(synth_res.content)

        # 末尾無音トリミング
        duration = trim_trailing_silence(output_path)

        return True, duration
    except Exception as e:
        print(f"  ERROR: {e}")
        return False, 0.0


def generate_voice_sbv2(text: str, output_path: str,
                        model: str = SBV2_MODEL, style: str = SBV2_STYLE) -> tuple:
    """Style-Bert-VITS2 APIで音声を生成してWAVファイルに保存（末尾無音トリミング付き）"""
    try:
        tts_text = fix_pronunciation(text)

        # SBV2は1リクエストでWAVを直接返す
        resp = requests.post(
            f"{SBV2_URL}/voice",
            params={
                "text": tts_text,
                "model_name": model,
                "style": style,
                "length": SBV2_LENGTH,
                "sdp_ratio": SBV2_SDP_RATIO,
                "noise": SBV2_NOISE,
                "noisew": SBV2_NOISEW,
                "language": "JP",
                "auto_split": True,
            },
            timeout=120
        )
        resp.raise_for_status()

        with open(output_path, "wb") as f:
            f.write(resp.content)

        # 末尾無音トリミング
        duration = trim_trailing_silence(output_path)

        return True, duration
    except requests.exceptions.ConnectionError:
        print(f"  ERROR: SBV2サーバーに接続できません ({SBV2_URL})")
        print(f"         Style-Bert-VITS2 の Server.bat を起動してください")
        return False, 0.0
    except Exception as e:
        print(f"  ERROR: {e}")
        return False, 0.0


def generate_voice(text: str, output_path: str, engine: str = "voicevox",
                   model: str = SBV2_MODEL, style: str = SBV2_STYLE) -> tuple:
    """エンジンに応じて音声生成を振り分け"""
    if engine == "sbv2":
        return generate_voice_sbv2(text, output_path, model=model, style=style)
    else:
        return generate_voice_voicevox(text, SPEAKER_ID, output_path)


def load_hashes(path: str = HASH_PATH) -> dict:
    """サイドカーファイルからハッシュを読み込む"""
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}


def save_hashes(hashes: dict, path: str = HASH_PATH) -> None:
    """サイドカーファイルにハッシュを保存（対話JSONには触らない）"""
    with open(path, "w", encoding="utf-8") as f:
        json.dump(hashes, f, ensure_ascii=False, indent=2)


def parse_args():
    parser = argparse.ArgumentParser(description="ボイス生成スクリプト（VOICEVOX / Style-Bert-VITS2）")
    parser.add_argument("--engine", choices=["voicevox", "sbv2"], default="voicevox",
                        help="音声エンジン (default: voicevox)")
    parser.add_argument("--model", default=SBV2_MODEL,
                        help=f"SBV2モデル名 (default: {SBV2_MODEL})")
    parser.add_argument("--style", default=SBV2_STYLE,
                        help=f"SBV2スタイル (default: {SBV2_STYLE})")
    parser.add_argument("--force", action="store_true",
                        help="全件再生成（差分検出を無視）")
    parser.add_argument("--dialogue", default=None,
                        help="対話JSONファイルパス（デフォルト: ch01_entrance.json）")
    parser.add_argument("--output-dir", default=None,
                        help="音声出力ディレクトリ（デフォルト: assets/audio/voice/ch01）")
    return parser.parse_args()


def main():
    args = parse_args()

    # --dialogue / --output-dir が指定されていればそちらを使う
    dialogue_path = args.dialogue if args.dialogue else DIALOGUE_PATH
    dialogue_path = os.path.abspath(dialogue_path)
    output_dir = args.output_dir if args.output_dir else OUTPUT_DIR
    output_dir = os.path.abspath(output_dir)
    hash_path = os.path.join(output_dir, ".voice_hashes.json")

    with open(dialogue_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    events = data.get("events", [])

    voice_events = []
    for ev in events:
        if ev.get("type") == "say" and "voice" in ev:
            voice_events.append(ev)

    # ハッシュはサイドカーファイルで管理（対話JSONを書き換えない）
    hashes = load_hashes(hash_path)

    chapter_label = os.path.basename(dialogue_path).replace(".json", "")
    mode_label = "全再生成 (--force)" if args.force else "差分生成"
    engine_label = "Style-Bert-VITS2" if args.engine == "sbv2" else "VOICEVOX"
    print(f"=== {chapter_label} ボイス{mode_label} [{engine_label}] ===")
    print(f"対象: {len(voice_events)} 件")
    if args.engine == "sbv2":
        print(f"model={args.model} style={args.style} length={SBV2_LENGTH}")
    else:
        print(f"speaker={SPEAKER_ID} speed={SPEED_SCALE} intonation={INTONATION_SCALE} pitch={PITCH_SCALE}")
    print(f"末尾トリミング: threshold={SILENCE_THRESHOLD} margin={TAIL_MARGIN_MS}ms")
    print()

    os.makedirs(output_dir, exist_ok=True)

    success = 0
    skipped = 0
    fail = 0
    hashes_updated = False

    for i, ev in enumerate(voice_events):
        voice_id = ev["voice"]
        text = ev.get("text", "")
        reading = ev.get("reading", "")
        voice_text = reading if reading else text
        output_path = os.path.join(output_dir, f"{voice_id}.wav")

        # 差分検出（サイドカーファイルのハッシュと比較）
        # SBV2使用時はエンジン名をハッシュに含めて区別
        hash_key = voice_id if args.engine == "voicevox" else f"{voice_id}@sbv2"
        new_hash = compute_voice_hash(text, reading)
        old_hash = hashes.get(hash_key, "")

        if not args.force and new_hash == old_hash and os.path.exists(output_path):
            print(f"[{i+1}/{len(voice_events)}] {voice_id} -- スキップ（変更なし）")
            skipped += 1
            continue

        reason = "force" if args.force else ("新規" if not old_hash else "変更あり")
        print(f"[{i+1}/{len(voice_events)}] {voice_id} ({reason})")
        if reading:
            print(f"  読み: {reading}")

        ok, duration = generate_voice(voice_text, output_path,
                                      engine=args.engine, model=args.model, style=args.style)
        if ok:
            size_kb = os.path.getsize(output_path) / 1024
            print(f"  -> OK ({size_kb:.1f} KB, {duration:.2f}s)")
            hashes[hash_key] = new_hash
            hashes_updated = True
            success += 1
        else:
            fail += 1

    # ハッシュをサイドカーファイルに保存（対話JSONは一切変更しない）
    if hashes_updated:
        save_hashes(hashes, hash_path)
        print()
        print(f"ハッシュ更新: {hash_path}")

    print()
    print(f"=== 完了: 生成 {success} / スキップ {skipped} / 失敗 {fail} / 合計 {len(voice_events)} ===")

    # .import ファイル存在チェック（CIデプロイに必要）
    if success > 0:
        missing_imports = []
        for ev in voice_events:
            import_path = os.path.join(output_dir, f"{ev['voice']}.wav.import")
            if not os.path.exists(import_path):
                missing_imports.append(f"{ev['voice']}.wav.import")
        if missing_imports:
            print()
            print("⚠ WARNING: 以下の .import ファイルがありません（本番デプロイに必要）")
            print("  Godotエディタでプロジェクトを一度開いて .import を生成し、git commit してください")
            for m in missing_imports:
                print(f"    - {m}")

    # ── 生成があった場合、wait 時間を自動調整 ──
    if success > 0:
        print()
        print("=== wait 時間を自動調整中 ===")
        fix_script = os.path.join(os.path.dirname(__file__), "fix_voice_wait.py")
        if os.path.exists(fix_script):
            result = subprocess.run(
                [sys.executable, fix_script, "--apply", "--backup"],
                capture_output=True, text=True, encoding="utf-8", errors="replace"
            )
            print(result.stdout)
            if result.returncode != 0:
                print(f"WARNING: fix_voice_wait.py が異常終了 (code {result.returncode})")
                if result.stderr:
                    print(result.stderr)
        else:
            print(f"WARNING: {fix_script} が見つかりません")

    if fail > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
