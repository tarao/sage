var FrameControl = function(node, definition) {
    var frames = U.getElementsByTagAndClassName(node, 'div', 'frame');

    var _select = function(close, args) {
        var names = args.filter(function(x){ return typeof x == 'string'; });
        var funs = args.filter(function(x){ return typeof x == 'function'; });

        var fs = [];
        frames.forEach(function(f) {
            if (U.klass(f).some(function(k){ return names.indexOf(k)>=0; })) {
                f.style.display = 'block';
                fs.push(f);
            } else if(close) {
                f.style.display = 'none';
            }

        });

        funs.forEach(function(f){ f.apply(null, fs); });

        return fs;
    };

    this.select = function(){ return _select(true, U.toA(arguments)); };
    this.activate = function(){ return _select(false, U.toA(arguments)); };
    this.open = function(page, callback) {
        var fs = this.select.apply(this, definition[page]);
        return callback && callback.apply(null, fs);
    };

    return this;
};
