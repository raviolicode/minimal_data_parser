require_relative 'scraper'

## Data Parser
## (Optional) List of criteria groups
## By default, parses ALL criteria groups
class DataParser
  def initialize(criteria_groups = nil)
    @merged_data = { stats: {}, providers: [] }
    @metadata = []
    @criteria = criteria_groups || %W(
      precios
      tiempos_espera
      metas
      rrhh
      estructura
      satisfaccion_derechos
      solicitud_consultas
    )
    build_metadata_info
  end

  def to_JSON(output_filename)
    @metadata.each do |metadata_item|
      add_data_from_criteria(metadata_item)
    end
    add_summary_data

    File.write(output_filename, JSON.generate(@merged_data))
  end

  private
  def build_metadata_info
    @criteria.each do |name|
      columns = File.readlines("columns/#{name}.txt").map(&:chomp)
      @metadata << OpenStruct.new(attribute: name, filename: "data/#{name}.csv", columns: columns.map(&:to_sym))
    end
  end

  # For a particular criteria
  # I need to add data aggregated by provider
  def add_data_from_criteria(metadata_item)
    info = Scraper.scrape(metadata_item.filename, metadata_item.columns)
    append_stats(metadata_item, info)

    # Each provider data id aggregated into the provider object
    info.each do |provider_data|
      provider_id = provider_data[:id]
      provider_data.delete(:id)

      existing_provider_data = @merged_data[:providers].find {|pdata| pdata[:id] == provider_id}
      if existing_provider_data
        existing_provider_data.merge!({ metadata_item.attribute => provider_data })
      else
        @merged_data[:providers] << { id: provider_id, metadata_item.attribute => provider_data }
      end
    end
  end

  # Add stats for all providers
  # @merged_data[:stats] will have the following structure:
  # stats: {
  #   tiempos_espera: {
  #     medicina_general:
  #       {10 => XX, 25, = XX, ..., 90 => XX, perc_with_data => YY}
  #     ...
  #   }
  # }
  #
  # Where XX are the values of the percentiles for that criterium
  # And YY is the percentage of providers that do have values
  def append_stats(metadata_item, info)
    stats = @merged_data[:stats]
    keys = metadata_item.columns.reject{ |key| key.to_s == 'id' }

    new_stats = keys.inject({}){ |result, key| result.merge(calculate_stats(info, key)) }
    stats.merge!({ metadata_item.attribute => new_stats })
  end

  # Calculate percentiles of a particular criteria
  def calculate_stats(info, key)
    raw_data = info.map{ |i| i[key] }
    data = raw_data.compact
    stats = DescriptiveStatistics::Stats.new(data)
    percentiles = [10, 25, 50, 75, 90].
      map{ |perc| { perc => stats.percentile(perc) } }.
      inject({}){ |result, p| result.merge(p) }

    percentiles.merge!( { perc_with_data: (raw_data.count - data.count) * 1.0 / raw_data.count } )

    { key => percentiles }
  end

  # TODO: refactor
  # calculate data that will be displayed on the summary page
  # this is mostly manual
  # Assumes certain data is present
  def add_summary_data
      medicamentos = %w(
        ticket_general_fonasa
        ticket_general
        topeados_fonasa
        topeados
      )

      tickets = %w(
        med_general
        med_general_fonasa
        pediatria_fonasa
        pediatria
        control_embarazo_fonasa
        control_embarazo
        control_ginecologia
        otras_fonasa
        otras
        domicilio_fonasa
        domicilio
        odontologia_fonasa
        odontologia
        consulta_referencia_fonasa
        consulta_referencia
      )

      tickets_urgentes = %w(
        urgencia_fonasa
        urgencia
        urgencia_domicilio_fonasa
        urgencia_domicilio
      )

      estudios = %w(
        endoscopia_fonasa
        endoscopia
        ecografia_fonasa
        ecografia
        ecodoppler_fonasa
        ecodoppler
        rx_fonasa
        rx
        rx_torax_fonasa
        rx_torax
        rx_colon_fonasa
        rx_colon
        resonancia_fonasa
        resonancia
        tomografia_fonasa
        tomografia
        rutina_fonasa
        rutina
      )

    @merged_data[:providers].each do |provider|
      if (provider['precios'])
        provider['precios'].merge!({
          promedios: {
            medicamentos: average(provider['precios'], medicamentos),
            tickets: average(provider['precios'], tickets),
            tickets_urgentes: average(provider['precios'], tickets_urgentes),
            estudios: average(provider['precios'], estudios)
          }
        })
      else
        # I need to show empty data when I don't have the data
        provider.merge!({ precios: { promedios: {} } })
      end
    end
  end

  # I want the average of the values of the selected keys
  # given a hash "values",
  # and an array of "selected_keys"
  def average(values, selected_keys)
    selected_values = selected_keys.map{|key| values[key.to_sym]}.compact
    avg = selected_values.reduce(:+).to_f / selected_values.size unless selected_values.empty?
    avg
  end
end

