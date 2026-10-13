import 'package:flutter/material.dart';

import '../../data/me_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/page_scaffold.dart';
import '../jodie/jodie_widgets.dart' show showPaymentSheet, toast;
import 'sub_page.dart';

const _filters = [
  ('all', 'nt_all', Icons.shopping_cart_outlined),
  ('books', 'st_books', Icons.menu_book_outlined),
  ('media', 'st_media', Icons.headphones_outlined),
  ('gifts', 'st_gifts', Icons.card_giftcard),
  ('study', 'st_study', Icons.school_outlined),
];

const _categoryLabel = {
  'books': 'st_book',
  'media': 'st_media',
  'gifts': 'st_gift',
  'study': 'st_study',
};

const _categoryIcon = {
  'books': Icons.menu_book_outlined,
  'media': Icons.album_outlined,
  'gifts': Icons.card_giftcard,
  'study': Icons.school_outlined,
};

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  String _filter = 'all';

  Future<void> _checkout() async {
    final paid = await showPaymentSheet(
      context,
      title: tr(context, 'me2_store'),
      rupees: meState.cartTotal,
    );
    if (!paid || !mounted) return;
    meState.clearCart();
    toast(context, tr(context, 'st_ordered'));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: meState,
      builder: (context, _) {
        final shown = MeState.products
            .where((p) => _filter == 'all' || p.category == _filter)
            .toList();
        final count = meState.cartCount;
        return SubPage(
          title: tr(context, 'me2_store'),
          subtitle: tr(context, 'me2_store_sub'),
          bandHeight: 235,
          headerExtra: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (count > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(68, 0, 16, 12),
                  child: Text(
                    tr(context, 'st_in_cart', args: {'n': '$count'}),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 13,
                    ),
                  ),
                ),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (_, i) {
                    final (id, key, icon) = _filters[i];
                    final on = id == _filter;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = id),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: on
                                  ? const Color(0xFFA719C8)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              icon,
                              color: on ? Colors.white : AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tr(context, key),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: on ? AppColors.ink : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.88,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [for (final p in shown) _ProductCard(product: p)],
              ),
            ),
            if (count > 0) ...[
              const SizedBox(height: 14),
              WhiteCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const IconTile(icon: Icons.shopping_cart_outlined),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr(
                                  context,
                                  'st_n_items',
                                  args: {'n': '$count'},
                                ),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                tr(
                                  context,
                                  'st_delivered',
                                  args: {'place': meState.location.name},
                                ),
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          rupees(meState.cartTotal),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _checkout,
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: AppColors.buttonGradient,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          tr(context, 'st_checkout'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFFA719C8),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _categoryIcon[product.category],
            color: Colors.white,
            size: 21,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          tr(context, _categoryLabel[product.category]!),
          style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: Text(
                rupees(product.rupees),
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => meState.addToCart(product),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFA719C8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tr(context, 'st_add'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
