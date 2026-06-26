import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import 'profile_controller.dart';

class EditPreferencesScreen extends ConsumerStatefulWidget {
  const EditPreferencesScreen({super.key});

  @override
  ConsumerState<EditPreferencesScreen> createState() => _EditPreferencesScreenState();
}

class _EditPreferencesScreenState extends ConsumerState<EditPreferencesScreen> {
  late final TextEditingController _preferencesController;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _preferencesController = TextEditingController();
  }

  @override
  void dispose() {
    _preferencesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    // Inizializza il controller di testo con il valore corrente
    userProfileAsync.whenData((profile) {
      if (!_initialized && profile != null) {
        _preferencesController.text = profile.travelPreferences ?? '';
        _initialized = true;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: const Text('Preferenze di viaggio'),
        backgroundColor: AppColors.deepBlack,
        elevation: 0,
      ),
      body: userProfileAsync.when(
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Le tue preferenze',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Inserisci le tue preferenze di viaggio (es. musica a bordo, fumo, bagagli, orari). Saranno visibili agli altri passeggeri e conducenti.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Text field
                const Text(
                  'PREFERENZE DI VIAGGIO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.universityGreen,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _preferencesController,
                  maxLines: 6,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Es. Non fumo in auto, preferisco musica rock. Ho spazio per bagagli di medie dimensioni...',
                    alignLabelWithHint: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.universityGreen, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _savePreferences,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.universityGreen,
                      disabledBackgroundColor: AppColors.universityGreen.withValues(alpha: 0.5),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Salva modifiche',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.universityGreen),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Errore nel caricamento dei dati: $err',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    final success = await ref
        .read(profileControllerProvider.notifier)
        .updatePreferences(_preferencesController.text);
    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferenze aggiornate con successo!'),
            backgroundColor: AppColors.universityGreen,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante l\'aggiornamento delle preferenze'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
