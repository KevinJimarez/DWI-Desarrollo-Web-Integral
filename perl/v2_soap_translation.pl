use strict;
use warnings;
use IO::Socket::INET;

# Importamos las librerías instaladas
use LWP::UserAgent;
use HTTP::Request::Common;
use JSON::PP;

$| = 1;

my $server = IO::Socket::INET->new(
    LocalHost => '127.0.0.1',
    LocalPort => 8000,
    Proto     => 'tcp',
    Listen    => 5,
    Reuse     => 1
) or die "No se pudo iniciar el servidor en el puerto 8000: $!\n";

print "Servidor Perl V2 (Librería de Traducción) activo en http://localhost:8000/v2_soap_translation.pl\n";

while (my $client = $server->accept()) {
    my $request = <$client>;
    next unless $request;
    
    my $number = 0;
    if ($request =~ /[\?&]n=(\d+)/) {
        $number = $1;
    }

    # 1. Consumo del servicio web SOAP público (DataAccess)
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

    my $endpoint_url = "https://www.dataaccess.com/webservicesserver/NumberConversion.wso";
    my $soap_response = `curl -s -X POST -H "Content-Type: text/xml; charset=utf-8" -d '$xml_payload' $endpoint_url`;

    my $ingles_words = "";
    if ($soap_response =~ /<m:NumberToWordsResult>(.*?)<\/m:NumberToWordsResult>/s) {
        $ingles_words = $1;
        $ingles_words =~ s/^\s+|\s+$//g;
    }

    # 2. Uso de librería para traducir de inglés a español
    # Utilizamos LWP::UserAgent (librería estándar robusta de Perl) para gestionar 
    # la traducción a través de un endpoint público y JSON::PP para procesar el resultado.
    my $spanish_words = "Error en la traducción";
    
    if ($ingles_words) {
        my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
        my $translate_url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=es&dt=t&q=" . $ingles_words;
        
        my $res = $ua->get($translate_url);
        
        if ($res->is_success) {
            eval {
                my $json = JSON::PP->new;
                my $datos = $json->decode($res->decoded_content);
                $spanish_words = lc($datos->[0]->[0]->[0]);
            };
        }
    }

    print $client "HTTP/1.1 200 OK\r\n";
    print $client "Content-Type: text/plain; charset=utf-8\r\n";
    print $client "Connection: close\r\n\r\n";
    print $client $spanish_words;
    close $client;
}