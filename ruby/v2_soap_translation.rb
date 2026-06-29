require 'sinatra'

set :port, 8000

def traducir_ingles_a_espanol(texto_en)
  termino = texto_en.downcase.strip
  
  diccionario = {
    "zero" => "cero", "one" => "uno", "two" => "dos", "three" => "tres", "four" => "cuatro",
    "five" => "cinco", "six" => "seis", "seven" => "siete", "eight" => "ocho", "nine" => "nueve",
    "ten" => "diez", "eleven" => "once", "twelve" => "doce", "thirteen" => "trece",
    "fourteen" => "catorce", "fifteen" => "quince", "sixteen" => "dieciséis",
    "seventeen" => "diecisiete", "eighteen" => "dieciocho", "nineteen" => "diecinueve",
    "twenty" => "veinte", "thirty" => "treinta", "forty" => "cuarenta", "fifty" => "cincuenta",
    "sixty" => "sesenta", "seventy" => "setenta", "eighty" => "ochenta", "ninety" => "noventa",
    "hundred" => "cien", "thousand" => "mil", "million" => "millón"
  }

  return diccionario[termino] if diccionario.key?(termino)

  palabras = termino.gsub("-", " ").split(" ")
  palabras_traducidas = palabras.map do |palabra|
    if diccionario.key?(palabra)
      diccionario[palabra]
    elsif palabra == "and"
      "y"
    else
      palabra
    end
  end

  resultado = palabras_traducidas.join(" ")
  resultado.gsub!("veinte uno", "veintiuno")
  resultado.gsub!("veinte dos", "veintidos")
  resultado.gsub!("veinte tres", "veintitres")
  resultado.gsub!("veinte cuatro", "veinticuatro")
  resultado.gsub!("veinte cinco", "veinticinco")
  resultado.gsub!("veinte seis", "veintiseis")
  resultado.gsub!("veinte siete", "veintisiete")
  resultado.gsub!("veinte ocho", "veintiocho")
  resultado.gsub!("veinte nueve", "veintinueve")
  resultado.gsub!("veinte y", "veinti")
  
  resultado
end

get '/v2_soap_translation.rb' do
  number = params['n'] || '0'

  xml_payload = <<-XML
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <NumberToWords xmlns="http://www.dataaccess.com/webservicesserver/">
      <ubiNum>#{number}</ubiNum>
    </NumberToWords>
  </soap:Body>
</soap:Envelope>
  XML

  url = "https://www.dataaccess.com/webservicesserver/NumberConversion.wso"
  response = `curl -s -X POST -H "Content-Type: text/xml; charset=utf-8" -d '#{xml_payload}' #{url}`

  if response =~ /<m:NumberToWordsResult>(.*?)<\/m:NumberToWordsResult>/m
    ingles_words = $1.strip
    traducir_ingles_a_espanol(ingles_words)
  else
    "Error: No se recibió la estructura esperada del servidor web."
  end
end