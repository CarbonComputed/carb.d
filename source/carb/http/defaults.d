module carb.http.defaults;

class RouteDefaults{
	protected{
	    TypeInfo_Class _controllerData;
	    string _action;
	}

	this(TypeInfo_Class controllerData, string action){
		this._controllerData = controllerData;
		this._action = action;
	}

    @property string routeAction() {
        return _action;
	}

	@property TypeInfo_Class routeControllerData(){
		return _controllerData;
	}


}