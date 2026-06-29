#!/usr/bin/env sh
set -eu

if [ "$#" -lt 3 ]; then
  printf '%s\n' 'usage: check_generated_artifacts.sh PASS_MESSAGE GENERATE_COMMAND PATH...' >&2
  exit 2
fi

pass_message=$1
shift
generate_command=$1
shift

tmp=${TMPDIR:-/tmp}/project-tools-generated-check.$$
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp"

# GENERATE_COMMAND receives the temporary output directory as its only argument.
sh -c "$generate_command" generated-check "$tmp"

for path in "$@"; do
  if ! cmp -s "$tmp/$path" "$path"; then
    printf 'generated artifact differs: %s\n' "$path" >&2
    diff -u "$path" "$tmp/$path" >&2 || true
    exit 1
  fi
done

printf '%s\n' "$pass_message"
