carb.d
======

An MVC framework built on vibe.d.
Example:
```
module carb.app;
import carb.base.controller;
import vibe.d;
import std.string;
import std.stdio;



import carb.http.router;
import carb.base.validator;





shared static this()
{
        auto router = new CarbRouter!"carb.controllers";

        router.resource!"index";


        auto settings = new HTTPServerSettings;
        settings.port = 8080;

        listenHTTP(settings, router);
}
```

In carb.controllers I have a file named index.d:
```
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

```
I have some example validators. Validators are processed with the query parameters. Here is an example:
```
class TVal : Validator{

	int x;

	void initWithArgs(string q,int y ){
		writeln(y);
		this.x = y;

	}
	override bool validate(){

		return true;
	}


}

class Val : Validator{

	int x;

	void initWithArgs(int id,TVal n ){
		
		this.x = n.x;

	}
	override bool validate(){

		return true;
	}


}
```


