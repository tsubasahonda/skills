# skills

AGENTS.md マージツールを提供するリポジトリです。

## マージツール（merge.sh）

別のリポジトリから取得した AGENTS.md（テンプレート）と、既存の AGENTS.md をマージするツールです。

### マージルール

1. **Core Principles** セクションがない場合 → 先頭に追加
2. **Maintenance Notes** セクションがない場合 → 末尾に追加
3. **プロジェクト固有セクション**（メモリ運用ルール等）→ Core Principles と Maintenance Notes の間に維持

### 使い方

```bash
# デフォルトテンプレートでマージ
./scripts/merge.sh ./AGENTS.md

# dry-run で結果を確認（ファイルは更新されない）
./scripts/merge.sh ./AGENTS.md -d

# テンプレートファイルを指定
./scripts/merge.sh ./AGENTS.md -t path/to/template.md

# URLからテンプレートを取得
./scripts/merge.sh ./AGENTS.md -t https://raw.githubusercontent.com/.../AGENTS.md

# 出力先を指定
./scripts/merge.sh ./AGENTS.md -o path/to/output.md

# ワンライナーで実行（curl と組み合わせ）
curl -s https://raw.githubusercontent.com/tsubasahonda/skills/main/scripts/merge.sh | bash -s -- ./AGENTS.md
```

### オプション

| オプション | 説明 |
|-----------|------|
| `-t, --template` | テンプレートファイルのパスまたはURL |
| `-o, --output` | 出力先パス（省略時はターゲットを上書き） |
| `-d, --dry-run` | 結果を表示のみ（ファイルに書き込まない） |
| `-h, --help` | ヘルプを表示 |

### テスト

```bash
./scripts/test_merge.sh
```

## ライセンス

MIT License
