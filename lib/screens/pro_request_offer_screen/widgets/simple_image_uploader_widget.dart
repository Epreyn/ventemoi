import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../core/classes/unique_controllers.dart';

class SimpleImageUploaderWidget extends StatefulWidget {
  final Function(String imageUrl) onImageUploaded;
  final VoidCallback? onCancel;

  const SimpleImageUploaderWidget({
    super.key,
    required this.onImageUploaded,
    this.onCancel,
  });

  @override
  State<SimpleImageUploaderWidget> createState() => _SimpleImageUploaderWidgetState();
}

class _SimpleImageUploaderWidgetState extends State<SimpleImageUploaderWidget> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImage;
  String? _imageName;
  bool _isUploading = false;
  bool _isUploaded = false;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 90,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = bytes;
          _imageName = image.name;
          _isUploaded = false; // Réinitialiser l'état d'upload
        });
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de sélectionner l\'image: $e',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) {
      Get.snackbar(
        'Attention',
        'Veuillez sélectionner une image',
        backgroundColor: Colors.orange.shade400,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final currentUser = UniquesControllers().data.firebaseAuth.currentUser;
      if (currentUser == null) throw 'Utilisateur non connecté';

      // Créer un nom unique pour l'image
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'banner_${currentUser.uid}_$timestamp.jpg';

      // Upload vers Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('establishment_banners')
          .child(fileName);

      final uploadTask = await storageRef.putData(
        _selectedImage!,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': currentUser.uid,
            'uploadDate': DateTime.now().toIso8601String(),
          },
        ),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      widget.onImageUploaded(downloadUrl);

      setState(() {
        _isUploaded = true;
      });

      // Ne pas fermer automatiquement - laisser l'utilisateur décider
      Get.snackbar(
        'Succès',
        'Image téléversée avec succès ! Vous pouvez maintenant fermer cette fenêtre.',
        backgroundColor: Colors.green.shade400,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors du téléversement: $e',
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isUploading = false);
    }
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
                    Icons.cloud_upload,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Téléverser une image',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Sélectionnez le format recommandé',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onCancel ?? () => Get.back(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Fermer',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Information sur le format recommandé
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade50,
                    Colors.orange.shade100.withOpacity(0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.aspect_ratio_rounded,
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
                          'Format recommandé : 16:9',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.orange.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dimensions idéales : 1920 x 1080 pixels',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Format optimal pour l\'affichage dans les cartes d\'offres',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Zone de sélection d'image
            InkWell(
              onTap: _isUploading ? null : _pickImage,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _selectedImage != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.memory(
                              _selectedImage!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedImage = null;
                                    _imageName = null;
                                    _isUploaded = false;
                                  });
                                },
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                tooltip: 'Supprimer',
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Cliquez pour sélectionner une image',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'JPG, PNG, WEBP • Max 10 MB',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            if (_imageName != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Image sélectionnée : $_imageName',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),

            // Boutons d'action
            _isUploaded
              ? // Après téléversement réussi
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Get.back(),
                        icon: Icon(Icons.check_circle, color: Colors.green.shade600),
                        label: Text(
                          'Fermer et utiliser cette image',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.green.shade600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green.shade50,
                          elevation: 0,
                          side: BorderSide(
                            color: Colors.green.shade600,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : // Avant téléversement
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isUploading ? null : (widget.onCancel ?? () => Get.back()),
                        child: Text(
                          'Annuler',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: (_isUploading || _selectedImage == null) ? null : _uploadImage,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.orange,
                                ),
                              )
                            : Icon(Icons.cloud_upload_rounded, color: Colors.orange.shade600),
                        label: Text(
                          _isUploading ? 'Téléversement...' : 'Téléverser l\'image',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.orange.shade600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[100],
                          elevation: 0,
                          side: BorderSide(
                            color: _isUploading || _selectedImage == null
                                ? Colors.grey[300]!
                                : Colors.orange.shade600,
                            width: 2,
                          ),
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

  @override
  void dispose() {
    super.dispose();
  }
}