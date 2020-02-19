import sys
from distutils.core import Extension

assert sys.platform == "darwin", "pasteboard only works on macOS"

pasteboard = Extension(
    "pasteboard._native",
    ["src/pasteboard/pasteboard.m"],
    extra_link_args=["-framework", "AppKit"],
    language="objective-c",
)


def build(setup_kwargs):
    setup_kwargs["ext_modules"] = [pasteboard]
