import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/nameable.dart';
import '../controllers/custom_dropdown_stream_builder_controller.dart';

class CustomDropdownStreamBuilder<T extends Nameable> extends StatelessWidget {
  final String tag;
  final Stream<List<T>> stream;
  final Rx<T?> initialItem;
  final String labelText;
  final ValueChanged<T?> onChanged;
  final double? maxWith;
  final double? maxHeight;
  final Future<bool>? isEnabled;
  final bool? noInitialItem;

  const CustomDropdownStreamBuilder({
    super.key,
    required this.tag,
    required this.stream,
    required this.initialItem,
    required this.labelText,
    required this.onChanged,
    this.maxWith,
    this.maxHeight,
    this.isEnabled,
    this.noInitialItem,
  });

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(CustomDropdownStreamBuilderController(), tag: tag);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWith ?? cc.maxWith,
        maxHeight: maxHeight ?? cc.maxHeight,
      ),
      child: StreamBuilder<List<T>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return UniquesControllers().data.loader();
          } else if (snapshot.hasError) {
            return Text('Erreur: ${snapshot.error}');
          } else {
            final items = snapshot.data ?? [];
            T? selectedItem;

            if (items.isNotEmpty) {
              selectedItem = items.firstWhere(
                (element) => element.id == initialItem.value?.id,
                orElse: () => items.first,
              );

              if (noInitialItem != true && initialItem.value == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  initialItem.value = selectedItem;
                });
              }
            }

            if (isEnabled == null) {
              return DropdownButtonFormField<T>(
                elevation: cc.dropDownElevation,
                focusColor: cc.dropDownFocusColor,
                borderRadius: cc.dropDownBorderRadius,
                icon: cc.dropDownIcon,
                decoration: cc.dropDownDecoration(labelText),
                items: items.map((value) {
                  return DropdownMenuItem<T>(
                    value: value,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(value.name),
                    ),
                  );
                }).toList(),
                value: (noInitialItem == true && initialItem.value == null) ? null : selectedItem,
                onChanged: onChanged,
              );
            } else {
              return FutureBuilder<bool>(
                future: isEnabled,
                builder: (BuildContext context, AsyncSnapshot<bool> futureSnap) {
                  if (futureSnap.connectionState == ConnectionState.waiting) {
                    return UniquesControllers().data.loader();
                  } else {
                    if (futureSnap.hasError) {
                      return Text('Erreur: ${futureSnap.error}');
                    } else {
                      final enabled = futureSnap.data ?? true;
                      return DropdownButtonFormField<T>(
                        elevation: cc.dropDownElevation,
                        focusColor: cc.dropDownFocusColor,
                        borderRadius: cc.dropDownBorderRadius,
                        icon: cc.dropDownIcon,
                        decoration: cc.dropDownDecoration(labelText),
                        items: items.map((value) {
                          return DropdownMenuItem<T>(
                            value: value,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(value.name),
                            ),
                          );
                        }).toList(),
                        value: (noInitialItem == true && initialItem.value == null) ? null : selectedItem,
                        onChanged: enabled ? onChanged : null,
                      );
                    }
                  }
                },
              );
            }
          }
        },
      ),
    );
  }
}
