module action_dispatch.namespace;

import carb.base.
import std.array;

class CarbNamespace {
  private {
    CarbRouter _router;
    string[]     _namespaces;
    string[]     _variables;
  }

  this(CarbRouter router, string namespace) {
    this(router, [namespace]);
  }

  this(CarbRouter router, string[] namespaces) {
    _router     = router;
    foreach(ns; namespaces) {
      _namespaces ~= ns;
      _variables  ~= ":" ~ singularize(ns) ~ "_id";
    }
  }

  string joinPrefix() {
    string[] prefix;
    for (int i = 0; i < _namespaces.length; i++) {
      prefix ~= _namespaces[i];
      prefix ~= _variables[i];
    }

    return join(prefix, "/");
  }

  CarbRouter resources(string resource) {
    _router.resources(resource, joinPrefix());
    return _router;
  }

  CarbRouter resources(string resource, void delegate(ActionNamespace namespace) yield) {
    resources(resource);

    auto namespace = new ActionNamespace(_router, _namespaces ~ resource);
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