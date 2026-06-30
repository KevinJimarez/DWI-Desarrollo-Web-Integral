using System.Text;

var builder = WebApplication.CreateBuilder(args);
builder.WebHost.UseUrls("http://localhost:8003");
var app = builder.Build();

string Convertir(int num)
{
    if (num == 0) return "cero";

    var unidades = new[] { "", "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve" };
    var decenas = new[] { "", "diez", "veinte", "treinta", "cuarenta", "cincuenta", "sesenta", "setenta", "ochenta", "noventa" };
    var especiales10 = new Dictionary<int, string> {
        {11, "once"}, {12, "doce"}, {13, "trece"}, {14, "catorce"}, {15, "quince"},
        {16, "dieciseis"}, {17, "diecisiete"}, {18, "dieciocho"}, {19, "diecinueve"}
    };
    var veinti = new[] { "", "veintiuno", "veintidos", "veintitres", "veinticuatro", "veinticinco", "veintiseis", "veintisiete", "veintiocho", "veintinueve" };

    string res = "";

    if (num >= 100)
    {
        int centena = num / 100;
        num %= 100;
        if (centena == 1 && num == 0) res += "cien ";
        else if (centena == 1) res += "ciento ";
        else if (centena == 5) res += "quinientos ";
        else if (centena == 7) res += "setecientos ";
        else if (centena == 9) res += "novecientos ";
        else res += unidades[centena] + "cientos ";
    }

    if (num >= 10 && num <= 19)
    {
        if (num == 10) res += "diez";
        else res += especiales10[num];
    }
    else if (num >= 20 && num <= 29)
    {
        if (num == 20) res += "veinte";
        else res += veinti[num - 20];
    }
    else if (num >= 30)
    {
        int decena = num / 10;
        int unidad = num % 10;
        if (unidad == 0) res += decenas[decena];
        else res += decenas[decena] + " y " + unidades[unidad];
    }
    else if (num > 0)
    {
        res += unidades[num];
    }

    return res.Trim();
}

app.MapGet("/v3_native_conversion", (string? n) =>
{
    if (string.IsNullOrEmpty(n) || !int.TryParse(n, out int number))
    {
        return Results.Text("Por favor, proporcione un parametro n valido en la URL.", "text/plain", Encoding.UTF8, statusCode: 400);
    }

    var result = Convertir(number);
    return Results.Text(result, "text/plain", Encoding.UTF8, statusCode: 200);
});

app.Run();