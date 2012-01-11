require 'worker/entry_users'
require 'worker/mark_order'
require 'worker/mark_effective'
require 'worker/relative_order'
require 'worker/scoring'
require 'worker/ignore_niche_entries'
require 'worker/ignore_hot_entries'
require 'worker/activity'
require 'worker/weight_precision'
require 'worker/weight_effective'
require 'worker/average_order'
require 'worker/order_to_score'
require 'worker/drop_effective'
require 'worker/weight_match'

class Worker
  SET = {
    :combined =>
    [ [ EntryUsers,
        MarkEffective,
        Scoring,
        Scoring::NoPenalty,
      ],
      [ WeightPrecision,
        WeightEffective,
      ]
    ],
    :broadcaster =>
    [ [ IgnoreNicheEntries,
        EntryUsers,
        MarkEffective,
        MarkOrder,
        RelativeOrder,
        Scoring,
        Scoring::NoPenalty,
      ],
      [ AverageOrder,
        OrderToScore,
        DropEffective,
      ]
    ],
    :match =>
    [ [ EntryUsers,
        MarkEffective,
        Scoring,
        Scoring::AllowLate,
      ],
      [ WeightPrecision,
        DropEffective,
        WeightMatch,
      ]
    ],
    :freak =>
    [ [ IgnoreHotEntries,
        EntryUsers,
        MarkEffective,
        Scoring,
        Scoring::NoPenalty,
        Scoring::InvNUsers,
      ],
      [ Activity,
      ]
    ],
  }

end

class Algorithm
  DESCRIPTION = {
    :broadcaster =>
    '人気エントリをいち早く見つけている人',
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
    return [ DESCRIPTION, Worker::SET, CONTEXT ].all?{|list| list[algo.to_sym]}
  end

  def self.description()
    return DESCRIPTION.reject{|k,d| !self.defined?(k)}.sort do |a,b|
      a[0].to_s <=> b[0].to_s
    end
  end

  def initialize(name) @name = name end
  def workers() return Worker::SET[@name] end
  def context() return CONTEXT[@name] end
end
