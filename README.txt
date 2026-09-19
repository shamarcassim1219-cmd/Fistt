FILES (copy over your ~/Fistt project, same paths):
  pubspec.yaml                          (adds camera + google_mlkit_face_detection)
  lib/screens/verification_screen.dart  (REPLACED - new in-app flow, no website)
  lib/screens/liveness_screen.dart      (NEW)
  lib/services/sl_locations.dart        (NEW)
  lib/services/api_service.dart         (adds submitVerification)
  backend/verification.routes.example.js (reference for your server)
