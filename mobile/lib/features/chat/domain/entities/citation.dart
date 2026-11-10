import 'package:equatable/equatable.dart';

class Citation extends Equatable {
  final String citationId;
  final String documentId;
  final String documentName;
  final String chunkId;
  final int chunkIndex;
  final int? pageNumber;
  final String excerpt;
  final double? similarityScore;

  const Citation({
    required this.citationId,
    required this.documentId,
    required this.documentName,
    required this.chunkId,
    required this.chunkIndex,
    this.pageNumber,
    required this.excerpt,
    this.similarityScore,
  });

  String get formattedPage => pageNumber != null ? 'p. $pageNumber' : 'Document';

  @override
  List<Object?> get props => [
        citationId,
        documentId,
        documentName,
        chunkId,
        chunkIndex,
        pageNumber,
        excerpt,
        similarityScore,
      ];
}

