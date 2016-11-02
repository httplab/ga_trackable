# frozen_string_literal: true
module GaTrackable
  class Engine < ::Rails::Engine

    isolate_namespace GaTrackable

    rake_tasks do
      Dir[File.join(File.dirname(__FILE__), 'tasks/*.rake')].each {|f| load f }
    end

  end
end
