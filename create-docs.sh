#!/bin/bash

# 設定ファイルのパスを定義
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$CURRENT_DIR/.terraform-docs.yml"

# 各モジュールディレクトリでterraform-docsを実行してREADMEを生成
for module in ./network ./webserver-cluster; do
  if [ -d "$module" ]; then
    # terraform-docsを設定ファイルを使用して実行
    (cd "$module" && terraform-docs --config "$CONFIG_FILE" markdown table --output-file README.md --output-mode inject .)
  fi
done