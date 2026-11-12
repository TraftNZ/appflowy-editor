import 'dart:typed_data';

import 'package:appflowy_editor/src/editor/util/file_picker/file_picker_service.dart';
import 'package:file_picker/file_picker.dart' as fp;

class FilePicker implements FilePickerService {
  @override
  Future<String?> getDirectoryPath({String? title}) {
    return fp.FilePicker.getDirectoryPath();
  }

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    fp.FileType type = fp.FileType.any,
    List<String>? allowedExtensions,
    Function(fp.FilePickerStatus p1)? onFileLoading,
    bool allowMultiple = false,
  }) async {
    // file_picker 13 selects one file through pickFile() and several through
    // pickFiles(); file contents are read on demand from the PlatformFile.
    if (!allowMultiple) {
      final file = await fp.FilePicker.pickFile(
        dialogTitle: dialogTitle,
        initialDirectory: initialDirectory,
        type: type,
        allowedExtensions: allowedExtensions,
        onFileLoading: onFileLoading,
      );
      return FilePickerResult(file == null ? const [] : [file]);
    }
    final files = await fp.FilePicker.pickFiles(
      dialogTitle: dialogTitle,
      initialDirectory: initialDirectory,
      type: type,
      allowedExtensions: allowedExtensions,
      onFileLoading: onFileLoading,
    );
    return FilePickerResult(files);
  }

  @override
  Future<String?> saveFile({
    required String fileName,
    required Uint8List bytes,
    String? dialogTitle,
    String? initialDirectory,
  }) async {
    final savedUri = await fp.FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      bytes: bytes,
      initialDirectory: initialDirectory,
    );
    if (savedUri == null) return null;
    // The service reports a location as a string; a `file:` URI is reported as
    // its path so callers can open it with dart:io, and any other scheme
    // (`content:` on Android, `blob:` on web) is reported verbatim.
    return savedUri.scheme == 'file'
        ? savedUri.toFilePath()
        : savedUri.toString();
  }
}
