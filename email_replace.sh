#!/bin/bash
# Sets the notification email (#SBATCH --mail-user=...) in every .scr job script in the
# top level of this repository. The compile scripts in compile/ have no --mail-user line;
# wrf-compile.sh passes the email to them when it submits them.

set -euo pipefail

EMAIL="${1:-}"

if [[ -z "$EMAIL" ]]; then
    echo "Usage: bash $(basename "$0") <YOUR EMAIL>" >&2
    exit 1
fi
if [[ ! "$EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+$ ]]; then
    echo "Invalid email address: $EMAIL" >&2
    exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Matches "#SBATCH --mail-user=ADDRESS" and "#SBATCH --mail-user ADDRESS". The rest of the
# line is replaced, since the placeholder (<YOUR EMAIL HERE>) contains spaces.
MAIL_LINE='^(#SBATCH[[:space:]]+--mail-user[=[:space:]][[:space:]]*).*'

shopt -s nullglob
for f in "$REPO_DIR"/*.scr; do
    name="${f#"$REPO_DIR"/}"
    if grep -Eq "$MAIL_LINE" "$f"; then
        sed -Ei "s/$MAIL_LINE/\\1$EMAIL/" "$f"
        echo "$name: email set to $EMAIL"
    else
        echo "$name: no #SBATCH --mail-user line, skipped" >&2
    fi
done
