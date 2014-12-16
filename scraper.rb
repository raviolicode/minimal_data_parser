require 'json'
require 'csv'
require 'descriptive_statistics/safe'

# 0 values are not valid in this case
# Data has not been provided if 0
CSV::Converters[:empty_data] = lambda do |data|
  (data == "0") ? nil : data
end

# Takes a file name and a set of column definitions
# And builds a hash with all the information
module Scraper
  def self.scrape(filename, columns)
    prepare(filename)
    data_collection = []

    CSV.foreach(filename, {col_sep: ";", converters: [:empty_data, :all]}) do |row|
      data_collection << Hash[columns.zip(row)]
    end
    data_collection.shift

    # puts data_collection
    data_collection
  end

  private
  # Some Files have Spanish format for their numbers, and confuses CSV parser
  # Need to be semi-colon separated
  # TODO: pass argument to CSV converter maybe?
  def self.prepare(file_name)
    file_content = File.read(file_name)
    file_content.gsub!(/(\d+),(\d+)/, '\1.\2')
    file_content.gsub!(/(\d+)%/, '\1')
    file_content.sub!("1 id_mutualista", "id")
    File.open(file_name, 'w') {|f| f.write(file_content) }
  end
end
