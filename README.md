# PR Review Action Flow

GitHub の PR レビューコメントを集約し、コード修正と返信までを Claude Code から行うためのプラグインです。

このリポジトリは、Claude Code の **plugin marketplace** としても利用できます。

## 主な機能

- 未解決のレビューコメント一覧を取得
- 各コメントの妥当性判断（suggestion も含めて精査）
- 必要なコード修正の適用
- 対応内容を含むレビューコメントへの返信

詳しいフローやコマンド仕様は、`commands/address-review-comments.md` を参照してください。

## インストール方法（Claude Code Plugin Marketplace 経由）

1. Claude Code のチャットで、次のコマンドを実行して marketplace を追加します:

   ```bash
   /plugin marketplace add hatayama/PRReviewActionFlow
   ```

2. 続いて **PR Review Action Flow** プラグインをインストールします（プラグイン ID は `pr-review-action-flow` を想定）:

   ```bash
   /plugin install pr-review-action-flow
   ```

3. インストール後は、`/address-review-comments <PR URL> [GitHub username]` のコマンドで利用できます。

## ディレクトリ構成

```text
.
├── .claude-plugin/
│   └── marketplace.json                 # PR Review Action Flow を公開するための marketplace 定義
├── commands/
│   ├── address-review-comments.md       # スラッシュコマンド定義 & 詳細ドキュメント
│   └── address-review-comments/
│       ├── get-review-comments.sh       # 未解決レビューコメント取得
│       └── reply-review-comment.sh      # レビューコメントへの返信
└── LICENSE
```


