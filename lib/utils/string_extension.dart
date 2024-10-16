extension StringExtension on String {
  String capitalize() {
    if (this.length > 1) return "${this[0].toUpperCase()}${this.substring(1)}";
    if (this.length == 1) return this[0].toUpperCase();
    return "";
  }
}