FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /source
COPY src/ ./src/
COPY ConstructionSiteManagement.slnx ./
RUN dotnet restore src/CSM.Web/CSM.Web.csproj
RUN dotnet publish src/CSM.Web/CSM.Web.csproj \
    --configuration Release \
    --no-restore \
    --output /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
ENV ASPNETCORE_HTTP_PORTS=10000
EXPOSE 10000
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "CSM.Web.dll"]
