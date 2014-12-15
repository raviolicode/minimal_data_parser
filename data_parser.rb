require_relative 'scraper'

class DataParser
  def initialize
    @merged_data = []
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
      @metadata << OpenStruct.new(attribute: name, filename: "data/#{name}.csv", columns: columns)
    end
  end

  def add_data_from_criteria(metadata_item)
    info = Scraper.scrape(metadata_item.filename, metadata_item.columns)

    info.each do |provider_data|
      provider_id = provider_data["id"]
      provider_data.delete("id")

      existing_provider_data = @merged_data.find {|pdata| pdata[:id] == provider_id}
      if existing_provider_data
        existing_provider_data.merge!({ metadata_item.attribute => provider_data })
      else
        @merged_data << { id: provider_id, metadata_item.attribute => provider_data }
      end
    end
  end
end

