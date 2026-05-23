part of '../home_screen.dart';

// ── TOP PRODUCTS SECTION ─────────────────────────────────────────────────────

class _TopProductsSection extends StatelessWidget {
  final List<TopProduct> products;
  const _TopProductsSection({required this.products});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Sellers',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: -0.8),
              ),
              Icon(CupertinoIcons.bolt_fill, color: Color(0xFFF59E0B), size: 18),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: products.length > 5 ? 5 : products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _TopProductCard(product: product, index: index);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TopProductCard extends StatelessWidget {
  final TopProduct product;
  final int index;
  const _TopProductCard({required this.product, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.slate100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '#${index + 1}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.slate600),
            ),
          ),
          const Spacer(),
          Text(
            product.productName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            '${product.unitsSold} units',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.accentColor),
          ),
        ],
      ),
    );
  }
}

// ── ALERT SECTION ────────────────────────────────────────────────────────────

class _AlertSection extends StatelessWidget {
  final List<LowStockProduct> items;
  const _AlertSection({required this.items});

  @override
  Widget build(BuildContext context) {
    final displayCount = items.length > 3 ? 3 : items.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stock Alerts',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: -0.8),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryDark.withValues(alpha: 0.04),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              children: List.generate(displayCount, (i) {
                final item = items[i];
                return _AlertTile(item: item, isOut: item.quantity == 0, isLast: i == (displayCount - 1));
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final LowStockProduct item;
  final bool isOut;
  final bool isLast;

  const _AlertTile({required this.item, required this.isOut, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isOut ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              isOut ? CupertinoIcons.exclamationmark_triangle_fill : CupertinoIcons.tag_fill,
              color: isOut ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
              size: 22,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: -0.5),
                ),
                Text(
                  isOut ? 'Critical: Out of Stock' : 'Low Stock: ${item.quantity} remaining',
                  style: TextStyle(
                    fontSize: 13,
                    color: isOut ? const Color(0xFFEF4444) : AppTheme.textSecondary,
                    fontWeight: isOut ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(CupertinoIcons.chevron_right, size: 16, color: AppTheme.slate300),
        ],
      ),
    );
  }
}

// ── SKELETONS ────────────────────────────────────────────────────────────────

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      margin: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(child: CupertinoActivityIndicator()),
    );
  }
}