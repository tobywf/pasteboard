Pasteboard
==========

`Pasteboard`_ exposes Python bindings for reading and writing macOS' AppKit
`NSPasteboard`_. This allows retrieving different formats (HTML/RTF fragments,
PDF/PNG/TIFF) and efficient polling of the pasteboard.

Installation
------------

Obviously, this module will only compile on **macOS**:

.. code-block:: bash

    pip install pasteboard

Usage
-----

Getting the contents
^^^^^^^^^^^^^^^^^^^^

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
to `NSPasteboardTypeString`_. See the ``pasteboard`` module members for other
options such as HTML fragment, RTF, PDF, PNG, and TIFF. Not all formats of
`NSPasteboardType`_ are implemented.

**diff** - Defaults to ``False``. When ``True``, only get and return the contents
if it has changed since the last call. Otherwise, ``None`` is returned.
This can be used to efficiently monitor the pasteboard for changes, which must
be done by polling (there is no option to subscribe to changes).

``get_contents`` will return the appropriate type, so `str`_ for string types,
and `bytes`_ for binary types. ``None`` is returned when:

* There is no data of the requested type (e.g. an image was copied but a string was requested).
* **diff** is ``True``, and the contents has not changed since the last call.
* An error occurred.

Setting the contents
^^^^^^^^^^^^^^^^^^^^

.. code-block:: python3

    >>> import pasteboard
    >>> pb = pasteboard.Pasteboard()
    >>> pb.set_contents('pasteboard')
    True
    >>>

Analogously, ``set_contents`` sets the contents of the pasteboard. This method
takes two arguments:

**data** - `str`_ or `bytes-like object`_, required. There is no type checking.
So if ``type`` indicates a string type and ``data`` is bytes-like but not UTF-8
encoded, the behaviour is undefined.

**type** - The format to set. Defaults to ``pasteboard.String``, which corresponds
to `NSPasteboardTypeString`_. See the ``pasteboard`` module members for other
options such as HTML fragment, RTF, PDF, PNG, and TIFF. Not all formats of
`NSPasteboardType`_ are implemented.

``set_contents`` will return ``True`` if the pasteboard was successfully set;
otherwise, ``False``. It may also throw `RuntimeError`_ if ``data`` can't be
converted to an AppKit type.

Development
-----------

(You don't need to know this if you're not changing ``pasteboard.m`` code.)

In the repository, I've included a ``Pipfile`` that can be used with `pipenv`_
to install all dependencies for testing (pasteboard has no Python dependencies
itself). There are some integration tests in ``tests.py`` to check the module
works as designed (using `pytest`_ and `hypothesis`_).

.. code-block:: console

    $ pipenv install
    $ pipenv run pytest tests.py --hypothesis-show-statistics

To clean up:

.. code-block:: console

    $ pipenv --rm
    $ rm -rf \
        .hypothesis/ \
        .pytest_cache/ \
        build/ \
        pasteboard.egg-info/ \
        __pycache__/ \
        pasteboard.*.so \
        Pipfile.lock

.. _Pasteboard: https://pypi.org/project/pasteboard/
.. _NSPasteboard: https://developer.apple.com/documentation/appkit/nspasteboard
.. _NSPasteboardTypeString: https://developer.apple.com/documentation/appkit/nspasteboardtypestring?language=objc
.. _NSPasteboardType: https://developer.apple.com/documentation/appkit/nspasteboardtype?language=objc
.. _str: https://docs.python.org/3/library/stdtypes.html#str
.. _bytes: https://docs.python.org/3/library/stdtypes.html#bytes
.. _bytes-like object: https://docs.python.org/3/glossary.html#term-bytes-like-object
.. _RuntimeError: https://docs.python.org/3/library/exceptions.html#RuntimeError
.. _pipenv: https://docs.pipenv.org/
.. _pytest: https://docs.pytest.org/en/latest/
.. _hypothesis: https://hypothesis.readthedocs.io/en/latest/
