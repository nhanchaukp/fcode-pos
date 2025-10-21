import 'package:flutter/material.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static final _categories = [
    _CategorySample(
      name: 'Điện thoại',
      productCount: 38,
      revenueShare: 0.42,
      icon: Icons.smartphone,
    ),
    _CategorySample(
      name: 'Laptop',
      productCount: 24,
      revenueShare: 0.28,
      icon: Icons.laptop_mac,
    ),
    _CategorySample(
      name: 'Phụ kiện',
      productCount: 56,
      revenueShare: 0.18,
      icon: Icons.headphones,
    ),
    _CategorySample(
      name: 'Thiết bị đeo',
      productCount: 14,
      revenueShare: 0.12,
      icon: Icons.watch,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh mục sản phẩm'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhóm sản phẩm',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _categories.length,
                separatorBuilder: (context, _) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Card(
                    elevation: 0,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 24,
                        child: Icon(category.icon),
                      ),
                      title: Text(
                        category.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${category.productCount} sản phẩm',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: category.revenueShare,
                              minHeight: 6,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Chiếm ${(category.revenueShare * 100).toStringAsFixed(1)}% doanh thu',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySample {
  const _CategorySample({
    required this.name,
    required this.productCount,
    required this.revenueShare,
    required this.icon,
  });

  final String name;
  final int productCount;
  final double revenueShare;
  final IconData icon;
}
