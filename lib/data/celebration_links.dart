// What a pastor or a cell leader taps to wish a member: a call, or WhatsApp with the greeting already written (they only press
// send). The number is the one the server keeps, with its country code: `+919702236261`.

/// The digits of the number: what a WhatsApp link wants (`919702236261`). Empty when there is no number.
String celebrationDigits(String? mobile) =>
    (mobile ?? '').replaceAll(RegExp(r'\D'), '');

/// A call to the member, or null when the member has no number.
Uri? callLink(String? mobile) {
  final digits = celebrationDigits(mobile);
  return digits.isEmpty ? null : Uri(scheme: 'tel', path: '+$digits');
}

/// WhatsApp opened on the member's chat with [message] typed in, or null when the member has no number.
Uri? whatsappLink(String? mobile, String message) {
  final digits = celebrationDigits(mobile);
  if (digits.isEmpty) return null;
  // A space is %20 (not the + a query map would make): WhatsApp reads it the same way in every app.
  return Uri(
    scheme: 'https',
    host: 'wa.me',
    path: '/$digits',
    query: 'text=${Uri.encodeComponent(message)}',
  );
}
