import com.sun.net.httpserver.*;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;

public class V3NativeConversion {
    private static final String[] UNIDADES = {"", "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve"};
    private static final String[] DECENAS = {"", "diez", "veinte", "treinta", "cuarenta", "cincuenta", "sesenta", "setenta", "ochenta", "noventa"};

    private static String convertir(int n) {
        if (n == 0) return "cero";
        if (n == 15) return "quince";
        if (n < 10) return UNIDADES[n];
        if (n < 20) return "dieci" + UNIDADES[n - 10];
        if (n < 30) return n == 20 ? "veinte" : "veinti" + UNIDADES[n - 20];
        if (n < 100) return DECENAS[n / 10] + (n % 10 == 0 ? "" : " y " + UNIDADES[n % 10]);
        if (n == 100) return "cien";
        return (n < 200 ? "ciento" : UNIDADES[n / 100] + "cientos") + (n % 100 == 0 ? "" : " " + convertir(n % 100));
    }

    public static void main(String[] args) throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(8013), 0);
        server.createContext("/v3_native_conversion", exchange -> {
            String query = exchange.getRequestURI().getQuery();
            String nStr = "";

            if (query != null) {
                for (String param : query.split("&")) {
                    String[] pair = param.split("=");
                    if (pair.length > 1 && pair[0].equals("n")) {
                        nStr = pair[1];
                        break;
                    }
                }
            }

            if (nStr.isEmpty()) {
                exchange.sendResponseHeaders(400, 0);
                exchange.close();
                return;
            }

            try {
                int n = Integer.parseInt(nStr);
                String resultado = convertir(n).trim();
                byte[] responseBytes = resultado.getBytes(StandardCharsets.UTF_8);
                
                exchange.getResponseHeaders().set("Content-Type", "text/plain; charset=utf-8");
                exchange.sendResponseHeaders(200, responseBytes.length);
                OutputStream os = exchange.getResponseBody();
                os.write(responseBytes);
                os.close();
            } catch (Exception e) {
                exchange.sendResponseHeaders(500, 0);
                exchange.close();
            }
        });

        server.start();
    }
}

