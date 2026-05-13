#!/usr/bin/env bash
set -u
cmd="$(jq -r '.tool_input.command // ""')"
case " $cmd " in
  *" git "*|*";git "*|*"&& git "*|*"& git "*|*"|git "*|*"|| git "*) : ;;
  *) exit 0 ;;
esac
block() {
  printf 'BLOCKED by .claude/hooks/block-branch-mess.sh: %s\n' "$1" >&2
  printf 'Policy: all work happens on main.\n' >&2
  exit 2
}
echo "$cmd" | grep -qE '\bgit\b[^|;&]*\bcheckout[[:space:]]+-b\b'             && block "git checkout -b creates a branch"
echo "$cmd" | grep -qE '\bgit\b[^|;&]*\bcheckout[[:space:]]+-B\b'             && block "git checkout -B creates/resets a branch"
echo "$cmd" | grep -qE '\bgit\b[^|;&]*\bswitch[[:space:]]+(-c|-C|--create)\b' && block "git switch -c creates a branch"
echo "$cmd" | grep -qE '\bgit\b[^|;&]*\bworktree[[:space:]]+add\b'             && block "git worktree add creates a worktree"
echo "$cmd" | grep -qE '\bgit\b[^|;&]*\bbranch[[:space:]]+-m\b'                && block "git branch -m renames"
co="$(echo "$cmd" | grep -oE '\bgit\b[^|;&]*\bcheckout[[:space:]]+[^[:space:]-][^[:space:]]*' | head -1 | awk '{print $NF}')"
if [ -n "$co" ] && [ "$co" != "main" ] && [ "$co" != "HEAD" ]; then
  echo "$cmd" | grep -qE '\bgit\b[^|;&]*\bcheckout[[:space:]]+\S+[[:space:]]+--[[:space:]]' \
    || block "git checkout $co switches branches (only 'main' allowed)"
fi
sw="$(echo "$cmd" | grep -oE '\bgit\b[^|;&]*\bswitch[[:space:]]+[^[:space:]-][^[:space:]]*' | head -1 | awk '{print $NF}')"
if [ -n "$sw" ] && [ "$sw" != "main" ]; then
  block "git switch $sw switches branches (only 'main' allowed)"
fi
if echo "$cmd" | grep -qE '\bgit\b[^|;&]*\bbranch[[:space:]]+[^[:space:]-]'; then
  bn="$(echo "$cmd" | grep -oE '\bgit\b[^|;&]*\bbranch[[:space:]]+[^[:space:]-][^[:space:]]*' | head -1 | awk '{print $NF}')"
  block "git branch $bn creates a branch"
fi
exit 0
