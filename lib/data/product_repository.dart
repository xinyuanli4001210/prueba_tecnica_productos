import 'local_db.dart';
import 'product.dart';
import 'rest_api_service.dart';

class ProductRepository {
  final LocalDb _db = LocalDb();
  final RestApiService _api = RestApiService();

  Future<List<Product>> loadLocal() async {
    final rows = await _db.getAll();
    return rows.map(Product.fromDbJson).toList();
  }

  Future<Product> create(String name, double price) async {
    try {
      final created = await _api.create(name, price);
      await _db.upsert(created.toDbJson());
      return created;
    } catch (_) {
      final temp = Product(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        price: price,
        synced: false,
      );
      await _db.upsert(temp.toDbJson());
      return temp;
    }
  }

  Future<Product> update(Product p) async {
    try {
      if (p.id.startsWith('local-')) {
        final created = await _api.create(p.name, p.price);
        await _db.delete(p.id);
        await _db.upsert(created.toDbJson());
        return created;
      }
      final updated = await _api.update(p.id, p.name, p.price);
      await _db.upsert(updated.toDbJson());
      return updated;
    } catch (_) {
      final local = p.copyWith(synced: false);
      await _db.upsert(local.toDbJson());
      return local;
    }
  }

  Future<void> remove(Product p) async {
    try {
      if (!p.id.startsWith('local-')) {
        await _api.delete(p.id);
      }
    } finally {
      await _db.delete(p.id);
    }
  }

  Future<Product?> tryResync(Product p) async {
    if (p.synced) return p;
    final created = await _api.create(p.name, p.price);
    await _db.delete(p.id);
    await _db.upsert(created.toDbJson());
    return created;
  }
}
