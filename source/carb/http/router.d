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
import carb.utils.util;
import carb.http.route;
import carb.http.namespace;



class CarbRouter : HTTPServerRequestHandler {

        enum _controllerDirectory = "carb.controllers";

        private {
                CarbRoute[][HTTPMethod.max+1] m_routes;
        }

        CarbRouter match(HTTPMethod method,string path)
        {
                import std.algorithm;
                assert(count(path, ':') <= CarbRoute.maxRouteParameters, "Too many route parameters");
                logDebug("add route %s %s", method, path);
              //  m_routes[method] ~= Route(path, cb);
                return this;
        }

        /// Adds a new route for requests matching the specified HTTP method and pattern.
        CarbRouter match(HTTPMethod method, string path, RouteDefaults defaults)
        {
                import std.algorithm;
                assert(count(path, ':') <= CarbRoute.maxRouteParameters, "Too many route parameters");
                //assert(defaults.controller.length && defaults.action.length,"Missing default data");
                logDebug("add route %s %s", method, path);


                m_routes[method] ~= new CarbRoute(method,path, defaults.controllerData,defaults.action);
                return this;
        }

        CarbRouter match(HTTPMethod method, string path)
        {



//                m_routes[method] ~= Route(path, defaults.controller,defaults.action);
                return this;
        }

        void addRoute(HTTPMethod method, string path, RouteDefaults defaults){
                import std.algorithm;
                assert(count(path, ':') <= CarbRoute.maxRouteParameters, "Too many route parameters");
                writeln(defaults.action);
             //   assert(defaults.controller.length && defaults.action.length,"Missing default data");

                logDebug("add route %s %s", method, path);


                m_routes[method] ~= new CarbRoute(method, path, defaults.controllerData,defaults.action);
                
        }

        final @property CarbRouter resource ( _C : Controller , string _R) (string prefix = "") {
                
                string _Base = prefix ~ "/" ~ _R.toLower();
                string _ID = _Base ~ "/:" ~ _R ~ "_id";
                string _Cont = _R.capitalize() ~ "Controller";
                string _Module = _R ~ "." ~ _Cont;
                //alias T = typeof(Controller.getType());
                
                foreach(memberName; __traits(allMembers,_C )) {

                    // this static if filters out private members that we can see, but cannot access
                    static if(__traits(compiles, __traits(getMember, _C, memberName))) {
                        string path = prefix ~ "/" ~ _R ~ "/" ~ memberName;

                        if(_R == "index"){
                            path = prefix;
                            path = path  ~ "/" ~ memberName;
                            if(memberName == "index"){
                                path = path ~ "";
                            }

                        }
                        enum hasAction =  hasAnnotation!(__traits(getMember, _C, memberName), Action);
                        enum hasPath = hasAnnotation!(__traits(getMember, _C, memberName), CarbPath);
                        enum hasHttpMethod = hasAnnotation!(__traits(getMember, _C, memberName), CarbMethod);
                        static if(hasPath || hasAction || hasHttpMethod){
                            static if(hasHttpMethod){
                                enum method = getAnnotation!(__traits(getMember, _C, memberName), CarbMethod)._method;
                               
                                static if(hasPath){
                                    enum p = getAnnotation!(__traits(getMember, _C, memberName), CarbPath);
                                    path = p._path;
                                   
                                }
                                else{
                                    import std.traits : ParameterTypeTuple, ReturnType,
                                    ParameterDefaultValueTuple, ParameterIdentifierTuple;  
                                    enum params = [ParameterIdentifierTuple!(__traits(getMember, _C,memberName))];
                                    if(params.length && params[0].toLower() == _R ~ "_id"){
                                        
                                        path =  path ~   "/:" ~ _R ~ "_id";
                                       
                                        
                                    }
                                }
                                

                                this.addRoute(method,path,RouteDefaults(_C.classinfo,memberName));
                            }
                            
                        }
                        
                    }
                }
                return this;

        }


        final @property CarbRouter resource(string _R)(string prefix=""){
                import std.algorithm;
                assert(_controllerDirectory.length,"You need to specify a controller directory");
                enum _Cont = _R.capitalize() ~ "Controller";
                enum _Module = _controllerDirectory  ~ "." ~ _R.toLower();

                mixin(format(
                        q{  
                            import %s;  
                            return resource!(%s,"""%s""")(prefix);
                        },
                        _Module,_Cont,_R));
                

        }

        final @property CarbRouter resource( _C : Controller)(){
            import std.traits;
            return resource!(_C,fullyQualifiedName!(_C).split(".")[$-1][0 .. $ - 10 ].toLower());
            
        }

        final @property CarbRouter resource(string _R)( void delegate(CarbNamespace namespace) yield) {
            resource!(_R);
            CarbNamespace namespace = new CarbNamespace(this,_R);
            
            yield(namespace);
            return this;
        }

        final @property CarbRouter namespace(string _R)( void delegate(CarbNamespace namespace) yield) {
            
            CarbNamespace n = new CarbNamespace(this,_R,_R);
            
            yield(n);
            return this;
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
                                                                                 

                                                auto o = ControllerFactory.create(r.controllerData,req,res);

                                                o.callMethod(req,res,r.action);

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

        @property typeof(m_routes) routes() {
            return m_routes;
        }

        

}




public struct RouteDefaults{
    TypeInfo_Class controllerData;
    string action;

}

