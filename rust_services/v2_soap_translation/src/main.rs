use regex::Regex;
use serde_json::Value;
use std::str::FromStr;
use tiny_http::{Header, Response, Server, StatusCode};

fn main() {
    let server = Server::http("0.0.0.0:8032").unwrap();
    let client = reqwest::blocking::Client::new();

    for request in server.incoming_requests() {
        let url = request.url().to_string();

        if !url.starts_with("/v2_soap_translation") {
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
            let response = Response::from_string("Por favor, proporcione el parametro n")
                .with_status_code(StatusCode(400));
            let _ = request.respond(response);
            continue;
        }

        let xml = format!(
            "<?xml version=\"1.0\" encoding=\"utf-8\"?><soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body><NumberToWords xmlns=\"http://www.dataaccess.com/webservicesserver/\"><ubiNum>{}</ubiNum></NumberToWords></soap:Body></soap:Envelope>",
            n
        );

        let soap_res = client
            .post("https://www.dataaccess.com/webservicesserver/NumberConversion.wso")
            .header("Content-Type", "text/xml; charset=utf-8")
            .body(xml)
            .send();

        match soap_res {
            Ok(res) => {
                let soap_body = res.text().unwrap_or_default();
                let re = Regex::new(r"<m:NumberToWordsResult>(.*?)</m:NumberToWordsResult>").unwrap();

                if let Some(caps) = re.captures(&soap_body) {
                    let eng_word = caps.get(1).map_or("", |m| m.as_str()).trim();
                    let encoded_word = eng_word.replace(" ", "%20");

                    let trans_url = format!(
                        "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=es&dt=t&q={}",
                        encoded_word
                    );

                    if let Ok(trans_res) = client.get(&trans_url).send() {
                        let trans_body = trans_res.text().unwrap_or_default();
                        
                        if let Ok(json) = serde_json::from_str::<Value>(&trans_body) {
                            if let Some(translated) = json[0][0][0].as_str() {
                                let mut response = Response::from_string(translated.to_lowercase())
                                    .with_status_code(StatusCode(200));
                                response.add_header(
                                    Header::from_str("Content-Type: text/plain; charset=utf-8").unwrap(),
                                );
                                let _ = request.respond(response);
                                continue;
                            }
                        }
                    }
                }
                let _ = request.respond(Response::empty(StatusCode(500)));
            }
            Err(_) => {
                let _ = request.respond(Response::empty(StatusCode(500)));
            }
        }
    }
}