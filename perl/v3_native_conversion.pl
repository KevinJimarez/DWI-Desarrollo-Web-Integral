use strict;
use warnings;
use IO::Socket::INET;

# Forzar salida inmediata en la consola
$| = 1;

# Función algorítmica basada puramente en el código base del lenguaje
sub convertir_numero_a_espanol {
    my $num = int(shift);
    return "cero" if $num == 0;

    my @unidades = ("", "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve");
    my @decenas = ("", "diez", "veinte", "treinta", "cuarenta", "cincuenta", "sesenta", "setenta", "ochenta", "noventa");
    my %especiales_10 = (
        11 => "once", 12 => "doce", 13 => "trece", 14 => "catorce", 15 => "quince",
        16 => "dieciséis", 17 => "diecisiete", 18 => "dieciocho", 19 => "diecinueve"
    );

    my $resultado = "";

    # Procesamiento de Centenas
    if ($num >= 100) {
        my $centena = int($num / 100);
        $num %= 100;
        if ($centena == 1 && $num == 0) { $resultado .= "cien "; }
        elsif ($centena == 1) { $resultado .= "ciento "; }
        elsif ($centena == 5) { $resultado .= "quinientos "; }
        elsif ($centena == 7) { $resultado .= "setecientos "; }
        elsif ($centena == 9) { $resultado .= "novecientos "; }
        else { $resultado .= $unidades[$centena] . "cientos "; }
    }

    # Procesamiento de Decenas y Unidades
    if ($num >= 10 && $num <= 19) {
        if ($num == 10) { $resultado .= "diez"; }
        else { $resultado .= $especiales_10{$num}; }
    }
    elsif ($num >= 20 && $num <= 29) {
        if ($num == 20) { $resultado .= "veinte"; }
        else {
            my @veinti = ("", "veintiuno", "veintidós", "veintitrés", "veinticuatro", "veinticinco", "veintiséis", "veintisiete", "veintiocho", "veintinueve");
            $resultado .= $veinti[$num - 20];
        }
    }
    elsif ($num >= 30) {
        my $decena = int($num / 10);
        my $unidad = $num % 10;
        if ($unidad == 0) { $resultado .= $decenas[$decena]; }
        else { $resultado .= $decenas[$decena] . " y " . $unidades[$unidad]; }
    }
    elsif ($num > 0) {
        $resultado .= $unidades[$num];
    }

    $resultado =~ s/^\s+|\s+$//g; # Remoción de espacios sobrantes (Trim nativo)
    return $resultado;
}

# Inicialización del servidor HTTP nativo
my $server = IO::Socket::INET->new(
    LocalHost => '127.0.0.1',
    LocalPort => 8000,
    Proto     => 'tcp',
    Listen    => 5,
    Reuse     => 1
) or die "No se pudo iniciar el servidor en el puerto 8000: $!\n";

print "Servidor Perl V3 (Código Base Local) activo en http://localhost:8000/v3_native_conversion.pl\n";

while (my $client = $server->accept()) {
    my $request = <$client>;
    next unless $request;

    my $response_body = "Por favor, proporcione un número válido.";
    if ($request =~ /[\?&]n=(\d+)/) {
        $response_body = convertir_numero_a_espanol($1);
    }

    # Respuesta HTTP estructurada hacia el cliente web
    print $client "HTTP/1.1 200 OK\r\n";
    print $client "Content-Type: text/plain; charset=utf-8\r\n";
    print $client "Connection: close\r\n\r\n";
    print $client $response_body;
    close $client;
}