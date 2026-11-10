import '../../domain/entities/citation.dart';

class CitationModel extends Citation {
  const CitationModel({
    required super.citationId,
    required super.documentId,
    required super.documentName,
    required super.chunkId,
    required super.chunkIndex,
    super.pageNumber,
    required super.excerpt,
    super.similarityScore,
  });

  factory CitationModel.fromJson(Map<String, dynamic> json) {
    return CitationModel(
      citationId: json['citation_id'] as String? ?? json['citationId'] as String? ?? '',
      documentId: json['document_id'] as String? ?? json['documentId'] as String? ?? '',
      documentName: json['document_name'] as String? ?? json['documentName'] as String? ?? 'Document',
      chunkId: json['chunk_id'] as String? ?? json['chunkId'] as String? ?? '',
      chunkIndex: json['chunk_index'] as int? ?? json['chunkIndex'] as int? ?? 0,
      pageNumber: json['page_number'] as int? ?? json['pageNumber'] as int?,
      excerpt: json['excerpt'] as String? ?? '',
      similarityScore: (json['similarity_score'] as num? ?? json['similarityScore'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'citation_id': citationId,
      'document_id': documentId,
      'document_name': documentName,
      'chunk_id': chunkId,
      'chunk_index': chunkIndex,
      'page_number': pageNumber,
      'excerpt': excerpt,
      'similarity_score': similarityScore,
    };
  }
}

