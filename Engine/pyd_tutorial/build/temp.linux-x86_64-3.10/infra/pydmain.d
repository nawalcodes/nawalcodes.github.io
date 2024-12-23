import pyd.def;
import pyd.exception;
import pyd.thread;

extern(C) void PydMain();

version(Python_3_0_Or_Later) {
    import deimos.python.Python;
    extern(C) export PyObject* PyInit_hello() {
        return pyd.exception.exception_catcher(delegate PyObject*() {
                pyd.thread.ensureAttached();
                pyd.def.pyd_module_name = "hello";
                PydMain();
                return pyd.def.pyd_modules[""];
                });
    }
}else version(Python_2_4_Or_Later) {
    extern(C) export void inithello() {
        pyd.exception.exception_catcher(delegate void() {
                pyd.thread.ensureAttached();
                pyd.def.pyd_module_name = "hello";
                PydMain();
                });
    }
}else static assert(false);

extern(C) void _Dmain(){
    // make druntime happy
}
