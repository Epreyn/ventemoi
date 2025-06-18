import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/classes/unique_controllers.dart';
import '../../../core/theme/custom_theme.dart';
import '../../../features/custom_app_bar/view/custom_app_bar.dart';
import '../../../features/custom_card_animation/view/custom_card_animation.dart';
import '../../../features/custom_space/view/custom_space.dart';
import '../../../features/screen_layout/view/screen_layout.dart';
import '../controllers/sponsorship_screen_controller.dart';

class SponsorshipScreen extends GetView<SponsorshipScreenController> {
  const SponsorshipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = Get.put(SponsorshipScreenController());
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return ScreenLayout(
      appBar: CustomAppBar(
        showUserInfo: true,
        showPoints: true,
        showDrawerButton: true,
        modernStyle: true,
        showGreeting: true,
      ),
      fabOnPressed: cc.openCreateUserBottomSheet,
      fabIcon: const Icon(Icons.person_add_rounded),
      fabText: const Text('Parrainer'),
      body: Obx(() {
        final sponsorship = cc.currentSponsorship.value;
        final sponsoredEmails = sponsorship?.sponsoredEmails ?? [];
        final sponsorInfo = cc.sponsorInfo.value;
        final totalEarnings = cc.totalEarnings.value;
        final activeReferrals = cc.activeReferrals.value;

        return Center(
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(scrollbars: false),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      isTablet ? 600 : UniquesControllers().data.baseMaxWidth,
                ),
                child: Column(
                  children: [
                    // Section Statistiques avec glassmorphism
                    CustomCardAnimation(
                      index: 0,
                      child: Container(
                        width: UniquesControllers().data.baseMaxWidth +
                            (UniquesControllers().data.baseSpace * 5),
                        padding: EdgeInsets.all(
                          UniquesControllers().data.baseSpace * 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              CustomTheme.lightScheme()
                                  .primary
                                  .withOpacity(0.15),
                              CustomTheme.lightScheme()
                                  .primary
                                  .withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: CustomTheme.lightScheme()
                                  .primary
                                  .withOpacity(0.15),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          //borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.insights_rounded,
                                      size: 32,
                                      color: CustomTheme.lightScheme().primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Mes Statistiques',
                                      style: TextStyle(
                                        fontSize: UniquesControllers()
                                                .data
                                                .baseSpace *
                                            2.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                                const CustomSpace(heightMultiplier: 3),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildStatCard(
                                      icon: Icons.groups_rounded,
                                      value: '${sponsoredEmails.length}',
                                      label: 'Filleuls',
                                      color: Colors.blue,
                                    ),
                                    _buildStatCard(
                                      icon: Icons.check_circle_rounded,
                                      value: '$activeReferrals',
                                      label: 'Actifs',
                                      color: Colors.green,
                                    ),
                                    _buildStatCard(
                                      icon: Icons.schedule_rounded,
                                      value: '${cc.pendingReferrals.value}',
                                      label: 'En attente',
                                      color: Colors.orange,
                                    ),
                                    _buildStatCard(
                                      icon: Icons.monetization_on_rounded,
                                      value: '$totalEarnings pts',
                                      label: 'Gains',
                                      color: Colors.purple,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const CustomSpace(heightMultiplier: 3),

                    // Section Code de parrainage
                    CustomCardAnimation(
                      index: 1,
                      child: Container(
                        width: UniquesControllers().data.baseMaxWidth +
                            (UniquesControllers().data.baseSpace * 5),
                        padding: EdgeInsets.all(
                          UniquesControllers().data.baseSpace * 2.5,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.35),
                              Colors.white.withOpacity(0.25),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: CustomTheme.lightScheme()
                                  .primary
                                  .withOpacity(0.15),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          //borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: CustomTheme.lightScheme()
                                            .primary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.qr_code_rounded,
                                        color:
                                            CustomTheme.lightScheme().primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Mon code de parrainage',
                                      style: TextStyle(
                                        fontSize: UniquesControllers()
                                                .data
                                                .baseSpace *
                                            2,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                                const CustomSpace(heightMultiplier: 3),
                                Container(
                                  padding: EdgeInsets.all(
                                    UniquesControllers().data.baseSpace * 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: CustomTheme.lightScheme()
                                        .primaryContainer
                                        .withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: CustomTheme.lightScheme()
                                          .primary
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        cc.referralCode.value,
                                        style: TextStyle(
                                          fontSize: UniquesControllers()
                                                  .data
                                                  .baseSpace *
                                              2.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                          color:
                                              CustomTheme.lightScheme().primary,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: () =>
                                                cc.copyReferralCode(),
                                            icon: Icon(
                                              Icons.copy_rounded,
                                              color: CustomTheme.lightScheme()
                                                  .primary,
                                            ),
                                            tooltip: 'Copier',
                                          ),
                                          IconButton(
                                            onPressed: () =>
                                                cc.shareReferralCode(),
                                            icon: Icon(
                                              Icons.send_rounded,
                                              color: CustomTheme.lightScheme()
                                                  .primary,
                                            ),
                                            tooltip: 'Inviter',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Section Mon parrain (si applicable)
                    if (sponsorInfo != null) ...[
                      const CustomSpace(heightMultiplier: 3),
                      CustomCardAnimation(
                        index: 2,
                        child: Container(
                          width: UniquesControllers().data.baseMaxWidth +
                              (UniquesControllers().data.baseSpace * 5),
                          padding: EdgeInsets.all(
                            UniquesControllers().data.baseSpace * 2.5,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.purple.withOpacity(0.15),
                                Colors.purple.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.15),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            //borderRadius: BorderRadius.circular(28),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.person_pin_rounded,
                                          color: Colors.purple,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Mon parrain',
                                        style: TextStyle(
                                          fontSize: UniquesControllers()
                                                  .data
                                                  .baseSpace *
                                              2,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const CustomSpace(heightMultiplier: 2),
                                  ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          Colors.purple.withOpacity(0.2),
                                      child: Text(
                                        sponsorInfo['name']
                                                ?.substring(0, 1)
                                                .toUpperCase() ??
                                            '?',
                                        style: TextStyle(
                                          color: Colors.purple,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      sponsorInfo['name'] ??
                                          'Nom non disponible',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(sponsorInfo['email'] ?? ''),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Section Mes filleuls
                    if (sponsoredEmails.isNotEmpty) ...[
                      const CustomSpace(heightMultiplier: 3),
                      CustomCardAnimation(
                        index: 3,
                        child: Container(
                          width: UniquesControllers().data.baseMaxWidth +
                              (UniquesControllers().data.baseSpace * 5),
                          padding: EdgeInsets.all(
                            UniquesControllers().data.baseSpace * 2.5,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.35),
                                Colors.white.withOpacity(0.25),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: CustomTheme.lightScheme()
                                    .primary
                                    .withOpacity(0.15),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            //borderRadius: BorderRadius.circular(28),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: CustomTheme.lightScheme()
                                              .primary
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.people_rounded,
                                          color:
                                              CustomTheme.lightScheme().primary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Mes filleuls (${sponsoredEmails.length})',
                                          style: TextStyle(
                                            fontSize: UniquesControllers()
                                                    .data
                                                    .baseSpace *
                                                2,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const CustomSpace(heightMultiplier: 2),
                                  ...sponsoredEmails
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final index = entry.key;
                                    final email = entry.value;
                                    final referralData =
                                        cc.referralDetails[email];
                                    final isActive =
                                        referralData?['isActive'] ?? false;
                                    final earnings =
                                        referralData?['earnings'] ?? 0;
                                    final joinDate =
                                        referralData?['joinDate'] ?? '';
                                    final userType =
                                        referralData?['userType'] ?? '';
                                    final name = referralData?['name'] ?? '';

                                    return Dismissible(
                                      key: Key(email),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding:
                                            const EdgeInsets.only(right: 20),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.delete_rounded,
                                          color: Colors.red,
                                        ),
                                      ),
                                      confirmDismiss: (direction) async {
                                        return await showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text('Confirmer'),
                                              content: Text(
                                                'Voulez-vous vraiment retirer $email de vos filleuls ?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(false),
                                                  child: Text('Annuler'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(true),
                                                  child: Text(
                                                    'Retirer',
                                                    style: TextStyle(
                                                        color: Colors.red),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      onDismissed: (direction) {
                                        cc.removeReferral(email);
                                      },
                                      child: Container(
                                        margin: EdgeInsets.only(
                                          bottom: UniquesControllers()
                                              .data
                                              .baseSpace,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isActive
                                                ? Colors.green.withOpacity(0.3)
                                                : Colors.grey.withOpacity(0.2),
                                          ),
                                        ),
                                        child: ListTile(
                                          leading: Stack(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: isActive
                                                    ? Colors.green
                                                        .withOpacity(0.2)
                                                    : Colors.grey
                                                        .withOpacity(0.2),
                                                child: Icon(
                                                  _getIconForUserType(userType),
                                                  color: isActive
                                                      ? Colors.green
                                                      : Colors.grey,
                                                ),
                                              ),
                                              if (isActive)
                                                Positioned(
                                                  right: 0,
                                                  bottom: 0,
                                                  child: Container(
                                                    width: 12,
                                                    height: 12,
                                                    decoration: BoxDecoration(
                                                      color: Colors.green,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: Colors.white,
                                                        width: 2,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          title: Text(
                                            name.isNotEmpty ? name : email,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (name.isNotEmpty)
                                                Text(
                                                  email,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          _getColorForUserType(
                                                                  userType)
                                                              .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Text(
                                                      userType.isNotEmpty
                                                          ? userType
                                                          : 'Non inscrit',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            _getColorForUserType(
                                                                userType),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    isActive
                                                        ? 'Actif'
                                                        : 'En attente',
                                                    style: TextStyle(
                                                      color: isActive
                                                          ? Colors.green
                                                          : Colors.orange,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (joinDate.isNotEmpty)
                                                Text(
                                                  'Inscrit le $joinDate',
                                                  style:
                                                      TextStyle(fontSize: 11),
                                                ),
                                            ],
                                          ),
                                          trailing: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '+$earnings pts',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                'Gains',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      const CustomSpace(heightMultiplier: 3),
                      CustomCardAnimation(
                        index: 3,
                        child: Container(
                          width: UniquesControllers().data.baseMaxWidth +
                              (UniquesControllers().data.baseSpace * 5),
                          padding: EdgeInsets.all(
                            UniquesControllers().data.baseSpace * 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.grey.withOpacity(0.15),
                                Colors.grey.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_add_alt_1_rounded,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const CustomSpace(heightMultiplier: 2),
                              Text(
                                'Aucun filleul pour le moment',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const CustomSpace(heightMultiplier: 1),
                              Text(
                                'Commencez à parrainer vos proches\net gagnez des récompenses !',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const CustomSpace(heightMultiplier: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(UniquesControllers().data.baseSpace * 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForUserType(String userType) {
    switch (userType.toLowerCase()) {
      case 'particulier':
        return Icons.person_rounded;
      case 'entreprise':
        return Icons.business_rounded;
      case 'boutique':
        return Icons.store_rounded;
      case 'association':
        return Icons.favorite_rounded;
      default:
        return Icons.person_outline_rounded;
    }
  }

  Color _getColorForUserType(String userType) {
    switch (userType.toLowerCase()) {
      case 'particulier':
        return Colors.blue;
      case 'entreprise':
        return Colors.purple;
      case 'boutique':
        return Colors.orange;
      case 'association':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}
