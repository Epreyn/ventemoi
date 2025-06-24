// lib/controllers/enterprise_category_selection_controller.dart

import 'package:get/get.dart';

class EnterpriseCategorySelectionController extends GetxController {
  final RxList<String> selectedIds = <String>[].obs;
  final RxBool hasModifications = false.obs;

  void initializeFromData(List<String> ids) {
    selectedIds.assignAll(ids);
    hasModifications.value = false;
  }

  void toggleCategory(String categoryId, int maxSelections) {
    if (selectedIds.contains(categoryId)) {
      selectedIds.remove(categoryId);
      hasModifications.value = true;
    } else if (selectedIds.length < maxSelections) {
      selectedIds.add(categoryId);
      hasModifications.value = true;
    } else {
      Get.snackbar(
        'Limite atteinte',
        'Vous avez atteint le maximum de $maxSelections catégories',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.9),
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  void removeCategory(String categoryId) {
    selectedIds.remove(categoryId);
    hasModifications.value = true;
  }

  void resetChanges(List<String> originalIds) {
    selectedIds.assignAll(originalIds);
    hasModifications.value = false;
  }

  List<String> getSelectedIds() {
    return selectedIds.toList();
  }
}
