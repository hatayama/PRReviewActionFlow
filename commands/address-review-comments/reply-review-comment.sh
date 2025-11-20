#!/bin/sh

# PR のレビューコメントスレッドに GitHub REST API で返信するヘルパースクリプト。
# resolve-review-run.sh から呼び出され、元コメント ID からスレッドのルートコメントを特定して返信を投稿する。

set -eu

usage() {
  printf 'Usage: %s <comment-id> <reply message>\n' "$(basename "$0")" >&2
  printf 'Example: %s 123456 \"LGTM です\"\n' "$(basename "$0")" >&2
}

if [ "$#" -lt 2 ]; then
  usage
  exit 1
fi

readonly COMMENT_ID="$1"
shift

readonly MESSAGE="$*"

if [ -z "$MESSAGE" ]; then
  printf '返信本文を指定してください\n' >&2
  exit 1
fi

OWNER="${OWNER:-}"
REPO="${REPO:-}"

if [ -z "$OWNER" ]; then
  OWNER="$(gh repo view --json owner -q .owner.login 2>/dev/null || true)"
fi

if [ -z "$REPO" ]; then
  REPO="$(gh repo view --json name -q .name 2>/dev/null || true)"
fi

if [ -z "$OWNER" ] || [ -z "$REPO" ]; then
  printf 'owner/repo を特定できませんでした。OWNER/REPO を環境変数で指定してください\n' >&2
  exit 1
fi

comment_info="$(gh api \"repos/$OWNER/$REPO/pulls/comments/$COMMENT_ID\" 2>/dev/null || true)"

if [ -z "$comment_info" ]; then
  printf 'コメント %s の取得に失敗しました。gh api のログを確認してください\n' \"$COMMENT_ID\" >&2
  exit 1
fi

root_comment_id=\"$(printf '%s' \"$comment_info\" | jq -r '(.in_reply_to_id // .id)')\"

if [ -z \"$root_comment_id\" ] || [ \"$root_comment_id\" = \"null\" ]; then
  printf 'コメント %s を特定できませんでした。ID が正しいか確認してください\n' \"$COMMENT_ID\" >&2
  exit 1
fi

pull_request_url=\"$(printf '%s' \"$comment_info\" | jq -r '.pull_request_url')\"
pull_number=\"$(printf '%s' \"$pull_request_url\" | sed -E 's#.*/pulls/([0-9]+)$#\1#')\"

if [ -z \"$pull_number\" ] || [ \"$pull_number\" = \"null\" ]; then
  printf 'PR番号を特定できませんでした\n' >&2
  exit 1
fi

if ! reply_url=\"$(gh api \
  --method POST \
  \"repos/$OWNER/$REPO/pulls/$pull_number/comments/$root_comment_id/replies\" \
  --raw-field body=\"$MESSAGE\" \
  --jq '.html_url')\" ; then
  printf '返信投稿に失敗しました。gh api のログを確認してください\n' >&2
  exit 1
fi

printf '返信を投稿しました: %s\n' \"$reply_url\"

