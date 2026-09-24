# MYGame Web
Responsive web frontend based on the uploaded Flutter APK source. It uses the same API base URL and endpoint paths found in `lib/services/api_service.dart`.

## Run
Serve this folder over HTTP/HTTPS (not `file://`). Example: `python3 -m http.server 8080`.

## API
Default base URL: `https://api.finbassshamar.online`.

Browser access requires the API server to allow the website origin via CORS. The frontend stores the auth token in `localStorage` for this prototype.
