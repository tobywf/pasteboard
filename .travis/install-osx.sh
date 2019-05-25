#!/bin/bash
set -xeuo pipefail

for PYVER3 in "3.6.8" "3.7.3" "3.8.0"; do
    # Python version number in different formats
    PYVER2=${PYVER3:0:3}

    if [[ "$PYVER3" == "3.8.0" ]]; then
        PYINST="python-3.8.0a4-macosx10.9.pkg"
    else
        PYINST="python-$PYVER3-macosx10.9.pkg"
    fi

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
