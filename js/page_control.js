var PageControl = function(pages, transit) {
    var self = this;

    this.current = null;

    this.open = function(name, args) {
        this.current = name;

        var page = pages[name];
        if (!page) throw new TypeError('Undefined page "'+name+'"');
        return page.apply(this, U.toA(arguments).slice(1));
    };

    var lastArgs;
    var changed = function(args) {
        var b0 = false;
        if (!lastArgs) {
            b0 = true;
            lastArgs = [];
        }
        var b1 = lastArgs.length != args.length;
        var b2 = lastArgs.some(function(x,i){ return x!=args[i]; });
        if (lastArgs.length > args.length) {
            lastArgs.splice(args.length, lastArgs.length - args.length);
        }
        U.toA(args).forEach(function(x,i){ lastArgs[i]=x; });
        return b0 || b1 || b2;
    };

    this.move = function(args) {
        if (!changed(arguments)) return;
        return transit.move.apply(this, arguments);
    };
    this.reload = function(args) {
        args = U.toA(arguments);
        if (arguments.length <= 0) args = lastArgs;
        changed(args);
        return transit.move.apply(this, args);
    };
    this.init = function(){ return transit.init.apply(this); };

    this.guard = function(func) {
        var current = this.current+'';
        return function() {
            if (self.current == current) return func.apply(null, arguments);
        };
    };

    return this;
};
