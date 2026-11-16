import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/operation.dart';

abstract interface class OperationsRepository {
  Future<List<Operation>> mine(OperationRole role);
  Future<Operation> detail(String id);
  Future<Operation> transition(String id, OperationStatus to);

  /// [scores] usa las claves del API (accuracy, fulfillment, communication, payment, reception).
  Future<void> review(String id, Map<String, int> scores, String? comment);
}

final operationsRepositoryProvider = Provider<OperationsRepository>(
  (ref) => throw UnimplementedError('operationsRepositoryProvider debe sobreescribirse en main.dart'),
);

class ApiOperationsRepository implements OperationsRepository {
  ApiOperationsRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Operation>> mine(OperationRole role) async {
    final response = await _client.get(
      '/operations',
      query: {'role': role == OperationRole.buyer ? 'buyer' : 'seller'},
    ) as Map<String, dynamic>;
    return (response['data'] as List<dynamic>).map((raw) => _fromJson(raw as Map<String, dynamic>)).toList();
  }

  @override
  Future<Operation> detail(String id) async {
    final response = await _client.get('/operations/$id') as Map<String, dynamic>;
    return _fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<Operation> transition(String id, OperationStatus to) async {
    final response = await _client.post('/operations/$id/transition', body: {'status': to.wire}) as Map<String, dynamic>;
    return _fromJson(response['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> review(String id, Map<String, int> scores, String? comment) async {
    await _client.post('/operations/$id/review', body: {
      ...scores,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    });
  }

  Operation _fromJson(Map<String, dynamic> json) {
    final listing = json['listing'] as Map<String, dynamic>;
    final other = json['other_user'] as Map<String, dynamic>;
    return Operation(
      id: '${json['id']}',
      status: OperationStatus.fromWire('${json['status']}'),
      role: json['my_role'] == 'seller' ? OperationRole.seller : OperationRole.buyer,
      total: double.tryParse('${json['total']}') ?? 0,
      quantity: double.tryParse('${json['quantity']}') ?? 0,
      unitPrice: double.tryParse('${json['unit_price']}') ?? 0,
      conversationId: '${json['conversation_id']}',
      listingId: '${listing['id']}',
      listingTitle: listing['title'] as String? ?? '',
      unit: listing['unit'] as String? ?? '',
      coverUrl: listing['cover_url'] as String?,
      counterpart: other['name'] as String? ?? '',
      createdAt: DateTime.tryParse('${json['created_at']}')?.toLocal() ?? DateTime.now(),
      counterpartId: '${other['id']}',
      actions: ((json['actions'] as List<dynamic>?) ?? const []).map((a) => OperationStatus.fromWire('$a')).toList(),
      canReview: json['can_review'] == true,
      reviewed: json['reviewed'] == true,
      events: ((json['events'] as List<dynamic>?) ?? const []).map((raw) {
        final e = raw as Map<String, dynamic>;
        return OperationEvent(
          status: OperationStatus.fromWire('${e['status']}'),
          at: DateTime.tryParse('${e['created_at']}')?.toLocal() ?? DateTime.now(),
          note: e['note'] as String?,
        );
      }).toList(),
    );
  }
}

/// Mis compras / mis ventas. autoDispose: se vuelve a pedir cada vez que se abre la pantalla.
final operationsProvider = FutureProvider.autoDispose.family<List<Operation>, OperationRole>(
  (ref, role) => ref.watch(operationsRepositoryProvider).mine(role),
);

final operationDetailProvider = FutureProvider.autoDispose.family<Operation, String>(
  (ref, id) => ref.watch(operationsRepositoryProvider).detail(id),
);
