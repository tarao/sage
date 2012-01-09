var App = function(header, content) {
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

    var removeAllChildren = function(node) {
        while (node.firstChild) node.removeChild(node.firstChild);
    };

    var showHeader = function(user) {
        removeAllChildren(header);
        var span = document.createElement('span');
        span.className = 'user';
        span.appendChild(document.createTextNode(user));
        var h2 = document.createElement('h2');
        [ span,
          document.createTextNode('さんへのおすすめユーザ')
        ].forEach(function(x){ h2.appendChild(x); });
        header.appendChild(h2);
    };

    var loading = function(small) {
        var img = document.createElement('img');
        img.src = './img/loading' + (small ? '_s' : '') + '.gif';
        return img;
    };

    var showLoading = function(node) {
        removeAllChildren(node);
        var div = document.createElement('div');
        div.style.textAlign = 'center';
        div.appendChild(loading());
        node.appendChild(div);
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

    var showResult = function(result, entry) {
        removeAllChildren(content);

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

    var showStatus = function(jobs) {
        var progress = document.getElementById('progress');
        if (progress) {
            removeAllChildren(progress);
        } else {
            removeAllChildren(content);

            var div = document.createElement('div');
            div.appendChild(document.createTextNode('計算中'));
            div.appendChild(loading(true));
            content.appendChild(div);

            var h3 = document.createElement('h3');
            h3.appendChild(document.createTextNode('進捗状況(推定値)'));
            content.appendChild(h3);

            var progress = document.createElement('div');
            progress.id = 'progress';
            content.appendChild(progress);
        }

        var c = counter(jobs);
        c.push(Math.round(100*counter.ratio()));

        var indicator = document.createElement('dl');
        indicator.className = 'indicator';

        [ [ '処理済', 'count' ],
          [ 'タスク', 'count' ],
          [ '進捗率', 'ratio' ],
        ].forEach(function(x, i) {
            var label = document.createElement('dt');
            label.appendChild(document.createTextNode(x[0]));

            var length = c[i]*2;
            var unit = '';
            if (x[1] == 'ratio') {
                length = Math.round(250*length/100);
                unit = '%';
            }

            var dd = document.createElement('dd');
            dd.className = x[1];
            var count = document.createElement('span');
            count.className = x[1];
            count.style.width = length+'px';
            count.appendChild(document.createTextNode(c[i]+unit));
            dd.appendChild(count);

            indicator.appendChild(label);
            indicator.appendChild(dd);
        });

        progress.appendChild(indicator);
    };

    var showReady = function() {
        removeAllChildren(content);
        var msg = 'まだなにもありません';
        var p = document.createElement('p');
        p.appendChild(document.createTextNode(msg));
        content.appendChild(p);
    };

    this.update = function(user, noloading) {
        if (!user && new RegExp('#(\\w+)$').test(location.href)) {
            user = RegExp.$1;
        }
        if (!user) return;

        showHeader(user);
        if (!noloading) showLoading(content);
        var self = this;

        GNN.XHR.json.retrieve({
            st: App.api('status', { user: user }),
            timeout: 5000
        }, function(res) { // success
            res = res.st
            switch (res.status) {
            case 'done':
                showResult(res.result, res.entry);
                break;
            case 'running':
                showStatus(res.jobs);
                setTimeout(function(){ self.update(user, true); }, 100);
                break;
            case 'ready':
                showReady();
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

App.onError = function(res) {
    console.debug(res);
};

var init = function() {
    var header = document.getElementById('header');
    var content = document.getElementById('content');
    new App(header, content).update();
};
