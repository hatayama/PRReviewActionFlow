---
description: "PRのレビューコメントを確認し、妥当性を判断して適切に対応します"
allowed_tools: Bash(commands/address-review-comments/*), Bash(git:*), Bash(gh:*), Read, Edit, Write, AskUserQuestion
model: sonnet
---

PRのレビューコメントを確認し、適切な対応を行います。

## コマンド形式

```
/address-review-comments <PR URL> [GitHub username]
```

- **PR URL**: 対応するPRのURL（必須）
- **GitHub username**: 使用するGitHubアカウント名（オプション）
  - 指定した場合、自動的に `gh auth switch --user <username>` を実行

### 使用例

```bash
# デフォルトアカウントで実行
/address-review-comments https://github.com/your-org/your-repo/pull/13249

# user-a アカウントに切り替えて実行
/address-review-comments https://github.com/your-org/your-repo/pull/13249 user-a

# user-b アカウントに切り替えて実行
/address-review-comments https://github.com/your-org/your-repo/pull/13249 user-b
```

## 基本フロー

0. **GitHubアカウントの切り替え**（username指定時のみ）
   ```bash
   gh auth switch --user <username>
   ```
   - 指定されたGitHubアカウントに切り替え

1. **未解決レビューコメントの取得**
   ```bash
   commands/address-review-comments/get-review-comments.sh <PR URL>
   ```
   - 未解決のレビューコメント一覧を取得

2. **各コメントの精査と妥当性判断**
   - 各コメントの内容を読み、技術的妥当性を判断
   - ```suggestion ブロックがあっても、その内容が適切かを必ず確認
   - ✅ **妥当な指摘**: 修正を適用（ステップ3へ）
   - ❌ **不当な指摘**: 理由をユーザーに説明（ステップ4へ）

3. **妥当な指摘への対応**
   - Edit/Write ツールを使って該当箇所を修正
   - 修正内容をユーザーに提示
   - **👤 ユーザー確認を取る**: 「この修正で commit・push してよいか？」
   - OK が出たら commit・push を実行
   - `reply-review-comment.sh` で返信（該当コミットSHAを含める）

4. **不当な指摘への対応**
   - 不当と判断した理由をユーザーに説明
   - ユーザーの承認を得てから、`reply-review-comment.sh` で返信

## 重要な注意事項

- ✅ **AI が自分で判断して Edit ツールで修正を適用する**
- ✅ **```suggestion ブロックの内容も無批判に受け入れない**
- ✅ **必ずユーザー確認を経てから commit・push する**
- ✅ **レビューコメントを無批判に受け入れない**

## 実行前の準備

gh コマンドの認証が設定されていることを確認してください：

```bash
gh auth status || gh auth login
```

**注意**: アカウント切り替えが必要な場合は、コマンドの2つ目の引数にGitHubユーザー名を指定してください。

このコマンドは、リポジトリのルートに `commands/address-review-comments/` が存在することを前提としています。

## レビューコメントへの返信

修正を commit・push した後、レビューコメントに返信：

```bash
commands/address-review-comments/reply-review-comment.sh <COMMENT_ID> "返信本文"
```

返信メッセージには必ず以下を含めること：
- 該当コミットのSHA（短縮版）
- 何を修正したかの説明

## 開発者向け情報  
### スクリプト構成  
- **get-review-comments.sh**: 未解決コメント取得
- **reply-review-comment.sh**: レビューコメント返信

## Claude Code Plugin Marketplace からの利用方法

このリポジトリを Claude Code の plugin marketplace として追加すると、**PR Review Action Flow** プラグインを簡単にインストールできます。

1. Claude Code のチャットで、次のコマンドを実行して marketplace を追加します（`your-username` は実際の GitHub ユーザー名や org 名に置き換えてください）:

   ```bash
   /plugin marketplace add hatayama/PRReviewActionFlow
   ```

2. 続いて **PR Review Action Flow** プラグインをインストールします（プラグイン ID は `pr-review-action-flow` を想定）:

   ```bash
   /plugin install pr-review-action-flow
   ```

3. インストール後は、これまで通り `/address-review-comments <PR URL> [GitHub username]` のコマンド形式で利用できます。


