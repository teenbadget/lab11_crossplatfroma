import 'dart:async';

import 'package:flutter/material.dart';

import 'shop_service.dart';

void main() => runApp(const ShopApp());

class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Async shop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ShopPage(),
    );
  }
}

/// Результат трьох запитів разом.
typedef ShopData = ({User user, List<Product> products, List<Order> orders});

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  bool _loading = false;
  bool _simulateError = false;
  String? _mode;
  String? _error;
  Duration? _elapsed;
  ShopData? _data;

  /// Послідовно: кожен await чекає завершення попереднього запиту.
  /// Загальний час = 2 с + 3 с + 1 с = 6 с.
  Future<ShopData> _loadSequentially(ShopService service) async {
    final user = await service.getUser();
    final products = await service.getProducts();
    final orders = await service.getOrders();
    return (user: user, products: products, orders: orders);
  }

  /// Паралельно: усі запити стартують одразу, Future.wait чекає на всі.
  /// Загальний час = найдовший запит = 3 с.
  Future<ShopData> _loadInParallel(ShopService service) async {
    final results = await Future.wait<Object>([
      service.getUser(),
      service.getProducts(),
      service.getOrders(),
    ]);
    return (
      user: results[0] as User,
      products: results[1] as List<Product>,
      orders: results[2] as List<Order>,
    );
  }

  Future<void> _run(
    String mode,
    Future<ShopData> Function(ShopService) loader,
  ) async {
    setState(() {
      _loading = true;
      _mode = mode;
      _error = null;
      _data = null;
      _elapsed = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final data = await loader(ShopService(failProducts: _simulateError))
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() => _data = data);
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _error = 'Сервер не відповів вчасно (timeout)');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      stopwatch.stop();
      if (mounted) {
        setState(() {
          _loading = false;
          _elapsed = stopwatch.elapsed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.inversePrimary,
        title: const Text('Інтернет-магазин (async)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Імітувати помилку (getProducts)'),
            value: _simulateError,
            onChanged: _loading
                ? null
                : (value) => setState(() => _simulateError = value),
          ),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _loading
                      ? null
                      : () => _run('Послідовно', _loadSequentially),
                  child: const Text('Послідовно'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _loading
                      ? null
                      : () => _run('Паралельно', _loadInParallel),
                  child: const Text('Паралельно'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text('Завантаження ($_mode)...'),
          ],
          if (_elapsed != null)
            Text(
              'Режим: $_mode. Час: ${(_elapsed!.inMilliseconds / 1000).toStringAsFixed(1)} с',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          if (_error != null)
            Card(
              color: scheme.errorContainer,
              child: ListTile(
                leading: Icon(Icons.error_outline, color: scheme.error),
                title: Text(_error!),
              ),
            ),
          if (_data != null) ..._buildData(_data!),
        ],
      ),
    );
  }

  List<Widget> _buildData(ShopData data) {
    return [
      const SizedBox(height: 8),
      Card(
        child: ListTile(
          leading: const Icon(Icons.person),
          title: Text(data.user.name),
          subtitle: Text(data.user.email),
        ),
      ),
      _SectionTitle('Товари (${data.products.length})'),
      for (final product in data.products)
        ListTile(
          dense: true,
          leading: const Icon(Icons.shopping_bag_outlined),
          title: Text(product.name),
          trailing: Text('${product.price.toStringAsFixed(2)} грн'),
        ),
      _SectionTitle('Замовлення (${data.orders.length})'),
      for (final order in data.orders)
        ListTile(
          dense: true,
          leading: const Icon(Icons.receipt_long_outlined),
          title: Text('№${order.id}: ${order.productName}'),
          subtitle: Text(order.status),
          trailing: Text('${order.total.toStringAsFixed(2)} грн'),
        ),
    ];
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
