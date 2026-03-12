---
name: linear-curl-issue-ops
description: Linear の GraphQL API を curl で操作して issue の作成・一覧取得・更新を行う。Linear MCP の書き込みが不安定なとき、PAT を使って確実に起票/更新したいとき、Keychain から `linear-api-key` を読み出して自動実行したいときに使用する。
---

# Linear Curl Issue Ops

## 概要

Linear API を `curl` で直接実行する。`viewer`/`project` の疎通確認、単発 issue 作成、JSON からの一括 issue 作成を定型化する。

## 前提

1. PAT を Keychain に保存する。

```bash
security add-generic-password -a "$USER" -s "linear-api-key" -w "lin_api_xxx" -U
```

2. 実行時は Keychain から読み出す。

```bash
export LINEAR_API_KEY="$(security find-generic-password -s "linear-api-key" -w)"
```

3. `jq` を利用する。

## ワークフロー

1. 認証疎通を確認する。
   `scripts/linear_graphql.sh 'query { viewer { id name email } }'`
2. 対象 team / project を解決する。
   `scripts/linear_graphql.sh 'query { projects(filter:{name:{eq:"$PROJECT_NAME"}}){nodes{id name teams{nodes{id key name}}}} }'`
3. issue を作成する。単発は GraphQL mutation、複数は `scripts/create_issues_from_json.sh` を使う。

## 主要スクリプト

### `scripts/linear_graphql.sh`

- 役割: 任意の GraphQL Query/Mutation を実行する。
- 入力: GraphQL 文字列（必須）、variables JSON 文字列（任意）。

### `scripts/create_issues_from_json.sh`

- 役割: JSON ファイルから issue を一括作成する。
- 入力:
  - `--team-id`
  - `--project-id`
  - `--file` (`[{\"title\":\"...\",\"description\":\"...\"}]`)
- 出力: `identifier`, `title`, `url` の TSV。

## 実行例

```bash
# 1) viewer 疎通
.agents/skills/linear-curl-issue-ops/scripts/linear_graphql.sh \
  'query { viewer { id name email } }'

# 2) JSON から一括作成
.agents/skills/linear-curl-issue-ops/scripts/create_issues_from_json.sh \
  --team-id "" \
  --project-id "" \
  --file ".agents/skills/linear-curl-issue-ops/references/issues.sample.json"
```

## 失敗時の確認

1. `security find-generic-password -s "linear-api-key" -w` が値を返すか確認する。
2. `LINEAR_API_KEY` が空でないか確認する。
3. GraphQL エラーはレスポンスの `errors[]` を優先して読む。
