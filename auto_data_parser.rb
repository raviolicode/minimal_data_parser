require 'csv'
require 'yaml'

## Auto Data Parser uses data that has been cleaned beforehand
class AutoDataParser

  def self.process(output_file, dir_path, csv_names)
    grouped_data = self.read_all(dir_path, *csv_names)
    condensed_data = self.condense(*grouped_data)

    File.write('output/details.json', JSON.generate(condensed_data))
  end

  def self.read_all(dir_path, *csv_names)
    options = { headers: true,
                converters: [:all, :empty_data, :true_indicator, :false_indicator]
              }

    csv_names.map do |name|
      csv = CSV.read(File.join(dir_path, "#{name}.csv"), options)

      csv_data = csv.to_a[1..-1].map do |row|
        Hash[csv.headers.zip(row)]
      end

      # csv_data is in the form of: {id: X, col1: Y, col2: Z}
      # we transform it to be: {id: X, csv_name: {col1: Y, col2: Z}}
      csv_data.map do |element|
        hash_with_id = element.select{|k,v| k == "id"}
        columns_data = element.reject{|k,v| k == "id"}

        hash_with_id.merge({ name => columns_data })
      end
    end
  end

  def self.condense(*pieces_of_data)
    first, *rest = pieces_of_data
    first.zip(*rest).map{|e| e.inject({}){ |merged, elt| merged.merge(elt || {}) }}
  end

  def self.add_averages!(data, config_file)
    averages_config = YAML.load_file(config_file)['averages']
    data.each do |provider|
      averages = averages_config.map do |average_info|
        criteria = average_info['criteria']
        selected_keys = average_info['columns']
        values = provider[criteria]

        # Adds one of the averages for that particular criteria:
        # Ex:
        # { id: 5, criterium1: { a: 1, b: 3 }, averages: { avg_a_and_b: 1.5 }}
        provider[criteria]["averages"] ||= {}
        provider[criteria]["averages"].merge!({ average_info['name'] => calculate_average(values, selected_keys) })
      end
    end
  end

  # I want the average of the values of the selected keys
  # given a hash "values", and an array of "selected_keys"
  def self.calculate_average(values, selected_keys)
    selected_values = selected_keys.map{|key| values[key]}

    # we need to measure providers equally
    # we only provide an average when all the elements are present
    # we return nil otherwise
    unless selected_values.include?(nil)
      selected_values.reduce(:+).to_f / selected_values.size unless selected_values.empty?
    end
  end

  # CSV converters, used to transform cells when parsing the CSV
  # 0 values are not valid in this case
  # Data has not been provided if 0
  CSV::Converters[:empty_data] = lambda do |data|
    (data == "0") ? nil : data
  end

  CSV::Converters[:true_indicator] = lambda do |data|
    (data.downcase == "si") ? true : data
  end

  CSV::Converters[:false_indicator] = lambda do |data|
    (data.downcase == "no") ? false : data
  end
end
