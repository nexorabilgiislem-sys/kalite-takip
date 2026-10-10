import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kalite_kontrol.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Tablo Oluşturma
    await db.execute('''
      CREATE TABLE IF NOT EXISTS kalite_kontrol (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        seri_no TEXT UNIQUE,
        musteri_token TEXT,
        kk_token TEXT
      )
    ''');

    // 2. 100.000 kayıt için hızlı arama (index) optimizasyonu
    await db.execute('CREATE INDEX IF NOT EXISTS idx_seri_no ON kalite_kontrol(seri_no)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_kk_token ON kalite_kontrol(kk_token)');
  }

  // 3. Google Drive / Buluttan Otomatik Güncelleme (İnternet Varsa)
  Future<void> buluttanListeyiGuncelle() async {
    final db = await database;
    try {
      // Buraya Google Drive'daki public liste.json dosyasının direkt indirme linkini yapıştıracaksın
      final response = await http.get(Uri.parse('BURAYA_GOOGLE_DRIVE_DOSYA_LINKIN_GELECEK'));

      if (response.statusCode == 200) {
        Map<String, dynamic> yeniListe = json.decode(response.body);

        // 100.000 veriyi donmadan saniyeler içinde işlemek için Transaction kullanıyoruz
        await db.transaction((txn) async {
          var batch = txn.batch();
          
          yeniListe.forEach((key, value) {
            batch.insert(
              'kalite_kontrol',
              {
                'seri_no': value['seri'],
                'musteri_token': value['musteri'],
                'kk_token': value['kk'],
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          });
          await batch.commit(noResult: true);
        });
        print("Liste buluttan başarıyla güncellendi.");
      }
    } catch (e) {
      print("İnternet yok veya bağlantı kurulamadı, yerel veritabanı kullanılıyor.");
    }
  }

  // 4. Kameradan Okutulan Karekodu Anlık Sorgulama (İnternet Gerektirmez, 0.1 saniye sürer)
  Future<Map<String, dynamic>?> karekodDogrula(String okutulanKod) async {
    final db = await database;
    
    List<Map<String, dynamic>> sonuc = await db.query(
      'kalite_kontrol',
      where: 'kk_token = ? OR seri_no = ?',
      whereArgs: [okutulanKod, okutulanKod],
      limit: 1,
    );

    if (sonuc.isNotEmpty) {
      return sonuc.first; // Kayıt bulundu (Ürün Onaylı / Doğru)
    }
    return null; // Kayıt bulunamadı (Hatalı / Sahte ürün)
  }
}
