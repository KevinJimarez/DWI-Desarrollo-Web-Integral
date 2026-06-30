const http = require('http');
const https = require('https');


const server = http.createServer((req, res) => {
    // Parsear la URL de forma nativa para obtener el parámetro 'n'
    const url = new URL(req.url, `http://${req.headers.host}`);
    const n = url.searchParams.get('n');

    if (!n) {
        res.writeHead(400, { 'Content-Type': 'text/plain; charset=utf-8' });
        return res.end('Por favor, proporcione el parámetro n en la URL.');
    }


    const xmlPayload = `<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <NumberToWords xmlns="http://www.dataaccess.com/webservicesserver/">
      <ubiNum>${n}</ubiNum>
    </NumberToWords>
  </soap:Body>
</soap:Envelope>`;

    // Opciones para la petición HTTPS nativa al WSDL
    const options = {
        hostname: 'www.dataaccess.com',
        port: 443,
        path: '/webservicesserver/NumberConversion.wso',
        method: 'POST',
        headers: {
            'Content-Type': 'text/xml; charset=utf-8',
            'Content-Length': Buffer.byteLength(xmlPayload)
        }
    };

    // Consumo SOAP
    const soapReq = https.request(options, (soapRes) => {
        let data = '';
        
        // Recibir los fragmentos de datos
        soapRes.on('data', (chunk) => {
            data += chunk;
        });

        // Al terminar de recibir la respuesta
        soapRes.on('end', () => {
            const match = data.match(/<m:NumberToWordsResult>(.*?)<\/m:NumberToWordsResult>/);
            const result = match ? match[1].trim() : "Error en la respuesta SOAP";
            
            // Responder al navegador web
            res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
            res.end(result);
        });
    });

    soapReq.on('error', (e) => {
        res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('Error interno del servidor al conectar con el servicio SOAP.');
    });

    soapReq.write(xmlPayload);
    soapReq.end();
});

server.listen(8000, () => {
    console.log('Servidor Node.js V1 (SOAP) activo en http://localhost:8000/v1_soap_client.js');
});