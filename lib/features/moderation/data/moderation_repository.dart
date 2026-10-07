import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

/// Motivos de reporte: el valor es el que guarda el backend; la etiqueta, lo que ve la persona.
const reportReasons = <String, String>{
  'fraude': 'Fraude',
  'informacion_falsa': 'Información falsa',
  'producto_inexistente': 'Producto inexistente',
  'documentacion_sospechosa': 'Documentación sospechosa',
  'publicacion_duplicada': 'Publicación duplicada',
  'conducta_inapropiada': 'Conducta inapropiada',
  'producto_no_permitido': 'Producto no permitido',
  'otro': 'Otro',
};

/// Publicación visible en espera de revisión.
class QueueItem {
  const QueueItem({
    required this.id,
    required this.title,
    required this.price,
    required this.seller,
    required this.place,
    required this.openReports,
    this.coverUrl,
  });

  final String id;
  final String title;
  final double price;
  final String seller;
  final String place;
  final int openReports;
  final String? coverUrl;
}

class ReportItem {
  const ReportItem({
    required this.id,
    required this.reason,
    required this.reporter,
    required this.listingId,
    required this.listingTitle,
    required this.listingStatus,
    required this.seller,
    this.description,
  });

  final String id;
  final String reason; // valor del backend
  final String? description;
  final String reporter;
  final String? listingId;
  final String listingTitle;
  final String listingStatus;
  final String seller;

  String get reasonLabel => reportReasons[reason] ?? reason;
}

enum ReportAction {
  dismiss('dismiss'),
  resolve('resolve'),
  hideListing('hide_listing');

  const ReportAction(this.wire);
  final String wire;
}

abstract interface class ModerationRepository {
  /// Cualquier usuario con sesión: reportar una publicación.
  Future<void> reportListing(String listingId, String reason, {String? description});

  Future<List<QueueItem>> queue();
  Future<void> approve(String listingId);
  Future<void> reject(String listingId, String reason);

  Future<List<ReportItem>> reports();
  Future<void> resolveReport(String reportId, ReportAction action, {String? note});
}

final moderationRepositoryProvider = Provider<ModerationRepository>(
  (ref) => throw UnimplementedError('moderationRepositoryProvider debe sobreescribirse en main.dart'),
);

final moderationQueueProvider = FutureProvider.autoDispose<List<QueueItem>>(
  (ref) => ref.watch(moderationRepositoryProvider).queue(),
);

final moderationReportsProvider = FutureProvider.autoDispose<List<ReportItem>>(
  (ref) => ref.watch(moderationRepositoryProvider).reports(),
);

class ApiModerationRepository implements ModerationRepository {
  ApiModerationRepository(this._client);

  final ApiClient _client;

  @override
  Future<void> reportListing(String listingId, String reason, {String? description}) async {
    await _client.post('/listings/$listingId/report', body: {
      'reason': reason,
      if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
    });
  }

  @override
  Future<List<QueueItem>> queue() async {
    final response = await _client.get('/moderation/listings') as Map<String, dynamic>;
    return (response['data'] as List<dynamic>).map((raw) {
      final json = raw as Map<String, dynamic>;
      final seller = json['seller'] as Map<String, dynamic>? ?? const {};
      final loc = json['location'] as Map<String, dynamic>?;
      final media = json['media'] as List<dynamic>? ?? const [];
      final place = [loc?['municipality'], loc?['state']].where((e) => e != null && '$e'.isNotEmpty).join(', ');
      return QueueItem(
        id: '${json['id']}',
        title: json['title'] as String? ?? '',
        price: double.tryParse('${json['price'] ?? 0}') ?? 0,
        seller: seller['name'] as String? ?? '',
        place: place,
        openReports: int.tryParse('${json['open_reports']}') ?? 0,
        coverUrl: media.isEmpty ? null : (media.first as Map<String, dynamic>)['url'] as String?,
      );
    }).toList();
  }

  @override
  Future<void> approve(String listingId) async {
    await _client.post('/moderation/listings/$listingId/approve');
  }

  @override
  Future<void> reject(String listingId, String reason) async {
    await _client.post('/moderation/listings/$listingId/reject', body: {'reason': reason});
  }

  @override
  Future<List<ReportItem>> reports() async {
    final response = await _client.get('/moderation/reports') as Map<String, dynamic>;
    return (response['data'] as List<dynamic>).map((raw) {
      final json = raw as Map<String, dynamic>;
      final listing = json['listing'] as Map<String, dynamic>?;
      return ReportItem(
        id: '${json['id']}',
        reason: '${json['reason']}',
        description: json['description'] as String?,
        reporter: json['reporter_name'] as String? ?? '',
        listingId: listing == null ? null : '${listing['id']}',
        listingTitle: listing?['title'] as String? ?? '(publicación eliminada)',
        listingStatus: listing?['status'] as String? ?? '',
        seller: listing?['seller_name'] as String? ?? '',
      );
    }).toList();
  }

  @override
  Future<void> resolveReport(String reportId, ReportAction action, {String? note}) async {
    await _client.post('/moderation/reports/$reportId/resolve', body: {
      'action': action.wire,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
  }
}
