package com.servicios;

import com.sun.net.httpserver.HttpServer;
import okhttp3.OkHttpClient;
import okhttp3.MediaType;
import okhttp3.RequestBody;
import org.json.JSONArray;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.regex.*;

public class V2SoapTranslation {
    public static void main(String[] args) throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(8012), 0);
        OkHttpClient client = new OkHttpClient();

        server.createContext("/v2_soap_translation", exchange -> {
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
                exchange.sendResponseHeaders(400, 0);
                exchange.close();
                return;
            }

            String xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?><soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body><NumberToWords xmlns=\"http://www.dataaccess.com/webservicesserver/\"><ubiNum>" + n + "</ubiNum></NumberToWords></soap:Body></soap:Envelope>";

            try {
                RequestBody body = RequestBody.create(xml, MediaType.parse("text/xml; charset=utf-8"));
                okhttp3.Request soapReq = new okhttp3.Request.Builder()
                        .url("https://www.dataaccess.com/webservicesserver/NumberConversion.wso")
                        .post(body)
                        .build();

                try (okhttp3.Response soapRes = client.newCall(soapReq).execute()) {
                    String soapData = soapRes.body().string();
                    Matcher m = Pattern.compile("<m:NumberToWordsResult>(.*?)</m:NumberToWordsResult>").matcher(soapData);

                    if (m.find()) {
                        String engWord = m.group(1).trim();
                        
                        okhttp3.Request transReq = new okhttp3.Request.Builder()
                                .url("https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=es&dt=t&q=" + engWord.replace(" ", "%20"))
                                .build();

                        try (okhttp3.Response transRes = client.newCall(transReq).execute()) {
                            String transData = transRes.body().string();

                            JSONArray jsonArray = new JSONArray(transData);
                            String translated = jsonArray.getJSONArray(0).getJSONArray(0).getString(0).toLowerCase();

                            byte[] out = translated.getBytes(StandardCharsets.UTF_8);
                            exchange.getResponseHeaders().set("Content-Type", "text/plain; charset=utf-8");
                            exchange.sendResponseHeaders(200, out.length);
                            OutputStream os = exchange.getResponseBody();
                            os.write(out);
                            os.close();
                        }
                    } else {
                        exchange.sendResponseHeaders(500, 0);
                        exchange.close();
                    }
                }
            } catch (Exception e) {
                exchange.sendResponseHeaders(500, 0);
                exchange.close();
            }
        });

        server.start();
        Thread.currentThread().join();
    }
}