import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_controller.dart';
import '../dashboard/responsive_dashboard.dart';

/// Kullanıcı oturumunu ve yönlendirmesini yöneten ana widget.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState.isLoading) {
      // Giriş işlemi devam ediyorsa yükleniyor göstergesi
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (authState.isAuthenticated) {
      // Kullanıcı giriş yaptıysa, rolüne göre dashboard'a yönlendir
      return ResponsiveDashboard(role: authState.role ?? 'öğrenci');
    }
    // Giriş yapılmamışsa giriş ekranı göster
    return const SignInScreen();
  }
}


class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    return Scaffold(
      body: Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('UNITY4 ACADEMY', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 24),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value != null && value.contains('@') ? null : 'Geçerli bir email girin',
                    onSaved: (value) => _email = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Şifre'),
                    obscureText: true,
                    validator: (value) => value != null && value.length >= 6 ? null : 'En az 6 karakter',
                    onSaved: (value) => _password = value ?? '',
                  ),
                  const SizedBox(height: 24),
                  if (authState.error != null && authState.error!.isNotEmpty)
                    Text(authState.error ?? '', style: const TextStyle(color: Colors.red)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: authState.isLoading
                            ? null
                            : () {
                                final formState = _formKey.currentState;
                                if (formState != null && formState.validate()) {
                                  formState.save();
                                  ref.read(authProvider.notifier).signIn(_email, _password);
                                }
                              },
                        child: authState.isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Giriş Yap'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SignUpScreen()),
                          );
                        },
                        child: const Text('Kayıt Ol'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value != null && value.contains('@') ? null : 'Geçerli bir email girin',
                    onSaved: (value) => _email = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Şifre'),
                    obscureText: true,
                    validator: (value) => value != null && value.length >= 6 ? null : 'En az 6 karakter',
                    onSaved: (value) => _password = value ?? '',
                  ),
                  const SizedBox(height: 24),
                  if (authState.error != null && authState.error!.isNotEmpty)
                    Text(authState.error ?? '', style: const TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: authState.isLoading
                        ? null
                        : () {
                            final formState = _formKey.currentState;
                            if (formState != null && formState.validate()) {
                              formState.save();
                              ref.read(authProvider.notifier).signUp(_email, _password);
                            }
                          },
                    child: authState.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Kayıt Ol'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
