require 'app'
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

  def initialize(name) @name = name end

  def workers() return Worker::SET[@name] end
  def context() return CONTEXT[@name] end
end
