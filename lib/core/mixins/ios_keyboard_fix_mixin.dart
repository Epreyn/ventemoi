// Fichier: lib/core/mixins/ios_keyboard_fix_mixin.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

mixin IOSKeyboardFixMixin<T extends StatefulWidget> on State<T> {
  // Map pour stocker les FocusNodes
  final Map<String, FocusNode> _focusNodes = {};

  // Timer pour gérer le délai
  Timer? _focusTimer;

  // Créer ou récupérer un FocusNode
  FocusNode getFocusNode(String tag) {
    if (!_focusNodes.containsKey(tag)) {
      _focusNodes[tag] = FocusNode();

      // Listener pour iOS web
      if (kIsWeb) {
        _focusNodes[tag]!.addListener(() {
          if (_focusNodes[tag]!.hasFocus) {
            _handleIOSFocus(_focusNodes[tag]!);
          }
        });
      }
    }
    return _focusNodes[tag]!;
  }

  // Gérer le focus sur iOS
  void _handleIOSFocus(FocusNode node) {
    if (!kIsWeb) return;

    // Annuler le timer précédent
    _focusTimer?.cancel();

    // Forcer le focus après un délai
    _focusTimer = Timer(const Duration(milliseconds: 100), () {
      if (!node.hasFocus && mounted) {
        node.requestFocus();
      }
    });
  }

  // Passer au champ suivant
  void focusNext(String currentTag, String nextTag) {
    FocusScope.of(context).unfocus();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        getFocusNode(nextTag).requestFocus();
      }
    });
  }

  // Méthode pour iOS spécifiquement
  void requestFocusIOS(String tag) {
    if (kIsWeb) {
      // Double focus pour iOS
      getFocusNode(tag).requestFocus();
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !getFocusNode(tag).hasFocus) {
          getFocusNode(tag).requestFocus();
        }
      });
    } else {
      getFocusNode(tag).requestFocus();
    }
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }
}

// ALTERNATIVE : Widget Wrapper pour les TextFields iOS

class IOSTextFieldWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  const IOSTextFieldWrapper({
    Key? key,
    required this.child,
    this.onTap,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !enabled) {
      return child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: AbsorbPointer(
        absorbing: false,
        child: child,
      ),
    );
  }
}
