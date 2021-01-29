# Pasteboard - Python interface for reading from NSPasteboard (macOS clipboard)
# Copyright (C) 2017-2021  Toby Fleming
# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
from typing import overload, AnyStr, Optional, Sequence, Union

class PasteboardType: ...

HTML: PasteboardType
PDF: PasteboardType
PNG: PasteboardType
RTF: PasteboardType
String: PasteboardType
TIFF: PasteboardType
TabularText: PasteboardType

class Pasteboard:
    @classmethod
    def __init__(self) -> None: ...
    @overload
    def get_contents(
        self,
        diff: bool = ...,
    ) -> Optional[str]: ...
    @overload
    def get_contents(
        self,
        type: PasteboardType = ...,
        diff: bool = ...,
    ) -> Union[str, bytes, None]: ...
    def set_contents(
        self,
        data: AnyStr,
        type: PasteboardType = ...,
    ) -> bool: ...
    def get_file_urls(
        self,
        diff: bool = ...,
    ) -> Optional[Sequence[str]]: ...
