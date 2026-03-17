"""
朝まで自律作業ループ — Claude Code が止まらないための自動チェック&修正ワーカー
使い方: python tools/overnight_worker.py
"""
import subprocess, time, os, json, sys

PROJECT = r"C:\repos\REC-OFF-AIR"
GODOT = os.path.expandvars(r'%USERPROFILE%\OneDrive\デスクトップ\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe')
LOG = os.path.join(PROJECT, "overnight_log.txt")

def log(msg):
    ts = time.strftime("%H:%M:%S")
    line = f"[{ts}] {msg}"
    print(line)
    with open(LOG, "a", encoding="utf-8") as f:
        f.write(line + "\n")

def run(cmd, timeout=120):
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout, cwd=PROJECT)
        return r.returncode, r.stdout, r.stderr
    except subprocess.TimeoutExpired:
        return -1, "", "TIMEOUT"

def compile_check():
    log("コンパイルチェック...")
    code, out, err = run(f'cmd.exe /c "cd /d {PROJECT} && \\"{GODOT}\\" --headless --import --quit"', timeout=90)
    combined = out + err
    if "SCRIPT ERROR" in combined:
        log(f"SCRIPT ERROR検出!")
        return False, combined
    log("コンパイルOK")
    return True, combined

def git_status():
    code, out, err = run("git status --porcelain")
    return out.strip()

def git_push():
    log("git add + commit + push...")
    run("git add -A")
    code, out, err = run('git commit -m "auto: overnight worker checkpoint" --allow-empty')
    code, out, err = run("git push")
    if code == 0:
        log("push完了")
    else:
        log(f"push失敗: {err}")

if __name__ == "__main__":
    log("=== overnight_worker 起動 ===")
    ok, _ = compile_check()
    if ok:
        log("プロジェクト正常。Claude Codeの作業を続けてください。")
    else:
        log("コンパイルエラーあり。修正が必要。")
    log("=== 完了 ===")
