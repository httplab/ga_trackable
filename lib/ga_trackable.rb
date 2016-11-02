# frozen_string_literal: true
require 'rails'
require 'google/api_client'

module GaTrackable
  require 'ga_trackable/configuration'
  require 'ga_trackable/version'
  require 'ga_trackable/trackable'
  require 'ga_trackable/base_fetcher'
  require 'ga_trackable/page_views_fetcher'
  require 'ga_trackable/video_plays_fetcher'
  require 'ga_trackable/engine'

  InvalidConfigurationError = Class.new(StandardError)

  class << self

    def setup(&blk)
      @config ||= GaTrackable::Configuration.new(&blk)

      if @config.invalid?
        msg = "GaTrackable configuration ERROR:\n"
        raise InvalidConfigurationError, msg + @config.errors.full_messages.join("\n")
      end

      @config
    end

    def reset
      @config = nil
    end

    def config
      @config || raise(InvalidConfigurationError, 'GaTrackable is not configured!')
    end

    def client
      @client ||= begin
                    client = Google::APIClient.new(
                      application_name: config.app_name,
                      application_version: config.app_version
                    )
                    key = Google::APIClient::PKCS12.load_key(config.secret_path, config.secret_key)
                    service_account = Google::APIClient::JWTAsserter.new(config.issuer_email, config.scope, key)
                    client.authorization = service_account.authorize
                    client
                  end
    end

    def analytics
      @analytics ||= client.discovered_api('analytics', 'v3')
    end

    delegate :out, to: :config

  end
end
