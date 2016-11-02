# frozen_string_literal: true
$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'ga_trackable/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'ga_trackable'
  s.version     = GaTrackable::VERSION
  s.authors     = %w(Yury Kotov)
  s.email       = %w(non-gi-suong@ya.ru)
  s.homepage    = 'https://github.com/httplab/ga_trackable'
  s.summary     = 'A Ruby wrapper for page views and video plays tracking via Google Analytics API'
  s.description = 'A Ruby wrapper for tracking via Google Analytics API'
  s.license     = 'MIT'

  s.files = Dir['{lib}/**/*', '{app}/**/*', '{db}/**/*', 'LICENSE', 'README.md']

  s.add_dependency 'rails'
  s.add_dependency 'google-api-client', '0.8.6'
  s.add_dependency 'activemodel'
  s.add_dependency 'colorize'
end
