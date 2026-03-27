import 'package:flutter/foundation.dart';

import '../model/pos_item_model.dart';

class InventoryData {
  static final ValueNotifier<List<POSItem>> notifier = ValueNotifier(
    <POSItem>[],
  );

  static final List<POSItem> items = [
    POSItem(
      name: "Siomai Beef 4pcs",
      price: 35,
      stock: 50,
      unit: "orders",
      category: "Food",
      lowStockAlert: 10,
      image:
          "https://images.unsplash.com/photo-1496116218417-1a781b1c416c?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Siomai Beef 6pcs",
      price: 50,
      stock: 50,
      unit: "orders",
      category: "Food",
      lowStockAlert: 10,
      image:
          "https://images.unsplash.com/photo-1496116218417-1a781b1c416c?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Siomai Chicken 4pcs",
      price: 35,
      stock: 50,
      unit: "orders",
      category: "Food",
      lowStockAlert: 10,
      image:
          "https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Siomai Chicken 6pcs",
      price: 50,
      stock: 50,
      unit: "orders",
      category: "Food",
      lowStockAlert: 10,
      image:
          "https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Siomai Japanese 4pcs",
      price: 35,
      stock: 50,
      unit: "orders",
      category: "Food",
      lowStockAlert: 10,
      image:
          "https://images.unsplash.com/photo-1563245372-f21724e3856d?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Siomai Japanese 6pcs",
      price: 50,
      stock: 50,
      unit: "orders",
      category: "Food",
      lowStockAlert: 10,
      image:
          "https://images.unsplash.com/photo-1563245372-f21724e3856d?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Empanada Beef",
      price: 45,
      stock: 30,
      unit: "pieces",
      category: "Food",
      lowStockAlert: 10,
      image:
          "https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Empanada Chicken",
      price: 45,
      stock: 30,
      unit: "pieces",
      category: "Food",
      lowStockAlert: 10,
      image:
          "https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Corndog Hotdog w/ Cheese",
      price: 35,
      stock: 30,
      unit: "pieces",
      category: "Food",
      lowStockAlert: 10,
      image:
          "https://images.unsplash.com/photo-1619740455993-9e612b1af08a?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Corndog Hotdog Only",
      price: 30,
      stock: 30,
      unit: "pieces",
      category: "Food",
      lowStockAlert: 10,
      image:
          "https://images.unsplash.com/photo-1619740455993-9e612b1af08a?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Corndog Cheese Only",
      price: 20,
      stock: 30,
      unit: "pieces",
      category: "Food",
      lowStockAlert: 10,
      image:
          "https://images.unsplash.com/photo-1619740455993-9e612b1af08a?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Chicken with Rice",
      price: 70,
      stock: 30,
      unit: "servings",
      category: "Food",
      lowStockAlert: 10,
      image:
          "https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Chicken Only",
      price: 55,
      stock: 30,
      unit: "servings",
      category: "Food",
      lowStockAlert: 10,
      image:
          "https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Rice Only",
      price: 15,
      stock: 50,
      unit: "servings",
      category: "Food",
      lowStockAlert: 15,
      image:
          "https://images.unsplash.com/photo-1516684732162-798a0062be99?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Mango Shake 12oz",
      price: 60,
      stock: 30,
      unit: "cups",
      category: "Beverage",
      lowStockAlert: 5,
      image:
          "https://images.unsplash.com/photo-1546173159-315724a31696?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Mango Shake 16oz",
      price: 80,
      stock: 30,
      unit: "cups",
      category: "Beverage",
      lowStockAlert: 5,
      image:
          "https://images.unsplash.com/photo-1546173159-315724a31696?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Mango Shake 22oz",
      price: 120,
      stock: 30,
      unit: "cups",
      category: "Beverage",
      lowStockAlert: 5,
      image:
          "https://images.unsplash.com/photo-1546173159-315724a31696?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Avocado Shake 12oz",
      price: 60,
      stock: 30,
      unit: "cups",
      category: "Beverage",
      lowStockAlert: 5,
      image:
          "https://images.unsplash.com/photo-1638176066666-ffb2f013c7dd?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Avocado Shake 16oz",
      price: 80,
      stock: 30,
      unit: "cups",
      category: "Beverage",
      lowStockAlert: 5,
      image:
          "https://images.unsplash.com/photo-1638176066666-ffb2f013c7dd?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Avocado Shake 22oz",
      price: 120,
      stock: 30,
      unit: "cups",
      category: "Beverage",
      lowStockAlert: 5,
      image:
          "https://images.unsplash.com/photo-1638176066666-ffb2f013c7dd?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Chocolate Shake 12oz",
      price: 60,
      stock: 30,
      unit: "cups",
      category: "Beverage",
      lowStockAlert: 5,
      image:
          "https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Chocolate Shake 16oz",
      price: 80,
      stock: 30,
      unit: "cups",
      category: "Beverage",
      lowStockAlert: 5,
      image:
          "https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Chocolate Shake 22oz",
      price: 120,
      stock: 30,
      unit: "cups",
      category: "Beverage",
      lowStockAlert: 5,
      image:
          "https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Cookies & Cream 12oz",
      price: 60,
      stock: 30,
      unit: "cups",
      category: "Beverage",
      lowStockAlert: 5,
      image:
          "https://images.unsplash.com/photo-1541658016709-82535e94bc69?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Cookies & Cream 16oz",
      price: 80,
      stock: 30,
      unit: "cups",
      category: "Beverage",
      lowStockAlert: 5,
      image:
          "https://images.unsplash.com/photo-1541658016709-82535e94bc69?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Cookies & Cream 22oz",
      price: 120,
      stock: 30,
      unit: "cups",
      category: "Beverage",
      lowStockAlert: 5,
      image:
          "https://images.unsplash.com/photo-1541658016709-82535e94bc69?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Ube Shake 12oz",
      price: 60,
      stock: 30,
      unit: "cups",
      category: "Beverage",
      lowStockAlert: 5,
      image:
          "https://images.unsplash.com/photo-1579954115545-a95591f28bfc?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Ube Shake 16oz",
      price: 80,
      stock: 30,
      unit: "cups",
      category: "Beverage",
      lowStockAlert: 5,
      image:
          "https://images.unsplash.com/photo-1579954115545-a95591f28bfc?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Ube Shake 22oz",
      price: 120,
      stock: 30,
      unit: "cups",
      category: "Beverage",
      lowStockAlert: 5,
      image:
          "https://images.unsplash.com/photo-1579954115545-a95591f28bfc?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Strawberry Shake 12oz",
      price: 60,
      stock: 30,
      unit: "cups",
      category: "Beverage",
      lowStockAlert: 5,
      image:
          "https://images.unsplash.com/photo-1579954115563-e72bf1381629?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Strawberry Shake 16oz",
      price: 80,
      stock: 30,
      unit: "cups",
      category: "Beverage",
      lowStockAlert: 5,
      image:
          "https://images.unsplash.com/photo-1579954115563-e72bf1381629?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Strawberry Shake 22oz",
      price: 120,
      stock: 30,
      unit: "cups",
      category: "Beverage",
      lowStockAlert: 5,
      image:
          "https://images.unsplash.com/photo-1579954115563-e72bf1381629?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Lemonade 12oz",
      price: 40,
      stock: 30,
      unit: "cups",
      category: "Beverage",
      lowStockAlert: 5,
      image:
          "https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Lemonade 16oz",
      price: 60,
      stock: 30,
      unit: "cups",
      category: "Beverage",
      lowStockAlert: 5,
      image:
          "https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Lemonade 22oz",
      price: 80,
      stock: 30,
      unit: "cups",
      category: "Beverage",
      lowStockAlert: 5,
      image:
          "https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Lemonade w/ Yakult 22oz",
      price: 90,
      stock: 30,
      unit: "cups",
      category: "Beverage",
      lowStockAlert: 5,
      image:
          "https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Bottled Water 500ml",
      price: 20,
      stock: 50,
      unit: "bottles",
      category: "Beverage",
      lowStockAlert: 10,
      image:
          "https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Coke Swakto",
      price: 20,
      stock: 48,
      unit: "bottles",
      category: "Beverage",
      lowStockAlert: 10,
      image:
          "https://images.unsplash.com/photo-1554866585-cd94860890b7?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Royal Swakto",
      price: 20,
      stock: 48,
      unit: "bottles",
      category: "Beverage",
      lowStockAlert: 10,
      image:
          "https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?w=200&h=200&fit=crop",
    ),
    POSItem(
      name: "Sprite Swakto",
      price: 20,
      stock: 48,
      unit: "bottles",
      category: "Beverage",
      lowStockAlert: 10,
      image:
          "https://images.unsplash.com/photo-1624517452488-04869289c4ca?w=200&h=200&fit=crop",
    ),
  ];
}
