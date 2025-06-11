#!/bin/bash

# Usage: ./DeepCompare.sh /path/to/dir1 /path/to/dir2

# set -e

DIR1="$1"
DIR2="$2"
HASH_CMD="md5sum"

if [[ -z "$DIR1" || -z "$DIR2" ]]; then
  echo "Usage: $0 <dir1> <dir2>"
  exit 1
fi

if [[ ! -d "$DIR1" || ! -d "$DIR2" ]]; then
  echo "Both arguments must be directories."
  exit 1
fi

echo "Comparing directories:"
echo "  DIR1: $DIR1"
echo "  DIR2: $DIR2"
echo

# Get list of all files relative to DIR1
echo "[INFO] Building file list from $DIR1 ..."
mapfile -t FILES1 < <(cd "$DIR1" && find . -type f | sort)
echo "[INFO] Found ${#FILES1[@]} files in $DIR1"

# Get list of all files relative to DIR2
echo "[INFO] Building file list from $DIR2 ..."
mapfile -t FILES2 < <(cd "$DIR2" && find . -type f | sort)
echo "[INFO] Found ${#FILES2[@]} files in $DIR2"

echo
echo "[INFO] Starting comparison..."

DIFF_COUNT=0

for REL_PATH in "${FILES1[@]}"; do
  FILE1="$DIR1/$REL_PATH"
  FILE2="$DIR2/$REL_PATH"

  if [[ ! -f "$FILE2" ]]; then
    printf "\r\033[K[MISSING] %s is missing in %s" "$REL_PATH" "$DIR2"
    echo ""
    ((DIFF_COUNT++))
    continue
  fi

  printf "\r\033[K[CHECKING] %s" "$REL_PATH"
  HASH1=$($HASH_CMD "$FILE1" | awk '{print $1}')
  HASH2=$($HASH_CMD "$FILE2" | awk '{print $1}')

  if [[ "$HASH1" != "$HASH2" ]]; then
    printf "\r\033[K[DIFF] %s differs:" "$REL_PATH"
    echo "       $DIR1 hash: $HASH1"
    echo "       $DIR2 hash: $HASH2"
    ((DIFF_COUNT++))
  fi
done

# Now check for extra files in DIR2
for REL_PATH in "${FILES2[@]}"; do
  if [[ ! -f "$DIR1/$REL_PATH" ]]; then
    printf "\r\033[K[EXTRA] %s exists in %s but not in %s" "$REL_PATH" "$DIR2" "$DIR1"
    ((DIFF_COUNT++))
  fi
done

echo
if [[ "$DIFF_COUNT" -eq 0 ]]; then
  echo "[SUCCESS] All files match!"
else
  echo "[SUMMARY] Found $DIFF_COUNT differences."
fi

