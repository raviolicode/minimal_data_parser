require 'minitest/autorun'
require_relative '../scraper.rb'

describe Scraper do
  it "scrapes a csv file correctly" do
    file_name = "fixtures/scraper_fixture.csv"
    columns = %W(
      id
      precio_ticket_general_fonasa
      precio_ticket_general
      precio_topeados_fonasa
      precio_topeados
      precio_med_general_fonasa
      precio_med_general
      precio_pediatria_fonasa
      precio_pediatria
      precio_control_embarazo_fonasa
      precio_control_embarazo
      precio_control_ginecologia_fonasa
      precio_control_ginecologia
      precio_otras_fonasa
      precio_otras
      precio_urgencia_fonasa
      precio_urgencia
      precio_domicilio_fonasa
      precio_domicilio
      precio_urgencia_domicilio_fonasa
      precio_urgencia_domicilio
      precio_odontologia_fonasa
      precio_odontologia
      precio_consulta_referencia_fonasa
      precio_consulta_referencia
      precio_endoscopia_fonasa
      precio_endoscopia
      precio_ecografia_fonasa
      precio_ecografia
      precio_ecodoppler_fonasa
      precio_ecodoppler
      precio_rx_fonasa
      precio_rx
      precio_rx_torax_fonasa
      precio_rx_torax
      precio_rx_colon_fonasa
      precio_rx_colon
      precio_resonancia_fonasa
      precio_resonancia
      precio_tomografia_fonasa
      precio_tomografia
      precio_rutina_fonasa
      precio_rutina
    )

    inspected_data = '[{"id"=>62, "precio_ticket_general_fonasa"=>110, "precio_ticket_general"=>110, "precio_topeados_fonasa"=>64, "precio_topeados"=>64, "precio_med_general_fonasa"=>74, "precio_med_general"=>74, "precio_pediatria_fonasa"=>74, "precio_pediatria"=>74, "precio_control_embarazo_fonasa"=>74, "precio_control_embarazo"=>74, "precio_control_ginecologia_fonasa"=>74, "precio_control_ginecologia"=>74, "precio_otras_fonasa"=>199, "precio_otras"=>199, "precio_urgencia_fonasa"=>315, "precio_urgencia"=>315, "precio_domicilio_fonasa"=>321, "precio_domicilio"=>321, "precio_urgencia_domicilio_fonasa"=>404, "precio_urgencia_domicilio"=>404, "precio_odontologia_fonasa"=>444, "precio_odontologia"=>444, "precio_consulta_referencia_fonasa"=>29, "precio_consulta_referencia"=>29, "precio_endoscopia_fonasa"=>128, "precio_endoscopia"=>128, "precio_ecografia_fonasa"=>211, "precio_ecografia"=>211, "precio_ecodoppler_fonasa"=>211, "precio_ecodoppler"=>211, "precio_rx_fonasa"=>86, "precio_rx"=>86, "precio_rx_torax_fonasa"=>86, "precio_rx_torax"=>86, "precio_rx_colon_fonasa"=>126, "precio_rx_colon"=>126, "precio_resonancia_fonasa"=>745, "precio_resonancia"=>745, "precio_tomografia_fonasa"=>244, "precio_tomografia"=>244, "precio_rutina_fonasa"=>192, "precio_rutina"=>192}]'
    Scraper.scrape(file_name, columns).inspect.must_equal inspected_data
  end
end
