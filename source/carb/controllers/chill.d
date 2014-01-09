module carb.controllers.chill;
import carb.base.controller;
import vibe.d;
import std.string;
import std.stdio;



import carb.http.router;
import carb.base.validator;


class ChillController : Controller{
        mixin DynamicImplementation!();

		this(HTTPServerRequest req, HTTPServerResponse res) {
			super(req,res);
		}

        @CarbMethod(HTTPMethod.GET)
        @CarbPath("")
        void index(int chill_id=5,int y = 9){
                //this.res.writeJsonBody(id);
                //this.res.writeJsonBody(q);
                writeln(chill_id);
                this.response.writeBody("Hello, World ", "text/plain");
        }




        
        
}
