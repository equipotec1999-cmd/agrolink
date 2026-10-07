enum OperationRole { buyer, seller }

/// Estados de la operación (los mismos que el backend; hoy solo se llega a
/// "oferta aceptada": pago y entrega vienen en fases posteriores).
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
}
