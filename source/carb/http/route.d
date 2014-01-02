module carb.http.route;

import vibe.d;
import std.stdio;
import std.conv;


class CarbRoute {

        protected{
                string _pattern;
                TypeInfo_Class _contInfo;
                string _action;
                HTTPMethod _method;           
        }


        this(){

        }

        this(HTTPMethod method, string pattern, string controllerName, string action){
                _method = method;
                this._pattern = pattern;
                _contInfo = cast(TypeInfo_Class)TypeInfo_Class.find(controllerName);
                this._action = action;
        }
        
        this(HTTPMethod method, string pattern, TypeInfo_Class contInfo, string action){
                _method = method;
                this._pattern = pattern;
                                writeln(this._pattern);

                this._contInfo = contInfo;
                this._action = action;
        }

        public static {
                enum maxRouteParameters = 64;
        }

        @property string controllerName() {
                return _contInfo.name;
        }

        @property string pattern() const{
                return _pattern;
        }

        @property HTTPMethod method() {
                return _method;
        }

        @property string action() {
                return _action;
        }

        @property TypeInfo_Class controllerData(){
                return _contInfo;
        }



        bool matches(string url, ref string[string] params)
        const {
                size_t i, j;

                // store parameters until a full match is confirmed
                import std.typecons;
                Tuple!(string, string)[maxRouteParameters] tmpparams;
                size_t tmppparams_length = 0;
                string pattern = _pattern;

                for (i = 0, j = 0; i < url.length && j < pattern.length;) {
                        if (pattern[j] == '*') {
                                foreach (t; tmpparams[0 .. tmppparams_length])
                                        params[t[0]] = t[1];
                                return true;
                        }
                        if (url[i] == pattern[j]) {
                                i++;
                                j++;
                        } else if(pattern[j] == ':') {
                                j++;
                                string name = skipPathNode(pattern, j);
                                string match = skipPathNode(url, i);
                                
                                assert(tmppparams_length < maxRouteParameters, "Maximum number of route parameters exceeded.");
                                tmpparams[tmppparams_length++] = tuple(name, urlDecode(match));
                        } else {
                                return false;
                        }

                }
                if ((j < pattern.length && pattern[j] == '*') || (i == url.length && j == pattern.length)) {
                        foreach (t; tmpparams[0 .. tmppparams_length])
                                params[t[0]] = t[1];
                        return true;
                }

                return false;
        }
}

unittest{
        string contName = "carb.controllers.index.IndexController";
        CarbRoute r = new CarbRoute(HTTPMethod.GET,"/",contName,"test");
        assert(contName==r.controllerName);
}


private string skipPathNode(string str, ref size_t idx)
{
        size_t start = idx;
        while( idx < str.length && str[idx] != '/' ) idx++;
        return str[start .. idx];
}