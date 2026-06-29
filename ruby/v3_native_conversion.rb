require 'sinatra'

set :port, 8000

def convertir_numero_a_espanol(num)
  num = num.to_i
  return "cero" if num == 0

  unidades = ["", "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve"]
  decenas = ["", "diez", "veinte", "treinta", "cuarenta", "cincuenta", "sesenta", "setenta", "ochenta", "noventa"]
  especiales_10 = {
    11 => "once", 12 => "doce", 13 => "trece", 14 => "catorce", 15 => "quince",
    16 => "dieciséis", 17 => "diecisiete", 18 => "dieciocho", 19 => "diecinueve"
  }
  
  resultado = ""
  
  # Procesamiento de Centenas (Hasta 999)
  if num >= 100
    centena = num / 100
    num %= 100
    if centena == 1 && num == 0
      resultado += "cien "
    elsif centena == 1
      resultado += "ciento "
    elsif centena == 5
      resultado += "quinientos "
    elsif centena == 7
      resultado += "setecientos "
    elsif centena == 9
      resultado += "novecientos "
    else
      resultado += "#{unidades[centena]}cientos "
    end
  end
  
  # Procesamiento de Decenas y Unidades
  if num >= 10 && num <= 19
    if num == 10
      resultado += "diez"
    else
      resultado += especiales_10[num]
    end
  elsif num >= 20 && num <= 29
    if num == 20
      resultado += "veinte"
    else
      veinti_unidades = ["", "veintiuno", "veintidós", "veintitrés", "veinticuatro", "veinticinco", "veintiséis", "veintisiete", "veintiocho", "veintinueve"]
      resultado += veinti_unidades[num - 20]
    end
  elsif num >= 30
    decena = num / 10
    unidad = num % 10
    if unidad == 0
      resultado += decenas[decena]
    else
      resultado += "#{decenas[decena]} y #{unidades[unidad]}"
    end
  elsif num > 0
    resultado += unidades[num]
  end
  
  resultado.strip
end

get '/v3_native_conversion.rb' do
  number = params['n'] || '0'
  
  # Validación de entrada para asegurar que sea un número válido
  if number =~ /^\d+$/
    convertir_numero_a_espanol(number)
  else
    "Por favor, proporcione un número entero válido en el parámetro 'n'."
  end
end