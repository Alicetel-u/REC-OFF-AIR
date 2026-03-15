#!/bin/bash
# CP3 自動プレイ トライ&エラーループ
# 失敗したら即ゲーム停止→再起動を繰り返す
# 成功条件: "自動プレイ完了" かつ "タイムアウト" "強制取得" がゼロ

GODOT_EXE="$USERPROFILE/OneDrive/デスクトップ/Godot_v4.6.1-stable_win64.exe/Godot_v4.6.1-stable_win64_console.exe"
PROJECT="C:/repos/REC-OFF-AIR"
LOG="$PROJECT/game_stdout.txt"
MAX_TRIES=10
WAIT_PER_ITEM=50  # アイテム1個あたりの最大待ち秒数（3個+出口=4 → 200秒）
TOTAL_WAIT=$((WAIT_PER_ITEM * 4 + 30))

for try in $(seq 1 $MAX_TRIES); do
    echo ""
    echo "========================================"
    echo "  Try $try / $MAX_TRIES"
    echo "========================================"

    # フラグファイル作成
    echo -n "3" > "$PROJECT/_autotest.txt"

    # ゲーム起動
    cmd.exe /c "cd /d $PROJECT && \"$GODOT_EXE\" --verbose" > "$LOG" 2>&1 &
    GAME_PID=$!

    # ログ監視ループ（10秒ごとにチェック）
    elapsed=0
    success=false
    failed=false
    while [ $elapsed -lt $TOTAL_WAIT ]; do
        sleep 10
        elapsed=$((elapsed + 10))

        # ゲームが勝手に終了していたら失敗
        if ! kill -0 $GAME_PID 2>/dev/null; then
            echo "[Try $try] Game crashed or exited at ${elapsed}s"
            failed=true
            break
        fi

        # ログチェック
        if grep -q "自動プレイ完了" "$LOG" 2>/dev/null; then
            # 完了した → 品質チェック
            timeouts=$(grep -c "タイムアウト" "$LOG" 2>/dev/null || echo 0)
            forced=$(grep -c "強制取得" "$LOG" 2>/dev/null || echo 0)
            echo "[Try $try] Completed! timeouts=$timeouts forced=$forced"
            if [ "$timeouts" -eq 0 ] && [ "$forced" -eq 0 ]; then
                echo "[Try $try] ★ PERFECT — ワープなし・強制取得なし！"
                success=true
            else
                echo "[Try $try] 完了したが品質不足（タイムアウト=$timeouts, 強制=$forced）"
                failed=true
            fi
            break
        fi

        # タイムアウトが出た時点で即失敗
        if grep -q "タイムアウト" "$LOG" 2>/dev/null; then
            echo "[Try $try] Timeout detected at ${elapsed}s — aborting"
            failed=true
            break
        fi

        # 進捗表示
        items=$(grep -c "取得OK\|強制取得" "$LOG" 2>/dev/null || echo 0)
        echo "[Try $try] ${elapsed}s — items=$items"
    done

    # ゲーム停止
    taskkill //F //IM Godot_v4.6.1-stable_win64_console.exe 2>/dev/null
    sleep 2

    if $success; then
        echo ""
        echo "========================================"
        echo "  SUCCESS on Try $try!"
        echo "========================================"
        grep "\[AutoPlay\]" "$LOG"
        exit 0
    fi

    if $failed; then
        echo "[Try $try] Failed — retrying..."
        # ログ表示
        grep "\[AutoPlay\]" "$LOG" 2>/dev/null
    fi
done

echo ""
echo "========================================"
echo "  $MAX_TRIES tries exhausted — needs code fix"
echo "========================================"
grep "\[AutoPlay\]" "$LOG" 2>/dev/null
exit 1
