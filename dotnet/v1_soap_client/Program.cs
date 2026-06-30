using System.Diagnostics;
using System.Text;
using System.Text.RegularExpressions;

var builder = WebApplication.CreateBuilder(args);
builder.WebHost.UseUrls("http://localhost:8001");
var app = builder.Build();

app.MapGet("/v1_soap_client", async (string? n) =>
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
        var result = match.Success ? match.Groups[1].Value.Trim() : "Error en la respuesta SOAP";

        return Results.Text(result, "text/plain", Encoding.UTF8, statusCode: 200);
    }
    catch (Exception ex)
    {
        return Results.Text($"Error interno: {ex.Message}", "text/plain", Encoding.UTF8, statusCode: 500);
    }
});

app.Run();