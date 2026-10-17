#!/bin/bash
set -euo pipefail
gcc -std=c11 -Wall -Wextra -Werror -o /workspace/hello /workspace/hello.c > /workspace/build.log 2>&1
