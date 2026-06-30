#include "httplib.h"
#include "json.hpp"
#include <iostream>
#include <string>
#include <regex>
#include <memory>
#include <array>
#include <algorithm>
#include <cctype>

using json = nlohmann::json;

std::string exec(const char* cmd) {
    std::array<char, 128> buffer;
    std::string result;
    std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd, "r"), pclose);
    if (!pipe) return "ERROR";
    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
        result += buffer.data();
    }
    return result;
}

int main() {
    httplib::Server svr;

    svr.Get("/v2_soap_translation", [](const httplib::Request& req, httplib::Response& res) {
        if (!req.has_param("n")) {
            res.set_content("Por favor, proporcione el parametro n", "text/plain; charset=utf-8");
            res.status = 400;
            return;
        }

        std::string n = req.get_param_value("n");
        std::string xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?><soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body><NumberToWords xmlns=\"http://www.dataaccess.com/webservicesserver/\"><ubiNum>" + n + "</ubiNum></NumberToWords></soap:Body></soap:Envelope>";
        
        std::string soapCmd = "curl -s -X POST -H \"Content-Type: text/xml; charset=utf-8\" -d '" + xml + "' https://www.dataaccess.com/webservicesserver/NumberConversion.wso";
        std::string soapResponse = exec(soapCmd.c_str());
        
        std::smatch match;
        std::regex expr("<m:NumberToWordsResult>(.*?)</m:NumberToWordsResult>");
        
        if (std::regex_search(soapResponse, match, expr) && match.size() > 1) {
            std::string engWord = match.str(1);
            
            engWord.erase(engWord.begin(), std::find_if(engWord.begin(), engWord.end(), [](unsigned char ch) { return !std::isspace(ch); }));
            engWord.erase(std::find_if(engWord.rbegin(), engWord.rend(), [](unsigned char ch) { return !std::isspace(ch); }).base(), engWord.end());
            std::string encodedWord = std::regex_replace(engWord, std::regex(" "), "%20");

            std::string transCmd = "curl -s \"https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=es&dt=t&q=" + encodedWord + "\"";
            std::string transResponse = exec(transCmd.c_str());

            try {
                json j = json::parse(transResponse);
                std::string translated = j[0][0][0].get<std::string>();
                std::transform(translated.begin(), translated.end(), translated.begin(), ::tolower);
                res.set_content(translated, "text/plain; charset=utf-8");
            } catch (...) {
                res.status = 500;
                res.set_content("Error procesando JSON de traduccion.", "text/plain; charset=utf-8");
            }
        } else {
            res.status = 500;
            res.set_content("Error en la respuesta SOAP.", "text/plain; charset=utf-8");
        }
    });

    svr.listen("0.0.0.0", 8022);
}

