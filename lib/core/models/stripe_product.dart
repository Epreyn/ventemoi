import 'package:cloud_firestore/cloud_firestore.dart';

class StripeProduct {
  final String id;
  final String name;
  final String description;
  final bool active;
  final Map<String, dynamic> metadata;
  final DateTime created;

  StripeProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.active,
    required this.metadata,
    required this.created,
  });

  factory StripeProduct.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StripeProduct(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      active: data['active'] ?? false,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      created: (data['created'] as Timestamp).toDate(),
    );
  }
}

class StripePrice {
  final String id;
  final String productId;
  final int unitAmount; // en centimes
  final String currency;
  final String type; // 'one_time' ou 'recurring'
  final bool active;
  final Map<String, dynamic> metadata;

  StripePrice({
    required this.id,
    required this.productId,
    required this.unitAmount,
    required this.currency,
    required this.type,
    required this.active,
    required this.metadata,
  });

  factory StripePrice.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StripePrice(
      id: doc.id,
      productId: data['product'] ?? '',
      unitAmount: data['unit_amount'] ?? 0,
      currency: data['currency'] ?? 'eur',
      type: data['type'] ?? 'one_time',
      active: data['active'] ?? false,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  double get amountInEuros => unitAmount / 100.0;
}

class StripeCheckoutSession {
  final String id;
  final String? customerId;
  final String mode; // 'payment', 'setup', 'subscription'
  final String status; // 'open', 'complete', 'expired'
  final String? paymentStatus; // 'paid', 'unpaid', 'no_payment_required'
  final String? successUrl;
  final String? cancelUrl;
  final List<StripeLineItem> lineItems;
  final Map<String, dynamic> metadata;

  StripeCheckoutSession({
    required this.id,
    this.customerId,
    required this.mode,
    required this.status,
    this.paymentStatus,
    this.successUrl,
    this.cancelUrl,
    required this.lineItems,
    required this.metadata,
  });

  factory StripeCheckoutSession.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final lineItemsData = data['line_items'] as List<dynamic>? ?? [];

    return StripeCheckoutSession(
      id: doc.id,
      customerId: data['customer'],
      mode: data['mode'] ?? 'payment',
      status: data['status'] ?? 'open',
      paymentStatus: data['payment_status'],
      successUrl: data['success_url'],
      cancelUrl: data['cancel_url'],
      lineItems:
          lineItemsData.map((item) => StripeLineItem.fromMap(item)).toList(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }
}

class StripeLineItem {
  final String priceId;
  final int quantity;
  final String? description;

  StripeLineItem({
    required this.priceId,
    required this.quantity,
    this.description,
  });

  factory StripeLineItem.fromMap(Map<String, dynamic> data) {
    return StripeLineItem(
      priceId: data['price'] ?? '',
      quantity: data['quantity'] ?? 1,
      description: data['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'price': priceId,
      'quantity': quantity,
      if (description != null) 'description': description,
    };
  }
}
