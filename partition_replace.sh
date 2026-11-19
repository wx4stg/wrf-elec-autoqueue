#!/bin/bash
# Sets the Slurm partition (#SBATCH --partition=... or #SBATCH -p ...) in every .scr job
# script in this repository, including the compile scripts in compile/.
# Only the partition changes: task counts and memory requests are left as they are,
# so check that they still fit the new partition's nodes.

set -euo pipefail

PARTITION="${1:-}"

if [[ -z "$PARTITION" ]]; then
    echo "Usage: bash $(basename "$0") <PARTITION NAME>" >&2
    exit 1
fi
if [[ ! "$PARTITION" =~ ^[A-Za-z0-9_.-]+$ ]]; then
    echo "Invalid partition name: $PARTITION (only letters, numbers, '_', '.' and '-' are allowed)" >&2
    exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Matches "#SBATCH --partition=NAME", "#SBATCH --partition NAME" and "#SBATCH -p NAME"
PARTITION_LINE='^(#SBATCH[[:space:]]+)(--partition[=[:space:]][[:space:]]*|-p[[:space:]]+)[^[:space:]]+'

shopt -s nullglob
for f in "$REPO_DIR"/*.scr "$REPO_DIR"/compile/*.scr; do
    name="${f#"$REPO_DIR"/}"
    if grep -Eq "$PARTITION_LINE" "$f"; then
        sed -Ei "s/$PARTITION_LINE/\\1\\2$PARTITION/" "$f"
        echo "$name: partition set to $PARTITION"
    else
        echo "$name: no #SBATCH partition line, skipped" >&2
    fi
done
