require 'sinatra'
require 'json'
require 'uri'

set :port, 8000

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

  wsdl_url = "https://www.dataaccess.com/webservicesserver/NumberConversion.wso?WSDL"
  endpoint_url = wsdl_url.gsub("?WSDL", "")
  
  soap_response = `curl -s -X POST -H "Content-Type: text/xml; charset=utf-8" -d '#{xml_payload}' #{endpoint_url}`

  if soap_response =~ /<m:NumberToWordsResult>(.*?)<\/m:NumberToWordsResult>/m
    ingles_words = $1.strip
    
    palabra_codificada = URI.encode_www_form_component(ingles_words)
    translate_url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=es&dt=t&q=#{palabra_codificada}"
    
    api_response = `curl -s "#{translate_url}"`
    
    begin
      datos = JSON.parse(api_response)
      datos[0][0][0].downcase
    rescue
      "Error al procesar la libreria de traduccion JSON."
    end
  else
    "Error: No se recibió la estructura esperada del servidor web."
  end
end