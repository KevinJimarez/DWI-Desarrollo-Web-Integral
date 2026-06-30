package main

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"regexp"
)

func main() {
	http.HandleFunc("/v1_soap_client", func(w http.ResponseWriter, r *http.Request) {
		n := r.URL.Query().Get("n")
		if n == "" {
			w.WriteHeader(http.StatusBadRequest)
			w.Header().Set("Content-Type", "text/plain; charset=utf-8")
			fmt.Fprint(w, "Por favor, proporcione el parametro n en la URL.")
			return
		}

		xmlPayload := fmt.Sprintf(`<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <NumberToWords xmlns="http://www.dataaccess.com/webservicesserver/">
      <ubiNum>%s</ubiNum>
    </NumberToWords>
  </soap:Body>
</soap:Envelope>`, n)

		req, err := http.NewRequest("POST", "https://www.dataaccess.com/webservicesserver/NumberConversion.wso", bytes.NewBufferString(xmlPayload))
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprint(w, "Error interno al crear la peticion")
			return
		}

		req.Header.Set("Content-Type", "text/xml; charset=utf-8")

		client := &http.Client{}
		resp, err := client.Do(req)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprint(w, "Error interno al conectar con SOAP")
			return
		}
		defer resp.Body.Close()

		body, err := io.ReadAll(resp.Body)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprint(w, "Error al leer la respuesta")
			return
		}

		re := regexp.MustCompile(`<m:NumberToWordsResult>(.*?)</m:NumberToWordsResult>`)
		match := re.FindStringSubmatch(string(body))

		if len(match) > 1 {
			w.Header().Set("Content-Type", "text/plain; charset=utf-8")
			fmt.Fprint(w, match[1])
		} else {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprint(w, "Error en la respuesta SOAP")
		}
	})

	http.ListenAndServe(":8000", nil)
}