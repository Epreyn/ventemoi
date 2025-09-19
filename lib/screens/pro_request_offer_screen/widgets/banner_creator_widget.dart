import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../core/classes/unique_controllers.dart';

class BannerCreatorWidget extends StatefulWidget {
  final Function(String imageUrl) onBannerCreated;
  final VoidCallback? onCancel;

  const BannerCreatorWidget({
    super.key,
    required this.onBannerCreated,
    this.onCancel,
  });

  @override
  State<BannerCreatorWidget> createState() => _BannerCreatorWidgetState();
}

class _BannerCreatorWidgetState extends State<BannerCreatorWidget> {
  final GlobalKey _bannerKey = GlobalKey();

  // Contrôleurs de texte
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  final TextEditingController _buttonTextController = TextEditingController();

  // États
  Uint8List? _selectedImage;
  String? _uploadedLogoUrl;
  bool _isGenerating = false;
  bool _isUploading = false;

  // Paramètres de design
  Color _backgroundColor = Colors.blue.shade600;
  Color _textColor = Colors.white;
  double _fontSize = 24;
  String _selectedFormat = '16:9'; // Format par défaut

  // Formats disponibles
  final Map<String, Size> _bannerFormats = {
    '16:9': const Size(1920, 1080), // Format HD standard
    '4:3': const Size(1600, 1200),  // Format plus carré
    '21:9': const Size(2560, 1080), // Format ultra-wide
    '1:1': const Size(1200, 1200),  // Format carré
    '9:16': const Size(1080, 1920), // Format portrait
  };

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _buttonTextController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedImage = result.files.single.bytes!;
        });
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger l\'image: $e',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _uploadLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() => _isUploading = true);

        final bytes = result.files.single.bytes!;
        final fileName = 'logos/${DateTime.now().millisecondsSinceEpoch}.png';

        final storageRef = FirebaseStorage.instance.ref().child(fileName);
        final uploadTask = await storageRef.putData(bytes);
        final downloadUrl = await uploadTask.ref.getDownloadURL();

        setState(() {
          _uploadedLogoUrl = downloadUrl;
          _isUploading = false;
        });

        Get.snackbar(
          'Succès',
          'Logo téléchargé avec succès',
          backgroundColor: Colors.green.shade400,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      Get.snackbar(
        'Erreur',
        'Impossible de télécharger le logo: $e',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _generateAndUploadBanner() async {
    if (_titleController.text.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez ajouter au moins un titre',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // Capturer l'image de la bannière
      RenderRepaintBoundary boundary =
          _bannerKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Upload vers Firebase Storage
      final fileName = 'banners/${DateTime.now().millisecondsSinceEpoch}.png';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = await storageRef.putData(pngBytes);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Enregistrer les métadonnées dans Firestore
      await FirebaseFirestore.instance.collection('banner_requests').add({
        'image_url': downloadUrl,
        'title': _titleController.text,
        'subtitle': _subtitleController.text,
        'button_text': _buttonTextController.text,
        'format': _selectedFormat,
        'created_at': FieldValue.serverTimestamp(),
        'user_id': UniquesControllers().data.firebaseAuth.currentUser?.uid,
        'status': 'pending_payment',
        'price': 10.0, // 10€ pour la création
      });

      widget.onBannerCreated(downloadUrl);

      Get.snackbar(
        'Succès',
        'Bannière créée avec succès ! Un paiement de 10€ sera requis pour la validation.',
        backgroundColor: Colors.green.shade400,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer la bannière: $e',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Widget _buildBannerPreview() {
    final size = _bannerFormats[_selectedFormat]!;
    final aspectRatio = size.width / size.height;

    return RepaintBoundary(
      key: _bannerKey,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            image: _selectedImage != null
                ? DecorationImage(
                    image: MemoryImage(_selectedImage!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.4),
                      BlendMode.darken,
                    ),
                  )
                : null,
            gradient: _selectedImage == null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _backgroundColor,
                      _backgroundColor.withOpacity(0.7),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Pattern décoratif
              if (_selectedImage == null)
                Positioned(
                  right: -50,
                  top: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),

              // Contenu principal
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    if (_uploadedLogoUrl != null)
                      Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            _uploadedLogoUrl!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                    // Titre
                    if (_titleController.text.isNotEmpty)
                      Text(
                        _titleController.text,
                        style: TextStyle(
                          fontSize: _fontSize * 2,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),

                    if (_subtitleController.text.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _subtitleController.text,
                        style: TextStyle(
                          fontSize: _fontSize,
                          color: _textColor.withOpacity(0.9),
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_buttonTextController.text.isNotEmpty) ...[
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: _textColor,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          _buttonTextController.text,
                          style: TextStyle(
                            color: _backgroundColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CustomTheme.lightScheme().primary,
                      CustomTheme.lightScheme().primary.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.brush_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Créateur de bannière',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Créez une bannière professionnelle pour 10€',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Sélecteur de format
          Text(
            'Format de la bannière',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _bannerFormats.entries.map((entry) {
                final isSelected = _selectedFormat == entry.key;
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () => setState(() => _selectedFormat = entry.key),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? CustomTheme.lightScheme().primary
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? CustomTheme.lightScheme().primary
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _getFormatIcon(entry.key),
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.key,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Champs de texte
          TextField(
            controller: _titleController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Titre principal',
              prefixIcon: const Icon(Icons.title_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _subtitleController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Sous-titre (optionnel)',
              prefixIcon: const Icon(Icons.subtitles_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _buttonTextController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Texte du bouton (optionnel)',
              prefixIcon: const Icon(Icons.smart_button_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 24),

          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _pickImage,
                  icon: const Icon(Icons.image_rounded),
                  label: const Text('Image de fond'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.grey[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadLogo,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.upload_rounded),
                  label: Text(_uploadedLogoUrl != null ? 'Logo ajouté' : 'Ajouter logo'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.orange[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Sélecteur de couleurs
          Row(
            children: [
              Text(
                'Couleur de fond',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 16),
              ...Colors.primaries.take(6).map((color) {
                return GestureDetector(
                  onTap: () => setState(() => _backgroundColor = color),
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _backgroundColor == color
                            ? Colors.black
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
          const SizedBox(height: 24),

          // Prévisualisation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.visibility_rounded,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Prévisualisation',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildBannerPreview(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Boutons finaux
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: widget.onCancel ?? () => Get.back(),
                  child: const Text('Annuler'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateAndUploadBanner,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_isGenerating ? 'Création...' : 'Créer bannière (10€)'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: CustomTheme.lightScheme().primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          ],
        ),
      ),
    );
  }

  IconData _getFormatIcon(String format) {
    switch (format) {
      case '16:9':
        return Icons.tv_rounded;
      case '4:3':
        return Icons.tablet_mac_rounded;
      case '21:9':
        return Icons.panorama_wide_angle_rounded;
      case '1:1':
        return Icons.crop_square_rounded;
      case '9:16':
        return Icons.phone_android_rounded;
      default:
        return Icons.aspect_ratio_rounded;
    }
  }
}