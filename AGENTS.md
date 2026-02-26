# AGENTS.md

<!-- Do not restructure or delete sections. Update individual values in-place when they change. -->

## Core Principles

- **Do NOT maintain backward compatibility** unless explicitly requested. Break things boldly.
- **Keep this file under 20-30 lines of instructions.** Every line competes for the agent's limited context budget (~150-200 total).

---

## メモリ運用ルール

このプロジェクトでは、以下 5 ファイルを「プロジェクトメモリ」として扱う。

- `SPEC.md`: 何を作るか（プロダクト仕様）
- `PLAN.md`: どう作るか（実装計画・マイルストーン・リスク）
- `ARCHITECTURE.md`: 技術設計（構成・モジュール・設計判断）
- `RUNBOOK.md`: 実行/運用ルール（読み、常に従う）
- `STATUS.md`: 現在地・課題・次アクション（再開コンテキスト）

## 優先順位（衝突時）

1. `RUNBOOK.md`（実行ルール）
2. `SPEC.md`（要求仕様）
3. `ARCHITECTURE.md`（設計判断）
4. `PLAN.md`（進行計画）
5. `STATUS.md`（現状記録）

## 更新トリガー

- 仕様変更が入ったら: `SPEC.md` を更新
- 実装計画/マイルストーンが変わったら: `PLAN.md` を更新
- 構成・API 境界・責務が変わったら: `ARCHITECTURE.md` を更新
- 手順・運用方法が変わったら: `RUNBOOK.md` を更新
- 作業完了/課題発生/再開点が変わったら: `STATUS.md` を更新

## 作業開始時ルール

1. `STATUS.md` を最初に読む
2. `RUNBOOK.md` の運用ルールを確認する
3. 必要に応じて `SPEC.md` / `PLAN.md` / `ARCHITECTURE.md` を参照する
4. development skill を使用

## 作業終了時ルール

1. 実施内容と差分を確認する
2. 少なくとも `STATUS.md` の「最終更新日」「変更点」「次アクション」を更新する
3. 仕様/設計/手順に変更があれば対応するメモリファイルも同時更新する
4. ビルド、 make migrate, seed, container の rebuild など、必要な手順を RUNBOOK.md に従って実行する

## 記述ルール

- 言語は日本語で統一する
- 推測ではなく、確認できた事実を優先して記録する
- 長文より「判断に必要な要点」を優先する
- 古い記述は削除せず、必要なら「廃止/置換」を明記する

## 禁止事項

- `RUNBOOK.md` に反する手順を黙って実行しない
- 仕様変更を `SPEC.md` に反映せず実装だけ先行しない
- 進捗変更を `STATUS.md` に残さず作業を終了しない

## Maintenance Notes

<!-- This section is permanent. Do not delete. -->

**Keep this file lean and current:**

1. **Remove placeholder sections** (sections still containing `[To be determined]` or `[Add your ... here]`) once you fill them in
2. **Review regularly** - stale instructions poison the agent's context
3. **CRITICAL: Keep total under 20-30 lines** - move detailed docs to separate files and reference them
4. **Update commands immediately** when workflows change
5. **Rewrite Architecture section** when major architectural changes occur
6. **Delete anything the agent can infer** from your code

**Remember:** Coding agents learn from your actual code. Only document what's truly non-obvious or critically important.
