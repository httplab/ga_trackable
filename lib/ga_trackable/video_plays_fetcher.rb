# frozen_string_literal: true
class GaTrackable::VideoPlaysFetcher < GaTrackable::BaseFetcher

  GA_FILTER = 'Video Plays'

  def counter_class
    GaTrackable::VideoPlaysCounter
  end

  # Поулчить данные по просмотрам для конкретного пути. Используется в rake-таске.
  def get_details_for(start_date: 1.year.ago, path:)
    ga_start_date = start_date.in_time_zone.strftime(GA_DATE_FORMAT)
    ga_end_date = DateTime.current.strftime(GA_DATE_FORMAT)

    data = @client.execute(api_method: @analytics.data.ga.get, parameters: {
      'ids' => "ga:#{@config.view_id}",
      'start-date' => ga_start_date,
      'end-date' => ga_end_date,
      'dimensions' => 'ga:eventCategory,ga:eventAction',
      'metrics' => 'ga:uniqueEvents,ga:totalEvents',
      'sort' => 'ga:eventCategory,ga:eventAction',
      'filters' => "ga:eventCategory==#{GA_FILTER};ga:eventAction=@#{path}"
    }).data
  end

  private

  # create_in_past нужен для создания счетчика "вчера". Это нужно в случае стартовой инициализации счетчиков.
  # Стартовые данные за весь период записываем вчерашним днем, за сегодня и далее -- записываем стандартным образом.
  # По-просмотрам видео есть специфика:
  #   одной странице могут соответствовать разные видеофайлы(event_action) в разное время.
  def process_row(row, hsh = {})
    event_action = row[1]

    entities = get_entities(fetch_video_url(event_action))

    entities.each {|e| process_entity(e, row, hsh) }
  end

  def process_entity(entity, row, create_in_past: false)
    event_category = row[0]
    event_action = row[1]
    unique_events = row[2].to_i
    total_events = row[3].to_i

    # Пытаемся получить каунтер на сегодняшний день для полученного видеофайла (event_action).
    today_counters = entity.video_plays_counters.where('created_at >= ? AND event_action = ?', start_date, event_action)
    fail "more than one today counter for #{entity.class.name}##{entity.id} and <#{event_action}>" if today_counters.size > 1

    if today_counters.any?
      counter = today_counters.first
    else
      counter = entity.video_plays_counters.build(
        event_category: event_category,
        event_action: event_action
      )
      if create_in_past
        counter.created_at = 1.day.ago
        counter.updated_at = counter.created_at
        counter.initial_data = true
      end
    end

    # Мы считаем просмотры по event_action плейлист.
    # В выдаче аналитики комбинации страница + видеофайл могут встречаться много раз.
    # По этому код ниже определяет надо инициализировать счетчики, или инкрементировать.
    key = event_action
    if sometime_processed_counters.index(key)
      counter.unique_events += unique_events
      counter.total_events += total_events
    else
      counter.unique_events = unique_events
      counter.total_events = total_events
      sometime_processed_counters << key
    end

    counter.save!
  end

  def get_data(tstart, tend, start_index, max_results)
    ga_start_date = tstart.strftime(GA_DATE_FORMAT)
    ga_end_date = tend.strftime(GA_DATE_FORMAT)

    params = {
      'ids' => "ga:#{@config.view_id}",
      'start-date' => ga_start_date,
      'end-date' => ga_end_date,
      'start-index' => start_index,
      'max-results' => max_results,
      'dimensions' => 'ga:eventCategory,ga:eventAction',
      'metrics' => 'ga:uniqueEvents,ga:totalEvents',
      'sort' => 'ga:eventCategory,ga:eventAction',
      'filters' => "ga:eventCategory==#{GA_FILTER}"
    }
    data = @client.execute(api_method: @analytics.data.ga.get, parameters: params).data

    GaTrackable.out << "Video plays data:\n"
    GaTrackable.out << "params:\n"
    GaTrackable.out << params.to_s
    GaTrackable.out << "\n"
    GaTrackable.out << "response:\n"
    GaTrackable.out << data.rows.to_s
    GaTrackable.out << "\n"

    data
  end

  def fetch_video_url(event_action)
    index = nil
    @config.video_url_base.each do |base|
      index = event_action.index base
      break if index.present?
    end
    if index.present?
      trailing_index = event_action.index('/playlist.m3u8') || event_action.length
      key = event_action.slice(index...trailing_index)
    else
      key = event_action
    end
  end

  def get_entity(video_url)
    @config.video_plays_entity_fetcher.call(video_url)
  end

end
