#!/bin/bash
#
# merge.sh のテストスクリプト
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MERGE_SCRIPT="${SCRIPT_DIR}/merge.sh"
TEST_DIR=""

# テスト用一時ディレクトリ作成
setup() {
    TEST_DIR=$(mktemp -d)
}

# テスト用一時ディレクトリ削除
teardown() {
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

# テスト結果表示
pass() {
    echo "✓ $1"
}

fail() {
    echo "✗ $1"
    echo "  期待: $2"
    echo "  実際: $3"
    exit 1
}

# テスト: ヘルプ表示
test_help() {
    local output
    output=$("$MERGE_SCRIPT" --help)

    if echo "$output" | grep -q "AGENTS.md マージスクリプト"; then
        pass "ヘルプが表示される"
    else
        fail "ヘルプが表示される" "AGENTS.md マージスクリプト" "$output"
    fi
}

# テスト: ターゲットファイルが存在しない場合
test_target_not_exists() {
    setup
    local output
    output=$("$MERGE_SCRIPT" "${TEST_DIR}/not_exists.md" --dry-run)

    if echo "$output" | grep -q "## Core Principles"; then
        pass "ターゲット不存在時: Core Principles が含まれる"
    else
        fail "Core Principles が含まれる" "## Core Principles" "$output"
    fi

    if echo "$output" | grep -q "## Maintenance Notes"; then
        pass "ターゲット不存在時: Maintenance Notes が含まれる"
    else
        fail "Maintenance Notes が含まれる" "## Maintenance Notes" "$output"
    fi

    teardown
}

# テスト: セクションがないターゲットをマージ
test_merge_without_sections() {
    setup

    cat > "${TEST_DIR}/target.md" << 'EOF'
# AGENTS.md

## カスタムルール

- ルール1
- ルール2
EOF

    local output
    output=$("$MERGE_SCRIPT" "${TEST_DIR}/target.md" --dry-run)

    if echo "$output" | grep -q "## Core Principles"; then
        pass "セクションなしターゲット: Core Principles が追加される"
    else
        fail "Core Principles が追加される" "## Core Principles" "$output"
    fi

    if echo "$output" | grep -q "## カスタムルール"; then
        pass "セクションなしターゲット: 既存コンテンツが維持される"
    else
        fail "既存コンテンツが維持される" "## カスタムルール" "$output"
    fi

    if echo "$output" | grep -q "## Maintenance Notes"; then
        pass "セクションなしターゲット: Maintenance Notes が追加される"
    else
        fail "Maintenance Notes が追加される" "## Maintenance Notes" "$output"
    fi

    teardown
}

# テスト: プロジェクトセクションを維持してマージ
test_merge_with_project_sections() {
    setup

    cat > "${TEST_DIR}/target.md" << 'EOF'
# AGENTS.md

## Core Principles

- Old principle

---

## メモリ運用ルール

- SPEC.md: プロダクト仕様
- PLAN.md: 実装計画

## 禁止事項

- Do not break things

## Maintenance Notes

Old notes
EOF

    local output
    output=$("$MERGE_SCRIPT" "${TEST_DIR}/target.md" --dry-run)

    if echo "$output" | grep -q "Do NOT maintain backward compatibility"; then
        pass "プロジェクトセクションあり: Core Principles が更新される"
    else
        fail "Core Principles が更新される" "Do NOT maintain backward compatibility" "$output"
    fi

    if echo "$output" | grep -q "## メモリ運用ルール"; then
        pass "プロジェクトセクションあり: メモリ運用ルールが維持される"
    else
        fail "メモリ運用ルールが維持される" "## メモリ運用ルール" "$output"
    fi

    if echo "$output" | grep -q "## 禁止事項"; then
        pass "プロジェクトセクションあり: 禁止事項が維持される"
    else
        fail "禁止事項が維持される" "## 禁止事項" "$output"
    fi

    if echo "$output" | grep -q "Keep this file lean and current"; then
        pass "プロジェクトセクションあり: Maintenance Notes が更新される"
    else
        fail "Maintenance Notes が更新される" "Keep this file lean and current" "$output"
    fi

    teardown
}

# テスト: テンプレートファイルを指定
test_with_template_file() {
    setup

    cat > "${TEST_DIR}/template.md" << 'EOF'
# AGENTS.md

## Core Principles

- Custom principle 1
- Custom principle 2

---

## Maintenance Notes

Custom maintenance notes
EOF

    cat > "${TEST_DIR}/target.md" << 'EOF'
## Project Section

Content here
EOF

    local output
    output=$("$MERGE_SCRIPT" "${TEST_DIR}/target.md" -t "${TEST_DIR}/template.md" --dry-run)

    if echo "$output" | grep -q "Custom principle 1"; then
        pass "テンプレートファイル指定: テンプレートの Core Principles が使用される"
    else
        fail "テンプレートの Core Principles が使用される" "Custom principle 1" "$output"
    fi

    if echo "$output" | grep -q "## Project Section"; then
        pass "テンプレートファイル指定: プロジェクトセクションが維持される"
    else
        fail "プロジェクトセクションが維持される" "## Project Section" "$output"
    fi

    teardown
}

# テスト: 出力先を指定
test_output_to_different_path() {
    setup

    cat > "${TEST_DIR}/target.md" << 'EOF'
## Test

Content
EOF

    "$MERGE_SCRIPT" "${TEST_DIR}/target.md" -o "${TEST_DIR}/output.md" > /dev/null

    if [[ -f "${TEST_DIR}/output.md" ]]; then
        pass "出力先指定: ファイルが作成される"
    else
        fail "ファイルが作成される" "${TEST_DIR}/output.md" "ファイルなし"
    fi

    if grep -q "## Core Principles" "${TEST_DIR}/output.md"; then
        pass "出力先指定: Core Principles が含まれる"
    else
        fail "Core Principles が含まれる" "## Core Principles" "$(cat ${TEST_DIR}/output.md)"
    fi

    teardown
}

# テスト: 構造の確認（Core Principles -> プロジェクトセクション -> Maintenance Notes）
test_structure_order() {
    setup

    cat > "${TEST_DIR}/target.md" << 'EOF'
# AGENTS.md

## Core Principles

- Old

---

## メモリ運用ルール

Memory rules

## 禁止事項

Prohibitions

## Maintenance Notes

Old notes
EOF

    local output
    output=$("$MERGE_SCRIPT" "${TEST_DIR}/target.md" --dry-run)

    local core_pos memory_pos maintenance_pos
    core_pos=$(echo "$output" | grep -n "## Core Principles" | head -1 | cut -d: -f1)
    memory_pos=$(echo "$output" | grep -n "## メモリ運用ルール" | head -1 | cut -d: -f1)
    maintenance_pos=$(echo "$output" | grep -n "## Maintenance Notes" | head -1 | cut -d: -f1)

    if [[ $core_pos -lt $memory_pos ]]; then
        pass "構造: Core Principles がメモリ運用ルールより前"
    else
        fail "Core Principles がメモリ運用ルールより前" "core_pos < memory_pos" "core=$core_pos, memory=$memory_pos"
    fi

    if [[ $memory_pos -lt $maintenance_pos ]]; then
        pass "構造: メモリ運用ルールが Maintenance Notes より前"
    else
        fail "メモリ運用ルールが Maintenance Notes より前" "memory_pos < maintenance_pos" "memory=$memory_pos, maintenance=$maintenance_pos"
    fi

    teardown
}

# 全テスト実行
run_all_tests() {
    echo "=== merge.sh テスト ==="
    echo ""

    test_help
    test_target_not_exists
    test_merge_without_sections
    test_merge_with_project_sections
    test_with_template_file
    test_output_to_different_path
    test_structure_order

    echo ""
    echo "=== 全テスト完了 ==="
}

# クリーンアップ
trap teardown EXIT

run_all_tests
