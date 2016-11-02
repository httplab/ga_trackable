# frozen_string_literal: true
class CreateVideoPlaysCounters < ActiveRecord::Migration

  def up
    create_table :ga_trackable_video_plays_counters do |t|
      t.integer  :trackable_id, null: false
      t.string   :trackable_type, null: false
      t.string   :event_category
      t.string   :event_action
      t.integer  :unique_events, default: 0
      t.text     :event_label
      t.integer  :total_events
      t.boolean  :initial_data, default: false

      t.timestamps null: false

      t.index :event_action
      t.index :event_category
      t.index [:trackable_id, :trackable_type], name: 'index_ga_trackable_video_plays_counters_on_trackable'
      t.index :trackable_type
    end
  end

  def down
    drop_table :ga_trackable_video_plays_counters
  end

end
