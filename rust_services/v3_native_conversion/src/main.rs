use std::str::FromStr;
use tiny_http::{Header, Response, Server, StatusCode};

const UNIDADES: [&str; 10] = ["", "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve"];
const DECENAS: [&str; 10] = ["", "diez", "veinte", "treinta", "cuarenta", "cincuenta", "sesenta", "setenta", "ochenta", "noventa"];

fn convertir(n: usize) -> String {
    if n == 0 { return "cero".to_string(); }
    if n == 15 { return "quince".to_string(); }
    if n < 10 { return UNIDADES[n].to_string(); }
    if n < 20 { return format!("dieci{}", UNIDADES[n - 10]); }
    if n < 30 {
        return if n == 20 { "veinte".to_string() } else { format!("veinti{}", UNIDADES[n - 20]) };
    }
    if n < 100 {
        let base = DECENAS[n / 10].to_string();
        return if n % 10 == 0 { base } else { format!("{} y {}", base, UNIDADES[n % 10]) };
    }
    if n == 100 { return "cien".to_string(); }
    
    let centena = if n < 200 { "ciento".to_string() } else { format!("{}cientos", UNIDADES[n / 100]) };
    if n % 100 == 0 { centena } else { format!("{} {}", centena, convertir(n % 100)) }
}

fn main() {
    let server = Server::http("0.0.0.0:8033").unwrap();

    for request in server.incoming_requests() {
        let url = request.url().to_string();

        if !url.starts_with("/v3_native_conversion") {
            let _ = request.respond(Response::empty(StatusCode(404)));
            continue;
        }

        let mut n_str = String::new();
        if let Some(query_idx) = url.find('?') {
            let query = &url[query_idx + 1..];
            for param in query.split('&') {
                let mut pair = param.split('=');
                if let (Some(key), Some(value)) = (pair.next(), pair.next()) {
                    if key == "n" {
                        n_str = value.to_string();
                        break;
                    }
                }
            }
        }

        if n_str.is_empty() {
            let _ = request.respond(Response::empty(StatusCode(400)));
            continue;
        }

        if let Ok(n) = n_str.parse::<usize>() {
            let resultado = convertir(n).trim().to_string();
            let mut response = Response::from_string(resultado).with_status_code(StatusCode(200));
            response.add_header(Header::from_str("Content-Type: text/plain; charset=utf-8").unwrap());
            let _ = request.respond(response);
        } else {
            let _ = request.respond(Response::empty(StatusCode(400)));
        }
    }
}