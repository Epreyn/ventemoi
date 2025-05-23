import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- Ajout
import 'package:ventemoi/core/classes/unique_controllers.dart';
import 'package:ventemoi/core/theme/custom_theme.dart';

import '../../../core/models/establishement.dart';
import '../controllers/enterprises_list_screen_controller.dart';

class EnterpriseCard extends StatelessWidget {
  final Establishment establishment;
  const EnterpriseCard({super.key, required this.establishment});

  @override
  Widget build(BuildContext context) {
    final cc = Get.find<EnterprisesListScreenController>();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bannière
          if (establishment.bannerUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: Image.network(
                establishment.bannerUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Logo
                if (establishment.logoUrl.isNotEmpty)
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(establishment.logoUrl),
                  )
                else
                  const CircleAvatar(
                    radius: 24,
                    child: Icon(Icons.store),
                  ),
                const SizedBox(width: 12),

                // Nom + desc
                Expanded(
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            establishment.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            establishment.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Infos (adresse/email/tel)
          Obx(() => _buildInfoLines(cc.enterpriseCategoriesMap)),
        ],
      ),
    );
  }

  Widget _buildInfoLines(RxMap<String, String> enterpriseCategoriesMap) {
    final info = <Widget>[];

    // On ajoute conditionnellement chaque ligne
    if (establishment.address.isNotEmpty) {
      info.add(
        _infoRow(
          Icons.location_on_outlined,
          establishment.address,
          // On appelle un handler "launchMaps" (défini plus bas)
          onTap: () => _launchMaps(establishment.address),
        ),
      );
    }

    if (establishment.email.isNotEmpty) {
      info.add(
        _infoRow(
          Icons.email_outlined,
          establishment.email,
          // On appelle un handler "launchMail"
          onTap: () => _launchEmail(establishment.email),
        ),
      );
    }

    if (establishment.telephone.isNotEmpty) {
      info.add(
        _infoRow(
          Icons.phone_outlined,
          establishment.telephone,
          // On appelle un handler "launchTel"
          onTap: () => _launchTel(establishment.telephone),
        ),
      );
    }

    if (establishment.enterpriseCategoryIds != null && establishment.enterpriseCategoryIds!.isNotEmpty) {
      var cats = '';
      for (var catId in establishment.enterpriseCategoryIds!) {
        final catName = enterpriseCategoriesMap[catId] ?? catId;
        cats += '$catName, ';
      }
      // On enlève la virgule finale
      cats = cats.substring(0, cats.length - 2);

      info.add(
        _infoRow(
          Icons.category_outlined,
          cats,
          // Dans ce cas, pas de lien => onTap = null
        ),
      );
    }

    if (info.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: info,
    );
  }

  Widget _infoRow(IconData icon, String text, {VoidCallback? onTap}) {
    return ListTile(
      dense: true,
      onTap: onTap,
      leading: Icon(
        icon,
        size: UniquesControllers().data.baseSpace * 3,
        color: CustomTheme.lightScheme().primary,
      ),
      title: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade800,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ----------------------------------------------------------------
  // Fonctions de lancement
  // ----------------------------------------------------------------

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchTel(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchMaps(String address) async {
    // On encode l'adresse
    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
