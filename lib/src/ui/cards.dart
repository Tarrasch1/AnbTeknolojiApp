import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import 'theme.dart';
import 'widgets.dart';

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).take(2).toList();
  if (parts.isEmpty) return '?';
  return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
}

Color partyTone(PartyType type) {
  switch (type) {
    case PartyType.customer:
      return kInfo;
    case PartyType.supplier:
      return kTeal;
    case PartyType.both:
      return kNavy;
  }
}

Color accountTone(AccountRole role) {
  switch (role) {
    case AccountRole.cash:
      return kGood;
    case AccountRole.bank:
      return kInfo;
    case AccountRole.checkPortfolio:
      return kWarn;
    case AccountRole.issuedChecks:
      return kNavy;
  }
}

Color docKindTone(DocKind kind) {
  switch (kind) {
    case DocKind.sale:
      return kGood;
    case DocKind.purchase:
      return kTeal;
    case DocKind.saleReturn:
    case DocKind.purchaseReturn:
      return kWarn;
    case DocKind.saleOrder:
    case DocKind.purchaseOrder:
      return kNavy;
    case DocKind.saleWaybill:
    case DocKind.purchaseWaybill:
      return kInfo;
    case DocKind.saleQuote:
      return kNavy;
  }
}

IconData categoryIcon(String category) {
  switch (category) {
    case 'Buzdolabı':
      return Icons.kitchen_outlined;
    case 'Çamaşır Makinesi':
    case 'Kurutma Makinesi':
      return Icons.local_laundry_service_outlined;
    case 'Bulaşık Makinesi':
      return Icons.countertops_outlined;
    case 'Ankastre Fırın':
      return Icons.microwave_outlined;
    case 'Ocak':
      return Icons.outdoor_grill_outlined;
    case 'Davlumbaz':
      return Icons.air_outlined;
    case 'Klima':
      return Icons.ac_unit;
    case 'Televizyon':
      return Icons.tv_outlined;
    case 'Elektrikli Süpürge':
      return Icons.cleaning_services_outlined;
    case 'Ütü':
      return Icons.dry_cleaning_outlined;
    case 'Kahve Makinesi':
      return Icons.coffee_outlined;
    case 'Airfryer':
      return Icons.outdoor_grill;
    case 'Su Sebili':
      return Icons.water_drop_outlined;
    case 'Isıtıcı':
      return Icons.whatshot_outlined;
    case 'Vantilatör':
      return Icons.mode_fan_off_outlined;
    case 'Aydınlatma':
      return Icons.lightbulb_outline;
    case 'Yedek Parça':
      return Icons.handyman_outlined;
    default:
      return Icons.electrical_services_outlined;
  }
}

IconData docKindIcon(DocKind kind) {
  switch (kind) {
    case DocKind.sale:
      return Icons.receipt_long;
    case DocKind.purchase:
      return Icons.inventory;
    case DocKind.saleReturn:
    case DocKind.purchaseReturn:
      return Icons.undo;
    case DocKind.saleOrder:
    case DocKind.purchaseOrder:
      return Icons.assignment_outlined;
    case DocKind.saleWaybill:
    case DocKind.purchaseWaybill:
      return Icons.local_shipping_outlined;
    case DocKind.saleQuote:
      return Icons.request_quote_outlined;
  }
}

IconData accountIcon(AccountRole role) {
  switch (role) {
    case AccountRole.cash:
      return Icons.payments_outlined;
    case AccountRole.bank:
      return Icons.account_balance;
    case AccountRole.checkPortfolio:
      return Icons.sticky_note_2_outlined;
    case AccountRole.issuedChecks:
      return Icons.outbox_outlined;
  }
}

class MarkBadge extends StatelessWidget {
  const MarkBadge({
    required this.label,
    required this.color,
    this.icon,
    this.size = 48,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.25)!],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [BoxShadow(color: color.withOpacity(0.28), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: icon == null
          ? Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.32))
          : Icon(icon, color: Colors.white, size: size * 0.48),
    );
  }
}

class FirmCard extends StatelessWidget {
  const FirmCard({
    required this.name,
    required this.city,
    required this.phone,
    required this.typeLabel,
    required this.balanceLabel,
    required this.balanceTone,
    required this.tone,
    required this.limitRatio,
    required this.overLimit,
    required this.onTap,
    super.key,
  });

  final String name;
  final String city;
  final String phone;
  final String typeLabel;
  final String balanceLabel;
  final Color balanceTone;
  final Color tone;
  final double limitRatio;
  final bool overLimit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HoverCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MarkBadge(label: initialsOf(name), color: tone),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kNavy)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF667085)),
                        const SizedBox(width: 2),
                        Expanded(child: Text(city.isEmpty ? 'İl yok' : city, style: const TextStyle(color: Color(0xFF667085), fontSize: 12))),
                      ],
                    ),
                  ],
                ),
              ),
              StatusChip(typeLabel, color: tone),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.call_outlined, size: 14, color: Color(0xFF667085)),
              const SizedBox(width: 4),
              Expanded(child: Text(phone.isEmpty ? 'Telefon yok' : phone, style: const TextStyle(fontSize: 12))),
              if (overLimit) const StatusChip('Limit aşıldı', color: kBad),
            ],
          ),
          const SizedBox(height: 12),
          Text(balanceLabel, style: TextStyle(color: balanceTone, fontWeight: FontWeight.w800, fontSize: 16)),
          if (limitRatio > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: limitRatio.clamp(0, 1),
                minHeight: 6,
                backgroundColor: const Color(0xFFF0EBE3),
                color: overLimit ? kBad : kCopper,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class GoodsCard extends StatelessWidget {
  const GoodsCard({
    required this.name,
    required this.brand,
    required this.category,
    required this.sku,
    required this.price,
    required this.stock,
    required this.minStock,
    required this.onTap,
    this.reserved = 0,
    super.key,
  });

  final String name;
  final String brand;
  final String category;
  final String sku;
  final String price;
  final double stock;
  final double minStock;
  final VoidCallback onTap;
  final double reserved;

  @override
  Widget build(BuildContext context) {
    final low = stock <= minStock;
    final cap = minStock <= 0 ? (stock <= 0 ? 1.0 : stock) : minStock * 2;
    final ratio = (stock / cap).clamp(0, 1).toDouble();
    return HoverCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MarkBadge(label: '', color: low ? kBad : kNavy, icon: categoryIcon(category), size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(brand, style: const TextStyle(color: kNavy, fontWeight: FontWeight.w700, fontSize: 12)),
                    Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusChip(category),
              StatusChip(sku.isEmpty ? 'Kodsuz' : sku),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(qtyText(stock), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: low ? kBad : kNavy)),
              const SizedBox(width: 6),
              Text('adet', style: TextStyle(color: low ? kBad : const Color(0xFF667085))),
              const Spacer(),
              Text(price, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          if (reserved > 0.0001) ...[
            const SizedBox(height: 4),
            Text(
              'Rezerve ${qtyText(reserved)} · satılabilir ${qtyText(stock - reserved)}',
              style: const TextStyle(color: kWarn, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: const Color(0xFFF0EBE3),
              color: low ? kBad : kGood,
            ),
          ),
        ],
      ),
    );
  }
}

class DocCard extends StatelessWidget {
  const DocCard({
    required this.kind,
    required this.no,
    required this.party,
    required this.meta,
    required this.amount,
    required this.status,
    required this.statusTone,
    this.extra,
    required this.onTap,
    super.key,
  });

  final DocKind kind;
  final String no;
  final String party;
  final String meta;
  final String amount;
  final String status;
  final Color statusTone;
  final String? extra;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HoverCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            MarkBadge(label: '', color: statusTone, icon: docKindIcon(kind), size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(no, style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
                  const SizedBox(height: 2),
                  Text(party, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(meta, style: const TextStyle(color: Color(0xFF667085), fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amount, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                StatusChip(status, color: statusTone),
                if (extra != null) Text(extra!, style: const TextStyle(color: kWarn, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<T?> showPanel<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Kapat',
    barrierColor: const Color(0xCC0E243F),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, _, __) => Center(child: builder(context)),
    transitionBuilder: (context, animation, _, child) {
      final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curve,
        child: ScaleTransition(scale: Tween<double>(begin: 0.96, end: 1).animate(curve), child: child),
      );
    },
  );
}

class PanelFrame extends StatelessWidget {
  const PanelFrame({
    required this.title,
    required this.subtitle,
    required this.mark,
    required this.body,
    required this.footer,
    this.headerColor = kNavy,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget mark;
  final Widget body;
  final Widget footer;
  final Color headerColor;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
      child: Material(
        color: Colors.white,
        elevation: 16,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [headerColor, Color.lerp(headerColor, const Color(0xFF1E4B73), 0.55)!],
                ),
              ),
              child: Row(
                children: [
                  mark,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(subtitle, style: const TextStyle(color: Color(0xFFE4D3B0))),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: body,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: footer,
            ),
          ],
        ),
      ),
    );
  }
}

class MiniStat extends StatelessWidget {
  const MiniStat({required this.icon, required this.label, required this.value, this.tone = kNavy, super.key});

  final IconData icon;
  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: tone.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: tone),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF667085))),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: tone, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
