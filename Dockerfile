# Build stage
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build

WORKDIR /src

COPY ["src/CSM.Api/CSM.Api.csproj", "src/CSM.Api/"]
COPY ["src/CSM.Application/CSM.Application.csproj", "src/CSM.Application/"]
COPY ["src/CSM.Domain/CSM.Domain.csproj", "src/CSM.Domain/"]
COPY ["src/CSM.Infrastructure/CSM.Infrastructure.csproj", "src/CSM.Infrastructure/"]
COPY ["src/CSM.Infrastructure.PostgreSqlMigrations/CSM.Infrastructure.PostgreSqlMigrations.csproj", "src/CSM.Infrastructure.PostgreSqlMigrations/"]

RUN dotnet restore "src/CSM.Api/CSM.Api.csproj"

COPY . .

WORKDIR "/src/src/CSM.Api"

RUN dotnet publish "CSM.Api.csproj" \
    --configuration Release \
    --no-restore \
    --output /app/publish \
    /p:UseAppHost=false


# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final

RUN apt-get update \
    && apt-get install -y --no-install-recommends libgssapi-krb5-2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV ASPNETCORE_HTTP_PORTS=8080

EXPOSE 8080

COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "CSM.Api.dll"]