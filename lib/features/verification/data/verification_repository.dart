import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/application/auth_controller.dart';

/// Estado de mi verificación como vendedor.
class VerificationStatus {
  const VerificationStatus({required this.isVerified, this.status, this.businessName, this.rejectionReason});

  final bool isVerified;

  /// pending | approved | rejected | null (nunca ha solicitado)
  final String? status;
  final String? businessName;
  final String? rejectionReason;

  bool get isPending => status == 'pendiente';
  bool get isRejected => status == 'rechazada' && !isVerified;
}

class VerificationDoc {
  const VerificationDoc({required this.id, required this.type});
  final String id;
  final String type;

  String get label => switch (type) {
        'identificacion' => 'Identificación',
        'comprobante_actividad' => 'Comprobante de actividad',
        _ => 'Otro documento',
      };
}

/// Solicitud pendiente, vista por moderación.
class PendingVerification {
  const PendingVerification({
    required this.id,
    required this.userName,
    required this.userEmail,
    required this.documents,
    this.businessName,
  });

  final String id;
  final String userName;
  final String userEmail;
  final String? businessName;
  final List<VerificationDoc> documents;
}

abstract interface class VerificationRepository {
  Future<VerificationStatus> status();
  Future<void> submit({String? businessName, required String idPath, required String activityPath, String? otherPath});

  // Moderación
  Future<List<PendingVerification>> pending();
  Future<Uint8List> documentBytes(String requestId, String docId);
  Future<void> approve(String id);
  Future<void> reject(String id, String reason);
}

final verificationRepositoryProvider = Provider<VerificationRepository>(
  (ref) => throw UnimplementedError('verificationRepositoryProvider debe sobreescribirse en main.dart'),
);

final verificationStatusProvider = FutureProvider.autoDispose<VerificationStatus>((ref) {
  ref.watch(authProvider);
  return ref.watch(verificationRepositoryProvider).status();
});

final pendingVerificationsProvider = FutureProvider.autoDispose<List<PendingVerification>>(
  (ref) => ref.watch(verificationRepositoryProvider).pending(),
);

class ApiVerificationRepository implements VerificationRepository {
  ApiVerificationRepository(this._client);

  final ApiClient _client;

  @override
  Future<VerificationStatus> status() async {
    final r = await _client.get('/verification') as Map<String, dynamic>;
    final d = r['data'] as Map<String, dynamic>;
    final req = d['request'] as Map<String, dynamic>?;
    return VerificationStatus(
      isVerified: d['is_verified'] == true,
      status: req?['status'] as String?,
      businessName: req?['business_name'] as String?,
      rejectionReason: req?['rejection_reason'] as String?,
    );
  }

  @override
  Future<void> submit({String? businessName, required String idPath, required String activityPath, String? otherPath}) async {
    await _client.postMultipartForm(
      '/verification',
      fields: {if (businessName != null && businessName.trim().isNotEmpty) 'business_name': businessName.trim()},
      files: {
        'id_document': idPath,
        'activity_document': activityPath,
        if (otherPath != null) 'other_document': otherPath,
      },
    );
  }

  @override
  Future<List<PendingVerification>> pending() async {
    final r = await _client.get('/moderation/verifications') as Map<String, dynamic>;
    return (r['data'] as List<dynamic>).map((raw) {
      final j = raw as Map<String, dynamic>;
      final user = j['user'] as Map<String, dynamic>? ?? const {};
      return PendingVerification(
        id: '${j['id']}',
        businessName: j['business_name'] as String?,
        userName: user['name'] as String? ?? '',
        userEmail: user['email'] as String? ?? '',
        documents: [
          for (final d in (j['documents'] as List<dynamic>? ?? const []))
            VerificationDoc(id: '${(d as Map<String, dynamic>)['id']}', type: '${d['type']}'),
        ],
      );
    }).toList();
  }

  @override
  Future<Uint8List> documentBytes(String requestId, String docId) =>
      _client.getBytes('/moderation/verifications/$requestId/documents/$docId');

  @override
  Future<void> approve(String id) async => _client.post('/moderation/verifications/$id/approve');

  @override
  Future<void> reject(String id, String reason) async =>
      _client.post('/moderation/verifications/$id/reject', body: {'reason': reason});
}
