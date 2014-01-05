module carb.http.namespace;
import std.typetuple;
import carb.http.router;
import std.array;
import std.algorithm;
import std.stdio;
import std.traits;
import std.string;

import carb.base.controller;


class CarbNamespace {


  private {
    CarbRouter _router;
    string[]     _namespaces;
    string[]     _variables;
    string[]     _prefixes;
  }




  this(CarbRouter router, string namespace,string prefix = "") {
    if(prefix.length){
      this(router,[namespace],[prefix]);
    }
    else{
      this(router,[namespace],[]);
    }

  }


  this(CarbRouter router, string[] namespaces,string[] prefixes) {
    _router     = router;
    foreach(int i,ns; namespaces) {
      _namespaces ~= ns;
        //writeln(ns,prefixes,find(prefixes,ns).length);

      //if(!find(prefixes,ns).length){
         _variables  ~= ":" ~ singularize(ns) ~ "_id";
      //}
    }
    foreach(p;prefixes){
      _prefixes ~= p;
    }
  }



  CarbRouter namespace(string _R)( void delegate(CarbNamespace namespace) yield) {
    _namespaces ~= _R;
    _prefixes ~= _R;
    _variables ~= "";
    CarbNamespace namespace = new CarbNamespace(_router,_namespaces,_prefixes);
    yield(namespace);
    return _router;
  }

  string joinPrefix() {
    string[] prefix;
    for (int i = 0; i < _namespaces.length; i++) {
      prefix ~= _namespaces[i];
      if(!find(_prefixes,_namespaces[i]).length){
        if(_variables.length){
          prefix ~= _variables[i];
        }


      }
    }
    return "/" ~ join(prefix, "/");
  }


  CarbRouter resource(string _R)() {
    _router.resource!(_R)(joinPrefix());


    return _router;
  }



  CarbRouter resource(string _R)( void delegate(CarbNamespace namespace) yield) {

    resource!(_R);
    CarbNamespace namespace = new CarbNamespace(_router,_namespaces ~ _R.split(".")[$-1],_prefixes);
    
    yield(namespace);
    return _router;
  }

  CarbRouter resource( _C : Controller)(){
      _router.resource!(_C)(joinPrefix());
      return _router;
  }

  CarbRouter resource( _C : Controller)( void delegate(CarbNamespace namespace) yield){

      _router.resource!(_C);
      CarbNamespace namespace = new CarbNamespace(_router, _namespaces ~ fullyQualifiedName!(_C).split(".")[$-1][0 .. $ - 10 ].toLower(),_prefixes);
      
      yield(namespace);
      return _router;
      
  }



  private {
    string singularize(string input) {
      // classes case
      if (input[input.length - 3..input.length - 1] == "ses")
        return input[0..input.length - 3];
      // books case
      else if (input[input.length - 1] == 's')
        return input[0..input.length - 1];

      return input;
    }
  }
}