require_relative 'scraper'

class DataParser
  def initialize
    @merged_data = [ { stats: {} } ]
    @metadata = []
    @criteria = %W(
      precios
      tiempos_espera
      satisfaccion_derechos
      metas
      solicitud_consultas
      rrhh
    )
    build_metadata_info
  end

  def to_JSON(output_filename)
    @metadata.each do |metadata_item|
      add_data_from_criteria(metadata_item)
    end
    File.open(output_filename, 'w') {|f| f.write(JSON.generate(@merged_data))}
  end

  private
  def build_metadata_info
    @criteria.each do |name|
      columns = File.readlines("columns/#{name}.txt").map(&:chomp)
      @metadata << OpenStruct.new(attribute: name, filename: "data/#{name}.csv", columns: columns.map(&:to_sym))
    end
  end

  def add_data_from_criteria(metadata_item)
    info = Scraper.scrape(metadata_item.filename, metadata_item.columns)
    append_stats(metadata_item, info)

    info.each do |provider_data|
      provider_id = provider_data[:id]
      provider_data.delete(:id)

      existing_provider_data = @merged_data.find {|pdata| pdata[:id] == provider_id}
      if existing_provider_data
        existing_provider_data.merge!({ metadata_item.attribute => provider_data })
      else
        @merged_data << { id: provider_id, metadata_item.attribute => provider_data }
      end
    end
  end

  def append_stats(metadata_item, info)
    stats = @merged_data.find {|pdata| pdata[:stats] }[:stats]
    keys = metadata_item.columns.reject{ |key| key.to_s == 'id' }

    new_stats = keys.inject({}){ |result, key| result.merge(calculate_stats(info, key)) }
    stats.merge!({ metadata_item.attribute => new_stats })
  end

  def calculate_stats(info, key)
    raw_data = info.map{ |i| i[key] }
    data = raw_data.compact
    stats = DescriptiveStatistics::Stats.new(data)
    percentiles = [10, 25, 50, 75, 90].
      map{ |perc| { perc => stats.percentile(perc) } }.
      inject({}){ |result, p| result.merge(p) }

    percentiles.merge!( { :perc_no_data => (raw_data.count - data.count) * 1.0 / raw_data.count } )

    { key => percentiles }
  end
end

