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
import carb.http.defaults;



class CarbRouter : HTTPServerRequestHandler {


        private {
                IRoute[][HTTPMethod.max+1] m_routes;
        }




        ///// Adds a new route for requests matching the specified HTTP method and pattern.
        //CarbRouter match(HTTPMethod method, string path, RouteDefaults!(Controller) defaults)
        //{
        //        import std.algorithm;
        //        assert(count(path, ':') <= CarbRoute!(Controller).maxRouteParameters, "Too many route parameters");
        //        //assert(defaults.controller.length && defaults.action.length,"Missing default data");
        //        logDebug("add route %s %s", method, path);
        //        writeln("Added Route: ",path," Method: ",method);
        //        //m_routes[method] ~= new CarbRoute!()(method,path, defaults.routeControllerData ,defaults.routeAction);
        //        return this;
        //}


        void addRoute(_C : Controller)(HTTPMethod method, string path, RouteDefaults!(_C) defaults){
                import std.algorithm;
                assert(count(path, ':') <= CarbRoute!(_C).maxRouteParameters, "Too many route parameters");
             //   assert(defaults.controller.length && defaults.action.length,"Missing default data");

                logDebug("add route %s %s", method, path);

                writeln("Added Route: ",path," Method: ",method);
                m_routes[method] ~= new CarbRoute!(_C)(method, path, defaults.routeAction);
                
        }

        final @property CarbRouter resource ( _C : Controller ) (string prefix = "") {
                import std.traits;
                enum _R = fullyQualifiedName!(_C).split(".")[$-1][0 .. $ - 10 ].toLower();
                string _Base = prefix ~ "/" ~ _R.toLower();
                string _ID = _Base ~ "/:" ~ _R ~ "_id";
                string _Cont = _R.capitalize() ~ "Controller";
                //string _Module = _R ~ "." ~ _Cont;
                //alias T = typeof(Controller.getType());
                
                foreach(memberName; __traits(allMembers,_C )) {

                    // this static if filters out private members that we can see, but cannot access
                    static if(__traits(compiles, __traits(getMember, _C, memberName))) {
                        string path = prefix;
                        if(_R == "index"){
                            path = path;
                        }
                        else{
                            path = path ~ "/" ~ _R;

                        }
                        if(memberName != "index"){
                            path = path ~ memberName;
                        }
                        enum hasAction =  hasAnnotation!(__traits(getMember, _C, memberName), Action);
                        enum hasPath = hasAnnotation!(__traits(getMember, _C, memberName), CarbPath);
                        enum hasHttpMethod = hasAnnotation!(__traits(getMember, _C, memberName), CarbMethod);
                        static if(hasPath || hasAction || hasHttpMethod){
                            static if(hasHttpMethod){
                                enum method = getAnnotation!(__traits(getMember, _C, memberName), CarbMethod)._method;
                               
                                static if(hasPath){
                                    enum p = getAnnotation!(__traits(getMember, _C, memberName), CarbPath);
                                    path ~= p._path;
                                   
                                }
                                
                                import std.traits : ParameterTypeTuple, ReturnType,
                                ParameterDefaultValueTuple, ParameterIdentifierTuple;  
                                enum params = [ParameterIdentifierTuple!(__traits(getMember, _C,memberName))];
                                if(params.length && params[0].toLower() == _R ~ "_id"){
                                    
                                    //path =  
                                    this.addRoute!(_C)(method,path ~   "/:" ~ _R ~ "_id",new RouteDefaults!(_C)(memberName));

                                    
                                }
                                
                                

                                this.addRoute!(_C)(method,path,new RouteDefaults!(_C)(memberName));
                            }
                            
                        }
                        
                    }
                }
                return this;

        }


        final @property CarbRouter resource(string _Module)(string prefix=""){
                import std.algorithm;
                //assert(_controllerDirectory.length,"You need to specify a controller directory");

                enum _last = _Module.split(".")[$-1];
                
                enum _Mod = _Module[0 .. ($-_last.length -1)];

                mixin(format(
                        q{  
                            import %s;
                            return resource!(%s)(prefix);
                        },
                        _Mod,_last));


        }



        final @property CarbRouter resource( _C : Controller)( void delegate(CarbNamespace namespace) yield){
            import std.traits;
            resource!(_C);
            CarbNamespace namespace = new CarbNamespace(this,fullyQualifiedName!(_C).split(".")[$-1][0 .. $ - 10 ].toLower());
            
            yield(namespace);
            return this;
            
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
        auto route(HTTPMethod method, string path, ref string[string] params) {
            

            while (true) {
              if (auto pr = &m_routes[method]) {
                foreach( ref r; *pr ) {
                  if (r.matches(path, params)) {
                    return r;
                  }
                }
              }
              if (method == HTTPMethod.HEAD) method = HTTPMethod.GET;
              else break;
            }
            return null;
        } 


        void handleRequest(HTTPServerRequest req, HTTPServerResponse res) {
            auto method = req.method;
            auto route  = route(method, req.path, req.params);

            if (!(route is null)) {

                auto o = route.controller(req,res);
               

                o.__send__(route.action,req,res);

                if( res.headerWritten )
                        return;
            }
        }





        @property typeof(m_routes) routes() {
            return m_routes;
        }

        

}




bool instanceof(T)(Object o) if(is(T == class)) {
    return true;
}

unittest {
  string[string] params;
  auto router = new CarbRouter;
  router.resource!("carb.controllers.chill.ChillController");

  assert(router.route(HTTPMethod.GET, "/chill/1", params).instanceof!(IRoute));

  import carb.controllers.index;
  router.resource!(IndexController);
  assert(router.route(HTTPMethod.GET, "/1", params).instanceof!(IRoute));
}

unittest {
  string[string] params;
  auto router = new CarbRouter;
  import carb.controllers.auth;
  import carb.controllers.chill;
  import carb.controllers.index;

  router.namespace!("api")( delegate void (CarbNamespace api) {
    api.resource!(AuthController)( delegate void (CarbNamespace auth) {
        auth.namespace!( "foo")( delegate void (CarbNamespace foo) {
            auth.resource!(ChillController);
        });
    });
  });

  assert(router.route(HTTPMethod.GET, "/api/auth/4/foo/chill/9", params).instanceof!IRoute);

  router.resource!(AuthController)( delegate void (CarbNamespace auth) {
            auth.resource!(ChillController);
  });

  assert(router.route(HTTPMethod.GET, "/auth/4/chill/9", params).instanceof!IRoute);


}


