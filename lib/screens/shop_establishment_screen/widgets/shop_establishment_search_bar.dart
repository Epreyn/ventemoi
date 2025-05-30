import 'package:flutter/material.dart';
import 'package:ventemoi/features/custom_card_animation/view/custom_card_animation.dart';

import '../../../core/classes/unique_controllers.dart';
import '../controllers/shop_establishment_screen_controller.dart';

class ShopEstablishmentSearchBar extends StatelessWidget {
  final ShopEstablishmentScreenController controller;
  const ShopEstablishmentSearchBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(UniquesControllers().data.baseSpace),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher un établissement',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(90),
          ),
        ),
        onChanged: (value) {
          controller.setSearchText(value);
        },
      ),
    );
  }
}
