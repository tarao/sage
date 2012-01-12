var FrameControl = function(node, definition) {
    var frames = U.getElementsByTagAndClassName(node, 'div', 'frame');

    var _select = function(close, args) {
        var names = args.filter(function(x){ return typeof x == 'string'; });
        var funs = args.filter(function(x){ return typeof x == 'function'; });

        var fs = {};
        frames.forEach(function(f) {
            var i = U.klass(f).reduce(function(r, k) {
                return r < 0 ? names.indexOf(k) : r;
            }, -1);
            if (i >= 0) {
                f.style.display = 'block';
                var name = names[i];
                fs[name] = (fs[name]||[]).concat([f]);
            } else if(close) {
                f.style.display = 'none';
            }

        });
        fs = names.reduce(function(r, k){ return r.concat(fs[k]||[]); }, []);

        funs.forEach(function(f){ f.apply(null, fs); });

        return fs;
    };

    var persistent = [];

    this.select = function(){ return _select(true, U.toA(arguments)); };
    this.activate = function(){ return _select(false, U.toA(arguments)); };
    this.open = function(page, callback) {
        var fs = this.select.apply(this, definition[page].concat(persistent));
        return callback && callback.apply(null, fs);
    };
    this.filter = function(klass) {
        var ks = U.toA(arguments);
        return frames.filter(function(f) {
            return ks.every(function(k){ return U.klass(f).indexOf(k) >= 0; });
        });
    };
    this.persistent = function() {
        persistent = persistent.concat(U.toA(arguments));
    };
    this.cancel = function() {
        var args = U.toA(arguments);
        persistent = persistent.filter(function(x) {
            return args.indexOf(x) < 0;
        });
    };

    return this;
};
