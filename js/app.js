var App = function(parent) {
    var frame = new FrameControl(parent, {
        select: [ 'select' ],
        loading: [ 'loading', 'select' ],
        user: [ 'algorithm', 'select' ],
        progress: [ 'header', 'status', 'select' ],
        result: [ 'header', 'result', 'select' ],
        ready: [ 'header', 'ready', 'select' ]
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

    var self = this;

    var move = function(user, algorithm) {
        var params = '#'+user;
        if (algorithm) params += ':'+algorithm;
        location.href = params;
        self.update(user);
    };

    var loading = function(small) {
        var img = document.createElement('img');
        img.src = './img/loading' + (small ? '_s' : '') + '.gif';
        return img;
    };

    var showHeader = function(nodes) {
        nodes = U.toA(arguments);
        frame.activate('header', function(node) {
            var h2 = node.getElementsByTagName('h2')[0];
            U.removeAllChildren(h2);
            nodes.forEach(function(x){ h2.appendChild(x); });
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

    var makeButton = function(node, args) {
        var button = document.createElement('a');
        button.className = 'button';
        button.href = '#'+args.user+':'+args.name;

        var status = document.createElement('span');
        status.className = 'ratio';

        [ 'name', 'desc' ].forEach(function(x) {
            var span = document.createElement('span');
            span.className = x;
            span.appendChild(document.createTextNode(args[x]));
            status.appendChild(span);
        });

        new U.Observer(button, 'onclick', function(e) {
            e.stop();
            move(args.user, args.name);
        });

        var counter = new Counter(3);
        var updateStatus = function() {
            var e = button;
            while (e && e != document) e = e.parentNode;
            if (!e) return; // the button has been removed

            var params = { user: args.user, algorithm: args.name };
            GNN.XHR.json.retrieve({
                json: App.api('status', params),
                timeout: 50000
            }, function(res) {
                res = res.json;
                switch (res.status) {
                case 'done':
                    button.className += ' done';
                    status.style.width = '100%';
                    break;
                case 'running':
                    counter(res.jobs);
                    status.style.width = Math.round(100*counter.ratio())+'%';
                    setTimeout(updateStatus, 100);
                    break;
                case 'queued':
                case 'ready':
                    status.style.width = '0';
                    setTimeout(updateStatus, 5000);
                    break;
                }
            }, function() {
                updateStatus();
            });
        };

        button.appendChild(status);
        node.appendChild(button);

        updateStatus();
    };

    var addButtons = function(user, ls) {
        frame.open('user', function(div) {
            div = U.getElementsByTagAndClassName(div, 'div', 'buttons')[0];
            U.removeAllChildren(div);
            ls.forEach(function(algo) {
                makeButton(div, { user: user, name: algo[0], desc: algo[1] });
            });
        });
    };

    var IdleTimer = function(wait, callback) {
        var id = null;
        this.ping = function() {
            if (id != null) clearTimeout(id);
            id = setTimeout(callback, wait);
        };
        return this;
    };

    var form = document.getElementById('id-selector');
    var selector = document.getElementById('hatena-id');
    var desc;

    var setUser = function(){ move(selector.value); };

    var timer = new IdleTimer(1000, setUser);
    new U.Observer(selector, 'onkeyup', function(e){ timer.ping(); });
    new U.Observer(form, 'onsubmit', function(e) {
        e.stop();
        selector.blur();
        setUser();
    });

    var parseParams = function(uri) {
        if (new RegExp('#(\\w+)(?::(\\w+))?$').test(uri)) {
            return { user: RegExp.$1, algorithm: RegExp.$2 };
        } else {
            return {};
        }
    };

    this.update = function(user, noloading) {
        var params = parseParams(location.href);
        user = user || params.user;

        if (!user) {
            frame.open('select');
            return;
        } else {
            selector.value = user;
            var e = document.createElement('span');
            e.className = 'user';
            e.appendChild(document.createTextNode(user));
            showHeader(e, document.createTextNode('さんへのおすすめユーザ'));
        }

        if (!noloading) frame.open('loading');

        if (params.algorithm) {

            GNN.XHR.json.retrieve({
                json: App.api('result', params),
                timeout: 5000
            }, function(res) { // success
                res = res.json
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
                case 'queued':
                    frame.open('progress', function(header, status) {
                        showStatus(status, 0);
                    });
                    setTimeout(function(){ self.update(user, true); }, 3000);
                    break;
                case 'ready':
                    frame.open('ready');
                    break;
                }
            }, function() { // timeout
                self.update(user, true);
            });
        } else if (!desc) {
            GNN.XHR.json(App.api('list'), function(ls) {
                desc = ls;
                addButtons(user, ls);
            });
        } else {
            addButtons(user, desc);
        }
    };

    return this;
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
