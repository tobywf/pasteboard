from typing import overload, AnyStr, Optional, Union


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
    def get_contents(self) -> str: ...

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
