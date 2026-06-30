#include "httplib.h"
#include <iostream>
#include <string>
#include <regex>
#include <memory>
#include <array>

std::string exec(const char* cmd) {
    std::array<char, 128> buffer;
    std::string result;
    std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd, "r"), pclose);
    if (!pipe) {
        return "ERROR";
    }
    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
        result += buffer.data();
    }
    return result;
}

int main() {
    httplib::Server svr;

    svr.Get("/v1_soap_client", [](const httplib::Request& req, httplib::Response& res) {
        if (!req.has_param("n")) {
            res.set_content("Por favor, proporcione el parametro n en la URL.", "text/plain; charset=utf-8");
            res.status = 400;
            return;
        }

        std::string n = req.get_param_value("n");
        std::string xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?><soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body><NumberToWords xmlns=\"http://www.dataaccess.com/webservicesserver/\"><ubiNum>" + n + "</ubiNum></NumberToWords></soap:Body></soap:Envelope>";
        
        std::string cmd = "curl -s -X POST -H \"Content-Type: text/xml; charset=utf-8\" -d '" + xml + "' https://www.dataaccess.com/webservicesserver/NumberConversion.wso";
        
        std::string soapResponse = exec(cmd.c_str());
        
        std::smatch match;
        std::regex expr("<m:NumberToWordsResult>(.*?)</m:NumberToWordsResult>");
        
        if (std::regex_search(soapResponse, match, expr) && match.size() > 1) {
            res.set_content(match.str(1), "text/plain; charset=utf-8");
        } else {
            res.status = 500;
            res.set_content("Error en la respuesta SOAP.", "text/plain; charset=utf-8");
        }
    });

    svr.listen("0.0.0.0", 8021);
}