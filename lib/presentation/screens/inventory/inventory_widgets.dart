part of '../inventory_screen.dart';

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isWarning;
  final bool isError;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    this.isWarning = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isError
              ? AppTheme.errorColor.withValues(alpha: 0.5)
              : (isWarning
                    ? AppTheme.warningColor.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1)),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isError
                    ? AppTheme.errorColor
                    : (isWarning ? AppTheme.warningColor : Colors.white),
                size: 14,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryItemCard extends ConsumerStatefulWidget {
  final dynamic product;
  final VoidCallback onAddStock;

  const _InventoryItemCard({required this.product, required this.onAddStock});

  @override
  ConsumerState<_InventoryItemCard> createState() => _InventoryItemCardState();
}

class _InventoryItemCardState extends ConsumerState<_InventoryItemCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showProductMenu(context, ref),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.name ?? 'Unknown',
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Qty: ${widget.product.quantity ?? 0}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.add_circle_outline,
                color: AppTheme.primaryColor,
              ),
              title: const Text('Add Stock'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onAddStock();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: AppTheme.primaryColor,
              ),
              title: const Text('Edit Product'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProductScreen(product: widget.product),
                  ),
                ).then((_) {
                  ref.invalidate(productsProvider);
                  ref.invalidate(paginatedProductsProvider);
                  ref.invalidate(expiredBatchesProvider);
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
              title: const Text('Delete Product'),
              textColor: AppTheme.errorColor,
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Delete "${widget.product.name}"? This will also delete all batches.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteProduct(context, ref);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(BuildContext context, WidgetRef ref) async {
    try {
      final service = ProductCrudService();
      await service.deleteProduct(widget.product.id);
      if (context.mounted) {
        ref.invalidate(productsProvider);
        ref.invalidate(expiredBatchesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

}

class _InventoryItemPill extends ConsumerStatefulWidget {
  final dynamic product;
  final VoidCallback onAddStock;

  const _InventoryItemPill({
    required this.product,
    required this.onAddStock,
  });

  @override
  ConsumerState<_InventoryItemPill> createState() => _InventoryItemPillState();
}

class _InventoryItemPillState extends ConsumerState<_InventoryItemPill> {
  void _openEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(product: widget.product),
      ),
    );
  }

  void _showProductMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_box_rounded, color: AppTheme.primaryColor),
              title: const Text('Add Stock', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                widget.onAddStock();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppTheme.primaryColor),
              title: const Text('Edit Product', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _openEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
              title: const Text('Delete Product', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Product?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor))),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ProductCrudService().deleteProduct(widget.product.id);
                  ref.invalidate(productsProvider);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLowStock = widget.product.quantity < 10;
    final bool isOutOfStock = widget.product.quantity == 0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.slate200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.slate900.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: () {
            HapticFeedback.heavyImpact();
            _showProductMenu(context, ref);
          },
          onTap: () {
            HapticFeedback.selectionClick();
            _openEdit();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Product Icon/Image
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.slate50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.slate100, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty
                        ? Image.network(
                            widget.product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
                          )
                        : _buildPlaceholderIcon(),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: AppTheme.slate900,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOutOfStock 
                                ? AppTheme.errorColor.withValues(alpha: 0.1)
                                : (isLowStock ? AppTheme.warningColor.withValues(alpha: 0.1) : AppTheme.successColor.withValues(alpha: 0.1)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOutOfStock ? Icons.error_outline_rounded : Icons.inventory_2_outlined,
                                  size: 10,
                                  color: isOutOfStock 
                                    ? AppTheme.errorColor 
                                    : (isLowStock ? AppTheme.warningColor : AppTheme.successColor),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.product.quantity.toInt()} left',
                                  style: TextStyle(
                                    color: isOutOfStock 
                                      ? AppTheme.errorColor 
                                      : (isLowStock ? AppTheme.warningColor : AppTheme.successColor),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '₹${widget.product.price}',
                            style: const TextStyle(
                              color: AppTheme.slate500,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        Icons.inventory_2_rounded,
        size: 20,
        color: AppTheme.textSecondary.withValues(alpha: 0.3),
      ),
    );
  }
}


class _QuickAddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

