#!/bin/bash
#
# AGENTS.md マージスクリプト
#
# 別のリポジトリから取得した AGENTS.md（テンプレート）と
# 既存の AGENTS.md をマージする。
#
# 使用方法:
#   ./merge.sh <target> [--template <file|url>]
#   curl -s https://... | bash -s -- <target>
#
# マージルール:
# 1. Core Principles セクションがない場合は先頭に追加
# 2. Maintenance Notes セクションがない場合は末尾に追加
# 3. プロジェクト固有セクション（メモリ運用ルール等）は維持
#

set -euo pipefail

# テンプレートの固定セクション
CORE_PRINCIPLES='
# AGENTS.md

<!-- Do not restructure or delete sections. Update individual values in-place when they change. -->

## Core Principles

- **Do NOT maintain backward compatibility** unless explicitly requested. Break things boldly.
- **Keep this file under 20-30 lines of instructions.** Every line competes for the agent'\''s limited context budget (~150-200 total).

---
'

MAINTENANCE_NOTES='
## Maintenance Notes

<!-- This section is permanent. Do not delete. -->

**Keep this file lean and current:**

1. **Remove placeholder sections** (sections still containing `[To be determined]` or `[Add your ... here]`) once you fill them in
2. **Review regularly** - stale instructions poison the agent'\''s context
3. **CRITICAL: Keep total under 20-30 lines** - move detailed docs to separate files and reference them
4. **Update commands immediately** when workflows change
5. **Rewrite Architecture section** when major architectural changes occur
6. **Delete anything the agent can infer** from your code

**Remember:** Coding agents learn from your actual code. Only document what'\''s truly non-obvious or critically important.
'

# デフォルトテンプレート（埋め込み）
DEFAULT_TEMPLATE="${CORE_PRINCIPLES}${MAINTENANCE_NOTES}"

usage() {
    cat << 'EOF'
AGENTS.md マージスクリプト

使用方法:
  ./merge.sh <target> [options]
  curl -s https://... | bash -s -- <target> [options]

引数:
  target              マージ対象の AGENTS.md ファイルパス

オプション:
  -t, --template      テンプレートファイルのパスまたはURL
  -o, --output        出力先パス（省略時は target を上書き）
  -d, --dry-run       結果を表示のみ（ファイルに書き込まない）
  -h, --help          ヘルプを表示

使用例:
  # デフォルトテンプレートでマージ
  ./merge.sh ./AGENTS.md

  # テンプレートファイルを指定
  ./merge.sh ./AGENTS.md -t template.md

  # URLからテンプレートを取得
  ./merge.sh ./AGENTS.md -t https://raw.githubusercontent.com/.../AGENTS.md

  # ワンライナーで実行
  curl -s https://raw.githubusercontent.com/.../merge.sh | bash -s -- ./AGENTS.md
EOF
}

# セクションが存在するかチェック
has_section() {
    local content="$1"
    local section_name="$2"
    echo "$content" | grep -q "^## ${section_name}$"
}

# プロジェクトセクションを抽出
# Core Principles と Maintenance Notes の間にあるコンテンツを取得
extract_project_sections() {
    local content="$1"

    # --- の後から ## Maintenance Notes の前までを抽出
    echo "$content" | awk '
        /^---$/ { in_project=1; next }
        /^## Maintenance Notes$/ { in_project=0 }
        in_project { print }
    '
}

# テンプレートから Core Principles セクションを抽出
extract_core_principles() {
    local content="$1"
    echo "$content" | awk '
        /^# AGENTS\.md$/ { in_header=1 }
        in_header { print }
        /^---$/ { exit }
    '
}

# テンプレートから Maintenance Notes セクションを抽出
extract_maintenance_notes() {
    local content="$1"
    echo "$content" | awk '
        /^## Maintenance Notes$/ { in_maintenance=1 }
        in_maintenance { print }
    '
}

# テンプレートを取得
get_template() {
    local template_source="$1"

    if [[ -z "$template_source" ]]; then
        # デフォルトテンプレートを使用
        echo "$DEFAULT_TEMPLATE"
        return
    fi

    if [[ "$template_source" =~ ^https?:// ]]; then
        # URL から取得
        curl -sL "$template_source"
    else
        # ローカルファイル
        cat "$template_source"
    fi
}

# メイン処理
main() {
    local target=""
    local template_source=""
    local output=""
    local dry_run=false

    # 引数解析
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--template)
                template_source="$2"
                shift 2
                ;;
            -o|--output)
                output="$2"
                shift 2
                ;;
            -d|--dry-run)
                dry_run=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                if [[ -z "$target" ]]; then
                    target="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$target" ]]; then
        echo "エラー: ターゲットファイルを指定してください" >&2
        usage >&2
        exit 1
    fi

    # テンプレート取得
    local template
    template=$(get_template "$template_source")

    # ターゲットファイルの存在確認
    if [[ ! -f "$target" ]]; then
        # ターゲットが存在しない場合はテンプレートをそのまま使用
        if $dry_run; then
            echo "$template"
        else
            local out="${output:-$target}"
            echo "$template" > "$out"
            echo "マージ完了: $out"
        fi
        exit 0
    fi

    local target_content
    target_content=$(cat "$target")

    # プロジェクトセクションを抽出
    local project_sections=""
    if has_section "$target_content" "Core Principles" && has_section "$target_content" "Maintenance Notes"; then
        project_sections=$(extract_project_sections "$target_content")
    else
        # セクションが不完全な場合は、ヘッダーを削除して残りを取得
        project_sections=$(echo "$target_content" | sed '/^# AGENTS\.md$/d')
    fi

    # テンプレートからセクションを抽出（テンプレートが指定された場合）
    local core_principles="${CORE_PRINCIPLES}"
    local maintenance_notes="${MAINTENANCE_NOTES}"

    if [[ -n "$template_source" ]]; then
        if has_section "$template" "Core Principles"; then
            core_principles=$(extract_core_principles "$template")
        fi
        if has_section "$template" "Maintenance Notes"; then
            maintenance_notes=$(extract_maintenance_notes "$template")
        fi
    fi

    # マージ結果を構築
    local result
    if [[ -n "$project_sections" ]]; then
        result="${core_principles}"$'\n'"${project_sections}"$'\n'"${maintenance_notes}"
    else
        result="${core_principles}"$'\n'"${maintenance_notes}"
    fi

    # 出力
    if $dry_run; then
        echo "$result"
    else
        local out="${output:-$target}"
        echo "$result" > "$out"
        echo "マージ完了: $out"
    fi
}

main "$@"
