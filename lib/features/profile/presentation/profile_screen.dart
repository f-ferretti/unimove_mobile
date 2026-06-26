import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(userProfileProvider.future),
        color: AppColors.universityGreen,
        child: userProfileAsync.when(
          data: (profile) {
            if (profile == null) {
              return const Center(
                child: Text(
                  'Nessun dato profilo disponibile',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                children: [
                  // Profile Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      children: [
                        _buildAvatar(profile.avatarUrl),
                        const SizedBox(height: 16),
                        Text(
                          profile.fullName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.universityGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatRole(profile.role),
                            style: const TextStyle(
                              color: AppColors.universityGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info Cards (Read-only Display)
                  _buildInfoCard(
                    title: 'Informazioni personali',
                    icon: Icons.person_outline,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailItem('Nome completo', profile.fullName),
                        const SizedBox(height: 12),
                        _buildDetailItem('Email istituzionale', profile.email),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildInfoCard(
                    title: 'Preferenze di viaggio',
                    icon: Icons.chat_bubble_outline,
                    content: Text(
                      (profile.travelPreferences != null && profile.travelPreferences!.trim().isNotEmpty)
                          ? profile.travelPreferences!
                          : 'Nessuna preferenza specificata',
                      style: TextStyle(
                        color: (profile.travelPreferences != null && profile.travelPreferences!.trim().isNotEmpty)
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                        fontSize: 14,
                        fontStyle: (profile.travelPreferences != null && profile.travelPreferences!.trim().isNotEmpty)
                            ? FontStyle.normal
                            : FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildInfoCard(
                    title: 'Informazioni bancarie',
                    icon: Icons.account_balance_wallet_outlined,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailItem('Intestatario conto', profile.ibanHolder ?? 'N/D'),
                        const SizedBox(height: 12),
                        _buildDetailItem(
                          'IBAN',
                          _maskIban(profile.iban),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.universityGreen),
          ),
          error: (err, stack) => Center(
            child: Text(
              'Errore nel caricamento del profilo: $err',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.startsWith('data:image')) {
      try {
        final base64Str = avatarUrl.split(',').last;
        final bytes = base64Decode(base64Str);
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.universityGreen, width: 2),
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundImage: MemoryImage(bytes),
          ),
        );
      } catch (_) {}
    }
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white10, width: 2),
      ),
      child: const CircleAvatar(
        radius: 50,
        backgroundColor: AppColors.surfaceDark,
        child: Icon(Icons.person, size: 50, color: AppColors.universityGreen),
      ),
    );
  }

  String _formatRole(String role) {
    switch (role.toUpperCase()) {
      case 'STUDENT': return 'Studente';
      case 'PROFESSOR': return 'Docente';
      case 'STAFF': return 'Personale PTA';
      default: return role;
    }
  }

  String _maskIban(String? iban) {
    if (iban == null || iban.trim().isEmpty) {
      return 'Nessun IBAN salvato';
    }
    final clean = iban.replaceAll(RegExp(r'\s+'), '');
    if (clean.length < 8) return clean;
    final start = clean.substring(0, 4);
    final end = clean.substring(clean.length - 4);
    return '$start •••• •••• •••• $end';
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.universityGreen,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.deepBlack,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: AppColors.universityGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 18),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                content,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
