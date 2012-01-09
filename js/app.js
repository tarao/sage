var App = function(parent) {
    var frame = new FrameControl(parent, {
        loading: [ 'header', 'loading' ],
        progress: [ 'header', 'status' ],
        result: [ 'header', 'result' ],
        ready: [ 'header', 'ready' ]
    });

    var Counter = function(phase) {
        var last = 0;
        var total = 0;
        var count = 0;

        phase = phase || 1;
        var p = 0;
        var threshold = 5;
        var dec = false;
        var ratio = 0.0;

        var self = function(val) {
            if (val < last) {
                if (!dec && val < threshold) dec = true;
                count += last - val;
            } else if (last < val) {
                if (dec && val > threshold) {
                    dec = false;
                    p++;
                }
                total += val - last;
            }
            last = val;

            return [ count, total ];
        };

        self.ratio = function() {
            if (total <= 0) return 0;
            return ( p + (count / total) ) / phase;
        };

        return self;
    };
    var counter = new Counter(3);

    var loading = function(small) {
        var img = document.createElement('img');
        img.src = './img/loading' + (small ? '_s' : '') + '.gif';
        return img;
    };

    var showHeader = function(user) {
        frame.activate('header', function(node) {
            var h2 = node.getElementsByTagName('h2')[0];
            U.removeAllChildren(h2);

            var span = document.createElement('span');
            span.className = 'user';
            span.appendChild(document.createTextNode(user));
            [ span,
              document.createTextNode('さんへのおすすめユーザ')
            ].forEach(function(x){ h2.appendChild(x); });
        });
    };

    var getPartialInformation = function(u, node) {
        var name = u.user;
        var uri = [ 'db/users',name[0],name,'partial.information' ].join('/');
        GNN.XHR.get(uri, function(res) {
            node.innerHTML = res.responseText;

            var li = document.createElement('li');
            li.className = 'info';
            li.appendChild(makeInfo(u));
            node.getElementsByTagName('ul')[0].appendChild(li);

            links = node.getElementsByTagName('a');
            for (var i=0; i < links.length; i++) {
                var href = links[i].getAttribute('href');
                if (new RegExp('^/').test(href)) {
                    links[i].href = 'http://b.hatena.ne.jp' + href;
                }
            }
        });
    };

    var makeInfo = function(u) {
        var node = document.createElement('dl');
        node.className = 'info';
        [ [ 'score', 'スコア' ],
          [ 'activity', 'ブクマ数/日' ],
          [ 'match',    '共通エントリ' ],
          [ 'order', '平均順位' ]
        ].forEach(function(x) {
            if (!u[x[0]]) return;

            var dt = document.createElement('dt');
            dt.className = x[0];
            dt.appendChild(document.createTextNode(x[1]));
            var dd = document.createElement('dd');
            dd.className = x[0];
            dd.appendChild(document.createTextNode(u[x[0]]+''));
            node.appendChild(dt);
            node.appendChild(dd);
        });
        return node;
    };

    var makeUsers = function(n, eid) {
        var node = document.createElement(n >= 10 ? 'strong' : 'em');
        node.className = 'users';
        n = document.createTextNode(n+' users');
        if (eid) {
            var a = document.createElement('a');
            a.href = 'http://b.hatena.ne.jp/entry?eid='+eid;
            a.appendChild(n);
            n = a;
        }
        node.appendChild(document.createTextNode(' '));
        node.appendChild(n);
        return node;
    };

    var makeEntryList = function(ls, entry) {
        var ul = document.createElement('ul');
        ul.className = 'entries';
        ls.slice(0, 5).forEach(function(eid) {
            var e = entry[eid];
            var li = document.createElement('li');
            var a = document.createElement('a');
            a.href = e.uri;
            a.appendChild(document.createTextNode(e.title));
            li.appendChild(a);
            li.appendChild(makeUsers(e.users, eid));
            ul.appendChild(li);
        });
        return ul;
    };

    var makeEntries = function(u, entry) {
        var node = document.createElement('dl');
        node.className = 'entries';
        [ [ 'eeid', '先行してブクマしたエントリ',
            [ 'eid', '共通してブクマしたエントリ' ] ],
          [ 'oeid', '他にブクマしているエントリ' ],
        ].forEach(function(x) {
            var es = u[x[0]];
            if (!es) {
                x = x[2];
                es = u[x[0]];
            }

            var dt = document.createElement('dt');
            dt.className = x[0];
            dt.appendChild(document.createTextNode(x[1]));
            var dd = document.createElement('dd');
            dd.className = x[0];
            dd.appendChild(makeEntryList(u[x[0]], entry));
            node.appendChild(dt);
            node.appendChild(dd);
        });
        return node;
    };

    var showResult = function(content, result, entry) {
        U.removeAllChildren(content);

        var ol = document.createElement('ol');
        ol.className = 'recommend';
        content.appendChild(ol);

        var counter = { i: 0 };
        var i = 0;
        var length = result.length;
        var next = function() {
            setTimeout(function() {
                var u = result[i];
                if (!u || i >= length) return;

                u.match = u.eid.length;

                var li = document.createElement('li');
                li.className = 'item';

                var pi = document.createElement('div');
                pi.className = 'partial_information';
                pi.appendChild(loading(true));
                pi.appendChild(document.createTextNode('id:'+u.user));
                getPartialInformation(u, pi);

                var entries = makeEntries(u, entry);

                li.appendChild(pi);
                li.appendChild(entries);
                ol.appendChild(li);

                i++;
                next();
            }, 1);
        };
        next();
    };

    var showStatus = function(node, jobs) {
        var c = counter(jobs);
        c.push(Math.round(100*counter.ratio()));

        [ 'count', 'ratio' ].reduce(function(r, k) {
            return r.concat(U.getElementsByTagAndClassName(node, 'span', k));
        }, []).forEach(function(x, i) {
            var length = c[i]*2;
            var unit = '';
            if (x.className == 'ratio') {
                length = Math.round(250*length/100);
                unit = '%';
            }

            U.removeAllChildren(x);
            x.style.width = length+'px';
            x.appendChild(document.createTextNode(c[i]+unit));
        });
    };

    this.update = function(user, noloading) {
        if (!user && new RegExp('#(\\w+)$').test(location.href)) {
            user = RegExp.$1;
        }
        if (!user) return;

        showHeader(user);
        if (!noloading) frame.open('loading');
        var self = this;

        GNN.XHR.json.retrieve({
            st: App.api('status', { user: user }),
            timeout: 5000
        }, function(res) { // success
            res = res.st
            switch (res.status) {
            case 'done':
                frame.open('result', function(header, result) {
                    showResult(result, res.result, res.entry);
                });
                break;
            case 'running':
                frame.open('progress', function(header, status) {
                    showStatus(status, res.jobs);
                });
                setTimeout(function(){ self.update(user, true); }, 100);
                break;
            case 'ready':
                frame.open('ready');
                break;
            }
        }, function() { // timeout
            self.update(user, true);
        });
    };
};

App.baseURI = function() {
    var uri = GNN.URI.location();
    uri.local.pop();
    return uri;
};

App.api = function(name, params) {
    var uri = App.baseURI();
    uri.local.push('api')
    uri.local.push(name+'.cgi');
    uri.params = params || {};
    uri.refresh = function() {
        delete uri.params.timestamp;
        return uri;
    };
    return uri;
};

var init = function() {
    new App(document.getElementById('article')).update();
};
