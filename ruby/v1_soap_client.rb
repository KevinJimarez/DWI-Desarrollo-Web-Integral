require 'sinatra'

set :port, 8000

get '/v1_soap_client.rb' do
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
    $1.strip
  else
    "Error: No se recibió la estructura esperada del servidor web."
  end
end