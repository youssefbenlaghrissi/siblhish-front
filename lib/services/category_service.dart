import '../models/category.dart';
import 'api_service.dart';

class CategoryService {
  // Obtenir les catégories de l'utilisateur
  static Future<List<Category>> getUserCategories(String userId) async {
    final response = await ApiService.get('/categories/$userId');
    final data = response['data'] as List<dynamic>;
    return data.map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
  }

  // Obtenir les catégories par défaut
  static Future<List<Category>> getDefaultCategories() async {
    final response = await ApiService.get('/categories/default');
    final data = response['data'] as List<dynamic>;
    return data.map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
  }

  // Créer une catégorie
  static Future<Category> createCategory(Map<String, dynamic> categoryData) async {
    final response = await ApiService.post('/categories', categoryData);
    final data = response['data'] as Map<String, dynamic>;
    return Category.fromJson(data);
  }

  // Mettre à jour une catégorie
  static Future<Category> updateCategory(
      String categoryId, Map<String, dynamic> categoryData) async {
    final response = await ApiService.put('/categories/$categoryId', categoryData);
    final data = response['data'] as Map<String, dynamic>;
    return Category.fromJson(data);
  }

  // Supprimer une catégorie
  static Future<void> deleteCategory(String categoryId) async {
    await ApiService.delete('/categories/$categoryId');
  }
}

