import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class FilePickerResult {
  const FilePickerResult(this.files);

  /// Picked files.
  final List<PlatformFile> files;
}

/// Abstract file picker as a service to implement dependency injection.
abstract class FilePickerService {
  Future<String?> getDirectoryPath({String? title}) async =>
      throw UnimplementedError('getDirectoryPath() has not been implemented.');

  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowMultiple = false,
  }) async => throw UnimplementedError('pickFiles() has not been implemented.');

  /// [fileName] and [bytes] are required: every platform writes the file
  /// itself and has nothing to write without them.
  ///
  /// Returns the saved location — a filesystem path where the platform gives
  /// one, otherwise the URI it returned — or null if the user cancelled.
  Future<String?> saveFile({
    required String fileName,
    required Uint8List bytes,
    String? dialogTitle,
    String? initialDirectory,
  }) async => throw UnimplementedError('saveFile() has not been implemented.');
}
