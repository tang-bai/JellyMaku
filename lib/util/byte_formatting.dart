const List<String> _byteUnits = <String>['B', 'KB', 'MB', 'GB', 'TB'];

/// Formats a byte count with binary units, for example `1.5 MB`.
String? formatBytes(int? bytes) {
  if (bytes == null || bytes < 0) {
    return null;
  }
  return _formatSize(bytes.toDouble(), _byteUnits, suffix: '');
}

/// Formats a transfer rate, for example `1.5 MB/s`.
String? formatBytesPerSecond(double? bytesPerSecond) {
  if (bytesPerSecond == null || !bytesPerSecond.isFinite || bytesPerSecond < 0) {
    return null;
  }
  return _formatSize(bytesPerSecond, _byteUnits, suffix: '/s');
}

String _formatSize(double value, List<String> units, {required String suffix}) {
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }

  final String number;
  if (unitIndex == 0) {
    number = value.toStringAsFixed(0);
  } else if (value >= 100) {
    number = value.toStringAsFixed(0);
  } else if (value >= 10) {
    number = value.toStringAsFixed(1);
  } else {
    number = value.toStringAsFixed(2);
  }
  return '$number ${units[unitIndex]}$suffix';
}
