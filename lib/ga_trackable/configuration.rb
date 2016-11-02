# frozen_string_literal: true
require 'active_model'

module GaTrackable
  class Configuration

    include ActiveModel::Validations

    def self.attribute_names
      %i(app_name app_version secret_path secret_key scope issuer_email view_id page_views_black_filter page_views_white_filter page_views_entity_fetcher video_plays_entity_fetcher out exceptions_handler video_url_base rails_env)
    end

    def attribute_names
      self.class.attribute_names
    end

    attr_accessor *attribute_names

    validates(
      :app_name,
      :app_version,
      :secret_path,
      :secret_key,
      :scope,
      :issuer_email,
      :view_id,
      :page_views_white_filter,
      :out,
      presence: true
    )

    def initialize
      @view_id = ENV['GA_TRACKABLE_VIEW_ID']
      @app_name = ENV['GA_TRACKABLE_APP_NAME']
      @app_version = ENV['GA_TRACKABLE_APP_VERSION']
      @secret_path = ENV['GA_TRACKABLE_SECRET_PATH']
      @secret_key = ENV['GA_TRACKABLE_KEY_SECRET']
      @scope = ENV['GA_TRACKABLE_SCOPE']
      @issuer_email = ENV['GA_TRACKABLE_ISSUER_EMAIL']
      @page_views_white_filter = ENV['GA_TRACKABLE_PAGEVIEWS_WHITE_FILTER']
      @page_views_black_filter = ENV['GA_TRACKABLE_PAGEVIEWS_BLACK_FILTER']
      @out = STDOUT
      @video_url_base = []

      yield(self) if block_given?

      @rails_env = @rails_env.to_sym

      [
        @view_id,
        @app_name,
        @app_version,
        @secret_path,
        @secret_key,
        @scope,
        @issuer_email,
        @page_views_white_filter,
        @page_views_black_filter,
        @video_url_base
      ].each(&:freeze)
    end

  end
end
