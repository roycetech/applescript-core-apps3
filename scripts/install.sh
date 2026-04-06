#!/bin/bash
# Created: Sat, Dec 06, 2025, at 01:14:28 PM
#
# @Purpose:
# 	Install the core apps3 libraries directly from the web.

set -e

PROJECT_CORE_DIR="$HOME/Projects/@roycetech/applescript-core"

if [ ! -d "$PROJECT_CORE_DIR" ]; then
    echo "E: applescript-core project was not found"
    exit 1
fi

PROJECT_DIR="$HOME/Projects/@roycetech/applescript-core-apps3"
REPO_URL="https://github.com/roycetech/applescript-core-apps3"

if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning lightweight repository..."
    git clone --depth=1 "$REPO_URL" "$PROJECT_DIR"
else
    echo "Updating lightweight repository..."
    git -C "$REPO_DIR" pull --depth=1 --rebase
fi

sudo mkdir -p /Library/Script\ Libraries/core/test
sudo mkdir -p /Library/Script\ Libraries/core/app

echo "Adding $(whoami) to the wheel group and allowing group write access to the Script Libraries folder..."
sudo dseditgroup -o edit -a "$(whoami)" -t user wheel \
  && sudo chmod g+w "/Library/Script Libraries" \
  && sudo chmod g+w "/Library/Script Libraries/core" \
  && sudo chmod g+w "/Library/Script Libraries/core/test" \
  && sudo chmod g+w "/Library/Script Libraries/core/app"

cd "$PROJECT_DIR"
make set-computer-deploy-type install
