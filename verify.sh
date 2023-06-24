#!/usr/bin/env bash
set -euo pipefail

git diff $(git merge-base origin/master upstream/master)..origin/master \
    --diff-filter=d \
    ':(exclude)README.md' \
    ':(exclude)build.zig' \
    ':(exclude)build.zig.zon' \
    ':(exclude).github' \
    ':(exclude).gitattributes' \
    ':(exclude).gitignore'
