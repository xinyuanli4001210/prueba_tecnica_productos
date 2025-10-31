import 'package:flutter/material.dart';
import '../data/product.dart';
import '../data/product_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  final _repo = ProductRepository();
  List<Product> _items = [];
  Product? _editing; // null = agregando
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final local = await _repo.loadLocal();
    setState(() {
      _items = local;
      _loading = false;
    });
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameCtrl.clear();
    _priceCtrl.clear();
    setState(() => _editing = null);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameCtrl.text.trim();
    final price = double.parse(_priceCtrl.text.trim().replaceAll(',', '.'));

    setState(() => _loading = true);
    try {
      if (_editing == null) {
        final p = await _repo.create(name, price);
        setState(() => _items = [..._items, p]);
        if (!p.synced) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Guardado localmente. Sin conexión.')),
          );
        }
      } else {
        final updated = await _repo.update(
          _editing!.copyWith(name: name, price: price),
        );
        setState(() {
          _items =
              _items.map((e) => e.id == _editing!.id ? updated : e).toList();
        });
        if (!updated.synced) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cambios guardados localmente.')),
          );
        }
      }
      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(Product p) async {
    setState(() => _loading = true);
    try {
      await _repo.remove(p);
      setState(() => _items.removeWhere((e) => e.id == p.id));
      if (_editing?.id == p.id) _clearForm();
    } finally {
      setState(() => _loading = false);
    }
  }

  void _startEdit(Product p) {
    setState(() => _editing = p);
    _nameCtrl.text = p.name;
    _priceCtrl.text = p.price.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editing != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos a comprar'),
        centerTitle: true,
      ),
      body: AbsorbPointer(
        absorbing: _loading,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _formCard(isEditing),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.shopping_cart_outlined),
                const SizedBox(width: 8),
                Text('Productos en la lista: ${_items.length}',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No hay productos añadidos aún')),
              )
            else
              ..._items.map(_productTile),
          ],
        ),
      ),
      floatingActionButton: _loading
          ? const FloatingActionButton(
              onPressed: null, child: CircularProgressIndicator())
          : null,
    );
  }

  Widget _formCard(bool isEditing) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Agregar producto',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del producto',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingrese un nombre'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  prefixText: '\$ ',
                  hintText: 'Ej: 149.99',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingrese un precio';
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  if (parsed == null) return 'Precio inválido';
                  if (parsed < 0) return 'El precio no puede ser negativo';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(isEditing ? 'Guardar cambios' : 'Agregar'),
                ),
              ),
              if (isEditing)
                TextButton.icon(
                  onPressed: _clearForm,
                  icon: const Icon(Icons.close),
                  label: const Text('Cancelar edición'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _productTile(Product p) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: p.synced
            ? const Icon(Icons.cloud_done_outlined)
            : const Icon(Icons.cloud_off_outlined),
        title: Text(p.name),
        subtitle: Text('\$ ${p.price.toStringAsFixed(2)}  (id: ${p.id})'),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _startEdit(p),
              tooltip: 'Editar',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(p),
              tooltip: 'Eliminar',
            ),
          ],
        ),
      ),
    );
  }
}
