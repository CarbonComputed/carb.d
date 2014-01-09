module carb.controllers.index;
import carb.base.controller;
import vibe.d;
import std.string;
import std.stdio;



import carb.http.router;
import carb.base.validator;


class IndexController : Controller{
        mixin DynamicImplementation!();

		this(HTTPServerRequest req, HTTPServerResponse res) {
			super(req,res);
		}

        @Action
        @CarbMethod(HTTPMethod.GET)
        @CarbPath("")
        void create(int index_id,Val q){
                //this.res.writeJsonBody(id);
                //this.res.writeJsonBody(q);
                this.response.writeBody("Hello, World id!", "text/plain");
        }


        
        
}
