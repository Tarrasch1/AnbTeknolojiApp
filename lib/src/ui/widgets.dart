import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import 'theme.dart';

void showMessage(BuildContext context, String? message) {
  if (message == null || message.isEmpty || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirm(BuildContext context, String title, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Onayla')),
      ],
    ),
  );
  return result == true;
}

Future<DateTime?> pickDate(BuildContext context, DateTime initial) {
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2020),
    lastDate: DateTime(2035),
  );
}

class HoverCard extends StatefulWidget {
  const HoverCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: context.palette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _hover ? context.palette.accent : context.palette.line),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(_hover ? 0.10 : 0.04),
              blurRadius: _hover ? 18 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            hoverColor: const Color(0x141D4E89),
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}

class KpiCard extends StatelessWidget {
  const KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    this.tone = kNavy,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 228,
      child: HoverCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w600, height: 1.25)),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: tone.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: tone, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, maxLines: 1, style: figureStyle(kInk, size: 22)),
            ),
          ],
        ),
      ),
    );
  }
}

class PageIntro extends StatelessWidget {
  const PageIntro({
    required this.title,
    required this.hint,
    required this.icon,
    this.trailing,
    this.inset = true,
    super.key,
  });

  final String title;
  final String hint;
  final IconData icon;
  final Widget? trailing;
  final bool inset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: inset ? const EdgeInsets.fromLTRB(16, 16, 16, 8) : const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: context.palette.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: context.palette.accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.palette.canvasInk)),
                const SizedBox(height: 2),
                Text(hint, style: TextStyle(color: context.palette.muted, height: 1.35)),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class MeaningBar extends StatelessWidget {
  const MeaningBar({required this.items, super.key});

  final List<(Color, String)> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: items.map((item) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: item.$1.withOpacity(0.1),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(item.$2, style: TextStyle(color: item.$1, fontSize: 12, fontWeight: FontWeight.w700)),
          );
        }).toList(),
      ),
    );
  }
}

class RecordRow extends StatelessWidget {
  const RecordRow({
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.trailingColor,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final Color tone;
  final String title;
  final String subtitle;
  final String trailing;
  final Color? trailingColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: HoverCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: tone.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: tone, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: kInk)),
                  Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kMuted, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(trailing, style: TextStyle(fontWeight: FontWeight.w800, color: trailingColor ?? tone)),
          ],
        ),
      ),
    );
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF667085)))),
    );
  }
}

class FormSection extends StatefulWidget {
  const FormSection({
    required this.step,
    required this.title,
    required this.hint,
    required this.icon,
    required this.child,
    super.key,
  });

  final String step;
  final String title;
  final String hint;
  final IconData icon;
  final Widget child;

  @override
  State<FormSection> createState() => _FormSectionState();
}

class _FormSectionState extends State<FormSection> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _hover ? kNavy : kLine, width: _hover ? 1.4 : 1),
            boxShadow: [
              BoxShadow(
                color: kNavy.withOpacity(_hover ? 0.10 : 0.04),
                blurRadius: _hover ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: kSoft, borderRadius: BorderRadius.circular(10)),
                    child: Text(widget.step, style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
                  ),
                  const SizedBox(width: 10),
                  Icon(widget.icon, color: kNavy, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
                        Text(widget.hint, style: const TextStyle(color: kMuted, fontSize: 12, height: 1.3)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              widget.child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps fields onto as many columns as fit, without leaving an empty cell.
class FieldGrid extends StatelessWidget {
  const FieldGrid({required this.children, this.minItemWidth = 200, super.key});

  final List<Widget> children;
  final double minItemWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : minItemWidth;
        final cols = (width / minItemWidth).floor().clamp(1, 4);
        const gap = 10.0;
        return Column(
          children: [
            for (var i = 0; i < children.length; i += cols)
              Padding(
                padding: EdgeInsets.only(bottom: i + cols >= children.length ? 0 : gap),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var j = 0; j < cols && i + j < children.length; j++) ...[
                      if (j > 0) const SizedBox(width: gap),
                      Expanded(child: children[i + j]),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class DateField extends StatelessWidget {
  const DateField({required this.label, required this.value, required this.onChanged, super.key});

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final picked = await pickDate(context, value);
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(shortDate(value), style: const TextStyle(color: kInk)),
      ),
    );
  }
}

class FormDialog extends StatelessWidget {
  const FormDialog({
    required this.title,
    required this.child,
    required this.actions,
    this.maxWidth = 760,
    this.maxHeight = 740,
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                border: Border(bottom: BorderSide(color: kLine)),
              ),
              child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kInk)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: child,
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
                border: Border(top: BorderSide(color: kLine)),
              ),
              child: Row(children: actions),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {this.trailing, super.key});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Row(
        children: [
          Expanded(child: Text(text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.palette.canvasInk))),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.text, {this.color = kNavy, super.key});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

Color statusColor(DocStatus status) {
  switch (status) {
    case DocStatus.draft:
      return kWarn;
    case DocStatus.approved:
      return kGood;
    case DocStatus.cancelled:
      return kBad;
    case DocStatus.invoiced:
      return kNavy;
  }
}

class InfoLine extends StatelessWidget {
  const InfoLine(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(color: Color(0xFF667085)))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

String balanceText(double balance) => balancePhrase(balance);

Color balanceColor(double balance) {
  if (balance > 0.009) return kBad;
  if (balance < -0.009) return kInfo;
  return kGood;
}
