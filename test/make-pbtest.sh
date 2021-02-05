#!/usr/bin/env bash
set -ex

python3 -m venv env
env/bin/python3 setup.py install
# if the interpreter exists immediately, to works
env/bin/python3 -c 'import pbtest; pbtest.test()'
