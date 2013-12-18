module carb.base.controller;
import vibe.d;
import std.variant;
import std.conv;
import std.traits;

import std.stdio;


interface Dynamic {
	Variant callMethod(HTTPServerRequest req, HTTPServerResponse res,string method);
}

enum DynamicallyAvailable; // we'll use this as a user-defined annotation to see if the method should be available

// This sees if the above attribute is on the member
bool isDynamicallyAvailable(alias member)() {
	// the way UDAs work in D is this trait gives you a list of them
	// they are identified by type and can also hold a value (though
	// we don't handle that case here)
	foreach(annotation; __traits(getAttributes, member))
		static if(is(annotation == DynamicallyAvailable))
			return true;
	return false;
}



//alias Helper(alias T) T; // this is used just to help make code shorter when doing reflection

// then the implementation is a mixin template. This won't get in the way of inheritance
// and will run the template on the child class (putting the code straight in the interface or
// base class will not be able to call new methods in the children. The reason is this code runs
// at compile time, and at compile time it can only see what's there in the source - no child class methods.)
//
// Actually, I think there is a way to put a template like this in the interface that does know child classes,
// but I don't remember how or if it would actually work for this kind of thing or not. But I know this way works.
mixin template DynamicImplementation() {
	private {
	        import vibe.data.json;
	        import std.conv : to;

	        string toRestString(Json value)
	        {
	                switch( value.type ){
	                        default: return value.toString();
	                        case Json.Type.Bool: return value.get!bool ? "true" : "false";
	                        case Json.Type.Int: return to!string(value.get!long);
	                        case Json.Type.Float: return to!string(value.get!double);
	                        case Json.Type.String: return value.get!string;
	                }
	        }

	        T fromRestString(T)(string value)
	        {
	                static if( is(T == bool) ) return value == "true";
	                else static if( is(T : int) ) return to!T(value);
	                else static if( is(T : double) ) return to!T(value); // FIXME: formattedWrite(dst, "%.16g", json.get!double);
	                else static if( is(T : string) ) return value;
	                else static if( __traits(compiles, T.fromString("hello")) ) return T.fromString(value);
	                else return deserializeJson!T(parseJson(value));
	        }
	}
    import std.traits : ParameterTypeTuple, ReturnType,
            ParameterDefaultValueTuple, ParameterIdentifierTuple;        
    import std.string : format;
    import std.algorithm : startsWith;
    import std.exception : enforce;

    import vibe.http.server : HTTPServerRequest, HTTPServerResponse;
    import vibe.http.common : HTTPStatusException, HTTPStatus;
    import vibe.utils.string : sanitizeUTF8;
    import vibe.internal.meta.funcattr : IsAttributedParameter;
	import std.variant;
	import std.conv;
	import std.traits;
	override Variant callMethod(HTTPServerRequest req, HTTPServerResponse res, string methodNameWanted) {



		foreach(memberName; __traits(allMembers, typeof(this))) {
//				writeln(memberName);

			if(memberName != methodNameWanted)
				continue;

			// this static if filters out private members that we can see, but cannot access
			static if(__traits(compiles, __traits(getMember, this, memberName))) {
				// the helper from above is needed for this line to compile
				// otherwise it would complain that alias = __traits is bad syntax
				// but now we can use member instead of writing __traits(getMember) over and over again
//				alias member = Helper!(__traits(getMember, this, memberName));

				// we're only interested in calling functions that are marked as available
				static if(is(typeof(__traits(getMember, this, memberName)) == function) && isDynamicallyAvailable!(__traits(getMember, this, memberName))) {
				
				alias PT = ParameterTypeTuple!(__traits(getMember, this, memberName));
				PT params;
				void jsonParamHandler(T, string method, alias Func)(T inst){

					        alias ParamDefaults = ParameterDefaultValueTuple!Func;
					        enum ParamNames = [ ParameterIdentifierTuple!Func ];
							
				                
				                foreach (i, P; PT) {
				                        static assert (
				                                ParamNames[i].length,
				                                format(
				                                        "Parameter %s of %s has no name",
				                                        i.stringof,
				                                        method
				                                )
				                        );

				                        // will be re-written by UDA function anyway
				                       // static if (!IsAttributedParameter!(Func, ParamNames[i])) {
				                                static if (i == 0 && ParamNames[i] == "id") {
				                                        // legacy special case for :id, backwards-compatibility
				                                        logDebug("id %s", req.params["id"]);
				                                        params[i] = fromRestString!P(req.params["id"]);
				                                } else static if (ParamNames[i].startsWith("_")) {
				                                        // URL parameter
				                                        static if (ParamNames[i] != "_dummy") {
				                                                enforce(
				                                                        ParamNames[i][1 .. $] in req.params,
				                                                        format("req.param[%s] was not set!", ParamNames[i][1 .. $])
				                                                );
				                                                logDebug("param %s %s", ParamNames[i], req.params[ParamNames[i][1 .. $]]);
				                                                params[i] = fromRestString!P(req.params[ParamNames[i][1 .. $]]);
				                                        }
				                                } else {
				                                        // normal parameter
				                                        alias DefVal = ParamDefaults[i];

				                                        if (req.method == HTTPMethod.GET) {
				                                                logDebug("query %s of %s" ,ParamNames[i], req.query);
				                                                
				                                                static if (is (DefVal == void)) {
				                                                        enforce(
				                                                                ParamNames[i] in req.query,
				                                                                format("Missing query parameter '%s'", ParamNames[i])
				                                                        );
				                                                } else {
				                                                        if (ParamNames[i] !in req.query) {
				                                                                params[i] = DefVal;
				                                                                continue;
				                                                        }
				                                                }

				                                                params[i] = fromRestString!P(req.query[ParamNames[i]]);
				                                               
				                                        } else {
				                                                logDebug("%s %s", method, ParamNames[i]);

				                                                enforce(
				                                                        req.contentType == "application/json",
				                                                        "The Content-Type header needs to be set to application/json."
				                                                );
				                                                enforce(
				                                                        req.json.type != Json.Type.Undefined,
				                                                        "The request body does not contain a valid JSON value."
				                                                );
				                                                enforce(
				                                                        req.json.type == Json.Type.Object,
				                                                        "The request body must contain a JSON object with an entry for each parameter."
				                                                );

				                                                static if (is(DefVal == void)) {
				                                                        enforce(
				                                                                req.json[ParamNames[i]].type != Json.Type.Undefined,
				                                                                format("Missing parameter %s", ParamNames[i])
				                                                        );
				                                                } else {
				                                                        if (req.json[ParamNames[i]].type == Json.Type.Undefined) {
				                                                                params[i] = DefVal;
				                                                                continue;
				                                                        }
				                                                }

				                                                params[i] = deserializeJson!P(req.json[ParamNames[i]]);
				                                        }
				                                }
				                        //}
				                }
				                
						}
					//Get JSON Params

					//alias member = (__traits(getMember, this, memberName);

					// now we have a function, so time to write the code to call it
					// gotta get our arguments converted to the right types. We get the
					// tuple of them, then loop over that, and extract it from our dynamic array.
					// We loop over the tuple because the compile time info is available there.
					
					jsonParamHandler!(typeof(this),memberName,__traits(getMember, this, memberName))(this);
					//writeln(functionArguments);
					// Note: This won't compile if the function takes fully immutable arguments!
					//foreach(index, ref arg; functionArguments) {
					//	if(index >= arguments.length)
					//		throw new Exception("Not enough arguments to call " ~ methodNameWanted);

					//	// I did string arguments here, could be other things too
					//	arg = to!(typeof(arg))(arguments[index]);

					//	// if you did Variant[] arguments, the following code would work instead
					//	// arg = arguments[index].get!(typeof(arg));
					//	// .coerce instead of .get tries to force a conversion if needed, so you might want that too
					//}

					Variant returnValue;

					// now, for calling the function and getting the return value,
					// we need to check if it returns void. If so, returnValue = void
					// won't compile, so we do two branches.
					static if(is(ReturnType!(__traits(getMember, this, memberName)) == void))
						__traits(getMember, this, memberName)(params);
					else
						returnValue = __traits(getMember, this, memberName)(params);

					return returnValue;
				}
			}
		}

		throw new Exception("No such method " ~ methodNameWanted);
	}



}


class Controller : Dynamic {
	mixin DynamicImplementation!();

	HTTPServerRequest req;
	HTTPServerResponse res;

	this() {
			
	}


	void init(HTTPServerRequest req, HTTPServerResponse res) {
		this.req = req;
		this.res = res;
			
	}



	static Controller factory(string name){
		return cast(Controller) Object.factory(name);
	}

	//static Controller getInstance(){
	//	return Object.factory(__MODULE__);
	//}
}

//class IndexController : Controller{
//        mixin DynamicImplementation!();

//        @DynamicallyAvailable
//        void index(){
//                this.res.writeBody("Hello, World!", "text/plain");
//        }
        
//}


