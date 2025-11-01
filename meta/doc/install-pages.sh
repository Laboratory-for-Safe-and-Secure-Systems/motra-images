#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# Prevent errors in a pipeline from being masked.
set -o pipefail

# TODO setup bash comp

# --- Configuration ---
# Add the directories containing your custom *.md pages here
# Use full paths for reliability
declare -a CUSTOM_PAGE_DIRS=(
    "pages/"
)
# --- End Configuration ---

# Function to print error messages to stderr
error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

# Check if tldr command exists
if ! command -v tldr >/dev/null 2>&1; then
    error_exit "'tldr' command not found. Please install tldr."
fi

# Update tldr pages and capture output
echo "Updating tldr pages..."
# Use '|| true' temporarily if tldr -u sometimes exits non-zero even on success/no change
# A better approach might be to check the specific exit code if known.
# For now, we capture output regardless and check for the expected line.
update_output=$(tldr -u) || echo "tldr --update finished (exit code $?). Continuing..."

echo "tldr update output:"
echo "$update_output"
echo "---------------------"

# Extract the tldr pages path using regex
echo "Attempting to extract tldr path..."
# Regex explanation:
# Matches the literal string "Downloading tldr pages to "
# Then captures (in group 1) a sequence starting with '/' followed by one or more
# non-whitespace characters. This should robustly capture the path.
regex="^Downloading tldr pages to (\/[a-z0-9\/.]+)"
tldr_path=""

if [[ "$update_output" =~ $regex ]]; then
    tldr_path=${BASH_REMATCH[1]}
    echo "Successfully extracted tldr path: $tldr_path"
else
    error_exit "Could not extract tldr path from the update output. Regex did not match."
fi

# Define the target directory for Linux pages
target_dir="${tldr_path}/pages/linux"
echo "Target directory for custom pages: $target_dir"

# Copy custom pages from source directories
echo "Copying custom pages..."
count=0
for src_dir in "${CUSTOM_PAGE_DIRS[@]}"; do
    echo "Checking source directory: $src_dir"
    if [ ! -d "$src_dir" ]; then
        echo "WARNING: Source directory '$src_dir' not found. Skipping." >&2
        continue
    fi

    # Find and copy .md files, handle case where no *.md files exist gracefully
    # Using find is robust. -maxdepth 1 prevents recursion.
    # -exec cp -vt "$target_dir" {} + copies files efficiently to the target.
    echo "Searching for *.md files in '$src_dir'..."
    find "$src_dir" -maxdepth 1 -name '*.md' -print0 | while IFS= read -d $'\0' file; do
        echo "  Copying '$file' to '$target_dir/'"
        if ! cp "$file" "$target_dir/"; then
            echo "WARNING: Failed to copy '$file'. Continuing..." >&2
        fi
    done 
done

echo "---------------------"
echo "Successfully copied custom pages to $target_dir."
echo "Script finished."
exit 0