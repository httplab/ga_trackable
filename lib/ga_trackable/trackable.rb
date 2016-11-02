# frozen_string_literal: true
module GaTrackable::Trackable
  extend ActiveSupport::Concern

  module ClassMethods
    def ga_trackable(video_plays:)
      setup_page_views_relations
      setup_video_plays_relations if video_plays
    end

    def setup_page_views_relations
      has_many :page_views_counters, class_name: GaTrackable::PageViewsCounter, as: :trackable, dependent: :destroy
      include PageViewsMethods
    end

    def setup_video_plays_relations
      has_many :video_plays_counters, class_name: GaTrackable::VideoPlaysCounter, as: :trackable, dependent: :destroy
      include VideoPlaysMethods
    end
  end

  module PageViewsMethods
    extend ActiveSupport::Concern

    def total_unique_page_views
      page_views_counters.sum(:unique_page_views)
    end

    def total_page_views
      page_views_counters.sum(:page_views)
    end
  end

  module VideoPlaysMethods
    extend ActiveSupport::Concern

    def total_unique_video_plays
      video_plays_counters.sum(:unique_events)
    end

    def total_video_plays
      video_plays_counters.sum(:total_events)
    end
  end
end
