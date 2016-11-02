# frozen_string_literal: true
class CreatePageViewsCounters < ActiveRecord::Migration

  def up
    create_table :ga_trackable_page_views_counters do |t|
      t.integer  :trackable_id,      null: false
      t.string   :trackable_type,    null: false
      t.string   :page_path
      t.integer  :unique_page_views, default: 0
      t.integer  :page_views,        default: 0
      t.boolean  :initial_data,      default: false

      t.timestamps null: false

      t.index :page_path
      t.index [:trackable_id, :trackable_type], name: 'index_ga_trackable_page_views_counters_on_trackable'
      t.index :trackable_type
    end
  end

  def down
    drop_table :ga_trackable_page_views_counters
  end

end
