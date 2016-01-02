/* Cydia Substrate - Powerful Code Insertion Platform
 * Copyright (C) 2008-2015  Jay Freeman (saurik)
*/

(function(exports) {

var libcycript = dlopen("/usr/lib/libcycript.dylib", RTLD_NOLOAD);
if (libcycript == null) {
    exports.error = dlerror();
    return;
}

var CYHandleServer = dlsym(libcycript, "CYHandleServer");
if (CYHandleServer == null) {
    exports.error = dlerror();
    return;
}

var info = new Dl_info;
if (dladdr(CYHandleServer, info) == 0) {
    exports.error = dlerror();
    return;
}

var path = info->dli_fname;
var slash = path.lastIndexOf('/');
if (slash == -1)
    return;

var libsubstrate = dlopen(path.substr(0, slash) + "/libsubstrate.dylib", RTLD_GLOBAL | RTLD_LAZY);
if (libsubstrate == null) {
    exports.error = dlerror();
    return;
}

MSGetImageByName = @encode(void *(const char *))(dlsym(libsubstrate, "MSGetImageByName"));
MSFindSymbol = @encode(void *(void *, const char *))(dlsym(libsubstrate, "MSFindSymbol"));
MSHookFunction = @encode(void(void *, void *, void **))(dlsym(libsubstrate, "MSHookFunction"));
MSHookMessageEx = @encode(void(Class, SEL, void *, void **))(dlsym(libsubstrate, "MSHookMessageEx"));

var slice = [].slice;

exports.getImageByName = MSGetImageByName;
exports.findSymbol = MSFindSymbol;

exports.hookFunction = function(func, hook, old) {
    var type = typeid(func);

    var pointer;
    if (old == null || typeof old === "undefined")
        pointer = null;
    else {
        pointer = new @encode(void **);
        *old = function() { return type(*pointer).apply(null, arguments); };
    }

    MSHookFunction(func.valueOf(), type(hook), pointer);
};

exports.hookMessage = function(isa, sel, imp, old) {
    var type = sel.type(isa);

    var pointer;
    if (old == null || typeof old === "undefined")
        pointer = null;
    else {
        pointer = new @encode(void **);
        *old = function() { return type(*pointer).apply(null, [this, sel].concat(slice.call(arguments))); };
    }

    MSHookMessageEx(isa, sel, type(function(self, sel) { return imp.apply(self, slice.call(arguments, 2)); }), pointer);
};

})(exports);
