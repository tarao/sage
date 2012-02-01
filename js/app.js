var App = function(parent) {
    var frame = new FrameControl(parent, {
        select: [ 'select' ],
        loading: [ 'loading', 'select' ],
        request: [ 'request', 'select' ],
        user: [ 'algorithm', 'select' ],
        progress: [ 'header', 'status', 'select' ],
        result: [ 'header', 'result', 'select' ],
        ready: [ 'header', 'ready', 'select' ]
    });

    this.page = {};
    var page = new PageControl(this.page, {
        // page transition
        init: function() {
            if (new RegExp('#(\\w+)(?::(\\w+))?$').test(location.href)) {
                return this.move(RegExp.$1, RegExp.$2);
            } else {
                return this.move();
            }
        },
        move: function(user, algorithm) {
            var uri = '#';
            if (user) {
                uri += user;
                if (algorithm) uri += ':' + algorithm
            }
            location.href = uri;

            if (!user) {
                return this.open('top');
            } else if (!algorithm) {
                return this.open('user', user);
            } else {
                return this.open('result', user, algorithm);
            }
        }
    });


    //// common

    var form = document.getElementById('id-selector');
    var selector = document.getElementById('hatena-id');

    var selectUser = function(){ page.move(selector.value); };

    var timer = new IdleTimer(1000, selectUser);
    new U.Observer(selector, 'onkeyup', function(e){ timer.ping(); });
    new U.Observer(form, 'onsubmit', function(e) {
        e.stop();
        timer.stop();
        selector.blur();
        selectUser();
    });

    var showHeader = function(nodes) {
        nodes = U.toA(arguments);
        frame.activate('header', function(node) {
            var h2 = node.getElementsByTagName('h2')[0];
            U.removeAllChildren(h2);
            nodes.forEach(function(x){ h2.appendChild(x); });
        });
    };

    var setUser = function(user) {
        selector.value = user;
        var e = document.createElement('span');
        e.className = 'user';
        e.appendChild(document.createTextNode(user));
        showHeader(e, document.createTextNode('さんへのおすすめユーザ'));
    };


    //// top page

    this.page.top = function(){ frame.open('select'); };


    //// user page

    var desc;
    this.page.user = function(user) {
        var xhrs = [];
        var timers = [];

        var request = function(div) {
            while (xhrs.length > 0) xhrs.shift().stop();
            while (timers.length > 0) clearTimeout(timers.shift());

            div = U.getElementsByTagAndClassName(div, 'div', 'command')[0];
            U.removeAllChildren(div);
            var a = document.createElement('a');
            a.className = 'button';
            a.href = '.';
            a.appendChild(document.createTextNode('計算開始'));

            new U.Observer(a, 'onclick', function(e) {
                e.stop();
                GNN.XHR.post(App.api('calc', { user: user }), function(res) {
                    res = JSON.parse(res.responseText);
                    switch (res.status) {
                    case 'queued':
                    case 'locked':
                        page.reload(user);
                        break;
                    case 'busy':
                        frame.activate('busy');
                        break;
                    case 'full':
                        frame.activate('full');
                        break;
                    case 'error':
                        console.log('error: '+res.value);
                        break;
                    }
                }, function(res) {
                    console.debug(res);
                });
            });

            div.appendChild(a);
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
                while (xhrs.length > 0) xhrs.shift().stop();
                while (timers.length > 0) clearTimeout(timers.shift());
                page.move(args.user, args.name);
            });

            var counter = new Counter(3);
            var updateStatus = page.guard(function() {
                var e = button;
                while (e && e != document) e = e.parentNode;
                if (!e) return; // the button has been removed

                var params = { user: args.user, algorithm: args.name };
                return GNN.XHR.json.retrieve({
                    json: App.api('status', params),
                    timeout: 50000
                }, page.guard(function(res) {
                    res = res.json;
                    switch (res.status) {
                    case 'done':
                        button.className += ' done';
                        status.style.width = '100%';
                        break;
                    case 'running':
                        counter(res.jobs);
                        status.style.width = counter.percentage()+'%';
                        timers.push(setTimeout(updateStatus, 100));
                        break;
                    case 'queued':
                    case 'ready':
                        status.style.width = '0';
                        timers.push(setTimeout(updateStatus, 5000));
                        break;
                    default:
                        console.log(res.status);
                        break;
                    }
                    args.status.set(args.name, res.status);
                    if (args.status.update) {
                        if (args.status.ready) {
                            frame.open('request', request);
                        } else {
                            frame.open('user');
                        }
                    }
                }), page.guard(function() {
                    updateStatus();
                }));
            });

            button.appendChild(status);
            node.appendChild(button);

            return updateStatus();
        };

        var addButtons = function(user, ls) {
            var div = frame.filter('algorithm')[0];
            div = U.getElementsByTagAndClassName(div, 'div', 'buttons')[0];

            U.removeAllChildren(div);
            while (xhrs.length > 0) xhrs.shift().stop();

            var st = {
                _ls: ls.map(function(x){return x[0];}),
                _st: {}, update: false, ready: false,
                set: function(name, status) {
                    var ls = this._ls;  var st = this._st;
                    st[name] = status;
                    this.update = ls.every(function(x){return st[x];});
                    this.ready = ls.every(function(x){return st[x]=='ready';});
                }
            };
            ls.forEach(function(algo) {
                xhrs.push(makeButton(div, {
                    user: user, name: algo[0], desc: algo[1], status: st
                }));
            });
        };

        setUser(user);
        frame.open('loading');

        if (!desc) { // initialize
            GNN.XHR.json(App.api('list'), page.guard(function(ls) {
                desc = ls;
                addButtons(user, ls);
            }));
        } else {
            addButtons(user, desc);
        }
    };


    //// result page

    this.page.result = function(user, algorithm) {
        var counter = new Counter(3);

        var loading = function(small) {
            var img = document.createElement('img');
            img.src = './img/loading' + (small ? '_s' : '') + '.gif';
            return img;
        };

        var getPartialInformation = function(u, node) {
            var name = u.user;
            var uri = [
                'db/users', name[0], name, 'partial.information'
            ].join('/');
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
                var span = U.getElementsByTagAndClassName(node, 'span', k);
                return r.concat(span);
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

        var checkStatus = function() {
            GNN.XHR.json.retrieve({
                json: App.api('result', { user: user, algorithm: algorithm }),
                timeout: 5000
            }, page.guard(function(res) { // success
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
                    setTimeout(function(){ checkStatus(); }, 100);
                    break;
                case 'queued':
                    frame.open('progress', function(header, status) {
                        showStatus(status, 0);
                    });
                    setTimeout(function(){ checkStatus(); }, 3000);
                    break;
                case 'ready':
                    frame.open('ready');
                    break;
                }
            }), page.guard(function() { // timeout
                page.move(user);
            }));
        };

        setUser(user);
        frame.open('loading');
        checkStatus();
    };

    page.init();

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
    new App(document.getElementById('article'));
};
