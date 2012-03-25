var U = {
    toA: function(a){ return Array.prototype.slice.call(a); },
    klass: function(node) {
        return node.className.split(/\s+/);
    },
    removeAllChildren: function(node) {
        while (node.firstChild) node.removeChild(node.firstChild);
    },
    getElementsByTagAndClassName: function(node, tag, klass) {
        klass = U.toA(arguments).slice(2);
        return U.toA(node.getElementsByTagName(tag)).filter(function(e) {
            var ks = U.klass(e);
            return klass.every(function(k){ return ks.indexOf(k) >= 0; });
        });
    },
    Event: function(e) {
        var self = { event: e };
        self.stop = function() {
            if (self.event.stopPropagation) {
                self.event.stopPropagation();
                self.event.preventDefault();
            } else {
                self.event.cancelBubble = true;
                self.event.returnValue = false;
            }
        };
        self.target = function() {
            return self.event.target || self.event.srcElement;
        };
        return self;
    },
    Observer: function(node, event, obj, m) {
        var self = { node: node, event: event };
        var fun = obj;
        if (typeof m == 'string') {
            fun = obj[m];
        } else if (typeof m != 'undefined') {
            fun = m;
        }
        var callback = function(e){ return fun.call(obj, new U.Event(e)); };
        self.start = function() {
            if (self.node.addEventListener) {
                if (event.indexOf('on') == 0) self.event = event.substr(2);
                self.node.addEventListener(self.event, callback, false);
            } else if (self.node.attachEvent) {
                self.node.attachEvent(self.event, callback);
            }
        };
        self.stop = function() {
            if (self.node.removeEventListener) {
                self.node.removeEventListener(self.event, callback, false);
            } else if (self.node.detachEvent) {
                self.node.detachEvent(self.event, callback);
            }
        }
        self.start();
        return self;
    }
};

var Progress = function(major, minor) {
    return {
        major: major,
        minor: minor,
        ratio: function() {
            var r = major.count / major.max;
            if (minor && minor.max > 0) {
                r += (1.0 / major.max) * (minor.count / minor.max);
            }
            return r;
        },
        percentage: function() {
            return Math.round(100*this.ratio());
        }
    };
};

var IdleTimer = function(wait, callback) {
    var id = null;
    this.ping = function() {
        this.stop();
        id = setTimeout(callback, wait);
    };
    this.stop = function() {
        if (id != null) clearTimeout(id);
    };
    return this;
};
