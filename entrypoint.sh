#!/bin/sh
set -e # エラーが発生したらスクリプトを終了

CONFIG_TEMPLATE="/homebridge/config.template.json"
CONFIG_PATH="/homebridge/config.json"
ENV_FILE="/app/.env" # コンテナ内の .env ファイルのパス (docker-compose.ymlでマウント)

# .env ファイルが存在するか確認し、なければ警告 (通常はマウントされるはず)
if [ ! -f "$ENV_FILE" ]; then
    echo "警告: .env ファイルが見つかりません。環境変数の設定が不完全かもしれません。"
else
    echo "情報: $ENV_FILE を読み込みます。"
    # コメント行と空行を除き、変数をエクスポート
    export $(grep -v '^#' $ENV_FILE | grep -v '^$' | xargs)
fi

# テンプレートファイルから設定ファイルを生成
echo "情報: $CONFIG_TEMPLATE から $CONFIG_PATH を生成します..."

# 各プレースホルダーを環境変数の値で置換。値が未設定の場合はデフォルト値を使用(:=演算子)
# sed の区切り文字を | に変更 (IRデータに / が含まれる可能性があるため)
sed \
    -e "s|__HOMEBRIDGE_USERNAME__|${HOMEBRIDGE_USERNAME:=0E:AA:BB:CC:DD:EE}|g" \
    -e "s|__HOMEBRIDGE_PIN__|${HOMEBRIDGE_PIN:=000-00-000}|g" \
    -e "s|__NATURE_REMO_TOKEN__|${NATURE_REMO_TOKEN:=NO_TOKEN_SET}|g" \
    -e "s|__PROJECTOR_ON_IR__|${PROJECTOR_ON_IR:=NO_IR_DATA}|g" \
    -e "s|__PROJECTOR_OFF_IR__|${PROJECTOR_OFF_IR:=NO_IR_DATA}|g" \
    -e "s|__CHILD_LIGHT_ON_IR__|${CHILD_LIGHT_ON_IR:=NO_IR_DATA}|g" \
    -e "s|__CHILD_LIGHT_OFF_IR__|${CHILD_LIGHT_OFF_IR:=NO_IR_DATA}|g" \
    -e "s|__NIGHT_LIGHT_ON_IR__|${NIGHT_LIGHT_ON_IR:=NO_IR_DATA}|g" \
    -e "s|__NIGHT_LIGHT_OFF_IR__|${NIGHT_LIGHT_OFF_IR:=NO_IR_DATA}|g" \
    "$CONFIG_TEMPLATE" > "$CONFIG_PATH"

echo "情報: $CONFIG_PATH の生成完了。"

# Homebridgeの永続化に必要なディレクトリを確認・作成
mkdir -p /homebridge/persist /homebridge/accessories

# Homebridge 本体の起動コマンドを実行 (CMD or original entrypoint)
echo "情報: Homebridgeを起動します..."
# oznu/homebridge イメージのデフォルトエントリーポイントを実行
exec /init
