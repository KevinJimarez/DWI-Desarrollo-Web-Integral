use std::process::Command;
use regex::Regex;
use tiny_http::{Server, Response, StatusCode, Header};
use std::str::FromStr;

fn main() {
    let server = Server::http("0.0.0.0:8031").unwrap();

    for request in server.incoming_requests() {
        let url = request.url().to_string();
        
        if !url.starts_with("/v1_soap_client") {
            let _ = request.respond(Response::empty(StatusCode(404)));
            continue;
        }

        let mut n = String::new();
        if let Some(query_idx) = url.find('?') {
            let query = &url[query_idx + 1..];
            for param in query.split('&') {
                let mut pair = param.split('=');
                if let (Some(key), Some(value)) = (pair.next(), pair.next()) {
                    if key == "n" {
                        n = value.to_string();
                        break;
                    }
                }
            }
        }

        if n.is_empty() {
            let response = Response::from_string("Por favor, proporcione el parametro n en la URL.")
                .with_status_code(StatusCode(400));
            let _ = request.respond(response);
            continue;
        }

        let xml = format!(
            "<?xml version=\"1.0\" encoding=\"utf-8\"?><soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body><NumberToWords xmlns=\"http://www.dataaccess.com/webservicesserver/\"><ubiNum>{}</ubiNum></NumberToWords></soap:Body></soap:Envelope>",
            n
        );

        let output = Command::new("curl")
            .arg("-s")
            .arg("-X")
            .arg("POST")
            .arg("-H")
            .arg("Content-Type: text/xml; charset=utf-8")
            .arg("-d")
            .arg(&xml)
            .arg("https://www.dataaccess.com/webservicesserver/NumberConversion.wso")
            .output();

        match output {
            Ok(out) => {
                let soap_response = String::from_utf8_lossy(&out.stdout);
                let re = Regex::new(r"<m:NumberToWordsResult>(.*?)</m:NumberToWordsResult>").unwrap();
                
                if let Some(caps) = re.captures(&soap_response) {
                    let result = caps.get(1).map_or("", |m| m.as_str()).trim();
                    let mut response = Response::from_string(result).with_status_code(StatusCode(200));
                    response.add_header(Header::from_str("Content-Type: text/plain; charset=utf-8").unwrap());
                    let _ = request.respond(response);
                } else {
                    let _ = request.respond(Response::from_string("Error en la respuesta SOAP.").with_status_code(StatusCode(500)));
                }
            }
            Err(_) => {
                let _ = request.respond(Response::empty(StatusCode(500)));
            }
        }
    }
}