import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dashcore/services/supabase_service.dart';
import 'package:dashcore/services/analytics_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/dash_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'privacy_policy_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isRegistering = false;

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!await _ensurePrivacyAccepted()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Introduce tu correo y contraseña.', isError: true);
      return;
    }

    if (password.length < 8) {
      _showMessage(
        'La contraseña debe tener al menos 8 caracteres.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final client = _supabase;
      if (client == null) {
        _showMessage(
          'Servicio no disponible. Inténtalo más tarde.',
          isError: true,
        );
        return;
      }

      if (_isRegistering) {
        AnalyticsService.instance.logEvent('signup_started');
        await client.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: 'io.dashcore.app://login-callback/',
        );

        if (!mounted) return;

        if (client.auth.currentSession == null) {
          _showMessage(
            'Registro iniciado. Revisa tu correo para confirmar la cuenta.',
          );
          return;
        }

        await _finishSignedIn(client.auth.currentSession!.user);
        return;
      }

      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      final user = response.user ?? client.auth.currentUser;
      if (user == null) {
        _showMessage('No se pudo iniciar sesión.', isError: true);
        return;
      }

      await _finishSignedIn(user);
    } on AuthException catch (e) {
      if (!mounted) return;
      _showMessage(_authErrorMessage(e.message), isError: true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (!await _ensurePrivacyAccepted()) return;
    setState(() => _isLoading = true);
    try {
      final client = _supabase;
      if (client == null) return;

      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.dashcore.app://login-callback/',
      );

      // El flujo de OAuth redirige fuera de la app o abre un webview.
      // La respuesta llegará vía deep link que maneja Supabase.
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error al iniciar con Google: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _ensurePrivacyAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('privacy_policy_accepted_version') ==
        PrivacyPolicyScreen.version)
      return true;
    if (!mounted) return false;
    final accepted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
    if (accepted != true) return false;
    await prefs.setString(
      'privacy_policy_accepted_version',
      PrivacyPolicyScreen.version,
    );
    await prefs.setString(
      'privacy_policy_accepted_at',
      DateTime.now().toUtc().toIso8601String(),
    );
    return true;
  }

  Future<void> _finishSignedIn(User user) async {
    try {
      await SupabaseService.instance.createUserProfile(user);
    } catch (e) {
      debugPrint('Error creating profile: $e');
    }

    if (!mounted) return;

    // Progress tutorial
    final settings = Provider.of<DashSettingsProvider>(context, listen: false);
    if (settings.isTutorialActive && settings.tutorialStep == 12) {
      settings.setTutorialStep(13);
    }

    Navigator.of(context).pop(true);
  }

  String _authErrorMessage(String error) {
    final message = error.toLowerCase();
    if (message.contains('already registered')) {
      return 'Este correo ya está registrado.';
    }
    if (message.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (message.contains('invalid email')) {
      return 'El correo electrónico no es válido.';
    }
    if (message.contains('password should be at least')) {
      return 'La contraseña es demasiado corta.';
    }
    if (message.contains('email not confirmed')) {
      return 'Debes confirmar tu correo antes de iniciar sesión.';
    }
    if (message.contains('too many requests')) {
      return 'Demasiados intentos. Inténtalo más tarde.';
    }
    return error.isNotEmpty ? error : 'No se pudo completar la operación.';
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF00E5FF);

    return Scaffold(
      backgroundColor: const Color(0xFF050608),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/png/car1.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: Color(0xFF050608)),
          ),
          const ColoredBox(color: Color(0xE6050608)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/dashcore_logo.png',
                      width: 90,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.speed_rounded,
                        color: themeColor,
                        size: 72,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'DASHCORE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 10,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'HIGH PERFORMANCE DASHBOARD',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 60),
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _isRegistering ? 'CREAR CUENTA' : 'INICIAR SESIÓN',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 30),
                          _buildTextField(
                            controller: _emailController,
                            label: 'EMAIL',
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                            controller: _passwordController,
                            label: 'CONTRASEÑA',
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          if (!_isRegistering)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () async {
                                        final email = _emailController.text
                                            .trim();
                                        if (email.isEmpty) {
                                          _showMessage(
                                            'Introduce tu correo para restablecer.',
                                            isError: true,
                                          );
                                          return;
                                        }
                                        try {
                                          await SupabaseService.instance
                                              .resetPassword(email);
                                          _showMessage(
                                            'Enlace de recuperación enviado a $email',
                                          );
                                        } catch (e) {
                                          _showMessage(
                                            'Error al enviar recuperación.',
                                            isError: true,
                                          );
                                        }
                                      },
                                child: const Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: TextStyle(
                                    color: themeColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColor,
                                foregroundColor: Colors.black,
                                disabledBackgroundColor: themeColor.withValues(
                                  alpha: 0.4,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Text(
                                      _isRegistering
                                          ? 'REGISTRARSE'
                                          : 'ACCEDER',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                            ),
                          ),
                          if (!_isRegistering) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: OutlinedButton(
                                onPressed: () =>
                                    setState(() => _isRegistering = true),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: themeColor,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'REGISTRARSE / CREAR CUENTA',
                                  style: TextStyle(
                                    color: themeColor,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Row(
                              children: [
                                Expanded(child: Divider(color: Colors.white10)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'O CONTINUAR CON',
                                    style: TextStyle(
                                      color: Colors.white24,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.white10)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : _handleGoogleSignIn,
                                icon: Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                                  height: 24,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.g_mobiledata_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                label: const Text(
                                  'GOOGLE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(
                                    0.05,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(
                                      color: Colors.white12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(
                              () => _isRegistering = !_isRegistering,
                            ),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white54,
                          ),
                          children: [
                            TextSpan(
                              text: _isRegistering
                                  ? '¿Ya tienes cuenta? '
                                  : '¿No tienes cuenta? ',
                            ),
                            TextSpan(
                              text: _isRegistering
                                  ? 'Inicia sesión'
                                  : 'Regístrate',
                              style: const TextStyle(
                                color: themeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white24,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isPassword
          ? TextInputType.visiblePassword
          : TextInputType.emailAddress,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF00E5FF), size: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF00E5FF)),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.02),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }
}
