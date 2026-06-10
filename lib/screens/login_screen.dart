import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../providers/view_state.dart';
import '../widgets/state_views.dart';

/// Simple "login": pick one of the seeded users. The chosen id becomes the
/// X-User-Id for every request.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    // Load users once after first frame (can't call provider in initState body
    // synchronously without context being ready for notifications).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Icon(Icons.sports_tennis_rounded,
                  size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text('QuickSlot',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              const SizedBox(height: 4),
              Text('Book badminton courts & turf grounds',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
              const SizedBox(height: 32),
              Text('Continue as', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Expanded(child: _buildBody(session)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(SessionProvider session) {
    switch (session.state) {
      case ViewState.loading:
      case ViewState.idle:
        return const LoadingView(label: 'Loading users…');
      case ViewState.error:
        return ErrorView(
          message: session.errorMessage ?? 'Could not load users',
          onRetry: session.loadUsers,
        );
      case ViewState.empty:
        return EmptyView(
          message: 'No users available',
          action: OutlinedButton(onPressed: session.loadUsers, child: const Text('Reload')),
        );
      case ViewState.success:
        return ListView.separated(
          itemCount: session.users.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final user = session.users[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(user.name[0])),
                title: Text(user.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  session.login(user);
                  context.go('/venues');
                },
              ),
            );
          },
        );
    }
  }
}
