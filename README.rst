Pasteboard
==========

Pasteboard exposes Python bindings for reading macOS' AppKit `NSPasteboard`__.
This allows retrieving different formats (HTML/RTF fragments, PDF/PNG/TIFF) and
efficient polling of the pasteboard.

__ https://developer.apple.com/documentation/appkit/nspasteboard

Installation
------------

Obviously, this module will only compile on **macOS**:

.. code-block:: bash

    pip install pasteboard

Usage
-----

.. code-block:: python3

    >>> import pasteboard
    >>> pb = pasteboard.Pasteboard()
    >>> pb.get_contents()
    'pasteboard'
    >>> pb.get_contents(diff=True)
    >>>

Unsurprisingly, ``get_contents`` gets the contents of the pasteboard. This method
takes two optional arguments:

**type** - The format to get. Defaults to ``pasteboard.String``, which corresponds
to `NSPasteboardTypeString`__. See the ``pasteboard`` module members for other
options such as HTML fragment, RTF, PDF, PNG, and TIFF. Not all formats are
implemented, such as ``NSPasteboardTypeColor``.

**diff** - Defaults to ``False``. When ``True``, only get and return the contents
if it has changed since the last call. Otherwise, ``None`` is returned.
This can be used to efficiently monitor the pasteboard for changes, which must
be done by polling (there is no option to subscribe to changes).

``get_contents`` will return the appropriate type, so ``str`` for string types,
and ``bytes`` for binary types. ``None`` is returned when:

* There is no data of the requested type (e.g. an image was copied but a string was requested).
* **diff** is ``True``, and the contents has not changed since the last call.
* An error occurred.

__ https://developer.apple.com/documentation/appkit/nspasteboardtypestring?language=objc
