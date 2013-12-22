module carb.app;
import carb.base.controller;
import vibe.d;
import std.string;
import std.stdio;



import carb.http.router;
import carb.base.validator;



class AuthController : Controller{
        mixin DynamicImplementation!();

        @Action
        void login(int y){
                writeln("y");
                writeln(y);
                this.res.writeJsonBody(y);
        }
        
}





shared static this()
{
        auto router = new CarbRouter!"carb.controllers";
        //router.get("/users/:user", &userInfo);
        //router.post("/adduser", &addUser);
        
      //  router.addRoute(HTTPMethod.GET,"/:id",RouteDefaults("index.IndexController","index"));
      
        router.resource!"index";

        
        // To reduce code redundancy, you can also
        // use method chaining:
        //router
        //        .get("/users/:user", &userInfo)
        //        .post("/adduser", &addUser);
        auto settings = new HTTPServerSettings;
        settings.port = 8080;

        listenHTTP(settings, router);
}