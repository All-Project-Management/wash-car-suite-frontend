import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wash_car_suite_frontend/login_page.dart';

import 'auth/auth_controller.dart';
import 'auth/auth_user.dart'; // <-- make sure this path matches your project

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _refresh(AuthController auth) async {
    await auth.tryAccount();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();
    final AuthUser? u = auth.user;

    final displayName = (u == null)
        ? 'Guest'
        : (u.fullName.trim().isNotEmpty ? u.fullName.trim() : u.email);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () => _refresh(auth),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 160.0,
              pinned: true,
              stretch: true,
              backgroundColor: theme.colorScheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Car Wash Suite',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primaryContainer,
                      ],
                    ),
                  ),
                ),
              ),
              actions: [_LogoutButton(auth: auth)],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(theme, u, displayName),

                    const SizedBox(height: 24),
                    Text(
                      'Account Summary',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (auth.loading)
                      const _LoadingState()
                    else if (u == null)
                      _EmptyState(
                        title: 'No Session Found',
                        subtitle: 'Please refresh or log in again.',
                        onRetry: () => _refresh(auth),
                      )
                    else
                      _AccountDetailsCard(u: u, onRefresh: () => _refresh(auth)),

                    const SizedBox(height: 32),
                    Center(
                      child: Opacity(
                        opacity: 0.5,
                        child: Text(
                          'v1.0.2 • Connected',
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, AuthUser? u, String displayName) {
    final roleLabel = u?.roleLabel ?? 'GUEST';
    final roleColor = (u != null && u.isAdmin) ? Colors.deepOrange : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(Icons.person_rounded, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u == null ? 'Not signed in' : 'Welcome,', style: theme.textTheme.bodySmall),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                _StatusChip(label: roleLabel, color: roleColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountDetailsCard extends StatelessWidget {
  const _AccountDetailsCard({required this.u, required this.onRefresh});
  final AuthUser u;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final roleLabel = u.roleLabel;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _DetailTile(icon: Icons.email_outlined, label: 'Email', value: u.email),
            const Divider(height: 32),
            _DetailTile(
              icon: Icons.person_outline,
              label: 'Full Name',
              value: u.fullName.isEmpty ? '—' : u.fullName,
            ),
            const Divider(height: 32),
            _DetailTile(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Role',
              value: roleLabel,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onRefresh,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Refresh Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.auth});
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout_rounded, color: Colors.white),
      onPressed: auth.loading
          ? null
          : () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Sign out?'),
            content: const Text('Do you want to log out of the suite?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Logout'),
              ),
            ],
          ),
        );

        if (ok == true) {
          await auth.logout();
          if (!context.mounted) return;

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
                (r) => false,
          );
        }
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: CircularProgressIndicator(),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle, required this.onRetry});
  final String title, subtitle;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.info_outline, size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(subtitle),
        TextButton(onPressed: onRetry, child: const Text('Try Again')),
      ],
    );
  }
}
