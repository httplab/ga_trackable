# frozen_string_literal: true
module GaTrackable
  class VideoPlaysCounter < ActiveRecord::Base

    belongs_to :trackable, polymorphic: true

    validates :trackable_id, :trackable_type, presence: true
    validates :trackable_id, uniqueness: { scope: :trackable_type }
    validates :event_category, :event_action, presence: true, if: 'unique_events > 0'

    scope :for_date, ->(date) { where('DATE(ga_trackable_video_plays_counters.created_at) = ?', date.in_time_zone) }
    scope :today, -> { for_date(Date.today) }
    scope :yesterday, -> { for_date(Date.yesterday) }

  end
end
