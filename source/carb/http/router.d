module carb.http.router;

import std.stdio;
public import vibe.http.server;
import std.string;

import vibe.core.log;

import vibe.http.fileserver;
import vibe.http.router;
import vibe.http.server;

import vibe.core.log;
import vibe.textfilter.urlencode;

import std.functional;
import carb.base.controller;

//enum _controllerDirectory = "carb.controllers";

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

class CarbRouter(string _controllerDirectory) : HTTPServerRequestHandler {
        //string controllerDirectory = "carb.base.controller";

        





        private {
                Route[][HTTPMethod.max+1] m_routes;
        }

        CarbRouter match(HTTPMethod method,string path)
        {
                import std.algorithm;
                assert(count(path, ':') <= maxRouteParameters, "Too many route parameters");
                logDebug("add route %s %s", method, path);
              //  m_routes[method] ~= Route(path, cb);
                return this;
        }

        /// Adds a new route for requests matching the specified HTTP method and pattern.
        CarbRouter match(HTTPMethod method, string path, RouteDefaults defaults)
        {
                import std.algorithm;
                assert(count(path, ':') <= maxRouteParameters, "Too many route parameters");
                assert(defaults.controller.length && defaults.action.length,"Missing default data");
                logDebug("add route %s %s", method, path);


                m_routes[method] ~= Route(path, defaults.controller,defaults.action);
                return this;
        }

        CarbRouter match(HTTPMethod method, string path)
        {



//                m_routes[method] ~= Route(path, defaults.controller,defaults.action);
                return this;
        }

        void addRoute(HTTPMethod method, string path, RouteDefaults defaults){
                import std.algorithm;
                assert(count(path, ':') <= maxRouteParameters, "Too many route parameters");
                assert(defaults.controller.length && defaults.action.length,"Missing default data");

                logDebug("add route %s %s", method, path);


                m_routes[method] ~= Route(path, defaults.controller,defaults.action);
                
        }

        final void resourceCont ( _C : Controller ) (string resource ) {
                string _Base = "/" ~ resource.toLower();
                string _ID         = _Base ~ "/:id";
                string _Cont = resource.capitalize() ~ "Controller";
                string _Module = resource ~ "." ~ _Cont;
                //alias T = typeof(Controller.getType());
                
                foreach(memberName; __traits(allMembers,_C )) {

                    // this static if filters out private members that we can see, but cannot access
                    static if(__traits(compiles, __traits(getMember, _C, memberName))) {
                        string path = "/" ~ resource ~ "/" ~ memberName;

                        if(resource == "index"){
                            path = "/" ~ memberName;
                            if(memberName == "index"){
                                path = "";
                            }

                        }
                        enum hasAction =  hasAnnotation!(__traits(getMember, _C, memberName), Action);
                        enum hasPath = hasAnnotation!(__traits(getMember, _C, memberName), CarbPath);
                        enum hasHttpMethod = hasAnnotation!(__traits(getMember, _C, memberName), CarbMethod);
                        static if(hasPath || hasAction || hasHttpMethod){
                            static if(hasHttpMethod){
                                enum method = getAnnotation!(__traits(getMember, _C, memberName), CarbMethod).method;
                               
                                static if(hasPath){
                                    enum p = getAnnotation!(__traits(getMember, _C, memberName), CarbPath);
                                    path = p.path;
                                   
                                }
                                else{
                                    import std.traits : ParameterTypeTuple, ReturnType,
                                    ParameterDefaultValueTuple, ParameterIdentifierTuple;  
                                    enum params = [ParameterIdentifierTuple!(__traits(getMember, _C,memberName))];
                                    static if(params.length && params[0].toLower() == "id"){
                                        
                                        path = path ~  "/:id";
                                       
                                        
                                    }
                                }

                                this.addRoute(method,path,RouteDefaults(_Module,resource));
                            }
                            
                        }
                        
                    }
                }

        }

        final @property void resource(string _R)(){
                import std.algorithm;
                

                enum _Cont = _R.capitalize() ~ "Controller";
                enum _Module = _controllerDirectory  ~ "." ~ _R.toLower();

                

                mixin(format(
                        q{  
                              import %s;
                              resourceCont!%s("""%s""");

                        },
                        _Module,_Cont,_R));
                       

                
        }
        
        /// Handles a HTTP request by dispatching it to the registered route handlers.
        
        override void handleRequest(HTTPServerRequest req, HTTPServerResponse res)
        {
                auto method = req.method;

                while(true)
                {   
                        if( auto pr = &m_routes[method] ){

                                foreach( ref r; *pr ){
                                        if( r.matches(req.path, req.params) ){
                                              //  logTrace("route match: %s -> %s %s", req.path, req.method, r.pattern);
                                                // .. parse fields ..
                                                //writeln(req.query["y"]);
                                                //create controller
                                                //r.controller "action"
                                                
                                                mixin(format(
                                                        q{  
                                                            string contDir = """%s""";
                                                        },
                                                        _controllerDirectory));
                                                auto o = Controller.factory( contDir ~"."~ r.controller,req,res);
                                                

                                              //  o.init(req,res);
                                             
                                                o.callMethod(req,res,r.action);
                                                //r.cb();
                                                if( res.headerWritten )
                                                        return;
                                        }
                                }
                        }
                        if( method == HTTPMethod.HEAD ) method = HTTPMethod.GET;
                        else break;
                }

                logTrace("no route match: %s %s", req.method, req.requestURL);
        }

    /// Returns all registered routes as const AA
        //const(typeof(m_routes)) getAllRoutes()
        //{
        //        return m_routes;
        //}
}



private enum maxRouteParameters = 64;

public struct RouteDefaults{
    string controller;
    string action;

}

private struct Route {
        string pattern;
        string controller;
        string action;
        
        bool matches(string url, ref string[string] params)
        const {
                size_t i, j;

                // store parameters until a full match is confirmed
                import std.typecons;
                Tuple!(string, string)[maxRouteParameters] tmpparams;
                size_t tmppparams_length = 0;

                for (i = 0, j = 0; i < url.length && j < pattern.length;) {
                        if (pattern[j] == '*') {
                                foreach (t; tmpparams[0 .. tmppparams_length])
                                        params[t[0]] = t[1];
                                return true;
                        }
                        if (url[i] == pattern[j]) {
                                i++;
                                j++;
                        } else if(pattern[j] == ':') {
                                j++;
                                string name = skipPathNode(pattern, j);
                                string match = skipPathNode(url, i);
                                assert(tmppparams_length < maxRouteParameters, "Maximum number of route parameters exceeded.");
                                tmpparams[tmppparams_length++] = tuple(name, urlDecode(match));
                        } else return false;
                }

                if ((j < pattern.length && pattern[j] == '*') || (i == url.length && j == pattern.length)) {
                        foreach (t; tmpparams[0 .. tmppparams_length])
                                params[t[0]] = t[1];
                        return true;
                }

                return false;
        }
}




private string skipPathNode(string str, ref size_t idx)
{
        size_t start = idx;
        while( idx < str.length && str[idx] != '/' ) idx++;
        return str[start .. idx];
}