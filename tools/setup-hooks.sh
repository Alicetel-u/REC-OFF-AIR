#!/bin/bash
# Git hooks セットアップスクリプト
# 新しいPCでclone後に一度だけ実行: bash tools/setup-hooks.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
HOOK_DIR="$REPO_DIR/.git/hooks"

echo "=== Git hooks セットアップ ==="

# pre-commit フックをコピー
cp "$SCRIPT_DIR/pre-commit" "$HOOK_DIR/pre-commit"
chmod +x "$HOOK_DIR/pre-commit"
echo "  pre-commit フックをインストールしました"

echo "=== 完了 ==="
