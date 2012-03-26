require 'pathname'
require 'progress'

$KCODE='UTF8'

class Pathname
  def [](*paths)
    loc = self
    loc = loc + paths.shift.to_s while paths.length > 0
    return loc.to_s
  end
end

class Conf
  def initialize(master, local=nil)
    @hash = master.merge(local||{})
  end

  def [](*keys) return keys.inject(@hash){|r,x|(r||{})[x.to_s]||(r||{})[x]} end
  def []=(key, val) @hash[key.to_s]=val; return self end
  def to_hash() return @hash end
end

class App
  def self.find_base(dir)
    e = Pathname($0).expand_path.parent.to_enum(:ascend)
    return e.map{|x| x+dir.to_s}.find{|x| x.directory?}
  end

  CONFIG = find_base(:config)
  SCRIPT = find_base(:script)
  DB = find_base(:db)
  USERS = DB + 'users'
  ENTRIES = DB + 'entries'

  def self.user_dir(user)
    return USERS[user[0..0], user]
  end

  SEMAPHORE = DB['semaphore.db']
  MAX_DISK_USAGE = 1024*1024 # kiB
  MAX_REQUEST = 1
  BATCH_PROCESSES = 1
  MAP_REDUCE = :sequential
  # MAP_REDUCE = :job_queue

  QUEUE = Conf.new(:global => {
                     :queue  => DB['global.queue.db'],
                     :result => DB['global.queue.result.db'],
                   },
                   :http_fetch => {
                     :queue  => DB['http_fetch.queue.db'],
                     :result => DB['http_fetch.queue.result.db'],
                     :last   => DB['http_fetch.last.db'],
                   },
                   :user => proc do |u| {
                       :queue  => File.join(user_dir(u), 'queue.db'),
                       :result => File.join(user_dir(u), 'queue.result.db'),
                       :lock   => File.join(user_dir(u), 'lock.db'),
                       :status => File.join(user_dir(u), 'status.db'),
                     }
                   end)

  HTTP_WAIT = 1
  # UPTODATE = 24 * 60 * 60 # a file in 24 hours is up to date
  UPTODATE = 365 * 24 * 60 * 60 # 365 days
  EFFECTIVE_BOOKMARKS = 30

  FILE = {
    :result => proc{|u| File.join(App.user_dir(u), 'result.json')},
    :entry  => proc{|u| File.join(App.user_dir(u), 'entry.json')},
  }

  MAX_RESULT = 50
  SHOW_ENTRIES = 5
  SHOW_OTHER_ENTRIES = 3

  class Path
    KEYS = [ :queue, :result, :lock, :status ]
    def initialize(user, algorithm)
      @user = user
      @algo = algorithm
    end

    def dir() return App.user_dir(@user) end

    def log() return File.join(dir, (@algo.to_s+'.log')) end

    def db()
      unless @db
        @db = Hash[*KEYS.map{|k| [ k, algo_db(k) ]}.flatten]
        class << @db
          KEYS.each{|m| define_method(m){ self[m] } }
        end
      end
      return @db
    end

    def global()
      unless @global
        @global = QUEUE[:global]
        class << @global
          [ :queue, :result ].each{|m| define_method(m){ self[m] } }
        end
      end
      return @global
    end

    def queue() return algo_db(:queue) end
    def result() return algo_db(:result) end
    def lock() return algo_db(:lock) end
    def satus() return algo_db(:status) end
    def user_lock() return db_(:lock) end
    def result() return algo(FILE[:result][@user]) end
    def entry() return algo(FILE[:entry][@user]) end

    private

    def db_(which) return QUEUE[:user][@user][which] end

    def algo(path)
      dirname = File.dirname(path)
      fname = File.basename(path)
      return File.join(dirname, [ @algo.to_s, fname ].join('.'))
    end

    def algo_db(which) return algo(db_(which)) end
  end

  class Semaphore
    def initialize(user)
      @user = user
      @semaphore = Store.new(SEMAPHORE)
    end

    def p()
      return @semaphore.transaction do |db|
        pids = db[:semaphore] || []
        req = db[:request] || {}
        done = db[:done] || []

        if pids.size < MAX_REQUEST && !req[@user]
          pids << Process.pid
          req[@user] = Process.pid
          done = done.reject{|u| u==@user}

          db[:semaphore] = pids
          db[:request] = req
          db[:done] = done

          nil
        else
          req.keys
        end
      end
    end

    def v()
      @semaphore.transaction do |db|
        pids = (db[:semaphore] || []).reject{|pid| pid == Process.pid}
        req = db[:request] || {}
        done = db[:done] || []

        req.delete(@user)
        done << @user

        db[:semaphore] = pids
        db[:request] = req
        db[:done] = done
      end
    end

    def running?()
      return @semaphore.ro.transaction do |db|
        req = db[:request] || {}
        req[@user]
      end
    end

    def list() return @semaphore.ro.transaction{|db| db[:done] || []} end
  end

  def self.up_to_date?(file)
    return false unless File.exist?(file)
    return File.mtime(file).to_i + App::UPTODATE > Time.now.to_i
  end

  def self.round(x, prec=10**3) return (x * prec).round / (1.0 * prec) end

  attr_reader :cgi, :user, :algorithm
  def initialize()
    require 'cgi'
    require 'job/queue'
    require 'json'
    require 'algorithm'

    @cgi = CGI.new
    cb = (@cgi.params['callback'][0] || '').strip
    cb = nil if cb.length == 0 || cb !~ /^\$?[a-zA-Z0-9\.\_\[\]]+$/
    @callback = cb
    @user = param(:user) || ''
    @user = nil unless @user =~ /^\w+$/
    @algorithm = param(:algorithm) || ''
    @algorithm = nil unless Algorithm.defined?(@algorithm)
    @path = Path.new(@user, @algorithm)
  end

  def header()
    ctype = @callback ? 'text/javascript' : 'application/json'
    return "Content-Type: #{ctype}; charset=utf-8\r\n\r\n"
  end

  def error_exit(status, message=nil)
    print(cgi.header('type' => 'text/plain', 'status' => status))
    puts(message ? message : status)
    exit
  end

  def json(data)
    data = data.to_json
    data = "#{@callback}(#{data});" if @callback
    return data
  end

  def params() return @cgi.params end

  def param(key)
    val = params[key.to_s][0]
    val = val.read if val.respond_to?(:read)
    return val
  end

  def check_running()
    return Store.new(@path.lock).ro.transaction{|db| db[:lock]}
  end

  def check_queued() return Semaphore.new(user).running? end

  def status(&block)
    dir = @path.dir
    if [ dir, @path.db.status, @path.lock ].any?{|x| !File.exist?(x)}
      return block.call(:queued) if Semaphore.new(@user).running?
      return block.call(:ready, nil)
    end

    status_db = Store.new(@path.db.status)
    task = Progress::Store.new(status_db, 'task')
    phase = Progress::Store.new(status_db, 'phase')

    if check_running && phase.loaded?
      progress = [ { :count => phase.step, :max => phase.max,
                     :msg => phase.msg } ]
      if task.loaded? && task.max
        progress << { :count => task.step, :max => task.max }
      end
      block.call(:running, progress)
    else
      if File.exist?(@path.result) && File.exist?(@path.entry)
        block.call(:done, nil)
      elsif check_queued || Semaphore.new(@user).running?
        block.call(:queued)
      else
        block.call(:ready, nil)
      end
    end
  end

  def result(&block)
    status do |st, progress|
      if st == :running
        block.call(st, :progress => progress)
      else
        result = IO.read(@path.result) rescue nil
        entry = IO.read(@path.entry) rescue nil
        if result && entry
          val = {
            :result => JSON.parse(result),
            :entry  => JSON.parse(entry),
          }
          block.call(:done, val)
        else
          block.call(st, nil)
        end
      end
    end
  end
end
