module carb.app;
import carb.base.controller;
import carb.http.namespace;
import vibe.d;
import std.string;
import std.stdio;



import carb.http.router;
import carb.base.validator;
import carb.orm.thing;



class AuthController : Controller{
        mixin DynamicImplementation!();

        this(HTTPServerRequest req, HTTPServerResponse res) {
            super(req,res);
        }

        @Action
        void login(int y){
                writeln("y");
                writeln(y);
                this.response.writeJsonBody(y);
        }

}

import carb.controllers.chill;



shared static this()
{
//        auto router = new CarbRouter;

//        //router.get("/users/:user", &userInfo);
//        //router.post("/adduser", &addUser);

//        //router.addRoute(HTTPMethod.GET,"/login",RouteDefaults(AuthController.classinfo,"login"));
//       // enum _controllerDirectory = "carb.controllers.";
//       //// router.resource!(_controllerDirectory ~"index");
//       // router.namespace!("api")( delegate void (CarbNamespace b) {
//       //     b.resource!(AuthController)( delegate void (CarbNamespace bloggers) {
//       //         bloggers.namespace!( "authasdf")( delegate void (CarbNamespace auth) {
//       //             auth.resource!(ChillController);
//       //         });;
//       //     });
//       // });

//        router.resource!("carb.controllers.chill.ChillController");
////router.resource!("index").resource!("auth");
//        //router.resource!(AuthController)();


//        // To reduce code redundancy, you can also
//        // use method chaining:
//        //router
//        //        .get("/users/:user", &userInfo)
//        //        .post("/adduser", &addUser);
//        auto settings = new HTTPServerSettings;
//        settings.port = 8080;

//        listenHTTP(settings, router);
    User a = new User();
    a._commit();
}
