Future<void> createTable(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS kalite_kontrol (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      seri_no TEXT UNIQUE,
      musteri_token TEXT,
      kk_token TEXT
    )
  ''');
  // Hızlı arama için indeksler (100.000 kayıt için şart)
  await db.execute('CREATE INDEX IF NOT EXISTS idx_seri_no ON kalite_kontrol(seri_no)');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_kk_token ON kalite_kontrol(kk_token)');
}
