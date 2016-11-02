# frozen_string_literal: true
class GaTrackable::PageViewsFetcher < GaTrackable::BaseFetcher

  def counter_class
    GaTrackable::PageViewsCounter
  end

  # Поулчить данные по просмотрам для конкретного пути. Используется в rake-таске.
  def get_details_for(start_date: 1.year.ago, path:)
    ga_start_date = start_date.strftime(GA_DATE_FORMAT)
    ga_end_date = DateTime.current.strftime(GA_DATE_FORMAT)

    data = @client.execute(api_method: @analytics.data.ga.get, parameters: {
      'ids' => "ga:#{@config.view_id}",
      'start-date' => ga_start_date,
      'end-date' => ga_end_date,
      'dimensions' => 'ga:pagePath,ga:pageTitle',
      'metrics' => 'ga:uniquePageviews,ga:pageviews',
      'sort' => 'ga:pagePath,ga:pageTitle',
      'filters' => "ga:pagePath=@#{path}"
    }).data
  end

  private

  # Обработать запись из коллекции, которую отдает гуглоаналитика.
  # create_in_past нужен для создания счетчика "вчера". Это нужно в случае стартовой инициализации счетчиков.
  # Стартовые данные за весь период записываем вчерашним днем, за сегодня и далее -- записываем стандартным образом.
  def process_row(row, create_in_past: false)
    # Пропускаем события с demo
    return if @config.page_views_black_filter && row[0] =~ @config.page_views_black_filter
    page_path = URI(row[0].split('?').first).path.chomp('/')
    unique_page_views = row[1].to_i
    page_views = row[2].to_i
    entity = get_entity(page_path)

    # Пытаемся получить каунтер на сегодняшний день.
    today_counters = entity.page_views_counters.where('created_at >= ?', start_date)
    fail "more than one today counter for #{entity.class.name}##{entity.id}" if today_counters.size > 1

    if today_counters.any?
      counter = today_counters.first
    else
      counter = entity.page_views_counters.build(page_path: page_path)
      if create_in_past
        counter.created_at = 1.day.ago
        counter.updated_at = counter.created_at
        counter.initial_data = true
      end
    end

    # Аналитика считает просмотры по каждому url-у и тайтлу.
    # Это значит что если в процессе существования сущности менялся ее тайтл,
    # но не менялся url, аналитика отдаст столько записей, сколько было разных тайтлов.
    # Нам нужна агрегированная информация по тайтлам. Для этого введен массив sometime_processed_counters
    # Если url в нем есть, значит количество просмотров не инициализируем, а инкрементируем.
    if sometime_processed_counters.index(page_path)
      counter.unique_page_views += unique_page_views
      counter.page_views += page_views
    else
      counter.unique_page_views = unique_page_views
      sometime_processed_counters << page_path
      counter.page_views = page_views
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
      'dimensions' => 'ga:pagePath',
      'metrics' => 'ga:uniquePageviews,ga:pageviews',
      'sort' => 'ga:pagePath',
      'filters' => "ga:pagePath=~#{@config.page_views_white_filter}"
    }

    data = @client.execute(api_method: @analytics.data.ga.get, parameters: params).data

    GaTrackable.out << "Page views data:\n"
    GaTrackable.out << "params:\n"
    GaTrackable.out << params.to_s
    GaTrackable.out << "\n"
    GaTrackable.out << "response:\n"
    GaTrackable.out << data.rows.to_s
    GaTrackable.out << "\n"

    data
  end

  def get_entity(page_path)
    @config.page_views_entity_fetcher.call(page_path)
  end

end
