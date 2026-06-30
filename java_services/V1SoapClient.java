import com.sun.net.httpserver.*;
import java.io.*;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.regex.*;

public class V1SoapClient {
    public static void main(String[] args) throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(8011), 0);
        server.createContext("/v1_soap_client", exchange -> {
            String query = exchange.getRequestURI().getQuery();
            String n = "";
            
            if (query != null) {
                for (String param : query.split("&")) {
                    String[] pair = param.split("=");
                    if (pair.length > 1 && pair[0].equals("n")) {
                        n = pair[1];
                        break;
                    }
                }
            }

            if (n.isEmpty()) {
                String error = "Por favor, proporcione el parametro n en la URL.";
                byte[] responseBytes = error.getBytes(StandardCharsets.UTF_8);
                exchange.getResponseHeaders().set("Content-Type", "text/plain; charset=utf-8");
                exchange.sendResponseHeaders(400, responseBytes.length);
                OutputStream os = exchange.getResponseBody();
                os.write(responseBytes);
                os.close();
                return;
            }

            String xmlPayload = "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
                    + "<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">"
                    + "  <soap:Body>"
                    + "    <NumberToWords xmlns=\"http://www.dataaccess.com/webservicesserver/\">"
                    + "      <ubiNum>" + n + "</ubiNum>"
                    + "    </NumberToWords>"
                    + "  </soap:Body>"
                    + "</soap:Envelope>";

            try {
                Process process = new ProcessBuilder("curl", "-s", "-X", "POST",
                        "-H", "Content-Type: text/xml; charset=utf-8",
                        "-d", xmlPayload,
                        "https://www.dataaccess.com/webservicesserver/NumberConversion.wso")
                        .start();

                BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream(), StandardCharsets.UTF_8));
                StringBuilder responseBuilder = new StringBuilder();
                String line;
                while ((line = reader.readLine()) != null) {
                    responseBuilder.append(line);
                }
                process.waitFor();

                String responseData = responseBuilder.toString();
                Matcher matcher = Pattern.compile("<m:NumberToWordsResult>(.*?)</m:NumberToWordsResult>").matcher(responseData);
                
                if (matcher.find()) {
                    String result = matcher.group(1).trim();
                    byte[] responseBytes = result.getBytes(StandardCharsets.UTF_8);
                    exchange.getResponseHeaders().set("Content-Type", "text/plain; charset=utf-8");
                    exchange.sendResponseHeaders(200, responseBytes.length);
                    OutputStream os = exchange.getResponseBody();
                    os.write(responseBytes);
                    os.close();
                } else {
                    String error = "Error en la respuesta SOAP.";
                    byte[] responseBytes = error.getBytes(StandardCharsets.UTF_8);
                    exchange.sendResponseHeaders(500, responseBytes.length);
                    OutputStream os = exchange.getResponseBody();
                    os.write(responseBytes);
                    os.close();
                }
            } catch (Exception e) {
                exchange.sendResponseHeaders(500, 0);
                exchange.close();
            }
        });

        server.start();
    }
}