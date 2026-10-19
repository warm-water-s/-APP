/// 轻量时间格式化，避免为单一展示需求引入 intl 依赖。
String formatSavedTime(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${time.year}-${two(time.month)}-${two(time.day)} '
      '${two(time.hour)}:${two(time.minute)}';
}
