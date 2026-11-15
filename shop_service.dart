/// Модель користувача інтернет-магазину.
class User {
  const User({required this.id, required this.name, required this.email});

  final int id;
  final String name;
  final String email;
}

/// Модель товару.
class Product {
  const Product({required this.id, required this.name, required this.price});

  final int id;
  final String name;
  final double price;
}

/// Модель замовлення.
class Order {
  const Order({
    required this.id,
    required this.productName,
    required this.total,
    required this.status,
  });

  final int id;
  final String productName;
  final double total;
  final String status;
}

/// Імітація запитів до сервера інтернет-магазину.
/// Кожен метод "думає" певний час (Future.delayed) і повертає результат.
class ShopService {
  const ShopService({this.failProducts = false});

  /// Якщо true, getProducts() завершується помилкою (для перевірки try/catch).
  final bool failProducts;

  Future<User> getUser() async {
    await Future.delayed(const Duration(seconds: 2));
    return const User(id: 13, name: 'Арсен Нехін', email: 'arsen@example.com');
  }

  Future<List<Product>> getProducts() async {
    await Future.delayed(const Duration(seconds: 3));
    if (failProducts) {
      throw Exception('Не вдалося отримати список товарів');
    }
    return const [
      Product(id: 1, name: 'Ноутбук', price: 32999.00),
      Product(id: 2, name: 'Навушники', price: 2499.50),
      Product(id: 3, name: 'Клавіатура', price: 1799.00),
      Product(id: 4, name: 'Монітор', price: 8999.90),
    ];
  }

  Future<List<Order>> getOrders() async {
    await Future.delayed(const Duration(seconds: 1));
    return const [
      Order(id: 101, productName: 'Навушники', total: 2499.50, status: 'Доставлено'),
      Order(id: 102, productName: 'Клавіатура', total: 1799.00, status: 'В дорозі'),
    ];
  }
}
