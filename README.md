carb.d
======

An MVC framework built on vibe.d.
Example:
```

import vibe.d;
import std.string;
import std.stdio;
import carb.http.router;
import carb.base.controller;


class IndexController : Controller{
        mixin DynamicImplementation!();

        @DynamicallyAvailable
        void index(int id,string q){
                this.res.writeJsonBody(id);
                this.res.writeJsonBody(q);
                this.res.writeBody("Hello, World id!", "text/plain");
        }
        
}

shared static this()
{
        auto router = new CarbRouter;

        router.controllerDirectory = "carb.app";
        router.addRoute(HTTPMethod.GET,"/:id",RouteDefaults("IndexController","index"));


        auto settings = new HTTPServerSettings;
        settings.port = 8080;

        listenHTTP(settings, router);
}
```
