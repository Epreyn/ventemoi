import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';

class CustomTextStreamController extends GetxController {
  final String collectionName;
  final String fieldToDisplay;

  final RxString documentIdRx = ''.obs;

  final RxString textValue = ''.obs;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  CustomTextStreamController({
    required this.collectionName,
    required String? initialDocumentId,
    required this.fieldToDisplay,
  }) {
    documentIdRx.value = initialDocumentId ?? '';
  }

  @override
  void onInit() {
    super.onInit();
    ever(documentIdRx, (String docId) {
      _subscribeToDocument(docId);
    });
    _subscribeToDocument(documentIdRx.value);
  }

  void _subscribeToDocument(String docId) {
    _subscription?.cancel();
    _subscription = null;

    if (docId.isEmpty) {
      textValue.value = '';
      return;
    }

    final docRef = UniquesControllers().data.firebaseFirestore.collection(collectionName).doc(docId);

    _subscription = docRef.snapshots().listen(
      (snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          textValue.value = data[fieldToDisplay]?.toString() ?? '';
        } else {
          textValue.value = 'Document introuvable.';
        }
      },
      onError: (error) {
        textValue.value = 'Erreur: $error';
      },
    );
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
