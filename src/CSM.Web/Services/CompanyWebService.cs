using System.Net.Http.Headers;
using System.Net.Http.Json;
using CSM.Web.Models.Companies;

namespace CSM.Web.Services;

public sealed class CompanyWebService
{
    private readonly HttpClient _http;
    private readonly IAuthService _auth;

    public CompanyWebService(HttpClient http, IAuthService auth)
    {
        _http = http;
        _auth = auth;
    }

    private async Task AuthorizeAsync()
    {
        var token = await _auth.GetTokenAsync();
        _http.DefaultRequestHeaders.Authorization = null;

        if (!string.IsNullOrWhiteSpace(token))
        {
            _http.DefaultRequestHeaders.Authorization =
                new AuthenticationHeaderValue("Bearer", token);
        }
    }

    public async Task<List<CompanyLookupModel>> GetLookupAsync()
    {
        await AuthorizeAsync();
        return await _http.GetFromJsonAsync<List<CompanyLookupModel>>("companies/lookup")
               ?? [];
    }

    public async Task<CompanyResponseModel> CreateAsync(CreateCompanyModel model)
    {
        await AuthorizeAsync();

        var response = await _http.PostAsJsonAsync("companies", model);

        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync();
            throw new InvalidOperationException(
                string.IsNullOrWhiteSpace(body)
                    ? $"Could not create company ({(int)response.StatusCode})."
                    : body);
        }

        return await response.Content.ReadFromJsonAsync<CompanyResponseModel>()
               ?? throw new InvalidOperationException("The company creation response was empty.");
    }
}
