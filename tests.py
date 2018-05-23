import pasteboard
import pytest

from hypothesis import assume, given, strategies as st

STRING_TYPES = (pasteboard.String, pasteboard.RTF, pasteboard.HTML, pasteboard.TabularText)
BINARY_TYPES = (pasteboard.PDF, pasteboard.PNG, pasteboard.TIFF)

# no null characters, no control characters, no surrogate characters
TEXT = st.characters(min_codepoint=1, blacklist_categories=('Cc', 'Cs'))


@given(TEXT)
def test_get_set_contents_default(s):
    assume(s.encode('utf-8'))
    pb = pasteboard.Pasteboard()
    assert pb.set_contents(s)
    assert pb.get_contents() == s


@given(TEXT)
def test_get_contents_diff_not_none_after_set(s):
    pb = pasteboard.Pasteboard()
    assert pb.set_contents(s)
    assert pb.get_contents(diff=True) == s
    assert pb.get_contents(diff=True) is None


@pytest.mark.parametrize('type', STRING_TYPES)
@given(TEXT)
def test_get_set_contents_string(type, s):
    pb = pasteboard.Pasteboard()
    assert pb.set_contents(s, type=type)
    assert pb.get_contents(type=type) == s
    assert pb.get_contents(type=type, diff=True) is None


@pytest.mark.parametrize('type', BINARY_TYPES)
@given(st.binary())
def test_get_set_contents_data(type, s):
    pb = pasteboard.Pasteboard()
    assert pb.set_contents(s, type=type)
    assert pb.get_contents(type=type) == s
    assert pb.get_contents(type=type, diff=True) is None


def test_get_set_contents_with_null_char():
    pb = pasteboard.Pasteboard()
    assert pb.set_contents('abc\x00def')
    assert pb.get_contents() == 'abc'


def test_get_set_contents_with_emoji_santa():
    s = '\x1f385'
    pb = pasteboard.Pasteboard()
    assert pb.set_contents(s)
    assert pb.get_contents() == s


@pytest.mark.parametrize('type,name', [
    (pasteboard.String, 'public.utf8-plain-text'),
    (pasteboard.RTF, 'public.rtf'),
    (pasteboard.HTML, 'public.html'),
    (pasteboard.TabularText, 'public.utf8-tab-separated-values-text'),
    (pasteboard.PDF, 'com.adobe.pdf'),
    (pasteboard.PNG, 'public.png'),
    (pasteboard.TIFF, 'public.tiff'),
])
def test_types_repr(type, name):
    assert repr(type) == "<PasteboardType {}>".format(name)
