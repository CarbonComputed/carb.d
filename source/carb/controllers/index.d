module carb.controllers.index;
import carb.base.controller;
import vibe.d;
import std.string;
import std.stdio;



import carb.http.router;
import carb.base.validator;


class IndexController : Controller{
        mixin DynamicImplementation!();

        @Action
        @CarbMethod(HTTPMethod.GET)
        void index(int id,Val q){
                //this.res.writeJsonBody(id);
                //this.res.writeJsonBody(q);
                this.res.writeBody("Hello, World id!", "text/plain");
        }


        
        
}
