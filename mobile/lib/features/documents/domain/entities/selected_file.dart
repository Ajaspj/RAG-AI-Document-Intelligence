import 'package:equatable/equatable.dart';

class SelectedFile extends Equatable {
  final String path;
  final String name;
  final int size;
  final String extension;
  final String? mimeType;

  const SelectedFile({
    required this.path,
    required this.name,
    required this.size,
    required this.extension,
    this.mimeType,
  });

  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  List<Object?> get props => [path, name, size, extension, mimeType];
}

