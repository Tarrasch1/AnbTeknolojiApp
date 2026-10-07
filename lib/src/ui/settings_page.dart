import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../models.dart';
import 'scope.dart';
import 'theme.dart';
import 'widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _name;
  late final TextEditingController _short;
  late final TextEditingController _taxNo;
  late final TextEditingController _taxOffice;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _iban;
  late final TextEditingController _vat;
  late final TextEditingController _term;
  late final TextEditingController _target;
  var _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    final profile = StoreScope.of(context).profile;
    _name = TextEditingController(text: profile.name);
    _short = TextEditingController(text: profile.shortName);
    _taxNo = TextEditingController(text: profile.taxNo);
    _taxOffice = TextEditingController(text: profile.taxOffice);
    _phone = TextEditingController(text: profile.phone);
    _email = TextEditingController(text: profile.email);
    _address = TextEditingController(text: profile.address);
    _city = TextEditingController(text: profile.city);
    _iban = TextEditingController(text: profile.iban);
    _vat = TextEditingController(text: numField(profile.defaultVat));
    _term = TextEditingController(text: '${profile.defaultTermDays}');
    _target = TextEditingController(text: profile.monthlyTarget == 0 ? '' : numField(profile.monthlyTarget));
    _ready = true;
  }

  @override
  void dispose() {
    if (_ready) {
      _name.dispose();
      _short.dispose();
      _taxNo.dispose();
      _taxOffice.dispose();
      _phone.dispose();
      _email.dispose();
      _address.dispose();
      _city.dispose();
      _iban.dispose();
      _vat.dispose();
      _term.dispose();
      _target.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Center(child: CircularProgressIndicator());
    final store = StoreScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PageIntro(
          inset: false,
          title: 'Ayarlar',
          hint: 'Fişte görünen firma bilgisi. Yedek bu cihazda duran kayıtların kopyasıdır.',
          icon: Icons.settings_outlined,
        ),
        const SectionTitle('Görünüm'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Koyu zemin', style: TextStyle(color: context.palette.canvasInk, fontWeight: FontWeight.w700)),
          subtitle: Text('Menü, üst bar ve sayfa zemini koyulaşır. Tutar kartları beyaz kalır.', style: TextStyle(color: context.palette.muted)),
          value: ThemeScope.of(context).isDark,
          onChanged: (_) => ThemeScope.of(context).toggle(),
        ),
        const SectionTitle('Firma'),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Ünvan')),
        const SizedBox(height: 8),
        TextField(controller: _short, decoration: const InputDecoration(labelText: 'Kısa ad')),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: _taxNo, decoration: const InputDecoration(labelText: 'VKN'))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _taxOffice, decoration: const InputDecoration(labelText: 'Vergi dairesi'))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Telefon'))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _email, decoration: const InputDecoration(labelText: 'E-posta'))),
        ]),
        const SizedBox(height: 8),
        TextField(controller: _address, decoration: const InputDecoration(labelText: 'Adres')),
        const SizedBox(height: 8),
        TextField(controller: _city, decoration: const InputDecoration(labelText: 'İl')),
        const SizedBox(height: 8),
        TextField(controller: _iban, decoration: const InputDecoration(labelText: 'IBAN')),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: _vat, decoration: const InputDecoration(labelText: 'Varsayılan KDV %'), keyboardType: TextInputType.number)),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _term, decoration: const InputDecoration(labelText: 'Varsayılan vade (gün)'), keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 8),
        TextField(controller: _target, decoration: const InputDecoration(labelText: 'Aylık ciro hedefi'), keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: () {
              store.saveProfile(
                CompanyProfile(
                  name: _name.text.trim(),
                  shortName: _short.text.trim(),
                  taxNo: _taxNo.text.trim(),
                  taxOffice: _taxOffice.text.trim(),
                  phone: _phone.text.trim(),
                  email: _email.text.trim(),
                  address: _address.text.trim(),
                  city: _city.text.trim(),
                  iban: _iban.text.trim(),
                  defaultVat: parseNum(_vat.text) ?? 20,
                  defaultTermDays: int.tryParse(_term.text) ?? 30,
                  monthlyTarget: parseNum(_target.text) ?? 0,
                ),
              );
              showMessage(context, 'Firma bilgisi kaydedildi');
            },
            child: const Text('Kaydet'),
          ),
        ),
        const SectionTitle('Yedek'),
        const Text(
          'Kayıtlar tarayıcıda ya da uygulamada bu cihazda tutulur. Yedeği kopyalayıp saklayın; başka bir cihaza elle yapıştırarak geri yükleyebilirsiniz.',
          style: TextStyle(color: Color(0xFF667085)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final raw = store.exportJson();
                await Clipboard.setData(ClipboardData(text: raw));
                if (!context.mounted) return;
                showMessage(context, 'Yedek panoya kopyalandı');
                await showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Yedek'),
                    content: SizedBox(width: 520, child: SingleChildScrollView(child: SelectableText(raw))),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat'))],
                  ),
                );
              },
              icon: const Icon(Icons.download_outlined),
              label: const Text('Yedeği göster'),
            ),
            OutlinedButton.icon(onPressed: () => _restore(context), icon: const Icon(Icons.upload_outlined), label: const Text('Yedekten yükle')),
            TextButton(
              onPressed: () async {
                final ok = await confirm(context, 'Örnek veriyi yükle', 'Mevcut kayıtlar silinir ve Akım Elektrik örnek verisi geri gelir.');
                if (!ok || !context.mounted) return;
                await store.resetDemo();
                if (!context.mounted) return;
                showMessage(context, 'Örnek veri yüklendi');
              },
              child: const Text('Örnek veriye dön'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _restore(BuildContext context) async {
    final controller = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yedekten yükle'),
        content: SizedBox(
          width: 520,
          child: TextField(controller: controller, maxLines: 8, decoration: const InputDecoration(hintText: 'JSON yedeği yapıştırın')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yükle')),
        ],
      ),
    );
    if (saved == true && context.mounted) {
      showMessage(context, StoreScope.of(context).importJson(controller.text) ?? 'Yedek yüklendi');
    }
    controller.dispose();
  }
}
