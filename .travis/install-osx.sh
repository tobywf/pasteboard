#!/bin/bash
set -xeuo pipefail

for PYVER3 in "3.6.8" "3.7.2"; do
    # Python version number in different formats
    PYVER2=${PYVER3:0:3}

    PYINST="python-$PYVER3-macosx10.9.pkg"
    URL="https://www.python.org/ftp/python/$PYVER3/$PYINST"

    echo "$PYVER2 ($PYVER3) - $URL"
    wget --quiet "$URL"
    sudo installer -pkg "$PYINST" -target /

    CERT_CMD="/Applications/Python $PYVER2/Install Certificates.command"
    if [[ -e "$CERT_CMD" ]]; then
        sh "$CERT_CMD"
    fi

    ls -la "/Library/Frameworks/Python.framework/Versions/$PYVER2/bin/"
done

"/Library/Frameworks/Python.framework/Versions/3.6/bin/python3.6" -m venv env
set +u
# shellcheck disable=SC1091
source "env/bin/activate"
set -u

pip install -U tox
