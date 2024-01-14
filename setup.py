from setuptools import setup, Extension

pasteboard = Extension(
    "pasteboard._native",
    ["src/pasteboard/pasteboard.m"],
    extra_compile_args=[
        "-Wall",
        "-Wextra",
        "-Wpedantic",
        "-Werror",
    ],
    extra_link_args=["-framework", "AppKit"],
    language="objective-c",
)

setup(
    ext_modules=[pasteboard],
    zip_safe=False,
)
