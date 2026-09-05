# MYGame Marketplace — Phase 1 Scaffold

## Setup steps (phone only)
1. Create a GitHub repo (e.g. `MYGame-App`).
2. Create every file above at its exact path shown (GitHub app → Add file → Create new file).
3. Create a Firebase project at console.firebase.google.com, add an Android app
   (package name e.g. `com.mygame.app`), download `google-services.json`.
4. Base64-encode `google-services.json`, save it as a GitHub Actions secret named
   `FIREBASE_ANDROID_CONFIG` (Repo → Settings → Secrets and variables → Actions).
5. Enable in Firebase Console: Authentication (Email/Password), Cloud Firestore, Storage.
6. Push any change → GitHub Actions builds the APK automatically → download from
   Actions tab → latest run → Artifacts.

## Next phases
- Add Listing form, Checkout modal, Verification (NIC/Selfie) screen
- Wallet screen + Escrow Cloud Functions
- Admin App (separate repo)
- PayHere payment gateway for real LKR top-ups
