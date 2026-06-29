use strict;
use warnings;
use IO::Socket::INET;

# Forzar salida inmediata en consola
$| = 1;

my $server = IO::Socket::INET->new(
    LocalHost => '127.0.0.1',
    LocalPort => 8000,
    Proto     => 'tcp',
    Listen    => 5,
    Reuse     => 1
) or die "No se pudo iniciar el servidor en el puerto 8000: $!\n";

print "Servidor Perl V1 (SOAP) activo en http://localhost:8000/v1_soap_client.pl\n";

while (my $client = $server->accept()) {
    my $request = <$client>;
    next unless $request;
    
    # Extraer el parámetro 'n' de la URL de forma nativa
    my $number = 0;
    if ($request =~ /[\?&]n=(\d+)/) {
        $number = $1;
    }

    # Payload XML SOAP estricto
    my $xml_payload = <<"XML";
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <NumberToWords xmlns="http://www.dataaccess.com/webservicesserver/">
      <ubiNum>$number</ubiNum>
    </NumberToWords>
  </soap:Body>
</soap:Envelope>
XML

    my $wsdl_url = "https://www.dataaccess.com/webservicesserver/NumberConversion.wso?WSDL";
    my $endpoint_url = $wsdl_url;
    $endpoint_url =~ s/\?WSDL//;

    # Consumo SOAP mediante bypass por consola (curl) para evitar conflictos SSL locales
    my $soap_response = `curl -s -X POST -H "Content-Type: text/xml; charset=utf-8" -d '$xml_payload' $endpoint_url`;

    my $response_body = "Error: No se recibió respuesta del servidor SOAP.";
    if ($soap_response =~ /<m:NumberToWordsResult>(.*?)<\/m:NumberToWordsResult>/s) {
        $response_body = $1;
        $response_body =~ s/^\s+|\s+$//g; # Trim
    }

    # Responder al navegador
    print $client "HTTP/1.1 200 OK\r\n";
    print $client "Content-Type: text/plain; charset=utf-8\r\n";
    print $client "Connection: close\r\n\r\n";
    print $client $response_body;
    close $client;
}