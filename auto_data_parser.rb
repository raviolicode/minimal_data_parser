require 'csv'
require 'yaml'

## Auto Data Parser uses data that has been cleaned beforehand
class AutoDataParser

  def self.process(output_file, dir_path, csv_names_uniq, csv_names_no_uniq=[])
    # provider info
    grouped_data_uniq = self.read_all(dir_path, true, *csv_names_uniq)
    grouped_data_no_uniq = self.read_all(dir_path, false, *csv_names_no_uniq)
    grouped_data = grouped_data_uniq + grouped_data_no_uniq

    providers_data = self.condense(*grouped_data)
    self.add_averages!(providers_data, 'config/averages.yml')
    data = { providers: providers_data }

    # lookup by state info
    self.add_lookup_table!(data)

    self.add_institution_info!(data)

    File.write('output/details.json', JSON.generate(data))
  end

  # dir_path: where CSV's are stored
  # unique_id?: if the CSV's have a unique id (provider id the unique id when it's present)
  # csv_names: list of CSV's to be read
  # returns an array of data, by provider_id.
  #
  # if id is unique in the CSV, criteria returns an object (criterium1, criterium2):
  # [[{"id"=>1, "criterium1"=>{"a"=>1, "b"=>2}},  {"id"=>2, "criterium1"=>{"a"=>10, "b"=>20}}],
  # [{"id"=>1, "criterium2"=>{"d"=>3, "e"=>4}},  {"id"=>2, "criterium2"=>{"d"=>30, "e"=>40}}], ...]
  #
  # if id is not unique the criterium should contain an array (criterium3):
  # [[{"id"=>1, "criterium3"=>[{"a"=>1, "b"=>2}, {"a"=>3, "b"=>4}], ...]
  #
  # TODO: refactor this code
  def self.read_all(dir_path, unique_id=true, *csv_names)
    options = { headers: true,
                converters: [:all, :empty_data, :true_indicator, :false_indicator]
              }

    csv_names.map do |csv_name|
      csv = CSV.read(File.join(dir_path, "#{csv_name}.csv"), options)

      csv_data = csv.to_a[1..-1].map do |row|
        Hash[csv.headers.zip(row)]
      end

      if unique_id
        # csv_data is in the form of: {id: X, col1: Y, col2: Z}, ...
        # we transform it to be: [{id: X, csv_name: {col1: Y, col2: Z}}, ...]
        csv_data.map do |element|
          hash_with_id = element.select{|k,v| k == "id"}
          columns_data = element.reject{|k,v| k == "id"}

          hash_with_id.merge({ csv_name => columns_data })
        end
      else
        # if id is not unique the criterium should contain an array:
        # csv_data is in the form of: {id: X, col1: Y, col2: Z}, {id: X, col1: Y_1, col2: Z_2}
        # {id: X, csv_name: [{col1: Y, col2: Z}, ..., {col1: Y_2, col2: Z_2}]}
        # {id: X2, csv_name: [{col1: Y_3, col2: Z_3}, ..., {col1: Y_4, col2: Z_4}]}
        col_data = []
        csv_data.each do |element|
          hash_with_id = element.select{|k,v| k == 'id'}
          columns_data = element.reject{|k,v| k == 'id'}
          if ( index = col_data.index{|elt| elt['id'] == hash_with_id['id']} )
            col_data[index][csv_name] << columns_data
          else
            col_data << hash_with_id.merge({ csv_name => [columns_data] })
          end
        end
        col_data
      end
    end
  end

  ## this method groups all information by provider id
  ## see test should condense
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

        if values
          # Adds one of the averages for that particular criteria:
          # Ex:
          # { id: 5, criterium1: { a: 1, b: 3 }, averages: { avg_a_and_b: 1.5 }}
          provider[criteria]["averages"] ||= {}
          provider[criteria]["averages"].merge!({ average_info['name'] => calculate_average(values, selected_keys) })
        end
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

  # TODO: add a separate module for this
  # I need a separate structure to store a lookup table:
  #   for each state in Uruguay,
  #   I want the index of the providers array
  # So the Angular app doesn't need to search the id each time
  #
  # Output example:
  # lookup_table: {
  #   montevideo: [0, 2, 4, 5, 20],
  #   colonia: [0, 2, 3],
  #   ...
  # }
  # TODO: refactor this code
  def self.add_lookup_table!(data)
    data.merge!(lookup_by_state: [])

    data[:providers].each_with_index do |provider, index|
      institutions = provider['sedes']
      states = institutions.map{|s| s["Departamento"]}.compact.uniq
      states.each do |state|
        if lookup = data[:lookup_by_state].find{|s| s[:name] == state}
          lookup[:providers] << index
        else
          data[:lookup_by_state] << { name: state, providers: [index] }
        end
      end
    end
  end

  def self.add_institution_info!(data)
    data[:providers].each do |provider|
      structure_data = provider['estructura']
      structure_data.merge!(estructura_por_departamento: {})

      inst_by_state = provider['sedes'].group_by{|i| i["Departamento"]}
      inst_by_state.each do |state, amount|
        structure_data[:estructura_por_departamento].merge!({ state =>
          {
            'Cantidad de sedes centrales' => count_by_group(inst_by_state[state], "Sede Central"),
            'Cantidad de sedes secundarias' => count_by_group(inst_by_state[state], "Sede Secundaria"),
            'Cantidad de sedes ambulatorias' => count_by_group(inst_by_state[state], "Ambulatorio"),
            'Tiene urgencia' => count_by_group(inst_by_state[state], "Servicio de Urgencia")
          }
        })
      end
    end
  end

  # TODO: refactor
  def self.count_by_group(institutions, group_name)
    institutions.select{|v| v["nivel"] == group_name}.compact.count
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
