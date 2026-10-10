import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'database_helper.dart'; // Az önceki veritabanı dosyan

class ScannerPage extends StatefulWidget {
  @override
  _ScannerPageState createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool _isScanned = false;
  String _mesaj = "Karekod bekleniyor...";
  Color _renk = Colors.grey;

  @override
  void initState() {
    super.initState();
    // Uygulama açıldığında arka planda buluttan güncellemeyi dene
    DatabaseHelper.instance.buluttanListeyiGuncelle();
  }

  void _qrOkutuldu(String kod) async {
    if (_isScanned) return;
    setState(() { _isScanned = true; });

    // Veritabanında ara (0.1 saniye sürer, internet istemez)
    var sonuc = await DatabaseHelper.instance.karekodDogrula(kod);

    setState(() {
      if (sonuc != null) {
        _mesaj = "BAŞARILI! Seri No: ${sonuc['seri_no']}";
        _renk = Colors.green; // Yeşil ekran
      } else {
        _mesaj = "HATALI / BULUNAMAYAN KOD!";
        _renk = Colors.red; // Kırmızı ekran
      }
    });

    // 3 saniye sonra tekrar taramaya izin ver
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        _isScanned = false;
        _mesaj = "Karekod bekleniyor...";
        _renk = Colors.grey;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('YATSAN Kalite Kontrol')),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _qrOkutuldu(barcode.rawValue!);
                  }
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: _renk,
              alignment: Alignment.center,
              child: Text(
                _mesaj,
                style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
