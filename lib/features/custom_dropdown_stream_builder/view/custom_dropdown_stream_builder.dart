import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/models/nameable.dart';
import '../../../core/theme/custom_theme.dart';
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
  final IconData? iconData;

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
    this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(CustomDropdownStreamBuilderController(), tag: tag);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWith ?? cc.maxWith,
      ),
      child: StreamBuilder<List<T>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  if (iconData != null) ...[
                    Icon(
                      iconData,
                      color: CustomTheme.lightScheme().primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                  ],
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: CustomTheme.lightScheme().primary,
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.red[300]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Erreur: ${snapshot.error}',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            );
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
              return _buildDropdown(
                items: items,
                selectedItem: selectedItem,
                enabled: true,
                iconData: iconData,
              );
            } else {
              return FutureBuilder<bool>(
                future: isEnabled,
                builder:
                    (BuildContext context, AsyncSnapshot<bool> futureSnap) {
                  if (futureSnap.connectionState == ConnectionState.waiting) {
                    return _buildDropdown(
                      items: items,
                      selectedItem: selectedItem,
                      enabled: false,
                      iconData: iconData,
                    );
                  } else {
                    if (futureSnap.hasError) {
                      return Text('Erreur: ${futureSnap.error}');
                    } else {
                      final enabled = futureSnap.data ?? true;
                      return _buildDropdown(
                        items: items,
                        selectedItem: selectedItem,
                        enabled: enabled,
                        iconData: iconData,
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

  Widget _buildDropdown({
    required List<T> items,
    required T? selectedItem,
    required bool enabled,
    IconData? iconData,
  }) {
    return Theme(
      data: Theme.of(Get.context!).copyWith(
        focusColor: Colors.transparent,
      ),
      child: DropdownButtonFormField<T>(
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: Colors.grey[700],
            fontSize: 16,
          ),
          prefixIcon: iconData != null
              ? Icon(
                  iconData,
                  color: CustomTheme.lightScheme().primary,
                )
              : null,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding: EdgeInsets.symmetric(
            horizontal: iconData != null ? 12 : 20,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: CustomTheme.lightScheme().primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: CustomTheme.lightScheme().error,
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: CustomTheme.lightScheme().error,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: enabled ? Colors.white.withOpacity(0.8) : Colors.grey[100],
        ),
        icon: Icon(
          Icons.expand_more_rounded,
          color: enabled ? CustomTheme.lightScheme().primary : Colors.grey[400],
        ),
        dropdownColor: Colors.white,
        elevation: 8,
        style: TextStyle(
          fontSize: 16,
          color: enabled ? Colors.black87 : Colors.grey[600],
        ),
        borderRadius: BorderRadius.circular(16),
        isExpanded: true,
        menuMaxHeight: 300,
        items: items.map((value) {
          return DropdownMenuItem<T>(
            value: value,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                value.name,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }).toList(),
        value: (noInitialItem == true && initialItem.value == null)
            ? null
            : selectedItem,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}
