using System.Diagnostics;
using System.Text;
using System.Text.RegularExpressions;
using GTranslate.Translators;

var builder = WebApplication.CreateBuilder(args);
builder.WebHost.UseUrls("http://localhost:8002");
var app = builder.Build();

app.MapGet("/v2_soap_translation", async (string? n) =>
{
    if (string.IsNullOrEmpty(n))
    {
        return Results.Text("Por favor, proporcione el parametro n en la URL.", "text/plain", Encoding.UTF8, statusCode: 400);
    }

    var xmlPayload = $@"<?xml version=""1.0"" encoding=""utf-8""?>
<soap:Envelope xmlns:soap=""http://schemas.xmlsoap.org/soap/envelope/"">
  <soap:Body>
    <NumberToWords xmlns=""http://www.dataaccess.com/webservicesserver/"">
      <ubiNum>{n}</ubiNum>
    </NumberToWords>
  </soap:Body>
</soap:Envelope>";

    var process = new Process
    {
        StartInfo = new ProcessStartInfo
        {
            FileName = "curl",
            Arguments = "-s -X POST -H \"Content-Type: text/xml; charset=utf-8\" -d @- https://www.dataaccess.com/webservicesserver/NumberConversion.wso",
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            UseShellExecute = false,
            CreateNoWindow = true
        }
    };

    try
    {
        process.Start();
        await process.StandardInput.WriteAsync(xmlPayload);
        process.StandardInput.Close();

        string responseData = await process.StandardOutput.ReadToEndAsync();
        await process.WaitForExitAsync();

        var match = Regex.Match(responseData, @"<m:NumberToWordsResult>(.*?)</m:NumberToWordsResult>");
        var englishWord = match.Success ? match.Groups[1].Value.Trim() : null;

        if (!string.IsNullOrEmpty(englishWord))
        {
            var translator = new GoogleTranslator();
            var translationResult = await translator.TranslateAsync(englishWord, "es");
            return Results.Text(translationResult.Translation.ToLower(), "text/plain", Encoding.UTF8, statusCode: 200);
        }

        return Results.Text("Error: No se pudo extraer la palabra del XML.", "text/plain", Encoding.UTF8, statusCode: 500);
    }
    catch
    {
        return Results.Text("Error interno al procesar la traduccion.", "text/plain", Encoding.UTF8, statusCode: 500);
    }
});

app.Run();