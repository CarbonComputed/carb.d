module carb.orm.thing;

import std.container;
import std.stdio;

class Field{

}

class StringField!(_ML){
	string value;
}

interface IOperation{

}

class Operation(T) : IOperation{
	string _action;
	T _value;
	string _field;

}

class Commit{
	Array!IOperation _operations;
}



class Thing{
	Commit _currentCommit;
	Array!Commit _history;

	int x;

	this(){
		x = 4;
	}

	bool _commit(){
         writeln(this.tupleof);
         writeln(typeid(typeof(this.tupleof)));
        return true;
	}

	bool _validate(){
		return true;
	}
}

class User: Thing{

	StringField!(20) _name;


	this(string name){
		super();
		_name.value = 8;
	}


}