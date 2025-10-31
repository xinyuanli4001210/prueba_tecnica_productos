import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'product.dart';

class RestApiService {
  static const String _base = 'https://api.restful-api.dev';
  static const Duration _timeout = Duration(seconds: 5);

  // Crear (POST /objects)
  Future<Product> create(String name, double price) async {
    final res = await http
        .post(
          Uri.parse('$_base/objects'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "name": name,
            "data": {"price": price},
          }),
        )
        .timeout(_timeout);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return Product.fromApiJson(jsonDecode(res.body));
    }
    throw Exception('Error creando producto (${res.statusCode})');
  }

  // Obtener por id (GET /objects/{id})
  Future<Product> getById(String id) async {
    final res =
        await http.get(Uri.parse('$_base/objects/$id')).timeout(_timeout);

    if (res.statusCode == 200) {
      return Product.fromApiJson(jsonDecode(res.body));
    }
    throw Exception('Error obteniendo producto (${res.statusCode})');
  }

  // Actualizar (PUT /objects/{id})
  Future<Product> update(String id, String name, double price) async {
    final res = await http
        .put(
          Uri.parse('$_base/objects/$id'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "name": name,
            "data": {"price": price},
          }),
        )
        .timeout(_timeout);

    if (res.statusCode == 200) {
      return Product.fromApiJson(jsonDecode(res.body));
    }
    throw Exception('Error actualizando producto (${res.statusCode})');
  }

  // Eliminar (DELETE /objects/{id})
  Future<void> delete(String id) async {
    final res =
        await http.delete(Uri.parse('$_base/objects/$id')).timeout(_timeout);

    if (res.statusCode == 200 || res.statusCode == 204) return;
    throw Exception('Error eliminando producto (${res.statusCode})');
  }
}
