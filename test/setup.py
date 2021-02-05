import sys
import os
from distutils.core import setup, Extension

assert sys.platform == "darwin"

pbtest = Extension(
    "pbtest",
    ["pbtest.m"],
    extra_compile_args=[
        "-Wall",
        "-Wextra",
        "-Wpedantic",
        "-Werror",
        f"-working-directory={os.getcwd()}",
    ],
    extra_link_args=["-framework", "AppKit"],
    language="objective-c",
)

setup(
    name="pbtest",
    version="1.0",
    description="This is a demo package",
    ext_modules=[pbtest],
    zip_safe=False,
)
