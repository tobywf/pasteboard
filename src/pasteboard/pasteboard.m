/*
    Pasteboard - Python interface for reading from NSPasteboard (macOS clipboard)
    Copyright (C) 2017-2021  Toby Fleming

    This Source Code Form is subject to the terms of the Mozilla Public License,
    v. 2.0. If a copy of the MPL was not distributed with this file, You can
    obtain one at https://mozilla.org/MPL/2.0/.
*/
#include <AppKit/AppKit.h>
#define PY_SSIZE_T_CLEAN
#include <Python.h>

// TODO: figure out how NSAutoreleasePool works with sub-interpreters
// (https://www.python.org/dev/peps/pep-3121/)
// it's not really a use-case I anticipate being useful for clipboard access...
static NSAutoreleasePool *pool = NULL;

typedef NSString * NSPasteboardType;
static PyObject *PasteboardType_Default = NULL;

typedef enum {DATA, STRING} PasteboardTypeReading;
typedef struct {
    PyObject_HEAD
    NSPasteboardType type;
    PasteboardTypeReading read;
} PasteboardTypeState;

static PyObject *
pasteboardtype_repr(PyObject *self)
{
    PasteboardTypeState *state = (PasteboardTypeState *)self;

    return PyUnicode_FromFormat("<PasteboardType %s>", [state->type UTF8String]);
}

PyDoc_STRVAR(pasteboardtype__doc__,
"Internal type to expose NSPasteboardTypes to Python.");

PyTypeObject PasteboardTypeType = {
    PyVarObject_HEAD_INIT(&PyType_Type, 0)
    .tp_name = "pasteboard.PasteboardType",
    .tp_doc = pasteboardtype__doc__,
    .tp_basicsize = sizeof(PasteboardTypeState),
    .tp_itemsize = 0,
    .tp_flags = Py_TPFLAGS_DEFAULT,
    .tp_repr = pasteboardtype_repr,
};

// PasteboardTypes cannot be created by anybody but this module
// This is just a helper to make creation easier
static PyObject *
pasteboardtype_new(NSPasteboardType ns_type, PasteboardTypeReading read)
{
    PyTypeObject *type = &PasteboardTypeType;

    PasteboardTypeState *state = (PasteboardTypeState *)type->tp_alloc(type, 0);

    state->type = ns_type;
    state->read = read;

    return (PyObject *)state;
}

typedef struct {
    PyObject_HEAD
    NSPasteboard *board;
    long long change_count;
} PasteboardState;

static PyObject *
pasteboard_new(PyTypeObject *type, PyObject *Py_UNUSED(args), PyObject *Py_UNUSED(kwargs))
{
    PasteboardState *state = (PasteboardState *)type->tp_alloc(type, 0);
    if (!state) {
        return NULL;
    }

    state->board = [NSPasteboard generalPasteboard];
    state->change_count = 0;

    return (PyObject *)state;
}

static void
pasteboard_dealloc(PyObject *self)
{
    PasteboardState *state = (PasteboardState *)self;

    if (state->board) {
        state->board = NULL;
    }

    Py_TYPE(state)->tp_free(state);
}

static PyObject *
pasteboard_repr(PyObject *self)
{
    PasteboardState *state = (PasteboardState *)self;

    return PyUnicode_FromFormat("<Pasteboard %lld>", state->change_count);
}

static PyObject *
get_contents(NSPasteboard *board, PasteboardTypeState* type)
{
    switch (type->read) {
        case DATA: {
            NSData *data = [board dataForType:type->type];
            if (!data) {
                Py_RETURN_NONE;
            }

            return PyBytes_FromStringAndSize([data bytes], [data length]);
        }

        case STRING: {
            NSString *str = [board stringForType:type->type];
            if (!str) {
                Py_RETURN_NONE;
            }

            return PyUnicode_FromString([str UTF8String]);
        }

        default:
            PyErr_SetString(PyExc_RuntimeError, "Unknown pasteboard type");
            return NULL;
    }
}

static PyObject *
pasteboard_get_contents(PyObject *self, PyObject *args, PyObject *kwargs)
{
    PasteboardState *state = (PasteboardState *)self;

    PyObject *type = PasteboardType_Default;
    int diff = 0; // FALSE

    static char *kwlist[] = {"type", "diff", NULL};

    if (!PyArg_ParseTupleAndKeywords(
            args, kwargs, "|O!p", kwlist,
            &PasteboardTypeType, &type, &diff)) {
        return NULL;
    }

    long long change_count = [state->board changeCount];

    if (diff && (change_count == state->change_count)) {
        Py_RETURN_NONE;
    }

    state->change_count = change_count;

    return get_contents(state->board, (PasteboardTypeState *)type);
}

PyDoc_STRVAR(pasteboard_get_contents__doc__,
"get_contents(type: PasteboardType = String, diff: bool = False) -> Union[str, bytes, None]\n\n"
"Gets the contents of the pasteboard.\n\n"
"type - The NSPasteboardType to get, see module members. Default is 'String'.\n"
"diff - Only get the contents if it has changed. Otherwise, `None` is returned. "
"Can be used for efficiently querying the pasteboard when polling for changes."
"Default is `False`.\n\n"
"Returns `str` for string types (text, HTML, RTF, etc.), and "
"`bytes` for binary types (PDF, PNG, TIFF, etc.). `None` is returned "
"if an error occurred, there is no data of the requested type, "
"or `diff` was set to `True` and the contents has not changed since "
"the last query.");

static PyObject *
set_contents(NSPasteboard *board, PasteboardTypeState* type, const char *bytes, Py_ssize_t length)
{
    switch (type->read) {
        case DATA: {
            NSData* data = [NSData
                dataWithBytesNoCopy:(void *)bytes
                length:length
                freeWhenDone:FALSE];
            if (!data) {
                PyErr_SetString(PyExc_RuntimeError, "Failed to allocate data");
                return NULL;
            }

            [board clearContents];
            if ([board setData:data forType:type->type]) {
                Py_RETURN_TRUE;
            } else {
                Py_RETURN_FALSE;
            }
        }

        case STRING: {
            NSString *str = [[NSString alloc]
                initWithBytesNoCopy:(void *)bytes
                length:length
                encoding:NSUTF8StringEncoding
                freeWhenDone:FALSE];
            if (!str) {
                PyErr_SetString(PyExc_RuntimeError, "Failed to allocate string");
                return NULL;
            }

            [board clearContents];
            if ([board setString:str forType:type->type]) {
                Py_RETURN_TRUE;
            } else {
                Py_RETURN_FALSE;
            }
        }

        default:
            PyErr_SetString(PyExc_RuntimeError, "Unknown pasteboard type");
            return NULL;
    }
}

static PyObject *
pasteboard_set_contents(PyObject *self, PyObject *args, PyObject *kwargs)
{
    PasteboardState *state = (PasteboardState *)self;

    PyObject *type = PasteboardType_Default;
    const char *bytes = NULL;
    Py_ssize_t length = 0;

    static char *kwlist[] = {"data", "type", NULL};

    if (!PyArg_ParseTupleAndKeywords(
            args, kwargs, "s#|O!", kwlist,
            &bytes, &length, &PasteboardTypeType, &type)) {
        return NULL;
    }

    return set_contents(state->board, (PasteboardTypeState *)type, bytes, length);
}

PyDoc_STRVAR(pasteboard_set_contents__doc__,
"set_contents(data: Union[str, bytes], type: PasteboardType = String) -> bool\n\n"
"Sets the contents of the pasteboard.\n\n"
"data - str or bytes-like object. If type is a string type and bytes is not "
"UTF-8 encoded, the behaviour is undefined.\n"
"type - The NSPasteboardType to get, see module members. Default is 'String'.\n"
"Returns `True` if the operation was successful; otherwise, `False`.");

static PyObject *
pasteboard_get_file_urls(PyObject *self, PyObject *args, PyObject *kwargs)
{
    PasteboardState *state = (PasteboardState *)self;
    int diff = 0; // FALSE

    static char *kwlist[] = {"diff", NULL};
    if (!PyArg_ParseTupleAndKeywords(args, kwargs, "|p", kwlist, &diff)) {
        return NULL;
    }

    long long change_count = [state->board changeCount];

    if (diff && (change_count == state->change_count)) {
        Py_RETURN_NONE;
    }

    state->change_count = change_count;

    // hopefully guard against non-file URLs
    NSArray *supportedTypes = @[NSPasteboardTypeFileURL];
    NSString *bestType = [state->board availableTypeFromArray:supportedTypes];
    if (!bestType) {
        Py_RETURN_NONE;
    }

    NSArray<Class> *classes = @[[NSURL class]];
    NSDictionary *options = @{};
    NSArray<NSURL*> *files = [state->board readObjectsForClasses:classes options:options];

    Py_ssize_t len = (Py_ssize_t)[files count];
    PyObject *urls = PyTuple_New(len);
    Py_ssize_t pos = 0;
    for (NSURL *url in files) {
        NSString *str = [url path];
        if ([url isFileURL] && str) {
            PyTuple_SetItem(urls, pos, PyUnicode_FromString([str UTF8String]));
            pos++;
        }
    }

    if (len != pos) {
        if (_PyTuple_Resize(&urls, pos) != 0) {
            PyErr_SetString(PyExc_RuntimeError, "Internal error: failed to resize tuple");
            return NULL;
        }
    }
    return urls;
}

PyDoc_STRVAR(pasteboard_get_file_urls__doc__,
"get_file_urls(diff: bool = False) -> Optional[Sequence[str]]\n\n"
"Gets the contents of the pasteboard as file URLs.\n\n"
"diff - Only get the contents if it has changed. Otherwise, `None` is returned. "
"Can be used for efficiently querying the pasteboard when polling for changes."
"Default is `False`.\n\n"
"Returns a sequence of strings corresponding to the file URL's path. "
"`None` is returned if an error occurred, there is no data of the requested "
"type, or `diff` was set to `True` and the contents has not changed since "
"the last query.");

static PyMethodDef pasteboard_methods[] = {
    {
        "get_contents",
        (PyCFunction)pasteboard_get_contents,
        METH_VARARGS | METH_KEYWORDS,
        pasteboard_get_contents__doc__,
    },
    {
        "set_contents",
        (PyCFunction)pasteboard_set_contents,
        METH_VARARGS | METH_KEYWORDS,
        pasteboard_set_contents__doc__,
    },
    {
        "get_file_urls",
        (PyCFunction)pasteboard_get_file_urls,
        METH_VARARGS | METH_KEYWORDS,
        pasteboard_get_file_urls__doc__,
    },
    {NULL, NULL, 0, NULL}  /* Sentinel */
};

PyDoc_STRVAR(pasteboard__doc__,
"Holds a reference to the global pasteboard for reading and writing.");

PyTypeObject PasteboardType = {
    PyVarObject_HEAD_INIT(&PyType_Type, 0)
    .tp_name = "pasteboard.Pasteboard",
    .tp_doc = pasteboard__doc__,
    .tp_basicsize = sizeof(PasteboardState),
    .tp_itemsize = 0,
    .tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE,
    .tp_dealloc = pasteboard_dealloc,
    .tp_repr = pasteboard_repr,
    .tp_methods = pasteboard_methods,
    .tp_new = pasteboard_new,
};

static void
module_free(void *);

PyDoc_STRVAR(module__doc__, "Python interface for NSPasteboard (macOS clipboard)");

static struct PyModuleDef pasteboard_module = {
   PyModuleDef_HEAD_INIT,
   .m_name = "_native",
   .m_doc = module__doc__,
   .m_size = -1,
   .m_free = module_free,
};

#define QUOTE(str) #str
#define PASTEBOARD_TYPE(name, read)  \
    PyObject *__##name = pasteboardtype_new(NSPasteboardType##name, read); \
    Py_INCREF(__##name); \
    if (PyModule_AddObject(module, QUOTE(name), __##name) < 0) {  \
        goto except;  \
    }

PyMODINIT_FUNC
PyInit__native(void)
{
    pool = [[NSAutoreleasePool alloc] init];
    if (!pool) {
        return NULL;
    }

    if (PyType_Ready(&PasteboardTypeType) < 0) {
        return NULL;
    }

    if (PyType_Ready(&PasteboardType) < 0) {
        return NULL;
    }

    PyObject *module = PyModule_Create(&pasteboard_module);
    if (!module) {
        goto except;
    }

    PASTEBOARD_TYPE(HTML, STRING)
    PASTEBOARD_TYPE(PDF, DATA)
    PASTEBOARD_TYPE(PNG, DATA)
    PASTEBOARD_TYPE(RTF, STRING)
    PASTEBOARD_TYPE(String, STRING)
    PasteboardType_Default = __String;
    PASTEBOARD_TYPE(TIFF, DATA)
    PASTEBOARD_TYPE(TabularText, STRING)

    Py_INCREF((PyObject *)&PasteboardType);
    if (PyModule_AddObject(module, "Pasteboard", (PyObject *)&PasteboardType) < 0) {
        goto except;
    }

    goto finally;
except:
    Py_XDECREF(module);
    module = NULL;
finally:
    return module;
}

static void
module_free(void *Py_UNUSED(unused))
{
    if (pool) {
        [pool release];
        pool = NULL;
    }
}
