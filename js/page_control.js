var PageControl = function(pages, transit) {
    var self = this;

    this.current = null;

    this.open = function(name, args) {
        this.current = name;

        var page = pages[name];
        if (!page) throw new TypeError('Undefined page "'+name+'"');
        return page.apply(this, U.toA(arguments).slice(1));
    };

    this.move = function(args){ return transit.move.apply(this, arguments); };
    this.init = function(){ return transit.init.apply(this); };

    this.guard = function(func) {
        var current = this.current;
        return function() {
            if (self.current == current) return func.apply(null, arguments);
        };
    };

    return this;
};
