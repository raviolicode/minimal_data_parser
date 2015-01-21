require_relative 'auto_data_parser.rb'
require 'json'

  # rrhh
  # estructura_general
  # indicadores_sinadi?

criteria_groups = %W(
  estructura
  metas
  precios
  satisfaccion_derechos
  solicitud_consultas
  tiempos_espera
)

AutoDataParser.process('output/details.json', 'data', criteria_groups)
