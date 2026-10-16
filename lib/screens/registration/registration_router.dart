import 'package:flutter/material.dart';

import '../../data/registration_data.dart';
import '../../data/server_sync.dart';
import '../main_shell.dart';
import 'registration_flow.dart';
import 'registration_status.dart';

/// Where to go after the OTP is verified: existing members enter the app,
/// new members register, and members awaiting approval see their status.
/// The server decides this in production (OTP verify returns the member state).
void routeAfterOtp(BuildContext context, String phone) {
  final Widget next;
  if (isExistingMember(phone) ||
      (registration.completed &&
          registration.phone == phone &&
          registration.status == RegStatus.approved)) {
    next = const MainShell();
  } else if (registration.completed && registration.phone == phone) {
    next = const RegistrationStatusScreen();
  } else {
    registration.start(phone);
    next = const RegistrationFlow();
  }
  Navigator.of(
    context,
  ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => next), (_) => false);
}

/// Same navigation, but the server decided where the member goes (`home`,
/// `registration` or `registrationStatus` from the OTP verify response).
/// The member's saved details are loaded first, so a returning member resumes.
Future<void> routeAfterServer(
  BuildContext context,
  String phone,
  String next,
) async {
  await loadMemberFromServer(phone);
  if (!context.mounted) return;
  final Widget screen;
  switch (next) {
    case 'home':
      registration.approve();
      screen = const MainShell();
    case 'registrationStatus':
      screen = const RegistrationStatusScreen();
    default:
      screen = RegistrationFlow(initialStep: registration.firstIncompleteStep);
  }
  Navigator.of(
    context,
  ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => screen), (_) => false);
}
