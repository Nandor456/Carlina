# Carlina — AutoDoc Tracker

Track Romanian vehicle document expiration dates.
Stack: NestJS API (`api/`) + Flutter mobile app (`mobile/`) + PostgreSQL.

---

## Local development

### Prerequisites
- Docker + Docker Compose
- Node 20+ and npm (for running the API outside Docker)
- Flutter 3.11+ (for the mobile app)

### Bring up the stack
```bash
cp api/.env.example api/.env.development
cp mobile/.env.example mobile/.env

# Postgres + API
cd infra && docker compose up -d
```

The API will be available at `http://localhost:3000/api`.

### Run the mobile app
```bash
cd mobile
flutter pub get
flutter run
```

---

## Deployment

### API
1. Build the Docker image:
   ```bash
   docker build -t carlina-api ./api
   ```
2. Provide the following env vars at runtime (do **not** bake them into the image):
   - `NODE_ENV=production`
   - `DB_HOST`, `DB_PORT`, `DB_USERNAME`, `DB_PASSWORD`, `DB_NAME`
   - `JWT_SECRET` (generate with `openssl rand -hex 32`)
   - `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_CALLBACK_URL`, `GOOGLE_IOS_CLIENT_ID`
   - `FRONTEND_URL` — comma-separated list of allowed CORS origins (**required**)
   - `FIREBASE_SERVICE_ACCOUNT_PATH` — path to the mounted Firebase admin JSON
3. Mount the Firebase admin JSON as a secret volume; never commit it.
4. **Migrations**: schema is currently auto-synced via `DB_SYNC=true`. Before scaling, generate a baseline migration with `npm run db:migrate:generate`, commit it, and set `DB_SYNC=false`.

### Mobile

#### Android
1. Generate a release keystore:
   ```bash
   keytool -genkey -v -keystore ~/carlina-release.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias carlina
   ```
2. Create `mobile/android/key.properties` (gitignored):
   ```
   storeFile=/absolute/path/to/carlina-release.jks
   storePassword=...
   keyAlias=carlina
   keyPassword=...
   ```
3. Build:
   ```bash
   cd mobile && flutter build appbundle --release
   ```

#### iOS
- Bundle id is set in Xcode (`PRODUCT_BUNDLE_IDENTIFIER`). Use Xcode signing & capabilities to attach your Apple Developer team, then `flutter build ipa --release`.

---

## Project structure
- `api/` — NestJS backend (TypeORM + Postgres + JWT + Google OAuth + Firebase push)
- `mobile/` — Flutter app (Riverpod + go_router + Dio)
- `infra/` — Docker Compose stack for local development
