# Pasteboard

[![License: MPL 2.0](https://img.shields.io/badge/License-MPL%202.0-brightgreen.svg)](https://opensource.org/licenses/MPL-2.0) [![Build](https://github.com/tobywf/pasteboard/workflows/Build/badge.svg?branch=master&event=push)](https://github.com/tobywf/pasteboard/actions)

[Pasteboard](https://pypi.org/project/pasteboard/) exposes Python bindings for reading and writing macOS' AppKit [NSPasteboard](https://developer.apple.com/documentation/appkit/nspasteboard). This allows retrieving different formats (HTML/RTF fragments, PDF/PNG/TIFF) and efficient polling of the pasteboard.

Now with type hints!

## Installation

Obviously, this module will only compile on **macOS**:

```bash
pip install pasteboard
```

## Usage

### Getting the contents

```pycon
>>> import pasteboard
>>> pb = pasteboard.Pasteboard()
>>> pb.get_contents()
'pasteboard'
>>> pb.get_contents(diff=True)
>>>
```

Unsurprisingly, `get_contents` gets the contents of the pasteboard. This method
takes two optional arguments:

**type** - The format to get. Defaults to `pasteboard.String`, which corresponds
to [NSPasteboardTypeString](https://developer.apple.com/documentation/appkit/nspasteboardtypestring?language=objc). See the `pasteboard` module members for other
options such as HTML fragment, RTF, PDF, PNG, and TIFF. Not all formats of [NSPasteboardType](https://developer.apple.com/documentation/appkit/nspasteboardtype?language=objc) are implemented.

**diff** - Defaults to `False`. When `True`, only get and return the contents if it has changed since the last call. Otherwise, `None` is returned. This can be used to efficiently monitor the pasteboard for changes, which must be done by polling (there is no option to subscribe to changes).

`get_contents` will return the appropriate type, so [str](https://docs.python.org/3/library/stdtypes.html#str) for string types,
and [bytes](https://docs.python.org/3/library/stdtypes.html#bytes) for binary types. `None` is returned when:

* There is no data of the requested type (e.g. an image was copied but a string was requested)
* **diff** is `True`, and the contents has not changed since the last call
* An error occurred

### Setting the contents

```pycon
>>> import pasteboard
>>> pb = pasteboard.Pasteboard()
>>> pb.set_contents('pasteboard')
True
>>>
```

Analogously, `set_contents` sets the contents of the pasteboard. This method
takes two arguments:

**data** - [str](https://docs.python.org/3/library/stdtypes.html#str) or [bytes-like object](https://docs.python.org/3/glossary.html#term-bytes-like-object), required. There is no type checking. So if `type` indicates a string type and `data` is bytes-like but not UTF-8 encoded, the behaviour is undefined.

**type** - The format to set. Defaults to `pasteboard.String`, which corresponds to [NSPasteboardTypeString](https://developer.apple.com/documentation/appkit/nspasteboardtypestring?language=objc). See the `pasteboard` module members for other options such as HTML fragment, RTF, PDF, PNG, and TIFF. Not all formats of [NSPasteboardType](https://developer.apple.com/documentation/appkit/nspasteboardtype?language=objc) are implemented.

`set_contents` will return `True` if the pasteboard was successfully set; otherwise, `False`. It may also throw [RuntimeError](https://docs.python.org/3/library/exceptions.html#RuntimeError) if `data` can't be converted to an AppKit type.

## Development

You don't need to know this if you're not changing `pasteboard.m` code. There are some integration tests in `tests.py` to check the module works as designed (using [pytest](https://docs.pytest.org/en/latest/) and [hypothesis](https://hypothesis.readthedocs.io/en/latest/)).

This project uses [pre-commit](https://pre-commit.com/) to run some linting hooks when committing. When you first clone the repo, please run:

```
pre-commit install
```

You may also run the hooks at any time:

```
pre-commit run --all-files
```

Dependencies are managed via [poetry](https://python-poetry.org/). To install all dependencies, use:

```
poetry install
```

This will also install development dependencies (`pytest`). To run the tests:

```
poetry run pytest tests.py --verbose
```

## License

From version 0.3.0 and forwards, this library is licensed under the Mozilla Public License Version 2.0. For more information, see `LICENSE`.
