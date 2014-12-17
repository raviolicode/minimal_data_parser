require_relative 'data_parser.rb'

criteria_groups = %W(
  precios
  tiempos_espera
  metas
  rrhh
  estructura
)

DataParser.new.to_JSON('output/details.json')
DataParser.new(criteria_groups).to_JSON('output/listing.json')
