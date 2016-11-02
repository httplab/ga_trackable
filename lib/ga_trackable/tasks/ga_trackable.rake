# frozen_string_literal: true
require 'colorize'

namespace :ga_trackable do
  # Все таски ga должны зависеть от check_staging, для предотвращения запуска
  # в стейджинг-окружении.
  task check_staging: :environment do
    if GaTrackable.config.rails_env && GaTrackable.config.rails_env == :staging
      puts 'Запрещен запуск задач GA на стейджинг-сервере.'.red
      exit
    end
  end

  desc 'Обновить статистику просмотров за сегодняшний день'
  task fetch_for_current_day: :check_staging do
    if GaTrackable.config.page_views_entity_fetcher
      GaTrackable::PageViewsFetcher.new.fetch_for_current_day!
    end
    if GaTrackable.config.video_plays_entity_fetcher
      GaTrackable::VideoPlaysFetcher.new.fetch_for_current_day!
    end
  end

  desc 'Initial fetch'
  task initial_fetch: :check_staging do
    if GaTrackable.config.page_views_entity_fetcher
      GaTrackable::PageViewsFetcher.new.send(:initial_fetch!, start_date: 1.year.ago)
    end
    if GaTrackable.config.video_plays_entity_fetcher
      GaTrackable::VideoPlaysFetcher.new.send(:initial_fetch!, start_date: 1.year.ago)
    end
  end

  desc 'Отобразить детальную информацию по просмотрам страниц'
  task get_details_for_page_views: :check_staging do
    path = ENV['path']
    unless path.present?
      puts <<-HERE.strip_heredoc
          Отобразить детальную информацию по просмотрам страниц:
              rake uralok:ga:get_details_for_page_views path=/programs/home-concert1/stories/tomas-live start_date=2014-10-01
              * Параметр start_date не обязателен (по-умолчанию: 1.year.ago).
        HERE
      exit
    end

    f = GaTrackable::PageViewsFetcher.new
    opts = { path: path }
    opts[:start_date] = DateTime.parse(ENV['start_date']) if ENV['start_date'].present?
    data = f.get_details_for opts

    totalUniquePageViews = 0
    totalPageViews = 0
    data.rows.each do |row|
      puts [data.columnHeaders[0].name.rjust(18), row[0]].join(': ')
      puts [data.columnHeaders[1].name.rjust(18), row[1]].join(': ')
      puts [data.columnHeaders[2].name, row[2]].join(': ')
      puts [data.columnHeaders[3].name, row[3]].join(': ')
      totalUniquePageViews += row[2].to_i
      totalPageViews += row[3].to_i
      puts '---'
    end

    puts "Всего уникальных просмотров за выбранный период: #{totalUniquePageViews}".green
    puts "Всего просмотров за выбранный период: #{totalPageViews}".green
  end

  desc 'Отобразить детальную информацию по просмотрам видео'
  task get_details_for_video_plays: :check_staging do
    path = ENV['path']
    unless path.present?
      puts <<-HERE.strip_heredoc
          Отобразить детальную информацию по просмотрам видео:
              rake uralok:ga:get_details_for_video_plays path=/programs/home-concert1/stories/tomas-live start_date=2014-10-01
              * Параметр start_date не обязателен (по-умолчанию: 1.year.ago).
        HERE
      exit
    end

    f = GaTrackable::VideoPlaysFetcher.new
    opts = { path: path }
    opts[:start_date] = DateTime.parse(ENV['start_date']) if ENV['start_date'].present?
    data = f.get_details_for opts

    totalUniqueEvents = 0
    totalEvents = 0
    data.rows.each do |row|
      puts [data.columnHeaders[0].name.rjust(18), row[0]].join(': ')
      puts [data.columnHeaders[1].name.rjust(18), row[1]].join(': ')
      puts [data.columnHeaders[2].name.rjust(18), row[2]].join(': ')
      puts [data.columnHeaders[3].name.rjust(18), row[3]].join(': ')
      puts [data.columnHeaders[4].name.rjust(18), row[4]].join(': ')
      totalUniqueEvents += row[3].to_i
      totalEvents += row[4].to_i
      puts '---'
    end

    puts "Всего уникальных просмотров за выбранный период: #{totalUniqueEvents}".green
    puts "Всего просмотров за выбранный период: #{totalEvents}".green
  end
end
