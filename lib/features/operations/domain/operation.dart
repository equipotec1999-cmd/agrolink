enum OperationRole { buyer, seller }

/// Estados de la operación (los mismos que el backend). El pago es manual:
/// el comprador avisa que pagó y el vendedor lo confirma.
enum OperationStatus {
  offerAccepted,
  pendingPayment,
  paid,
  preparingDelivery,
  inTransit,
  delivered,
  confirmed,
  completed,
  cancelled,
  dispute;

  /// Valor que entiende el API.
  String get wire => switch (this) {
        offerAccepted => 'oferta_aceptada',
        pendingPayment => 'pendiente_pago',
        paid => 'pagado',
        preparingDelivery => 'preparando_entrega',
        inTransit => 'en_transito',
        delivered => 'entregado',
        confirmed => 'confirmado',
        completed => 'completado',
        cancelled => 'cancelado',
        dispute => 'disputa',
      };

  static OperationStatus fromWire(String v) => switch (v) {
        'pendiente_pago' => pendingPayment,
        'pagado' => paid,
        'preparando_entrega' => preparingDelivery,
        'en_transito' => inTransit,
        'entregado' => delivered,
        'confirmado' => confirmed,
        'completado' => completed,
        'cancelado' => cancelled,
        'disputa' => dispute,
        _ => offerAccepted,
      };

  String get label => switch (this) {
        offerAccepted => 'Oferta aceptada',
        pendingPayment => 'Pendiente de pago',
        paid => 'Pagado',
        preparingDelivery => 'Preparando entrega',
        inTransit => 'En tránsito',
        delivered => 'Entregado',
        confirmed => 'Confirmado',
        completed => 'Completado',
        cancelled => 'Cancelado',
        dispute => 'En disputa',
      };
}

/// Paso de la línea de tiempo de una operación.
class OperationEvent {
  const OperationEvent({required this.status, required this.at, this.note});
  final OperationStatus status;
  final DateTime at;
  final String? note;
}

class Operation {
  const Operation({
    required this.id,
    required this.status,
    required this.role,
    required this.total,
    required this.quantity,
    required this.unitPrice,
    required this.conversationId,
    required this.listingId,
    required this.listingTitle,
    required this.unit,
    required this.counterpart,
    required this.createdAt,
    this.coverUrl,
    this.actions = const [],
    this.canReview = false,
    this.reviewed = false,
    this.counterpartId = '',
    this.events = const [],
  });

  final String id;
  final OperationStatus status;
  final OperationRole role;
  final double total;
  final double quantity;
  final double unitPrice;
  final String conversationId;
  final String listingId;
  final String listingTitle;
  final String unit;
  final String counterpart;
  final String? coverUrl;
  final DateTime createdAt;

  /// Estados a los que yo puedo pasarla ahora (los calcula el servidor).
  final List<OperationStatus> actions;
  final bool canReview;
  final bool reviewed;
  final String counterpartId;
  final List<OperationEvent> events;
}
