const http = require('http');

function convertir(num) {
    num = parseInt(num, 10);
    if (num === 0) return "cero";

    const unidades = ["", "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve"];
    const decenas = ["", "diez", "veinte", "treinta", "cuarenta", "cincuenta", "sesenta", "setenta", "ochenta", "noventa"];
    const especiales10 = {
        11: "once", 12: "doce", 13: "trece", 14: "catorce", 15: "quince",
        16: "dieciséis", 17: "diecisiete", 18: "dieciocho", 19: "diecinueve"
    };

    let res = "";

    if (num >= 100) {
        let centena = Math.floor(num / 100);
        num %= 100;
        if (centena === 1 && num === 0) res += "cien ";
        else if (centena === 1) res += "ciento ";
        else if (centena === 5) res += "quinientos ";
        else if (centena === 7) res += "setecientos ";
        else if (centena === 9) res += "novecientos ";
        else res += unidades[centena] + "cientos ";
    }

    if (num >= 10 && num <= 19) {
        if (num === 10) res += "diez";
        else res += especiales10[num];
    } else if (num >= 20 && num <= 29) {
        if (num === 20) res += "veinte";
        else {
            const veinti = ["", "veintiuno", "veintidós", "veintitrés", "veinticuatro", "veinticinco", "veintiséis", "veintisiete", "veintiocho", "veintinueve"];
            res += veinti[num - 20];
        }
    } else if (num >= 30) {
        let decena = Math.floor(num / 10);
        let unidad = num % 10;
        if (unidad === 0) res += decenas[decena];
        else res += decenas[decena] + " y " + unidades[unidad];
    } else if (num > 0) {
        res += unidades[num];
    }

    return res.trim();
}

const server = http.createServer((req, res) => {
    const url = new URL(req.url, `http://${req.headers.host}`);
    const n = url.searchParams.get('n');

    let responseBody = "Por favor, proporcione el parámetro n en la URL.";
    if (n) {
        responseBody = convertir(n);
    }

    res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end(responseBody);
});

server.listen(8000, () => {
    console.log('Servidor Node.js V3 activo en http://localhost:8000/v3_native_conversion.js');
});