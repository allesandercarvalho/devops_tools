
// Stub implementation to satisfy warnings when not compiled on specific platforms
class FileSaver {
  static Future<void> saveFile(String content, String fileName) async {
    throw UnimplementedError('FileSaver not available on this platform');
  }
}
