import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/placeholder_screen.dart';

class JobDetailScreen extends StatelessWidget {
  final String? jobId;

  const JobDetailScreen({super.key, this.jobId});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
      title: 'Job Detail', icon: Icons.business_center_rounded);
}
