import 'package:flutter/material.dart';

/// Temporary scaffold used by not-yet-implemented screens so routing can be
/// wired and tested end-to-end before each screen gets its real UI. Replace
/// each usage with the real screen build as that feature is implemented.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderScreen(
      {super.key, required this.title, this.icon = Icons.construction_rounded});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).hintColor),
            const SizedBox(height: 12),
            Text('$title — coming soon',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
