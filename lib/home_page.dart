import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth/auth_controller.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final u = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Wash Suite'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: auth.loading ? null : () => auth.logout(),
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                u == null ? 'No user loaded' : 'Welcome ${u.fullName.isEmpty ? u.email : u.fullName}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text('Role: ${u?.role ?? "-"}'),
              const SizedBox(height: 10),
              Text('Token in memory: ${((auth.token ?? '').isNotEmpty) ? "YES" : "NO"}'),
            ],
          ),
        ),
      ),
    );
  }
}
