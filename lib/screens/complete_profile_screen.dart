import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../providers/view_state.dart';
import '../widgets/brand.dart';

/// Step 3 (new users only): set a display name, which PATCHes /users/:id
/// against the id created during OTP request.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final session = context.read<SessionProvider>();
    final ok = await session.updateName(_nameController.text.trim());
    if (!mounted) return;
    if (ok) {
      context.go('/venues');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(session.errorMessage ?? 'Could not save your name')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final loading = session.profileState == ViewState.loading;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GradientHeader(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🎉', style: TextStyle(fontSize: 40)),
                SizedBox(height: 12),
                Text(
                  "You're in!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Just one last thing before you start booking.',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('What should we call you?',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      enabled: !loading,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        labelText: 'Your name',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? 'Please enter your name' : null,
                      onFieldSubmitted: (_) => loading ? null : _save(),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: loading ? null : _save,
                      child: loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                          : const Text('Continue'),
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
}
