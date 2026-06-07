import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

typedef EmailAuthCallback =
    Future<void> Function(String email, String password);

class EmailAuthSheet extends StatefulWidget {
  const EmailAuthSheet({
    required this.onSignIn,
    required this.onSignUp,
    super.key,
  });

  final EmailAuthCallback onSignIn;
  final EmailAuthCallback onSignUp;

  @override
  State<EmailAuthSheet> createState() => _EmailAuthSheetState();
}

class _EmailAuthSheetState extends State<EmailAuthSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool createAccount}) async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (createAccount) {
        await widget.onSignUp(email, password);
      } else {
        await widget.onSignIn(email, password);
      }
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _friendlyAuthError(error));
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'No se pudo completar el acceso. Comprueba tu conexión.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyAuthError(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'Introduce un email válido.',
      'invalid-credential' ||
      'user-not-found' ||
      'wrong-password' => 'Email o contraseña incorrectos.',
      'email-already-in-use' => 'Ese email ya tiene una cuenta.',
      'weak-password' => 'La contraseña debe tener al menos 6 caracteres.',
      'network-request-failed' => 'No hay conexión. Inténtalo de nuevo.',
      'operation-not-allowed' =>
        'El acceso con email no está habilitado en Firebase.',
      _ => error.message ?? 'No se pudo completar el acceso.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Acceso con email',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Puedes usar un correo ficticio para estas primeras pruebas.',
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('email-auth-email'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty || !email.contains('@')) {
                    return 'Introduce un email válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('email-auth-password'),
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(createAccount: false),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if ((value ?? '').length < 6) {
                    return 'Usa al menos 6 caracteres.';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  key: const Key('email-auth-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                FilledButton(
                  key: const Key('email-auth-sign-in'),
                  onPressed: () => _submit(createAccount: false),
                  child: const Text('Entrar'),
                ),
                TextButton(
                  key: const Key('email-auth-sign-up'),
                  onPressed: () => _submit(createAccount: true),
                  child: const Text('Crear cuenta de prueba'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
