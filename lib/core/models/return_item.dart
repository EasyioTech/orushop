class ReturnItem {
  final int id;
  final int returnId;
  final int saleItemId;
  final int quantity;

  ReturnItem({
    required this.id,
    required this.returnId,
    required this.saleItemId,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'returnId': returnId,
      'saleItemId': saleItemId,
      'quantity': quantity,
    };
  }

  static ReturnItem fromMap(Map<String, dynamic> map) {
    return ReturnItem(
      id: map['id'] as int,
      returnId: map['returnId'] as int,
      saleItemId: map['saleItemId'] as int,
      quantity: map['quantity'] as int,
    );
  }
}
