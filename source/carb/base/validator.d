module carb.base.validator;

import std.stdio;
import vibe.data.json;

interface IValidator {
	template InitWithArgs(A ...){
		void initWithArgs(A a);
	}
	bool validate();
	string getError();
	void setError(string error);
}

abstract class Validator : IValidator{
	string error;
	override{
		template InitWithArgs(A ...){
			abstract void initWithArgs(A a);
		}
		abstract bool validate();		
	}

	string getError(){
		return error;
	}

	void setError(string error){
		this.error = error;
	}
}

class Val : Validator{

	int x;

	void initWithArgs(int id,string q,int y ){
		writeln("yay!");
		this.x = y;

	}
	override bool validate(){

		return true;
	}


}

