module carb.utils.util;

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
