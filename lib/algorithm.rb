require 'case'

# map reduce
require 'map_reduce'

# map
require 'mapper/recent_bookmarks'
require 'mapper/entry/users'
require 'mapper/entry/each_user'

# reduce
require 'reducer/entry/ignore_niche_entries'
require 'reducer/entry/ignore_hot_entries'
require 'reducer/entry/mark_effective'
require 'reducer/entry/mark_order'
require 'reducer/entry/relative_order'
require 'reducer/entry/scoring'
require 'reducer/user/accumulate'
require 'reducer/user/activity'
require 'reducer/user/weight_precision'
require 'reducer/user/weight_effective'
require 'reducer/user/weight_match'
require 'reducer/user/average_order'
require 'reducer/user/order_to_score'
require 'reducer/user/drop_effective'
require 'reducer/user/clean'

module MapReduce
  SET = {
    :combined =>
    [ { :map    => :RecentBookmarks,
        # key: nil -> entry
        :reduce => nil,
      },
      { :map    => :Users,
        # key: entry -> entry
        :reduce =>
        [ :MarkEffective,
          :Scoring,
          :'Scoring::NoPenalty',
        ],
      },
      { :map    => :EachUser,
        # key: entry -> user
        :reduce =>
        [ :Accumulate,
          :WeightPrecision,
          :WeightEffective,
          :Clean,
        ],
      },
    ],

    :broadcaster =>
    [ { :map    => :RecentBookmarks,
        # key: nil -> entry
        :reduce => :IgnoreNicheEntries,
      },
      { :map    => :Users,
        # key: entry -> entry
        :reduce =>
        [ :MarkEffective,
          :MarkOrder,
          :RelativeOrder,
          :Scoring,
          :'Scoring::NoPenalty',
        ],
      },
      { :map    => :EachUser,
        # key: entry -> user
        :reduce =>
        [ :Accumulate,
          :AverageOrder,
          :OrderToScore,
          :DropEffective,
          :Clean,
        ],
      },
    ],

    :match =>
    [ { :map    => :RecentBookmarks,
        # key: nil -> entry
        :reduce => nil,
      },
      { :map    => :Users,
        # key: entry -> entry
        :reduce =>
        [ :MarkEffective,
          :Scoring,
          :'Scoring::AllowLate',
        ],
      },
      { :map    => :EachUser,
        # key: entry -> user
        :reduce =>
        [ :Accumulate,
          :WeightPrecision,
          :DropEffective,
          :WeightMatch,
          :Clean,
        ],
      },
    ],

    :freak =>
    [ { :map    => :RecentBookmarks,
        # key: nil -> entry
        :reduce => :IgnoreHotEntries,
      },
      { :map    => :Users,
        # key: entry -> entry
        :reduce =>
        [ :MarkEffective,
          :Scoring,
          :'Scoring::NoPenalty',
          :'Scoring::InvNUsers',
        ],
      },
      { :map    => :EachUser,
        # key: entry -> user
        :reduce =>
        [ :Accumulate,
          :Activity,
          :Clean,
        ],
      },
    ],
  }
end

class Algorithm
  DESCRIPTION = {
    :broadcaster =>
    '人気エントリをいち早くブクマしている人',
    :match =>
    '似たエントリをブクマしている人',
    :freak =>
    'ニッチなエントリをブクマしている人',
  }

  CONTEXT = {
    :combined => {
      :recent_bookmarks => 100,
      :scoring => {
        :dom => Scoring::ByTimeEffective,
        :fun => Scoring::Linear,
        :regularize => true,
      },
    },
    :broadcaster => {
      :recent_bookmarks => 200,
      :scoring => {
        :dom => Scoring::ByOrder,
        :fun => Scoring::Constant,
        :regularize => true,
      },
    },
    :match => {
      :recent_bookmarks => 100,
      :scoring => {
        :dom => Scoring::ByOrder,
        :fun => Scoring::Constant,
        :regularize => false,
      },
    },
    :freak => {
      :recent_bookmarks => 500,
      :scoring => {
        :dom => Scoring::ByOrder,
        :fun => Scoring::Constant,
        :regularize => false,
      },
    },
  }

  def self.defined?(algo)
    return nil if !algo || algo.to_s.empty?
    return [ MapReduce::SET, CONTEXT ].all?{|list| list[algo.to_sym]}
  end

  def self.description()
    return DESCRIPTION.reject{|k,d| !self.defined?(k)}.sort do |a,b|
      a[0].to_s <=> b[0].to_s
    end
  end

  def initialize(name) @name = name end
  def context() return CONTEXT[@name] end

  def emitter(name, *args)
    return nil unless name

    fqn = [ :MapReduce ]
    fqn += name.to_s.split('::').map(&:to_sym)
    klass = fqn.inject(Kernel){|r,x| r.const_get(x)}
    return klass.new(*args)
  end

  def mapper(name, *args)
    return emitter(name, *args)
  end

  def reducer(name, *args)
    return emitter(name, *args)
  end
end
