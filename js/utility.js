var U = {
    toA: function(a){ return Array.prototype.slice.call(a); },
    klass: function(node) {
        return node.className.split(/\s+/);
    },
    removeAllChildren: function(node) {
        while (node.firstChild) node.removeChild(node.firstChild);
    },
    getElementsByTagAndClassName: function(node, tag, klass) {
        return U.toA(node.getElementsByTagName(tag)).filter(function(e) {
            return U.klass(e).indexOf(klass) >= 0;
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
