module carb.utils.util;

import std.stdio;

template hasAnnotation(alias f, Attr) {
    bool helper() {

        foreach(attr; __traits(getAttributes, f)){

            static if(is(attr == Attr) || is(typeof(attr) == Attr)){
                
                return true;
            }
        }
        return false;

    }

    enum bool hasAnnotation = helper;
}

template hasValueAnnotation(alias f, Attr) {
    bool helper() {
        foreach(attr; __traits(getAttributes, f))
            static if(is(typeof(attr) == Attr))
                return true;
        return false;

    }
    enum bool hasValueAnnotation = helper;
}



template getAnnotation(alias f, Attr) if(hasValueAnnotation!(f, 
Attr)) {
    auto helper() {
        foreach(attr; __traits(getAttributes, f))
            static if(is(typeof(attr) == Attr))
                return attr;
        assert(0);
    }

    enum getAnnotation = helper;
}

string[] getAllDynamicClasses() {
        string[] list;
        pragma(msg,__traits(allMembers,ModuleInfo));
        // ModuleInfo is a class defined in the globally-available object.d
        // that gives info about all the modules. It can be looped over and inspected.
        foreach(mod; ModuleInfo) {

                classList: foreach(classInfo; mod.localClasses) {
                        // this is info about all the top-level classes in the program
                        if(doesClassMatch(classInfo))
                                list ~= classInfo.name;
                }
        }

        return list;
}

// this is runtime info, so we can't use the compile time __traits
// reflection on it, but there's some info available through its methods.
bool doesClassMatch(ClassInfo classInfo) {
        foreach(iface; classInfo.interfaces) {
                // the name is the fully-qualified name, so it includes the module name too
                if(iface.classinfo.name == "carb.base.controller.Dynamic") {
                        return true;
                }
        }

        // if we haven't found it yet, the interface might still be implemented,
        // just on the base class instead. Redo the check on the base class, if there
        // is one.
        if(classInfo.base !is null)
                return doesClassMatch(classInfo.base);
        return false;
}