import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;

Widget buildGoogleWebButton() {
  return (GoogleSignInPlatform.instance as web.GoogleSignInPlugin).renderButton(
    configuration: const web.GSIButtonConfiguration(
      type: web.GSIButtonType.icon,
      shape: web.GSIButtonShape.circle,
      theme: web.GSIButtonTheme.filledBlue,
      size: web.GSIButtonSize.large,
    ),
  );
}
