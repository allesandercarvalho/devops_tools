import 'dart:io';

class FileSaver {
  static Future<void> saveFile(String content, String fileName) async {
    // For MVP on desktop without path_provider, we try to save to current directory or report path.
    // In a real app we'd use path_provider to find Downloads directory.
    // Here we'll just write to the current working directory which is usually the project root in dev.
    
    final file = File(fileName);
    await file.writeAsString(content);
    // On desktop, we can't easily "download", so this writes to local disk.
    // Use user-visible notification to say where it was saved.
    print('File saved to ${file.absolute.path}');
  }
}
