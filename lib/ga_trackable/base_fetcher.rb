# frozen_string_literal: true
class GaTrackable::BaseFetcher

  GA_DATE_FORMAT = '%Y-%m-%d'

  attr_reader :start_date
  attr_reader :end_date
  attr_accessor :sometime_processed_counters

  def initialize(
        client: GaTrackable.client,
        analytics: GaTrackable.analytics,
        config: GaTrackable.config
      )
    @client = client
    @analytics = analytics
    @config = config
    @sometime_processed_counters = []
  end

  # Вытащить просмотры за текущий день. Метод может вызываться много раз,
  # количество просмотров за текущий день будет обновляться.
  def fetch_for_current_day!
    @start_date = DateTime.current.beginning_of_day
    @end_date = DateTime.current

    self.sometime_processed_counters = []

    start_index = 1
    max_results = 1000

    begin
      rows = get_data(start_date, end_date, start_index, max_results).rows
      rows.each do |row|
        begin
          process_row(row, create_in_past: true)
        rescue => ex
          handle_exception(ex)
        end
      end
      start_index += max_results
    end while rows.size == max_results

    self.sometime_processed_counters = []
    true
  end

  private

  # Инициализировать кеши просмотров. Метод приватный, потому что его вызов
  # приведет к тому, что все каунтеры будут удалены и перестроены.
  # Стартовой датой считаем 1 год назад.
  # Вытаскиваем просмотры за все время, исключая сегодняшний день.
  # Просмотры за сегодня и далее должны вытаскиваться с помощью fetch_for_current_day! и
  # запоминаться в виде отдельного счетчика.
  def initial_fetch!(start_date: 1.year.ago)
    @start_date = start_date
    @end_date = 1.day.ago.end_of_day

    self.sometime_processed_counters = []
    counter_class.delete_all

    start_index = 1
    max_results = 1000

    begin
      rows = get_data(start_date, end_date, start_index, max_results).rows
      rows.each do |row|
        begin
          process_row(row, create_in_past: true)
        rescue => ex
          handle_exception(ex)
        end
      end
      start_index += max_results
    end while rows.size == max_results

    self.sometime_processed_counters = []
    true
  end

  def handle_exception(ex)
    @config.out << "Exception occured:\n"
    @config.out << ex.message
    @config.out << "\n"
    @config.out << ex.backtrace.join("\n")

    @config.exceptions_handler.error(ex)
  end

end
