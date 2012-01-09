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
    }
}
