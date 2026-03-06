import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/purchase_provider.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    final purchaseState = ref.watch(purchaseProvider);
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final isPremium = purchaseState.isPremium || (user?.isPremium == true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current plan status
          _buildCurrentPlanCard(context, theme, isPremium, user?.planExpiresAt),
          const SizedBox(height: 24),

          if (!isPremium) ...[
            // Premium benefits
            _buildPremiumBenefitsCard(context, theme),
            const SizedBox(height: 24),

            // Price & subscribe button
            _buildSubscribeSection(context, theme, purchaseState),
          ] else ...[
            // Premium management
            _buildPremiumManagementCard(context, theme, user?.planExpiresAt),
          ],

          const SizedBox(height: 16),

          // Restore purchases
          Center(
            child: TextButton(
              onPressed: purchaseState.isLoading
                  ? null
                  : () => ref.read(purchaseProvider.notifier).restorePurchases(),
              child: const Text('Restore Purchases'),
            ),
          ),

          // Error message
          if (purchaseState.error != null) ...[
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        purchaseState.error!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanCard(
    BuildContext context,
    ThemeData theme,
    bool isPremium,
    DateTime? expiresAt,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              isPremium ? Icons.workspace_premium : Icons.person,
              size: 48,
              color: isPremium
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              isPremium ? 'Premium Plan' : 'Free Plan',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isPremium
                  ? 'You have access to all features'
                  : 'Upgrade to unlock all features',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBenefitsCard(BuildContext context, ThemeData theme) {
    final benefits = [
      _BenefitItem(
        icon: Icons.auto_awesome,
        title: 'Unlimited AI Generations',
        description: 'No daily limit on AI caption and hashtag generation',
      ),
      _BenefitItem(
        icon: Icons.cloud_upload,
        title: '50GB Storage',
        description: 'Store up to 50GB of photos and results',
      ),
      _BenefitItem(
        icon: Icons.block,
        title: 'No Ads',
        description: 'Enjoy an ad-free experience',
      ),
      _BenefitItem(
        icon: Icons.support_agent,
        title: 'Priority Support',
        description: 'Get faster responses from our support team',
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Premium Benefits',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...benefits.map((benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          benefit.icon,
                          size: 20,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              benefit.title,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              benefit.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribeSection(
    BuildContext context,
    ThemeData theme,
    PurchaseState purchaseState,
  ) {
    // Try to get the price from the store product, fall back to the known price.
    String priceText = '\u00a5480/month';
    if (purchaseState.products.isNotEmpty) {
      final product = purchaseState.products.first;
      priceText = '${product.price}/month';
    }

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              priceText,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cancel anytime',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: purchaseState.isLoading
                    ? null
                    : () => ref.read(purchaseProvider.notifier).buyPremium(),
                icon: purchaseState.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.workspace_premium),
                label: Text(
                    purchaseState.isLoading ? 'Processing...' : 'Subscribe'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumManagementCard(
    BuildContext context,
    ThemeData theme,
    DateTime? expiresAt,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Subscription',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (expiresAt != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Next billing date'),
                subtitle: Text(
                  '${expiresAt.year}/${expiresAt.month.toString().padLeft(2, '0')}/${expiresAt.day.toString().padLeft(2, '0')}',
                ),
              ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.settings),
              title: const Text('Manage in Store'),
              subtitle: const Text(
                  'Change or cancel your subscription in your device\'s app store'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // In production, open the platform's subscription management page.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Opening subscription management in app store...'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitItem {
  final IconData icon;
  final String title;
  final String description;

  _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
