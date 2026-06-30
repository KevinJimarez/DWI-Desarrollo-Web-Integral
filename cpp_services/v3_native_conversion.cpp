#include "httplib.h"
#include <string>
#include <vector>

const std::vector<std::string> UNIDADES = {"", "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve"};
const std::vector<std::string> DECENAS = {"", "diez", "veinte", "treinta", "cuarenta", "cincuenta", "sesenta", "setenta", "ochenta", "noventa"};

std::string convertir(int n) {
    if (n == 0) return "cero";
    if (n == 15) return "quince";
    if (n < 10) return UNIDADES[n];
    if (n < 20) return "dieci" + UNIDADES[n - 10];
    if (n < 30) return n == 20 ? "veinte" : "veinti" + UNIDADES[n - 20];
    if (n < 100) return DECENAS[n / 10] + (n % 10 == 0 ? "" : " y " + UNIDADES[n % 10]);
    if (n == 100) return "cien";
    return (n < 200 ? "ciento" : UNIDADES[n / 100] + "cientos") + (n % 100 == 0 ? "" : " " + convertir(n % 100));
}

int main() {
    httplib::Server svr;

    svr.Get("/v3_native_conversion", [](const httplib::Request& req, httplib::Response& res) {
        if (!req.has_param("n")) {
            res.status = 400;
            return;
        }
        try {
            int n = std::stoi(req.get_param_value("n"));
            std::string resultado = convertir(n);
            
            size_t start = resultado.find_first_not_of(" ");
            if (start != std::string::npos) resultado = resultado.substr(start);
            
            res.set_content(resultado, "text/plain; charset=utf-8");
        } catch (...) {
            res.status = 500;
        }
    });

    svr.listen("0.0.0.0", 8023);
}

