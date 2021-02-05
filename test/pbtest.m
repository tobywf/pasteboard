#include <AppKit/AppKit.h>
#define PY_SSIZE_T_CLEAN
#include <Python.h>

static PyObject *
pbtest_test(PyObject *Py_UNUSED(self), PyObject *Py_UNUSED(args))
{
    BOOL ok;
    @autoreleasepool {
        NSPasteboard *pb = [NSPasteboard generalPasteboard];
        [pb clearContents];
        ok = [pb writeObjects:@[
            [NSURL fileURLWithPath:@(__FILE__ "-example1")],
            [NSURL fileURLWithPath:@(__FILE__ "-example2")],
        ]];
    }
    if (ok) {
        Py_RETURN_TRUE;
    } else {
        Py_RETURN_FALSE;
    }
}

static PyMethodDef pbtest_methods[] = {
    {"test", pbtest_test, METH_NOARGS, "TEST ME"},
    {NULL, NULL, 0, NULL},
};

static struct PyModuleDef pbtest_module = {
    PyModuleDef_HEAD_INIT,
    .m_name = "pbtest",
    .m_methods = pbtest_methods,
    .m_size = -1,
};

PyMODINIT_FUNC
PyInit_pbtest(void)
{
    return PyModule_Create(&pbtest_module);
}
