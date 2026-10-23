/// Log timestamps follow the device clock so they line up with what the user
/// sees in the OS, rendered as `MM.dd-HH:mm` (e.g. `10.22-18:28`).
String formatLogTime(DateTime time) {
  final local = time.toLocal();

  String pad(int value) => value.toString().padLeft(2, '0');

  return '${pad(local.month)}.${pad(local.day)}-${pad(local.hour)}:${pad(local.minute)}';
}
