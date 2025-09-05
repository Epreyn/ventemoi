import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../../core/models/enterprise_subcategory_option.dart';
import '../../../core/models/enterprise_category.dart';
import '../../../core/classes/unique_controllers.dart';
import '../../../core/theme/custom_theme.dart';

class SubcategoryOptionsSelector extends StatefulWidget {
  final String subcategoryId;
  final List<String>? selectedOptionIds;
  final Function(List<String>) onOptionsChanged;
  
  const SubcategoryOptionsSelector({
    Key? key,
    required this.subcategoryId,
    this.selectedOptionIds,
    required this.onOptionsChanged,
  }) : super(key: key);

  @override
  State<SubcategoryOptionsSelector> createState() => _SubcategoryOptionsSelectorState();
}

class _SubcategoryOptionsSelectorState extends State<SubcategoryOptionsSelector> {
  List<String> _selectedOptions = [];
  
  @override
  void initState() {
    super.initState();
    _selectedOptions = widget.selectedOptionIds ?? [];
  }
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: UniquesControllers()
          .data
          .firebaseFirestore
          .collection('enterprise_subcategory_options')
          .where('subcategory_id', isEqualTo: widget.subcategoryId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final options = snapshot.data!.docs
            .map((doc) => EnterpriseSubcategoryOption.fromDocument(doc))
            .toList()
          ..sort((a, b) => a.index.compareTo(b.index));
            
        if (options.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Options disponibles:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((option) {
                final isSelected = _selectedOptions.contains(option.id);
                return FilterChip(
                  label: Text(
                    option.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedOptions.add(option.id);
                      } else {
                        _selectedOptions.remove(option.id);
                      }
                    });
                    widget.onOptionsChanged(_selectedOptions);
                  },
                  selectedColor: CustomTheme.lightScheme().primary,
                  backgroundColor: Colors.grey[100],
                  checkmarkColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

// Widget pour afficher les options sélectionnées de manière formatée
class SubcategoryOptionsDisplay extends StatelessWidget {
  final String subcategoryId;
  final List<String> optionIds;
  
  const SubcategoryOptionsDisplay({
    Key? key,
    required this.subcategoryId,
    required this.optionIds,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (optionIds.isEmpty) return const SizedBox.shrink();
    
    return StreamBuilder<QuerySnapshot>(
      stream: UniquesControllers()
          .data
          .firebaseFirestore
          .collection('enterprise_subcategory_options')
          .where('subcategory_id', isEqualTo: subcategoryId)
          .where(FieldPath.documentId, whereIn: optionIds)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final options = snapshot.data!.docs
            .map((doc) => EnterpriseSubcategoryOption.fromDocument(doc))
            .toList()
          ..sort((a, b) => a.index.compareTo(b.index));
        
        final optionNames = options.map((o) => o.name).toList();
        
        if (optionNames.isEmpty) return const SizedBox.shrink();
        
        return Text(
          ' (${optionNames.join(', ')})',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        );
      },
    );
  }
}