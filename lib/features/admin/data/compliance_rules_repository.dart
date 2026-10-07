import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class ComplianceRule {
  const ComplianceRule({
    required this.id,
    required this.title,
    required this.sourceName,
    required this.documentSuggested,
    required this.documentRequired,
    this.productTypeId,
    this.categoryId,
    this.description,
    this.sourceUrl,
  });

  final int id;
  final int? productTypeId;
  final int? categoryId;
  final String title;
  final String? description;
  final String sourceName;
  final String? sourceUrl;
  final bool documentSuggested;
  final bool documentRequired;

  factory ComplianceRule.fromJson(Map<String, dynamic> j) => ComplianceRule(
        id: int.tryParse('${j['id']}') ?? 0,
        productTypeId: int.tryParse('${j['product_type_id']}'),
        categoryId: int.tryParse('${j['category_id']}'),
        title: j['title'] as String? ?? '',
        description: j['description'] as String?,
        sourceName: j['source_name'] as String? ?? '',
        sourceUrl: j['source_url'] as String?,
        documentSuggested: j['document_suggested'] == true,
        documentRequired: j['document_required'] == true,
      );
}

abstract interface class ComplianceRulesRepository {
  Future<List<ComplianceRule>> list();
  Future<void> create(Map<String, dynamic> body);
  Future<void> update(int id, Map<String, dynamic> body);
  Future<void> delete(int id);
}

final complianceRulesRepositoryProvider = Provider<ComplianceRulesRepository>(
  (ref) => throw UnimplementedError('complianceRulesRepositoryProvider debe sobreescribirse en main.dart'),
);

final complianceRulesProvider = FutureProvider.autoDispose<List<ComplianceRule>>(
  (ref) => ref.watch(complianceRulesRepositoryProvider).list(),
);

class ApiComplianceRulesRepository implements ComplianceRulesRepository {
  ApiComplianceRulesRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<ComplianceRule>> list() async {
    final r = await _client.get('/admin/compliance-rules') as Map<String, dynamic>;
    return (r['data'] as List<dynamic>).map((e) => ComplianceRule.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> create(Map<String, dynamic> body) async => _client.post('/admin/compliance-rules', body: body);

  @override
  Future<void> update(int id, Map<String, dynamic> body) async => _client.patch('/admin/compliance-rules/$id', body: body);

  @override
  Future<void> delete(int id) async => _client.delete('/admin/compliance-rules/$id');
}
