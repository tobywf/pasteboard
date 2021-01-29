import pasteboard
import pytest
import mypy.api

from hypothesis import given, strategies as st
from pasteboard import Pasteboard, PasteboardType
from pathlib import Path
from typing import Tuple

STRING_TYPES = (
    pasteboard.String,
    pasteboard.RTF,
    pasteboard.HTML,
    pasteboard.TabularText,
)
BINARY_TYPES = (pasteboard.PDF, pasteboard.PNG, pasteboard.TIFF)

# no null characters, no control characters, no surrogate characters
TEXT = st.characters(min_codepoint=1, blacklist_categories=("Cc", "Cs"))


@given(TEXT)
def test_get_set_contents_default(s: str) -> None:
    pb = Pasteboard()
    assert pb.set_contents(s)
    assert pb.get_contents() == s


@given(TEXT)
def test_get_contents_diff_not_none_after_set(s: str) -> None:
    pb = Pasteboard()
    assert pb.set_contents(s)
    assert pb.get_contents(diff=True) == s
    assert pb.get_contents(diff=True) is None


@pytest.mark.parametrize("type", STRING_TYPES)
@given(TEXT)
def test_get_set_contents_string(type: PasteboardType, s: str) -> None:
    pb = Pasteboard()
    assert pb.set_contents(s, type=type)
    assert pb.get_contents(type=type) == s
    assert pb.get_contents(type=type, diff=True) is None


@pytest.mark.parametrize("type", BINARY_TYPES)
@given(st.binary())
def test_get_set_contents_data(type: PasteboardType, b: bytes) -> None:
    pb = Pasteboard()
    assert pb.set_contents(b, type=type)
    assert pb.get_contents(type=type) == b
    assert pb.get_contents(type=type, diff=True) is None


def test_get_set_contents_with_null_char() -> None:
    pb = Pasteboard()
    assert pb.set_contents("abc\x00def")
    assert pb.get_contents() == "abc"


def test_get_set_contents_with_emoji_santa() -> None:
    s = "\x1f385"
    pb = Pasteboard()
    assert pb.set_contents(s)
    assert pb.get_contents() == s


@pytest.mark.parametrize(
    "type,name",
    [
        (pasteboard.String, "public.utf8-plain-text"),
        (pasteboard.RTF, "public.rtf"),
        (pasteboard.HTML, "public.html"),
        (pasteboard.TabularText, "public.utf8-tab-separated-values-text"),
        (pasteboard.PDF, "com.adobe.pdf"),
        (pasteboard.PNG, "public.png"),
        (pasteboard.TIFF, "public.tiff"),
    ],
)
def test_types_repr(type: PasteboardType, name: str) -> None:
    assert repr(type) == f"<PasteboardType {name}>"


def test_file_urls() -> None:
    pb = Pasteboard()
    assert pb.set_contents("abc\x00def")
    assert pb.get_file_urls() is None
    assert pb.get_file_urls(diff=True) is None


def mypy_run(tmp_path: Path, content: str) -> Tuple[str, str, int]:
    py = tmp_path / "test.py"
    py.write_text(content)
    filename = str(py)
    normal_report, error_report, exit_status = mypy.api.run([filename, "--strict"])
    return normal_report.replace(filename, "test.py"), error_report, exit_status


def test_type_hints_pasteboard_valid(tmp_path: Path) -> None:
    normal_report, error_report, exit_status = mypy_run(
        tmp_path,
        """
from pasteboard import Pasteboard
pb = Pasteboard()
""",
    )
    assert exit_status == 0, normal_report


def test_type_hints_pasteboard_invalid_args(tmp_path: Path) -> None:
    normal_report, error_report, exit_status = mypy_run(
        tmp_path,
        """
from pasteboard import Pasteboard
pb = Pasteboard("bar")
""",
    )
    assert exit_status == 1, normal_report
    assert 'Too many arguments for "Pasteboard"' in normal_report


def test_type_hints_pasteboard_invalid_kwargs(tmp_path: Path) -> None:
    normal_report, error_report, exit_status = mypy_run(
        tmp_path,
        """
from pasteboard import Pasteboard
pb = Pasteboard(foo="bar")
""",
    )
    assert exit_status == 1, normal_report
    assert 'Unexpected keyword argument "foo" for "Pasteboard"' in normal_report


def test_type_hints_get_contents_valid_no_args(tmp_path: Path) -> None:
    normal_report, error_report, exit_status = mypy_run(
        tmp_path,
        """
from pasteboard import Pasteboard
from typing import Optional
pb = Pasteboard()
s: Optional[str] = pb.get_contents()
""",
    )
    assert exit_status == 0, normal_report


def test_type_hints_get_contents_valid_diff_arg(tmp_path: Path) -> None:
    normal_report, error_report, exit_status = mypy_run(
        tmp_path,
        """
from pasteboard import Pasteboard
pb = Pasteboard()
s = pb.get_contents(diff=True)
if s:
    s += "foo"
""",
    )
    assert exit_status == 0, normal_report


def test_type_hints_get_contents_valid_type_args(tmp_path: Path) -> None:
    normal_report, error_report, exit_status = mypy_run(
        tmp_path,
        """
from pasteboard import Pasteboard, PNG
from typing import Union
pb = Pasteboard()
s = pb.get_contents(type=PNG)
if s:
    if isinstance(s, str):
        s += "foo"
    else:
        s += b"foo"
""",
    )
    assert exit_status == 0, normal_report


def test_type_hints_get_contents_valid_both_args(tmp_path: Path) -> None:
    normal_report, error_report, exit_status = mypy_run(
        tmp_path,
        """
from pasteboard import Pasteboard, PNG
from typing import Union
pb = Pasteboard()
s = pb.get_contents(type=PNG, diff=True)
if s:
    if isinstance(s, str):
        s += "foo"
    else:
        s += b"foo"
""",
    )
    assert exit_status == 0, normal_report


@pytest.mark.parametrize("arg", ['"bar"', 'foo="bar"', 'type="bar"', 'diff="bar"'])
def test_type_hints_get_contents_invalid_arg(arg: str, tmp_path: Path) -> None:
    normal_report, error_report, exit_status = mypy_run(
        tmp_path,
        f"""
from pasteboard import Pasteboard
pb = Pasteboard()
pb.get_contents({arg})
""",
    )
    assert exit_status == 1, normal_report
    assert "No overload variant" in normal_report


@pytest.mark.parametrize("arg", ['"bar"', 'b"bar"'])
def test_type_hints_set_contents_valid_no_args(arg: str, tmp_path: Path) -> None:
    normal_report, error_report, exit_status = mypy_run(
        tmp_path,
        f"""
from pasteboard import Pasteboard
pb = Pasteboard()
result: bool = pb.set_contents({arg})
""",
    )
    assert exit_status == 0, normal_report


@pytest.mark.parametrize("arg", ['"bar"', 'b"bar"'])
def test_type_hints_set_contents_valid_type_args(arg: str, tmp_path: Path) -> None:
    normal_report, error_report, exit_status = mypy_run(
        tmp_path,
        f"""
from pasteboard import Pasteboard, PNG
pb = Pasteboard()
result: bool = pb.set_contents({arg}, type=PNG)
""",
    )
    assert exit_status == 0, normal_report


def test_type_hints_set_contents_invalid_arg(tmp_path: Path) -> None:
    normal_report, error_report, exit_status = mypy_run(
        tmp_path,
        f"""
from pasteboard import Pasteboard
pb = Pasteboard()
result: bool = pb.set_contents(0)
""",
    )
    assert exit_status == 1, normal_report
    assert '"set_contents" of "Pasteboard" cannot be "int"' in normal_report


def test_type_hints_set_contents_invalid_type_arg(tmp_path: Path) -> None:
    normal_report, error_report, exit_status = mypy_run(
        tmp_path,
        f"""
from pasteboard import Pasteboard
pb = Pasteboard()
result: bool = pb.set_contents("", type="bar")
""",
    )
    assert exit_status == 1, normal_report
    msg = 'Argument "type" to "set_contents" of "Pasteboard" has incompatible type "str"; expected "PasteboardType'
    assert msg in normal_report


def test_type_hints_set_contents_invalid_kwarg(tmp_path: Path) -> None:
    normal_report, error_report, exit_status = mypy_run(
        tmp_path,
        f"""
from pasteboard import Pasteboard
pb = Pasteboard()
result: bool = pb.set_contents("", foo="bar")
""",
    )
    assert exit_status == 1, normal_report
    assert (
        'Unexpected keyword argument "foo" for "set_contents" of "Pasteboard"'
        in normal_report
    )


def test_type_hints_set_contents_invalid_result(tmp_path: Path) -> None:
    normal_report, error_report, exit_status = mypy_run(
        tmp_path,
        f"""
from pasteboard import Pasteboard
pb = Pasteboard()
result: str = pb.set_contents("")
""",
    )
    assert exit_status == 1, normal_report
    assert (
        'Incompatible types in assignment (expression has type "bool", variable has type "str")'
        in normal_report
    )
