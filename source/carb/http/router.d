module carb.http.router;

import std.stdio;
public import vibe.http.server;
import std.metastrings;
import std.string;

import vibe.core.log;

import vibe.http.fileserver;
import vibe.http.router;
import vibe.http.server;

import vibe.core.log;
import vibe.textfilter.urlencode;

import std.functional;
import carb.base.controller;


class CarbRouter : URLRouter {
        string controllerDirectory = "carb.base.controller";

        private {
                Route[][HTTPMethod.max+1] m_routes;
        }

        /// Adds a new route for requests matching the specified HTTP method and pattern.
        CarbRouter match(HTTPMethod method, string path, RouteDefaults defaults = RouteDefaults())
        {
                import std.algorithm;
                assert(count(path, ':') <= maxRouteParameters, "Too many route parameters");
                logDebug("add route %s %s", method, path);


                m_routes[method] ~= Route(path, defaults.controller,defaults.action);
                return this;
        }

        void addRoute(HTTPMethod method, string path, RouteDefaults defaults = RouteDefaults()){
                import std.algorithm;
                assert(count(path, ':') <= maxRouteParameters, "Too many route parameters");
                logDebug("add route %s %s", method, path);


                m_routes[method] ~= Route(path, defaults.controller,defaults.action);
                
        }

        void resource(string resource){
                //import std.algorithm;
                //assert(count(path, ':') <= maxRouteParameters, "Too many route parameters");
                //logDebug("add route %s %s", method, path);
                

                //m_routes[method] ~= Route(path, defaults.controller,defaults.action);
                
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
                                                writeln(r.controller);

                                                auto o = Controller.factory(controllerDirectory ~"."~ r.controller);
                                                o.init(req,res);
                                                writeln(o);
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
    string controller = "IndexController";
    string action = "index";

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

//private void jsonMethodHandler(string method, alias Func)
//{
//        import std.traits : ParameterTypeTuple, ReturnType,
//                ParameterDefaultValueTuple, ParameterIdentifierTuple;        
//        import std.string : format;
//        import std.algorithm : startsWith;
//        import std.exception : enforce;

//        import vibe.http.server : HTTPServerRequest, HTTPServerResponse;
//        import vibe.http.common : HTTPStatusException, HTTPStatus;
//        import vibe.utils.string : sanitizeUTF8;
//        import vibe.internal.meta.funcattr : IsAttributedParameter;

//        alias PT = ParameterTypeTuple!Func;
//        alias RT = ReturnType!Func;
//        alias ParamDefaults = ParameterDefaultValueTuple!Func;
//        enum ParamNames = [ ParameterIdentifierTuple!Func ];
        

//                PT params;
                
//                foreach (i, P; PT) {
//                        static assert (
//                                ParamNames[i].length,
//                                format(
//                                        "Parameter %s of %s has no name",
//                                        i.stringof,
//                                        method
//                                )
//                        );

//                        // will be re-written by UDA function anyway
//                        static if (!IsAttributedParameter!(Func, ParamNames[i])) {
//                                static if (i == 0 && ParamNames[i] == "id") {
//                                        // legacy special case for :id, backwards-compatibility
//                                        logDebug("id %s", req.params["id"]);
//                                        params[i] = fromRestString!P(req.params["id"]);
//                                } else static if (ParamNames[i].startsWith("_")) {
//                                        // URL parameter
//                                        static if (ParamNames[i] != "_dummy") {
//                                                enforce(
//                                                        ParamNames[i][1 .. $] in req.params,
//                                                        format("req.param[%s] was not set!", ParamNames[i][1 .. $])
//                                                );
//                                                logDebug("param %s %s", ParamNames[i], req.params[ParamNames[i][1 .. $]]);
//                                                params[i] = fromRestString!P(req.params[ParamNames[i][1 .. $]]);
//                                        }
//                                } else {
//                                        // normal parameter
//                                        alias DefVal = ParamDefaults[i];
//                                        if (req.method == HTTPMethod.GET) {
//                                                logDebug("query %s of %s" ,ParamNames[i], req.query);
                                                
//                                                static if (is (DefVal == void)) {
//                                                        enforce(
//                                                                ParamNames[i] in req.query,
//                                                                format("Missing query parameter '%s'", ParamNames[i])
//                                                        );
//                                                } else {
//                                                        if (ParamNames[i] !in req.query) {
//                                                                params[i] = DefVal;
//                                                                continue;
//                                                        }
//                                                }

//                                                params[i] = fromRestString!P(req.query[ParamNames[i]]);
//                                        } else {
//                                                logDebug("%s %s", method, ParamNames[i]);

//                                                enforce(
//                                                        req.contentType == "application/json",
//                                                        "The Content-Type header needs to be set to application/json."
//                                                );
//                                                enforce(
//                                                        req.json.type != Json.Type.Undefined,
//                                                        "The request body does not contain a valid JSON value."
//                                                );
//                                                enforce(
//                                                        req.json.type == Json.Type.Object,
//                                                        "The request body must contain a JSON object with an entry for each parameter."
//                                                );

//                                                static if (is(DefVal == void)) {
//                                                        enforce(
//                                                                req.json[ParamNames[i]].type != Json.Type.Undefined,
//                                                                format("Missing parameter %s", ParamNames[i])
//                                                        );
//                                                } else {
//                                                        if (req.json[ParamNames[i]].type == Json.Type.Undefined) {
//                                                                params[i] = DefVal;
//                                                                continue;
//                                                        }
//                                                }

//                                                params[i] = deserializeJson!P(req.json[ParamNames[i]]);
//                                        }
//                                }
//                        }
//                }
                
//                try {
//                        import vibe.internal.meta.funcattr;

//                        auto handler = createAttributedFunction!Func(req, res);

//                        static if (is(RT == void)) {
//                                handler(&__traits(getMember, inst, method), params);
//                                res.writeJsonBody(Json.emptyObject);
//                        } else {
//                                auto ret = handler(&__traits(getMember, inst, method), params);
//                                res.writeJsonBody(ret);
//                        }
//                } catch (HTTPStatusException e) {
//                        res.writeJsonBody([ "statusMessage": e.msg ], e.status);
//                } catch (Exception e) {
//                        // TODO: better error description!
//                        res.writeJsonBody(
//                                [ "statusMessage": e.msg, "statusDebugMessage": sanitizeUTF8(cast(ubyte[])e.toString()) ],
//                                HTTPStatus.internalServerError
//                        );
//                }
        
        
        
//}


private string skipPathNode(string str, ref size_t idx)
{
        size_t start = idx;
        while( idx < str.length && str[idx] != '/' ) idx++;
        return str[start .. idx];
}