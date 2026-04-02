import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_hub_provider.dart';
import '../theme/app_theme.dart';

class BiotechSettingsScreen extends StatefulWidget {
  const BiotechSettingsScreen({super.key});

  @override
  State<BiotechSettingsScreen> createState() => _BiotechSettingsScreenState();
}

class _BiotechSettingsScreenState extends State<BiotechSettingsScreen> {
  final _emailController = TextEditingController();
  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final hub = context.read<AnalysisHubProvider>();
    _emailController.text = hub.userEmail ?? '';
    _apiKeyController.text = hub.ncbiApiKey ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _saveSettings(AnalysisHubProvider hub) {
    hub.updateNcbiIdentity(
      email: _emailController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GENOMIC IDENTITY SYNCHRONIZED'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hub = context.watch<AnalysisHubProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('LABORATORY SETTINGS'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: [
              _sectionHeader(theme, 'NCBI ENTREZ IDENTITY'),
              const SizedBox(height: 16),
              _bentoCard(
                theme: theme,
                accentColor: AppTheme.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NCBI requires an email address for API usage. Providing an API key increases rate limits from 3 to 10 requests per second.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _settingsTextField(
                      label: 'ADMINISTRATOR EMAIL',
                      controller: _emailController,
                      hint: 'researcher@institution.edu',
                      icon: Icons.alternate_email_rounded,
                    ),
                    const SizedBox(height: 20),
                    _settingsTextField(
                      label: 'NCBI API KEY (OPTIONAL)',
                      controller: _apiKeyController,
                      hint: '32-character hex key',
                      icon: Icons.vpn_key_outlined,
                      isPassword: true,
                    ),
                    const SizedBox(height: 32),
                    _GradientButton(
                      label: 'SYNCHRONIZE CREDENTIALS',
                      onPressed: () => _saveSettings(hub),
                      theme: theme,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              _sectionHeader(theme, 'SEARCH CALIBRATION'),
              const SizedBox(height: 16),
              _bentoCard(
                theme: theme,
                accentColor: AppTheme.tertiary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'MAX SEARCH RESULTS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Colors.white30,
                          ),
                        ),
                        Text(
                          '${hub.ncbiSearchLimit} Results',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Slider(
                      value: hub.ncbiSearchLimit.toDouble(),
                      min: 5,
                      max: 100,
                      divisions: 19,
                      activeColor: AppTheme.tertiary,
                      onChanged: (v) => hub.setNcbiSearchLimit(v.toInt()),
                    ),
                    Text(
                      'Higher depth increases discovery range but may prolong query latency.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4),
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _sectionHeader(theme, 'ANALYTICAL GUARDRAILS'),
              const SizedBox(height: 16),
              _bentoCard(
                theme: theme,
                accentColor: Colors.orange,
                child: Column(
                  children: [
                    _settingsToggle(
                      title: 'Auto-Telemetry Polling',
                      subtitle: 'Ensures real-time stress monitoring during HP analysis.',
                      value: hub.autoTelemetry, 
                      onChanged: (val) => hub.setAutoTelemetry(value: val),
                      theme: theme,
                      accentColor: Colors.orange,
                    ),
                    const Divider(height: 32, thickness: 0.5, color: Colors.white10),
                    _settingsToggle(
                      title: 'Aggressive Garbage Collection',
                      subtitle: 'Explicitly trigger memory cleanup before large DNA clusters.',
                      value: hub.isSafetyLocked, 
                      onChanged: (v) => hub.toggleSafetyLock(isLocked: v),
                      theme: theme,
                      accentColor: Colors.orange,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              Center(
                child: Text(
                  'BioPulse Genomic Workbench v1.2.0\nChaquopy Python Runtime active',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white10,
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title) => Text(
      title,
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );

  Widget _bentoCard({
    required ThemeData theme,
    required Color accentColor,
    required Widget child,
  }) => Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.1),
        ),
      ),
      child: child,
    );

  Widget _settingsTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white30,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18),
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            fillColor: Colors.black.withValues(alpha: 0.2),
          ),
        ),
      ],
    );

  Widget _settingsToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeData theme,
    required Color accentColor,
  }) => Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white30,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: accentColor.withValues(alpha: 0.5),
          activeThumbColor: accentColor,
        ),
      ],
    );
}

class _GradientButton extends StatelessWidget {

  const _GradientButton({
    required this.label,
    required this.theme, this.onPressed,
  });
  final String label;
  final VoidCallback? onPressed;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ),
    );
}
