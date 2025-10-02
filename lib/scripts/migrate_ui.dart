#!/usr/bin/env dart

import 'dart:io';

/// Script de migration automatique pour le nouveau système de design
/// Usage: dart lib/scripts/migrate_ui.dart [--dry-run]

void main(List<String> arguments) {
  final isDryRun = arguments.contains('--dry-run');
  
  final migrations = [
    // CustomTheme.lightScheme() migrations
    Migration(
      pattern: r'CustomTheme\.lightScheme\(\)\.primary',
      replacement: 'AppThemeConfig.primaryColor',
      description: 'CustomTheme.primary → AppThemeConfig.primaryColor',
    ),
    Migration(
      pattern: r'CustomTheme\.lightScheme\(\)\.error',
      replacement: 'AppThemeConfig.errorColor',
      description: 'CustomTheme.error → AppThemeConfig.errorColor',
    ),
    Migration(
      pattern: r'CustomTheme\.lightScheme\(\)\.onPrimary',
      replacement: 'AppThemeConfig.textOnPrimary',
      description: 'CustomTheme.onPrimary → AppThemeConfig.textOnPrimary',
    ),
    Migration(
      pattern: r'CustomTheme\.lightScheme\(\)\.surface',
      replacement: 'AppThemeConfig.surfaceColor',
      description: 'CustomTheme.surface → AppThemeConfig.surfaceColor',
    ),
    Migration(
      pattern: r'CustomTheme\.lightScheme\(\)\.onSurface',
      replacement: 'AppThemeConfig.textPrimary',
      description: 'CustomTheme.onSurface → AppThemeConfig.textPrimary',
    ),
    
    // Colors migrations simples
    Migration(
      pattern: r'Colors\.white(?!\.withOpacity)',
      replacement: 'AppThemeConfig.backgroundColor',
      description: 'Colors.white → AppThemeConfig.backgroundColor',
    ),
    Migration(
      pattern: r'Colors\.black(?!\.withOpacity)',
      replacement: 'AppThemeConfig.textPrimary',
      description: 'Colors.black → AppThemeConfig.textPrimary',
    ),
    Migration(
      pattern: r'Colors\.grey\[300\]',
      replacement: 'AppThemeConfig.grey300',
      description: 'Colors.grey[300] → AppThemeConfig.grey300',
    ),
    Migration(
      pattern: r'Colors\.grey\[400\]',
      replacement: 'AppThemeConfig.grey400',
      description: 'Colors.grey[400] → AppThemeConfig.grey400',
    ),
    Migration(
      pattern: r'Colors\.grey\[500\]',
      replacement: 'AppThemeConfig.grey500',
      description: 'Colors.grey[500] → AppThemeConfig.grey500',
    ),
    Migration(
      pattern: r'Colors\.grey\[600\]',
      replacement: 'AppThemeConfig.grey600',
      description: 'Colors.grey[600] → AppThemeConfig.grey600',
    ),
    Migration(
      pattern: r'Colors\.grey\[700\]',
      replacement: 'AppThemeConfig.grey700',
      description: 'Colors.grey[700] → AppThemeConfig.grey700',
    ),
    Migration(
      pattern: r'Colors\.grey\[800\]',
      replacement: 'AppThemeConfig.grey800',
      description: 'Colors.grey[800] → AppThemeConfig.grey800',
    ),
    Migration(
      pattern: r'Colors\.grey(?!\[)',
      replacement: 'AppThemeConfig.grey500',
      description: 'Colors.grey → AppThemeConfig.grey500',
    ),
    Migration(
      pattern: r'Colors\.red',
      replacement: 'AppThemeConfig.errorColor',
      description: 'Colors.red → AppThemeConfig.errorColor',
    ),
    Migration(
      pattern: r'Colors\.green',
      replacement: 'AppThemeConfig.successColor',
      description: 'Colors.green → AppThemeConfig.successColor',
    ),
    Migration(
      pattern: r'Colors\.orange',
      replacement: 'AppThemeConfig.warningColor',
      description: 'Colors.orange → AppThemeConfig.warningColor',
    ),
    Migration(
      pattern: r'Colors\.blue',
      replacement: 'AppThemeConfig.infoColor',
      description: 'Colors.blue → AppThemeConfig.infoColor',
    ),
    
    // Spacing migrations
    Migration(
      pattern: r'const SizedBox\(height: 8(\.0)?\)',
      replacement: 'const SizedBox(height: AppThemeConfig.spaceSM)',
      description: 'SizedBox(height: 8) → AppThemeConfig.spaceSM',
    ),
    Migration(
      pattern: r'const SizedBox\(height: 12(\.0)?\)',
      replacement: 'const SizedBox(height: AppThemeConfig.spaceMD)',
      description: 'SizedBox(height: 12) → AppThemeConfig.spaceMD',
    ),
    Migration(
      pattern: r'const SizedBox\(height: 16(\.0)?\)',
      replacement: 'const SizedBox(height: AppThemeConfig.spaceLG)',
      description: 'SizedBox(height: 16) → AppThemeConfig.spaceLG',
    ),
    Migration(
      pattern: r'const SizedBox\(height: 20(\.0)?\)',
      replacement: 'const SizedBox(height: AppThemeConfig.spaceXL)',
      description: 'SizedBox(height: 20) → AppThemeConfig.spaceXL',
    ),
    Migration(
      pattern: r'const SizedBox\(height: 24(\.0)?\)',
      replacement: 'const SizedBox(height: AppThemeConfig.spaceXXL)',
      description: 'SizedBox(height: 24) → AppThemeConfig.spaceXXL',
    ),
    Migration(
      pattern: r'const SizedBox\(height: 32(\.0)?\)',
      replacement: 'const SizedBox(height: AppThemeConfig.spaceXXXL)',
      description: 'SizedBox(height: 32) → AppThemeConfig.spaceXXXL',
    ),
    Migration(
      pattern: r'const SizedBox\(width: 8(\.0)?\)',
      replacement: 'const SizedBox(width: AppThemeConfig.spaceSM)',
      description: 'SizedBox(width: 8) → AppThemeConfig.spaceSM',
    ),
    Migration(
      pattern: r'const SizedBox\(width: 12(\.0)?\)',
      replacement: 'const SizedBox(width: AppThemeConfig.spaceMD)',
      description: 'SizedBox(width: 12) → AppThemeConfig.spaceMD',
    ),
    Migration(
      pattern: r'const SizedBox\(width: 16(\.0)?\)',
      replacement: 'const SizedBox(width: AppThemeConfig.spaceLG)',
      description: 'SizedBox(width: 16) → AppThemeConfig.spaceLG',
    ),
    
    // BorderRadius migrations
    Migration(
      pattern: r'BorderRadius\.circular\(8(\.0)?\)',
      replacement: 'AppThemeConfig.radiusSM',
      description: 'BorderRadius.circular(8) → AppThemeConfig.radiusSM',
    ),
    Migration(
      pattern: r'BorderRadius\.circular\(12(\.0)?\)',
      replacement: 'AppThemeConfig.radiusMD',
      description: 'BorderRadius.circular(12) → AppThemeConfig.radiusMD',
    ),
    Migration(
      pattern: r'BorderRadius\.circular\(16(\.0)?\)',
      replacement: 'AppThemeConfig.radiusLG',
      description: 'BorderRadius.circular(16) → AppThemeConfig.radiusLG',
    ),
    Migration(
      pattern: r'BorderRadius\.circular\(20(\.0)?\)',
      replacement: 'AppThemeConfig.radiusXL',
      description: 'BorderRadius.circular(20) → AppThemeConfig.radiusXL',
    ),
    Migration(
      pattern: r'BorderRadius\.circular\(24(\.0)?\)',
      replacement: 'AppThemeConfig.radiusXXL',
      description: 'BorderRadius.circular(24) → AppThemeConfig.radiusXXL',
    ),
  ];
  
  // Trouver tous les fichiers Dart
  final libDir = Directory('lib');
  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.contains('/scripts/')) // Exclure ce script
      .toList();
  
  
  int totalChanges = 0;
  final Map<String, int> changesByFile = {};
  
  for (final file in files) {
    String content = file.readAsStringSync();
    String newContent = content;
    int fileChanges = 0;
    
    for (final migration in migrations) {
      final regex = RegExp(migration.pattern);
      final matches = regex.allMatches(content).length;
      
      if (matches > 0) {
        newContent = newContent.replaceAll(regex, migration.replacement);
        fileChanges += matches;
        totalChanges += matches;
      }
    }
    
    if (fileChanges > 0) {
      changesByFile[file.path] = fileChanges;
      
      if (!isDryRun) {
        // Ajouter les imports nécessaires si pas déjà présents
        if (!newContent.contains('app_theme_config.dart') && 
            (newContent.contains('AppThemeConfig') || newContent.contains('context.'))) {
          final lines = newContent.split('\n');
          int importIndex = lines.indexWhere((l) => l.startsWith('import'));
          if (importIndex >= 0) {
            // Trouver le bon chemin relatif pour l'import
            final depth = file.path.split('/').length - 2; // -2 pour lib/ et le fichier
            final prefix = '../' * (depth - 1);
            final importLine = "import '${prefix}core/config/app_theme_config.dart';";
            
            if (!newContent.contains(importLine)) {
              lines.insert(importIndex, importLine);
              newContent = lines.join('\n');
            }
          }
        }
        
        file.writeAsStringSync(newContent);
      }
      
    }
  }
  
  
  if (isDryRun) {
  } else {
  }
}

class Migration {
  final String pattern;
  final String replacement;
  final String description;
  
  Migration({
    required this.pattern,
    required this.replacement,
    required this.description,
  });
}