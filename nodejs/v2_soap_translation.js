const http = require('http');
const https = require('https');

const translate = require('translate-google');

const server = http.createServer((req, res) => {
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

    // 2. Consumo del servicio web SOAP público
    const soapReq = https.request(options, (soapRes) => {
        let data = '';
        
        soapRes.on('data', (chunk) => {
            data += chunk;
        });

        soapRes.on('end', async () => {
            const match = data.match(/<m:NumberToWordsResult>(.*?)<\/m:NumberToWordsResult>/);
            const englishWord = match ? match[1].trim() : null;

            if (englishWord) {
                try {
                    // 3. Uso de la librería para traducir de inglés a español
                    // Aprovechamos la naturaleza asíncrona de Node.js con await
                    const spanishWord = await translate(englishWord, { to: 'es' });
                    
                    res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
                    res.end(spanishWord.toLowerCase());
                } catch (error) {
                    res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
                    res.end('Error al procesar la traducción con la librería.');
                }
            } else {
                res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
                res.end('Error: No se pudo extraer la palabra del XML.');
            }
        });
    });

    soapReq.on('error', (e) => {
        res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('Error interno al conectar con SOAP.');
    });

    soapReq.write(xmlPayload);
    soapReq.end();
});

server.listen(8000, () => {
    console.log('Servidor Node.js V2 (Traducción) activo en http://localhost:8000/v2_soap_translation.js');
});