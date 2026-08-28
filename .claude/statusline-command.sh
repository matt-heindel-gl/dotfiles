#!/usr/bin/env bash
# Claude Code status line — styled after the robbyrussell oh-my-zsh theme
# Input: JSON from stdin

input=$(cat)

cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // ""')
dir=$(basename "$cwd")

# Git branch from the worktree field, or by running git in the cwd
branch=$(echo "$input" | jq -r '.worktree.branch // empty')
if [ -z "$branch" ] && [ -n "$cwd" ]; then
  branch=$(git --git-dir="$cwd/.git" --work-tree="$cwd" symbolic-ref --short HEAD 2>/dev/null || true)
fi

# Context window
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Rate limits (Claude.ai subscription)
five_h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')

# Build output
# Arrow + directory (cyan)
output=$(printf '\033[0;36m%s\033[0m' "$dir")

# Git branch (red/green)
if [ -n "$branch" ]; then
  output="$output $(printf '\033[0;32mgit:(\033[0;31m%s\033[0;32m)\033[0m' "$branch")"
fi

# Context used
if [ -n "$used_pct" ]; then
  output="$output $(printf '\033[0;33mctx:%.0f%%\033[0m' "$used_pct")"
fi

# 5-hour rate limit
if [ -n "$five_h" ]; then
  output="$output $(printf '\033[0;35m5h:%.0f%%\033[0m' "$five_h")"
fi

printf '%b\n' "$output"
