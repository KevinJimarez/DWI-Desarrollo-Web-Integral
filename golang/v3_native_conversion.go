package main

import (
	"fmt"
	"net/http"
	"strconv"
	"strings"
)

func convertir(num int) string {
	if num == 0 {
		return "cero"
	}

	unidades := []string{"", "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve"}
	decenas := []string{"", "diez", "veinte", "treinta", "cuarenta", "cincuenta", "sesenta", "setenta", "ochenta", "noventa"}
	especiales10 := map[int]string{
		11: "once", 12: "doce", 13: "trece", 14: "catorce", 15: "quince",
		16: "dieciseis", 17: "diecisiete", 18: "dieciocho", 19: "diecinueve",
	}
	veinti := []string{"", "veintiuno", "veintidos", "veintitres", "veinticuatro", "veinticinco", "veintiseis", "veintisiete", "veintiocho", "veintinueve"}

	res := ""

	if num >= 100 {
		centena := num / 100
		num %= 100
		if centena == 1 && num == 0 {
			res += "cien "
		} else if centena == 1 {
			res += "ciento "
		} else if centena == 5 {
			res += "quinientos "
		} else if centena == 7 {
			res += "setecientos "
		} else if centena == 9 {
			res += "novecientos "
		} else {
			res += unidades[centena] + "cientos "
		}
	}

	if num >= 10 && num <= 19 {
		if num == 10 {
			res += "diez"
		} else {
			res += especiales10[num]
		}
	} else if num >= 20 && num <= 29 {
		if num == 20 {
			res += "veinte"
		} else {
			res += veinti[num-20]
		}
	} else if num >= 30 {
		decena := num / 10
		unidad := num % 10
		if unidad == 0 {
			res += decenas[decena]
		} else {
			res += decenas[decena] + " y " + unidades[unidad]
		}
	} else if num > 0 {
		res += unidades[num]
	}

	return strings.TrimSpace(res)
}

func main() {
	http.HandleFunc("/v3_native_conversion", func(w http.ResponseWriter, r *http.Request) {
		nStr := r.URL.Query().Get("n")
		if nStr == "" {
			w.WriteHeader(http.StatusBadRequest)
			w.Header().Set("Content-Type", "text/plain; charset=utf-8")
			fmt.Fprint(w, "Por favor, proporcione el parametro n en la URL.")
			return
		}

		num, err := strconv.Atoi(nStr)
		if err != nil {
			w.WriteHeader(http.StatusBadRequest)
			w.Header().Set("Content-Type", "text/plain; charset=utf-8")
			fmt.Fprint(w, "Por favor, proporcione un parametro n valido.")
			return
		}

		resultado := convertir(num)
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		fmt.Fprint(w, resultado)
	})

	http.ListenAndServe(":8002", nil)
}