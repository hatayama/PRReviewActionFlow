#!/bin/sh

# resolve-review.sh
# 指定した PR の未解決レビューコメントを GraphQL で取得し、
# resolve-review 系 slash command 用に 1 行 1 JSON オブジェクトとして標準出力に返すヘルパースクリプト。

set -eu

if [ "$#" -eq 0 ]; then
  printf 'Usage: %s <PR number or PR URL>\n' "$(basename "$0")" >&2
  exit 1
fi

readonly INPUT="$1"

OWNER="${OWNER:-}"
REPO="${REPO:-}"

ensure_repo_context() {
  if [ -n "$OWNER" ] && [ -n "$REPO" ]; then
    return
  fi

  repo_payload="$(gh repo view --json owner,name --jq '.owner.login + " " + .name' 2>/dev/null || true)"
  if [ -z "$repo_payload" ]; then
    return
  fi

  repo_owner=${repo_payload%% *}
  repo_name=${repo_payload##* }

  if [ -z "$OWNER" ] && [ -n "$repo_owner" ]; then
    OWNER="$repo_owner"
  fi

  if [ -z "$REPO" ] && [ -n "$repo_name" ]; then
    REPO="$repo_name"
  fi
}

ensure_repo_context

PR=""

case "$INPUT" in
  http://*|https://*)
    parsed="$(printf '%s' "$INPUT" | sed -E 's#^https?://github\\.com/([^/]+)/([^/]+)/pull/([0-9]+).*$#\1 \2 \3#')"
    if [ -n "$parsed" ]; then
      IFS=' ' read -r parsed_owner parsed_repo parsed_number <<EOF
$parsed
EOF
      if [ -z "$OWNER" ]; then
        OWNER="$parsed_owner"
      fi
      if [ -z "$REPO" ]; then
        REPO="$parsed_repo"
      fi
      if [ -z "$PR" ]; then
        PR="$parsed_number"
      fi
    fi

    if [ -z "$PR" ]; then
      PR="$(gh pr view "$INPUT" --json number -q .number 2>/dev/null || true)"
    fi
    ;;
  *)
    PR="$INPUT"
    ;;
esac

if [ -z "$OWNER" ] || [ -z "$REPO" ]; then
  printf 'owner/repo を特定できませんでした。OWNER/REPO を環境変数で指定してください\n' >&2
  exit 1
fi

if [ -z "$PR" ]; then
  printf 'PR を特定できませんでした。PR番号またはURLを指定してください\n' >&2
  exit 1
fi

gh api graphql \
  -F owner="$OWNER" -F repo="$REPO" -F pr="$PR" \
  -f query='
query($owner:String!, $repo:String!, $pr:Int!){
  repository(owner:$owner, name:$repo){
    pullRequest(number:$pr){
      reviewThreads(first: 100){
        nodes{
          isResolved
          isOutdated
          resolvedBy { login }
          comments(first: 100){
            nodes{
              databaseId
              author { login }
              path
              body
              line
              originalLine
              createdAt
            }
          }
        }
      }
    }
  }
}' \
  --jq '
.data.repository.pullRequest.reviewThreads.nodes[]
| select(.isResolved | not)
| . as $t
| $t.comments.nodes[]
| {
    resolved: $t.isResolved,
    outdated: $t.isOutdated,
    resolvedBy: ($t.resolvedBy.login // null),
    id: .databaseId,
    user: .author.login,
    path: .path,
    line: (.line // .originalLine),
    body: .body,
    createdAt
  }'


