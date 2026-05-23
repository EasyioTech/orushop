import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerRepository {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  Future<Map<String, dynamic>?> getOwnerDetails() async {
    if (_userId.isEmpty) return null;

    try {
      final doc = await _firestore.collection('owners').doc(_userId).get();
      return doc.data();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateStoreName(String name) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');

    try {
      await _firestore.collection('owners').doc(_userId).set(
        {'storeName': name},
        SetOptions(merge: true),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateStorePhone(String phone) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');

    try {
      await _firestore.collection('owners').doc(_userId).set(
        {'storePhone': phone},
        SetOptions(merge: true),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateStoreAddress(String address) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');

    try {
      await _firestore.collection('owners').doc(_userId).set(
        {'storeAddress': address},
        SetOptions(merge: true),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateReceiptBanner(
    String title, 
    String subtitle, 
    String url, 
    String style,
    String? icon,
    int? color,
    int? textColor,
  ) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');

    try {
      await _firestore.collection('owners').doc(_userId).set(
        {
          'receiptBannerTitle': title,
          'receiptBannerSubtitle': subtitle,
          'receiptBannerUrl': url,
          'receiptBannerStyle': style,
          if (icon != null) 'receiptBannerIcon': icon,
          if (color != null) 'receiptBannerColor': color,
          if (textColor != null) 'receiptBannerTextColor': textColor,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveShopDetails(Map<String, dynamic> data) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');

    try {
      await _firestore.collection('owners').doc(_userId).set(
        data,
        SetOptions(merge: true),
      );
    } catch (e) {
      rethrow;
    }
  }



  Stream<Map<String, dynamic>?> ownerDetailsStream() {
    if (_userId.isEmpty) return Stream.value(null);

    return _firestore.collection('owners').doc(_userId).snapshots().map((doc) {
      return doc.data();
    });
  }
}
