#!/usr/bin/env bash

set -ex
clang test.m -framework AppKit -Wall -Wextra -Wpedantic -Werror -working-directory=$PWD -o test
./test
