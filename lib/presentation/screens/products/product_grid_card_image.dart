part of '../products_screen.dart';

/// Image stack + placeholder for [_ProductGridCardState]
extension _ProductGridCardImage on _ProductGridCardState {
  Widget _buildImageStack({
    required bool inCart,
    required bool outOfStock,
    required String qtyDisplay,
  }) {
    return Stack(
      children: [
        Container(
          height: 85,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.slate50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'product_image_${widget.product.id}',
                  child: widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty
                      ? Image.network(
                          widget.product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
                        )
                      : widget.product.imagePath != null && widget.product.imagePath!.isNotEmpty
                          ? Image.file(
                              File(widget.product.imagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
                            )
                          : _buildPlaceholderIcon(),
                ),
                if (outOfStock)
                  Container(
                    color: Colors.black.withValues(alpha: 0.4),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SOLD OUT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (inCart)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 10),
                  const SizedBox(width: 4),
                  Text(
                    qtyDisplay,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          top: 10,
          right: 10,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.product.isLoose)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.scale_rounded,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              if (widget.product.isService)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.room_service_rounded,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              if (widget.isRecentlyAdded && !inCart) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderIcon() {
    final int hash = widget.product.category.hashCode;
    final List<Color> gradients = [
      [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
      [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
      [const Color(0xFFFAF5FF), const Color(0xFFF3E8FF)],
      [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)],
    ][hash.abs() % 4];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradients,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 28,
              color: AppTheme.primaryColor.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 4),
            Text(
              widget.product.category.toUpperCase(),
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryColor.withValues(alpha: 0.45),
                letterSpacing: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
