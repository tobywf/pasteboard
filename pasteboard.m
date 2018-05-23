/*
    Pasteboard - Python interface for reading from NSPasteboard (macOS clipboard)
    Copyright (C) 2017-2018  Toby Fleming

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#include <AppKit/AppKit.h>
#include <Python.h>

// TODO: figure out how NSAutoreleasePool works with sub-interpreters
// (https://www.python.org/dev/peps/pep-3121/)
// it's not really a use-case I anticipate being useful for clipboard access...
static NSAutoreleasePool *pool = NULL;

typedef NSString * NSPasteboardType;
static PyObject *PasteboardType_Default = NULL;

typedef enum {DATA, STRING, PROP} PasteboardTypeReading;
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
    "pasteboard.PasteboardType",    /* tp_name */
    sizeof(PasteboardTypeState),    /* tp_basicsize */
    0,                              /* tp_itemsize */
    /* methods */
    0,                              /* tp_dealloc */
    0,                              /* tp_print */
    0,                              /* tp_getattr */
    0,                              /* tp_setattr */
    0,                              /* tp_reserved */
    pasteboardtype_repr,            /* tp_repr */
    0,                              /* tp_as_number */
    0,                              /* tp_as_sequence */
    0,                              /* tp_as_mapping */
    0,                              /* tp_hash */
    0,                              /* tp_call */
    0,                              /* tp_str */
    0,                              /* tp_getattro */
    0,                              /* tp_setattro */
    0,                              /* tp_as_buffer */
    Py_TPFLAGS_DEFAULT,             /* tp_flags */
    pasteboardtype__doc__,          /* tp_doc */
    0,                              /* tp_traverse */
    0,                              /* tp_clear */
    0,                              /* tp_richcompare */
    0,                              /* tp_weaklistoffset */
    0,                              /* tp_iter */
    0,                              /* tp_iternext */
    0,                              /* tp_methods */
    0,                              /* tp_members */
    0,                              /* tp_getset */
    0,                              /* tp_base */
    0,                              /* tp_dict */
    0,                              /* tp_descr_get */
    0,                              /* tp_descr_set */
    0,                              /* tp_dictoffset */
    0,                              /* tp_init */
    PyType_GenericAlloc,            /* tp_alloc */
    0,                              /* tp_new */
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
pasteboard_new(PyTypeObject *type, PyObject *args, PyObject *kwargs)
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
            Py_RETURN_NONE;
    }
}

static PyObject *
pasteboard_get_contents(PyObject *self, PyObject *args, PyObject *kwargs)
{
    PasteboardState *state = (PasteboardState *)self;

    PyObject *type = PasteboardType_Default;
    bool diff = FALSE;

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
"get_contents(type, diff=False) -> str/bytes/None\n\n"
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
            Py_RETURN_NONE;
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
"set_contents(data, type) -> True/False/None\n\n"
"Sets the contents of the pasteboard.\n\n"
"data - str or bytes-like object. If type is a string type and bytes is not "
"UTF-8 encoded, the behaviour is undefined.\n"
"type - The NSPasteboardType to get, see module members. Default is 'String'.\n"
"Returns `True` if the operation was successful; otherwise, `False`.");

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
    {NULL}  /* Sentinel */
};

PyDoc_STRVAR(pasteboard__doc__,
"Holds a reference to the global pasteboard for reading and writing.");

PyTypeObject PasteboardType = {
    PyVarObject_HEAD_INIT(&PyType_Type, 0)
    "pasteboard.Pasteboard",        /* tp_name */
    sizeof(PasteboardState),        /* tp_basicsize */
    0,                              /* tp_itemsize */
    /* methods */
    pasteboard_dealloc,             /* tp_dealloc */
    0,                              /* tp_print */
    0,                              /* tp_getattr */
    0,                              /* tp_setattr */
    0,                              /* tp_reserved */
    pasteboard_repr,                /* tp_repr */
    0,                              /* tp_as_number */
    0,                              /* tp_as_sequence */
    0,                              /* tp_as_mapping */
    0,                              /* tp_hash */
    0,                              /* tp_call */
    0,                              /* tp_str */
    0,                              /* tp_getattro */
    0,                              /* tp_setattro */
    0,                              /* tp_as_buffer */
    Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE, /* tp_flags */
    pasteboard__doc__,              /* tp_doc */
    0,                              /* tp_traverse */
    0,                              /* tp_clear */
    0,                              /* tp_richcompare */
    0,                              /* tp_weaklistoffset */
    0,                              /* tp_iter */
    0,                              /* tp_iternext */
    pasteboard_methods,             /* tp_methods */
    0,                              /* tp_members */
    0,                              /* tp_getset */
    0,                              /* tp_base */
    0,                              /* tp_dict */
    0,                              /* tp_descr_get */
    0,                              /* tp_descr_set */
    0,                              /* tp_dictoffset */
    0,                              /* tp_init */
    PyType_GenericAlloc,            /* tp_alloc */
    pasteboard_new,                 /* tp_new */
};

static void
module_free(void *);

PyDoc_STRVAR(module__doc__, "Python interface for NSPasteboard (macOS clipboard)");

static struct PyModuleDef pasteboard_module = {
   PyModuleDef_HEAD_INIT,
   "pasteboard",            /* m_name */
   module__doc__,           /* m_doc */
   -1,                      /* m_size */
   NULL,                    /* m_methods */
   NULL,                    /* m_slots */
   NULL,                    /* m_traverse */
   NULL,                    /* m_clear */
   module_free              /* m_free */
};

#define QUOTE(str) #str
#define PASTEBOARD_TYPE(name, read)  \
    PyObject *__##name = pasteboardtype_new(NSPasteboardType##name, read); \
    if (PyModule_AddObject(module, QUOTE(name), __##name) < 0) {  \
        return NULL;  \
    }

PyMODINIT_FUNC
PyInit_pasteboard(void)
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
        return NULL;
    }

    // PASTEBOARD_TYPE(Color, ???)
    // PASTEBOARD_TYPE(FindPanelSearchOptions, PROP)
    // PASTEBOARD_TYPE(Font, ???)
    PASTEBOARD_TYPE(HTML, STRING)
    // PASTEBOARD_TYPE(MultipleTextSelection, ???)
    PASTEBOARD_TYPE(PDF, DATA)
    PASTEBOARD_TYPE(PNG, DATA)
    PASTEBOARD_TYPE(RTF, STRING)
    // PASTEBOARD_TYPE(RTFD, STRING)
    // PASTEBOARD_TYPE(Ruler, ???)
    // PASTEBOARD_TYPE(Sound, ???)
    PASTEBOARD_TYPE(String, STRING)
    PasteboardType_Default = __String;
    PASTEBOARD_TYPE(TIFF, DATA)
    PASTEBOARD_TYPE(TabularText, STRING)
    // PASTEBOARD_TYPE(TextFinderOptions, PROP)

    Py_INCREF((PyObject *)&PasteboardType);
    PyModule_AddObject(module, "Pasteboard", (PyObject *)&PasteboardType);

    return module;
}

static void
module_free(void *unused)
{
    if (pool) {
        [pool release];
        pool = NULL;
    }
}
