require 'csv'

class ShopMonthlyReportGenerateService
  HEADERS = [
    'Firstname',
    'Lastname',
    'Email',
    'Number of worked shifts',
    'Total of worked hours',
    'Number of paid absence shifts',
    'Total of paid absences hours',
    'Number of unpaid absence shifts',
    'Total of unpaid absence hours',
    'Total of paid hours',
    'Wages',
  ].freeze

  CSV_OPTIONS = {
    write_headers: true,
    headers: HEADERS,
    col_sep: ';',
  }.freeze

  ##
  # @param shop_id: generate report on this given shop
  # @param date: month of the export (from beginning of the month to the end)
  # @param filepath: generate CSV file at this location
  #
  def initialize(shop_id, date, filepath)
    @shop = Shop.find(shop_id)
    @date = date
    @filepath = filepath
  end

  def run
  end
end
