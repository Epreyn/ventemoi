// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// import '../../../core/theme/custom_theme.dart';
// import '../../modern_button/view/modern_button.dart';

// class ModernFABButton extends StatelessWidget {
//   final String tag;
//   final String text;
//   final IconData? iconData;
//   final VoidCallback? onPressed;
//   final bool isExpanded;
//   final Color? backgroundColor;
//   final Color? foregroundColor;
//   final double? width;

//   const ModernFABButton({
//     super.key,
//     required this.tag,
//     required this.text,
//     this.iconData,
//     this.onPressed,
//     this.isExpanded = true,
//     this.backgroundColor,
//     this.foregroundColor,
//     this.width,
//   });

//   @override
//   Widget build(BuildContext context) {
//     if (!isExpanded && iconData != null) {
//       // FAB compact (icon seulement)
//       return Hero(
//         tag: tag,
//         child: ModernButtonExtension.icon(
//           icon: iconData!,
//           onPressed: onPressed,
//           size: ModernButtonSize.large,
//           color: backgroundColor ?? CustomTheme.lightScheme().primary,
//           iconColor: foregroundColor ?? Colors.white,
//           tooltip: text,
//         ),
//       );
//     }

//     // FAB étendu
//     return Hero(
//       tag: tag,
//       child: ModernButton(
//         text: text,
//         icon: iconData,
//         onPressed: onPressed,
//         width: width,
//         size: ModernButtonSize.large,
//         color: backgroundColor ?? CustomTheme.lightScheme().primary,
//         textColor: foregroundColor ?? Colors.white,
//       ),
//     );
//   }
// }

// // Widget pour un groupe de FAB avec menu
// class ModernFABMenu extends StatefulWidget {
//   final List<ModernFABMenuItem> items;
//   final IconData mainIcon;
//   final IconData? closeIcon;
//   final String mainTooltip;
//   final Color? backgroundColor;
//   final Color? foregroundColor;

//   const ModernFABMenu({
//     super.key,
//     required this.items,
//     required this.mainIcon,
//     this.closeIcon,
//     this.mainTooltip = '',
//     this.backgroundColor,
//     this.foregroundColor,
//   });

//   @override
//   State<ModernFABMenu> createState() => _ModernFABMenuState();
// }

// class _ModernFABMenuState extends State<ModernFABMenu>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _expandAnimation;
//   late Animation<double> _rotationAnimation;
//   bool _isExpanded = false;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _expandAnimation = CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeOutBack,
//       reverseCurve: Curves.easeInBack,
//     );
//     _rotationAnimation = Tween<double>(
//       begin: 0,
//       end: 0.125, // 45 degrés
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     ));
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   void _toggle() {
//     setState(() {
//       _isExpanded = !_isExpanded;
//       if (_isExpanded) {
//         _animationController.forward();
//       } else {
//         _animationController.reverse();
//       }
//     });
//     HapticFeedback.lightImpact();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final backgroundColor =
//         widget.backgroundColor ?? CustomTheme.lightScheme().primary;
//     final foregroundColor = widget.foregroundColor ?? Colors.white;

//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.end,
//       children: [
//         // Items du menu
//         AnimatedBuilder(
//           animation: _expandAnimation,
//           builder: (context, child) {
//             return Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: widget.items.asMap().entries.map((entry) {
//                 final index = entry.key;
//                 final item = entry.value;
//                 final delay = index / widget.items.length;

//                 return FadeTransition(
//                   opacity: _expandAnimation,
//                   child: ScaleTransition(
//                     scale: CurvedAnimation(
//                       parent: _expandAnimation,
//                       curve: Interval(
//                         delay * 0.5,
//                         delay * 0.5 + 0.5,
//                         curve: Curves.easeOutBack,
//                       ),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.only(bottom: 16),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           if (item.label != null)
//                             Container(
//                               margin: const EdgeInsets.only(right: 12),
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 8,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: Colors.black.withOpacity(0.8),
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                               child: Text(
//                                 item.label!,
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                             ),
//                           ModernButtonExtension.icon(
//                             icon: item.icon,
//                             onPressed: () {
//                               _toggle();
//                               item.onPressed();
//                             },
//                             size: ModernButtonSize.medium,
//                             color:
//                                 item.color ?? backgroundColor.withOpacity(0.9),
//                             iconColor: item.iconColor ?? foregroundColor,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               }).toList(),
//             );
//           },
//         ),

//         // Bouton principal
//         AnimatedBuilder(
//           animation: _rotationAnimation,
//           builder: (context, child) {
//             return Transform.rotate(
//               angle: _rotationAnimation.value * 2 * 3.14159,
//               child: ModernButtonExtension.icon(
//                 icon: _isExpanded
//                     ? (widget.closeIcon ?? Icons.close)
//                     : widget.mainIcon,
//                 onPressed: _toggle,
//                 size: ModernButtonSize.large,
//                 color: backgroundColor,
//                 iconColor: foregroundColor,
//                 tooltip: widget.mainTooltip,
//               ),
//             );
//           },
//         ),
//       ],
//     );
//   }
// }

// class ModernFABMenuItem {
//   final IconData icon;
//   final VoidCallback onPressed;
//   final String? label;
//   final Color? color;
//   final Color? iconColor;

//   const ModernFABMenuItem({
//     required this.icon,
//     required this.onPressed,
//     this.label,
//     this.color,
//     this.iconColor,
//   });
// }
