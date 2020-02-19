import sys as _sys

assert _sys.platform == "darwin", "pasteboard only works on macOS"

from ._native import *
