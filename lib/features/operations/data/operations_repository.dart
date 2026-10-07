import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/operation.dart';

abstract interface class OperationsRepository {
  Future<List<Operation>> mine(OperationRole role);
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
    );
  }
}

/// Mis compras / mis ventas. autoDispose: se vuelve a pedir cada vez que se abre la pantalla.
final operationsProvider = FutureProvider.autoDispose.family<List<Operation>, OperationRole>(
  (ref, role) => ref.watch(operationsRepositoryProvider).mine(role),
);
