# frozen_string_literal: true
module GaTrackable
  class PageViewsCounter < ActiveRecord::Base

    belongs_to :trackable, polymorphic: true

    validates :trackable_id, :trackable_type, presence: true
    validates :trackable_id, uniqueness: { scope: :trackable_type }
    validates :page_path, presence: true, if: 'unique_page_views > 0'

    scope :for_date, ->(date) { where('DATE(ga_trackable_page_views_counters.created_at) = ?', date.in_time_zone) }
    scope :today, -> { for_date(Date.today) }
    scope :yesterday, -> { for_date(Date.yesterday) }

  end
end
