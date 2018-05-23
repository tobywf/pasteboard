"""Pasteboard - Python interface for reading from NSPasteboard (macOS clipboard)."""
from setuptools import setup, Extension
import os.path
import sys

assert sys.platform == 'darwin'

readme_path = os.path.abspath(os.path.join(os.path.dirname(__file__), 'README.rst'))
with open(readme_path, encoding='utf-8') as f:
    readme = f.read()

pasteboard = Extension(
    'pasteboard',
    ['pasteboard.m'],
    extra_link_args=['-framework', 'AppKit'],
    language='objective-c',
)

setup(
    name='pasteboard',
    version='0.2.0',
    description=__doc__,
    long_description=readme,
    author='Toby Fleming',
    author_email='tobywf@users.noreply.github.com',
    url='https://github.com/tobywf/pasteboard',
    license='GPLv3',
    ext_modules=[pasteboard],
    classifiers=[
        'Development Status :: 4 - Beta',
        'Environment :: MacOS X :: Cocoa',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: GNU General Public License v3 (GPLv3)',
        'Natural Language :: English',
        'Operating System :: MacOS :: MacOS X',
        'Programming Language :: Objective C',
        'Programming Language :: Python :: 3 :: Only',
        'Programming Language :: Python :: Implementation :: CPython',
        'Topic :: Desktop Environment',
        'Topic :: Software Development :: Libraries',
    ],
    keywords='macOS clipboard pasteboard',
)
