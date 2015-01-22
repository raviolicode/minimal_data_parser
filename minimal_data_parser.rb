require_relative 'auto_data_parser.rb'
require 'json'

  # rrhh
  # estructura_general
  # indicadores_sinadi?

#   estructura
#   metas
#   precios
#
#   solicitud_consultas
#   tiempos_espera
#   sedes
criteria_groups = %W(
  satisfaccion_derechos
)

AutoDataParser.process('output/details.json', 'data', criteria_groups)
