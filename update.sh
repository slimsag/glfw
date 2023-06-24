#!/usr/bin/env bash
set -euo pipefail

git remote add upstream https://github.com/glfw/glfw || true
git fetch upstream
git merge upstream/master --strategy ours
