# Render deployment

The root `render.yaml` Blueprint provisions a PostgreSQL database and two
Docker web services: the ASP.NET Core API and Blazor Server web app. Both use
Render's Free plan. SQL Server remains the default database for local
Development; Render runs the separate PostgreSQL EF Core migration assembly.

## Run the Flutter web app locally

The Flutter web app uses the local API at `http://127.0.0.1:5065/api` by
default in debug mode. Start the API and Flutter app in separate terminals:

1. Start the API from the repository root:

   ```powershell
   dotnet run --project src/CSM.Api/CSM.Api.csproj --launch-profile http
   ```

2. From `mobile/csm_app`, fetch Flutter dependencies and run the web app on
   the port already allowed by the API's local CORS settings:

   ```powershell
   flutter pub get
   flutter run -d chrome --web-hostname localhost --web-port 8080
   ```

Open `http://localhost:8080` in Chrome. The API's Development CORS settings
already allow this origin. The default local database and JWT settings still
need to be configured for your machine as described in the sections below.

## Render deployment

The root `render.yaml` Blueprint provisions a PostgreSQL database and two
Docker web services: the ASP.NET Core API and Blazor Server web app. Both use
Render's Free plan. SQL Server remains the default database for local
Development; Render runs the separate PostgreSQL EF Core migration assembly.

### Free-plan limitations

Render describes its Free instances as suitable for hobby projects and
previews, not production:

- A free web service spins down after 15 minutes without inbound traffic and
  can take about a minute to start on the next request. Blazor Server pages and
  SignalR connections can be interrupted by sleep or service restarts.
- Free web services have ephemeral filesystems. Uploaded documents and photos
  saved to the API container can disappear after a restart or redeploy.
- A free Render Postgres database is limited to 1 GB and expires 30 days after
  creation. It becomes inaccessible at expiration and is deleted after a
  further 14-day grace period unless upgraded. Free databases have no Render
  backups.
- Free web services share 750 instance-hours per workspace each month. The
  monthly free allowance can suspend services if exhausted.

The deployment is appropriate for a temporary demo. Do not store data or
uploads that cannot be lost. Back up or migrate the database before its
expiration; to keep it continuously, upgrade the database before day 30.
Check Render's current [free plan limits](https://render.com/docs/free).

## Deploy the Blueprint

1. Push this repository to GitHub and connect the repository to Render.
2. In the Render Dashboard select **New → Blueprint**, choose this repository
   and the `main` branch, and keep the Blueprint path as `render.yaml`.
3. Review the Blueprint. During setup, provide the required
   `CSM_BOOTSTRAP_ADMIN_PASSWORD` secret for initial administrator seeding.
   It must meet the application's six-digit password policy.
4. Deploy the Blueprint. Render builds the API and web Docker images and
   creates the PostgreSQL database. The API applies the PostgreSQL schema
   migration at startup and seeds the initial data.
5. In the Render Dashboard, open the API service and copy its public URL.
   Render supplies this hostname to the web service through `CSM_API_HOST`;
   the web app builds its HTTPS `/api/` base URL from it.
6. After the API logs confirm the administrator has been seeded, remove
   `CSM_BOOTSTRAP_ADMIN_PASSWORD` from the API service's environment settings
   and redeploy.
7. Set the repository variable `CSM_API_BASE_URL` to the public API URL ending
   in `/api` (without a final slash), such as
   `https://csm-api-example.onrender.com/api`. The Android GitHub workflow
   requires this variable to build a release.

The API health endpoint is `/health`. Render terminates public HTTPS and
forwards HTTP to the container; the services listen on Render's default
`PORT` value, 10000. Render sets `RENDER_EXTERNAL_HOSTNAME`; the API and web
use it for production host filtering.

## CORS for Flutter Web

The Blazor Server web app calls the API server-to-server, so it does not
require browser CORS access. Native Android/iOS apps also do not use browser
CORS. If deploying a Flutter Web build that calls the API directly, add its
exact HTTPS origin to the API service environment, for example:

```text
Cors__AllowedOrigins__0=https://your-flutter-web.onrender.com
```

Add more origins with `Cors__AllowedOrigins__1`, etc. Do not include a path or
use wildcards. With no origins configured, browser cross-origin API access is
denied.

## Database settings and migration from SQL Server

The Render Blueprint connects `DATABASE_URL` to the Render Postgres database.
The API converts Render's `postgres://` URL to an Npgsql connection string and
requires TLS. Production selects `Database:Provider=PostgreSQL`; local
development continues to select SQL Server.

The PostgreSQL baseline migration creates an empty schema. It does **not**
transfer rows from your local SQL Server `CSM_DB`, nor copy uploaded files.
Since you said you need existing records preserved, do not treat the Render
database as a migration or backup of SQL Server. Before switching any real
users:

1. Make and verify a complete SQL Server backup; keep the source database
   unchanged.
2. Use a tested SQL Server-to-PostgreSQL conversion in a separate staging
   database. Verify row counts, relationships, dates, decimal values, and
   application workflows before cutover.
3. Export existing document and photo files separately. Render's free
   filesystem is ephemeral, so persistent uploads require external object
   storage or a paid persistent disk.
4. Retain the original SQL Server backup and verify a restore plan. Export
   PostgreSQL data regularly while using the free Render database; Render does
   not back it up.

EF Core migrations run automatically on API startup. Do not deploy this
PostgreSQL configuration against existing production records until the data
conversion has been verified.

## Secrets and runtime configuration

The Blueprint generates a unique JWT signing key. Render's PostgreSQL
connection URL is provided by its database reference. Keep both in Render
environment settings; do not add credentials to source control. The bootstrap
admin password is needed only for initial seeding and should then be removed.

Local SQL Server settings and localhost URLs remain in
`appsettings.Development.json`. Set local `Jwt__SecretKey` and, for a new
database, `CSM_BOOTSTRAP_ADMIN_PASSWORD` in your Windows user environment or
another local secret provider.

## References

- [Render Blueprint specification](https://render.com/docs/blueprint-spec)
- [Render Docker services](https://render.com/docs/docker)
- [Render PostgreSQL connections](https://render.com/docs/postgresql-creating-connecting)
- [Render free plan limits](https://render.com/docs/free)
