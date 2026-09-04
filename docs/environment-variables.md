# DashCore configuration and secrets

DashCore must not package a `.env` file inside the application. Values embedded
in a Flutter or Android build are readable by anyone who obtains the APK.

## Public client configuration

These values may be included in the client, but the backend must enforce Row
Level Security and authorization rules:

- Supabase project URL.
- Supabase publishable/anon key.
- Public redirect URLs.

## Secrets

These values must never be embedded in Flutter assets, Dart constants, Android
resources, or build arguments distributed to users:

- Supabase service-role keys.
- SerpAPI or other paid provider keys.
- Signing-store and signing-key passwords.
- Private API tokens.

Secret-backed requests must be proxied through a trusted backend. The current
SerpAPI integration is not reachable from the production application graph and
must remain disabled until it uses such a backend.
