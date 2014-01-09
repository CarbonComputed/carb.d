module carb.http.defaults;
import carb.base.controller;

class RouteDefaults(_C : Controller){
	protected{
	    _C _controller;
	    string _action;
	}

	this(string action){
		this._action = action;
	}

    @property string routeAction() {
        return _action;
	}

	@property TypeInfo_Class routeControllerData(){
		return _controller.classinfo;
	}



}