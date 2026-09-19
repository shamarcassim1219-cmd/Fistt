Flutter (copy into ~/Fistt, same path):
  lib/screens/verification_screen.dart   (auto-result handling)
Server (copy to your backend):
  backend/autoVerify.js                  (OCR + face match + NIC/birthday check)
  backend/autoVerify.test.js             (node autoVerify.test.js)
  backend/verification.routes.example.js (how to call it)
Server setup:  npm i @aws-sdk/client-rekognition multer
Env vars:      AWS_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
