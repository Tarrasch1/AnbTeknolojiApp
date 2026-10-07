# Akım Elektrik

Elektrikli ev aletleri toptancısı için stok, cari, satış ve tahsilat paneli. Tek firmada ürün, müşteri, tedarikçi, belge, kasa ve servis aynı yerde durur.

Kayıtlar bu tarayıcıda saklanır. Başka bir bilgisayara kendiliğinden gitmez. Başka cihazda açmak için **Ayarlar** ekranından yedek alınıp oraya yapıştırılır.

Yayındaki adres [https://tarrasch1.github.io/AnbTeknolojiApp/](https://tarrasch1.github.io/AnbTeknolojiApp/) son yayınlanan kopyayı gösterir. Bu dosya, projedeki güncel sürümün yapabildiklerini anlatır.

## Bakiye ne demek

Pozitif bakiye: cari bize borçlu. Negatif bakiye: biz cariye borçluyuz. Sıfır: hesap kapalı.

- Satış faturası stoktan düşer ve müşteriyi borçlandırır.
- Alış faturası stoğa girer ve bizi tedarikçiye borçlandırır.
- Satış iadesi stoğa geri koyar ve müşteri borcunu düşürür.
- Alış iadesi stoktan çıkar ve tedarikçi borcunu düşürür.
- Teklif ve sipariş stoku da cariyi de değiştirmez. Satış siparişi onaylanınca miktar rezerve edilir; satılabilir stok eldeki stok eksi rezervdir.
- İrsaliye yalnız stoku etkiler. İrsaliyeden kesilen fatura stoğu ikinci kez düşürmez, cariyi işler.
- Onaylı belge iptal edilince stok hareketi geri alınır. Altında iptal edilmemiş bir belge varsa iptal durur.
- Fiyatlar KDV hariçtir. Satırda iskonto oranı vardır. Cariye bağlı fiyat listesi satış fiyatını indirir. Özel fiyat varsa liste yerine o geçerlidir.
- Kredi limiti aşılırsa satış onayında uyarı çıkar. Onay durmaz. Uyarı, bakiye artı açık satış siparişleri artı bu belgenin tutarıdır. Siparişten kesilen faturada o sipariş ikinci kez sayılmaz.
- Satış, satış siparişi, satış irsaliyesi ve teklifte satır net fiyatı alış fiyatının altındaysa kâr uyarısı çıkar. Onay yine durmaz.
- Satılabilir stok yetmezse stoktan çıkan belgenin onayı durur. İrsaliyesi daha önce kesilmiş fatura bu kontrolden geçmez, çünkü stok irsaliyede düşmüştür.
- Satış ve satış iadesi onaylanınca alış maliyeti satıra kilitlenir. Sonradan alış fiyatı değişince eski faturanın kârı yeniden yazılmaz. Eski yedek ilk açıldığında, maliyeti boş olan onaylı satışlara o andaki alış fiyatı yazılır. Bu, belgenin kesildiği gündeki gerçek maliyet olmayabilir.

## Ekranlar

Üst bantta sayfa adı, arama ve koyu zemin anahtarı vardır. Geniş ekranda sol menü derin laciverttir, aktif sayfa mavi bir hapla belli olur, alttaki ok menüyü daraltır. Dar ekranda menü çekmecededir. Arama ürün, cari, belge numarası ve seri numarasına bakar.

Koyu zemin menüyü, üst bandı ve sayfa zeminini koyulaştırır. Tutar kartları beyaz kalır.

### Özet

Firma adı, il ve vergi numarası üst karttadır. Rozetler bakiyeyi okur: kırmızı bize borç, mavi bizim borcumuz, yeşil kapalı hesap.

Kartlar: stok değeri, müşteri alacağı, tedarikçi borcu, bu ayki satış, aylık ciro hedefi, bu ayki brüt kâr, vade ajandası, kritik stok, açık irsaliye, açık servis.

Ayrıca:

- En büyük bakiyeli firma kartları
- Kasa ve banka bakiyeleri. Çek portföyü nakit sayılmaz
- Bugün ve geçmiş arama planı
- Tahsilat listesi yazdırma: vadesi dünden önce dolmuş, kapanmamış satışlar
- Bugünün vadelerini yazdırma
- Limiti aşan müşterileri yazdırma. Bu liste yalnız bakiyeye bakar, açık sipariş girmez
- Bu haftanın alış vadelerini yazdırma: kalanı olan onaylı alışlar, vadesi bugün veya 7 gün içinde
- Açık satış ve alış siparişlerini yazdırma
- Ödeme sözü gelen satışlar
- Bugünün kasa ve banka gün sonu. Çek portföyü girmez. Virman eşit giriş ve çıkış yazar
- Teslim edilmemiş sevkiyat
- Vadesi yaklaşan çek ve senet
- 21 günlük vade ajandası: açık satışlar ve portföydeki çekler
- Minimumun altındaki ürünler
- Son belgeler

### Stok

Sekmeler: ürünler, hareketler, alış önerisi, yavaş stok.

Ürün tablosunda kod, ad, marka, stok, alış, satış ve satır toplamları vardır. Marka süzülür. Liste Excel’e çıkar. Hareketler cariye göre süzülür.

Alış önerisi, minimumun altındaki ürünü son tedarikçiye bağlar ve alış siparişi taslağı açar. Son alışı olmayan ürün taslağa yazılmaz. Yavaş stok, elde duran ve 90 gündür satışı veya satış irsaliyesi olmayan ürünlerdir. Hiç satılmamış olanlar da girer.

Ürün kartında fiyat geçmişi, tedarikçi alış fiyatları, son satış fiyatları, depo bazında stok ve seri numaraları durur. Alış fiyatı bir önceki alışa göre yüzde 10 veya daha fazla artınca bu değişim raporlarda **Alış sıçraması** olarak görünür. Yalnız satış fiyatının değişmesi oraya girmez.

### Cariler

Müşteri ve tedarikçi ayrı sekmelerdedir. Kartta vergi numarası, yetkili, telefon, adres, fiyat listesi, vade, risk limiti, plasiyer ve son mutabakat vardır.

Karttan satış, alış, tahsilat, ödeme, virman, özel fiyat, toplu tahsilat veya toplu ödeme ve mutabakat çıktısı açılır. **Mutabık kalındı** bugünün tarihini yazar. Ekstre tam borç, alacak ve bakiyeyi gösterir; satırda ürün, miktar ve belge notu vardır. Ekstre Excel’e de çıkar.

Son kasa hareketi, kasa veya bankadaki son tahsilat ya da ödemedir. Çek portföyü ve verilen çek hesabı bu satıra girmez.

Görüşme arama, söz veya not olarak tarihli durur. Arama planı günü gelince özette görünür.

Aynı vergi numarası birden fazla kartta yazılıysa raporlarda listelenir. Kartlar birleştirilmez.

### Belgeler

Sekmeler: satış, alış, teklif, sipariş, irsaliye, iade.

Arama belge numarası, cari, not, iade nedeni ve ürün adına bakar.

Belge taslak kaydedilir, onaylanır, iptal edilir, kopyalanır ve yazdırılır. Onaylı belge, alt belgesi yoksa düzeltilebilir. Satış ve alış iadesinde onay ve düzeltme için iade nedeni zorunludur.

Satış faturasına ödeme sözü tarihi yazılır. Satış, satış irsaliyesi ve alış irsaliyesinde teslim durumu seçilir: hazırlanıyor, yolda, teslim edildi.

E-belge alanı elle işaretlenir: yok, sırada, kesildi, iptal. Bu işaret GİB’e bağlanmaz ve e-fatura göndermez.

Sipariş ve teklif faturaya çevrilebilir. İrsaliye faturaya çevrilebilir.

### Finans

- Tahsilat ve ödeme: nakit, havale, kart, çek, senet. Belgeye bağlanan tahsilat o belgenin kalanını düşürür. Çek ve senetten doğan kayıt ile virman satırı buradan düzeltilmez.
- Toplu tahsilat veya toplu ödeme, seçilen açık faturaların her biri için ayrı fiş keser.
- Kasa sayımı, sayılan tutarla kasa bakiyesinin farkını fiş olarak işler.
- Virman iki cari arasında aynı tutarı ters yönde taşır. Kasayı değiştirmez.
- Çek ve senet: portföy, bankaya çıkış, tahsil, ödeme, karşılıksız, ciro, iade.
- Fiyat listeleri yüzde iskonto tanımlar. Cari karta bağlanır.

### Servis

Garanti sorgusu seri numarasına bakar. Servis fişi açık, işlemde, parça bekliyor, bitti ve iptal durumlarında tutulur.

### Harita

Türkiye’nin 81 ili. İlin üzerine gelince öne çıkar. Tıklayınca o ildeki firmalar ve ilin, toplam satış içindeki payı görünür. İlin doğru çıkması için cari kartındaki il adı dolu olmalıdır.

### Aktarım

Her türün kendi Excel ve CSV dosyası vardır. İçe aktarmada aynı kayıt atlanır veya güncellenir.

- Ürün kartı: stok kodu aynıysa kart güncellenir, yeni kod kart açar.
- Cari: vergi numarası veya ünvan aynıysa kart güncellenir.
- Tahsilat ve ödeme: fiş numarası varsa atlanır. Yeni satır kasa veya bankaya işlenir.
- Satış, alış, iade, sipariş ve irsaliye: aynı belge numarası atlanır. Durum onaylıysa stok ve cari işlenir. Durum boşsa taslak kalır.

### Raporlar

Dönem çipleri bu ay, bu yıl ve tümüdür. Ciro ve kâr seçilen dönemin onaylı satışlarından gelir. Stok ve bakiye bugünkü değerdir. Bazı listeler dönemden etkilenmez; ekrandaki not bunu yazar.

Döneme bakanlar:

- Geçen aya göre ciro ve kâr. Bu kutu dönem çipinden etkilenmez, takvim ayını bir önceki ayla kıyaslar.
- KDV özeti
- Ürün kârı
- En çok satanlar
- En çok ciro yapan müşteriler ve tedarikçiler
- Plasiyer cirosu. Plasiyer adı boşsa **Plasiyersiz** diye toplanır. Tutar, KDV dahil satış eksi iadedir. Plasiyer, carinin kartındaki güncel addır.
- Marka dağılımı
- Kategori cirosu
- İade oranı: dönemdeki satış adedine göre iade adedi. İadesi olmayan ürün girmez. Oran yüzde 100’ü geçebilir.
- Zararına kapanmış satışlar: satırın net birim fiyatı, belgede kilitlenen alış maliyetinin altında. Güncel alış fiyatı kullanılmaz. Satış iadesi girmez.
- Verilen iskonto: onaylı satışlardaki satır iskontosunun KDV hariç tutarı, cari bazında.

Dönemden bağımsızlar:

- Ortalama tahsilat süresi: kapanmış ve belgeye bağlı tahsilatta, fatura tarihinden son tahsilata kadar gün. Bağsız tahsilat girmez.
- Plasiyer tahsilat süresi: aynı sürenin, plasiyerin fatura adedine göre ağırlıklı ortalaması.
- Alacak yaşlandırma: 1–30, 31–60, 61–90, 90+.
- Tedarikçi borç yaşlandırma: vadesi gelmemiş, 0–30, 31–60, 60+.
- Depo stok değeri
- Vadesi geçen faturalar
- Uyuyan müşteriler: 90 gündür satış veya satış irsaliyesi olmayan müşteriler. Hiç satılmamış olanlar önde. Tedarikçi girmez.
- En çok iade edilen ürünler
- Stok yaşı: eldeki stokta, son onaylı alış veya alış irsaliyesinden bu yana gün. Elle stok girişi yaşı başlatmaz. Alışı yoksa **Alış yok** yazar.
- Dönmeyen teklifler: 15 gündür faturalanmamış onaylı teklifler.
- Açık satış ve alış siparişleri. Faturaya dönünce listeden düşer.
- Geciken alış siparişleri: 7 gün ve daha eski, faturası kesilmemiş onaylı alış siparişleri.
- Limit aşan cariler. Tedarikçi ve limiti sıfır olan kart girmez.
- Mutabakat bekleyenler: bakiyesi açık, mutabakatı hiç olmayan veya 30 günden eski cariler.
- Alış sıçraması
- Pasif ürünlü açık belgeler: ürün kartı kapalı, satış siparişi, alış siparişi veya teklif hâlâ onaylı.
- E-belge iş listesi: onaylı satışta e-belge işareti boş olanlar. Liste elle takip içindir. GİB bağlantısı değildir.

### Ayarlar

Firma ünvanı, vergi numarası, iletişim, IBAN, varsayılan KDV, varsayılan vade ve aylık ciro hedefi. Hedef sıfırsa özette **Yok** yazar.

Yedek, bu cihazdaki kayıtların kopyasıdır. Kopyalayıp saklanır, başka cihaza yapıştırılarak geri yüklenir.

## Yazdırılan listeler

Belge, ekstre, mutabakat, tahsilat, bugünün vadeleri, limit aşanlar, bu hafta ödenecek alışlar, açık siparişler, ödeme sözü, kasa gün sonu, sevkiyat, çek ve senet. Bunlar şirket içi çıktıdır. GİB belgesi değildir.

## Bu programın yapmadığı işler

GİB e-fatura göndermez ve e-belge durumunu kendisi sormaz. Banka hesabını bağlanıp hareket çekmez. Birden fazla kullanıcı ve yetki yoktur. Satış noktası ve internet mağazası yoktur.
