# Guide d'intégration Frontend-Backend

## 📋 Alignement Frontend-Backend

Le frontend Flutter est maintenant aligné avec le backend Spring Boot. Voici les correspondances :

### ✅ Modèles alignés
- **User** ↔ `UserProfileDto`
- **Expense** ↔ `ExpenseDto` / `ExpenseRequestDto`
- **Income** ↔ `IncomeDto` / `IncomeRequestDto`
- **Category** ↔ `CategoryDto`
- **Goal** ↔ `GoalDto` / `GoalRequestDto`

### ✅ Services API créés
- `UserService` - Gestion du profil utilisateur
- `ExpenseService` - Gestion des dépenses
- `IncomeService` - Gestion des revenus
- `CategoryService` - Gestion des catégories
- `GoalService` - Gestion des objectifs
- `HomeService` - Données de la page d'accueil

### ✅ Endpoints utilisés
- `/api/v1/users/{userId}/profile` - Profil utilisateur
- `/api/v1/expenses/{userId}` - Liste des dépenses
- `/api/v1/incomes/{userId}` - Liste des revenus
- `/api/v1/categories/{userId}` - Catégories utilisateur
- `/api/v1/goals/{userId}` - Objectifs utilisateur
- `/api/v1/home/balance/{userId}` - Solde
- `/api/v1/home/transactions/{userId}?limit=100` - Transactions récentes (filtres appliqués côté frontend)

---

## 🗄️ Script SQL pour alimenter la base de données

### Prérequis
1. PostgreSQL installé et démarré
2. Base de données `siblhish` créée
3. Utilisateur `youssefbenlaghrissi` avec les permissions appropriées

### Exécution du script

#### Option 1 : Via psql (ligne de commande)
```bash
psql -U youssefbenlaghrissi -d siblhish -f scripts/seed_database.sql
```

#### Option 2 : Via pgAdmin
1. Ouvrir pgAdmin
2. Se connecter à la base de données `siblhish`
3. Ouvrir l'éditeur de requête
4. Copier-coller le contenu de `scripts/seed_database.sql`
5. Exécuter le script (F5)

#### Option 3 : Via IntelliJ IDEA / DataGrip
1. Ouvrir la connexion à la base de données
2. Ouvrir le fichier `scripts/seed_database.sql`
3. Exécuter le script

### Contenu du script
Le script crée :
- ✅ 1 utilisateur de test (Youssef Benlaghrissi)
- ✅ 6 catégories par défaut (Alimentation, Transport, Loisirs, Santé, Shopping, Éducation)
- ✅ 3 revenus (Salaire mensuel, Projet freelance, Vente)
- ✅ 4 dépenses (Courses, Essence, Cinéma, Consultation médicale)
- ✅ 2 objectifs (Vacances d'été, Formation professionnelle)

### ⚠️ Important
- Le script utilise `ON CONFLICT DO NOTHING` pour éviter les doublons
- Si vous exécutez le script plusieurs fois, il ne créera pas de doublons
- L'ID utilisateur par défaut est **1** (modifiez-le si nécessaire)

---

## 🔧 Configuration de l'API

### Fichier de configuration
Le fichier `lib/config/api_config.dart` contient la configuration de l'URL de base.

### URL selon l'environnement

#### Android Emulator
```dart
static const String baseUrl = 'http://10.0.2.2:8081/api/v1';
```

#### iOS Simulator
```dart
static const String baseUrl = 'http://localhost:8081/api/v1';
```

#### Téléphone physique (via WiFi)
1. Trouver l'IP locale de votre machine :
   - Windows : `ipconfig` dans PowerShell
   - Mac/Linux : `ifconfig` ou `ip addr`
2. Modifier `api_config.dart` :
   ```dart
   static const String baseUrl = 'http://192.168.1.100:8081/api/v1'; // Remplacer par votre IP
   ```
3. S'assurer que le téléphone et l'ordinateur sont sur le même réseau WiFi
4. Désactiver le pare-feu Windows si nécessaire

---

## 🚀 Utilisation

### 1. Démarrer le backend Spring Boot
```bash
cd C:\Users\youssef.benlaghrissi\Documents\siblhish-api
./mvnw spring-boot:run
# ou
mvn spring-boot:run
```

Le backend sera accessible sur `http://localhost:8081`

### 2. Exécuter le script SQL
```bash
psql -U youssefbenlaghrissi -d siblhish -f scripts/seed_database.sql
```

### 3. Configurer l'URL dans Flutter
Modifier `lib/config/api_config.dart` selon votre environnement (voir ci-dessus).

### 4. Lancer l'application Flutter
```bash
flutter pub get
flutter run -d 46210DLAQ000NV
```

---

## 🔄 Migration depuis les données statiques

Pour migrer le `BudgetProvider` vers les appels API :

1. **Remplacer les données statiques par des appels API** dans `lib/providers/budget_provider.dart`
2. **Gérer le chargement asynchrone** avec des états de chargement
3. **Gérer les erreurs réseau** avec try-catch
4. **Mettre en cache les données** si nécessaire

### Exemple d'intégration dans BudgetProvider

```dart
import '../services/user_service.dart';
import '../services/expense_service.dart';
import '../services/income_service.dart';
import '../services/category_service.dart';
import '../services/goal_service.dart';
import '../services/home_service.dart';

class BudgetProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUserData(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Charger les données depuis l'API
      _currentUser = await UserService.getProfile(userId);
      _expenses = await ExpenseService.getExpenses(userId);
      _incomes = await IncomeService.getIncomes(userId);
      _categories = await CategoryService.getUserCategories(userId);
      _goals = await GoalService.getGoals(userId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

---

## 🧪 Tester la connexion

### Test manuel avec curl
```bash
# Tester le backend
curl http://localhost:8081/api/v1/users/1/profile

# Tester depuis l'émulateur Android
adb shell
curl http://10.0.2.2:8081/api/v1/users/1/profile
```

### Test depuis Flutter
Ajouter un bouton de test dans l'application pour vérifier la connexion :
```dart
ElevatedButton(
  onPressed: () async {
    try {
      final user = await UserService.getProfile('1');
      print('User loaded: ${user.fullName}');
    } catch (e) {
      print('Error: $e');
    }
  },
  child: Text('Test API'),
)
```

---

## 📝 Notes importantes

1. **IDs numériques** : Le backend utilise des `Long` (numériques) alors que Flutter utilise des `String`. Les services gèrent automatiquement la conversion.

2. **Dates** : Le backend utilise `LocalDateTime` / `LocalDate` (format ISO 8601). Flutter convertit automatiquement vers `DateTime`.

3. **Enums** : Les enums du backend (`PaymentMethod`, `RecurrenceFrequency`) sont représentés comme des `String` dans Flutter.

4. **Pagination** : Les endpoints de liste supportent la pagination. Les services incluent les paramètres `page` et `size`.

5. **Gestion d'erreurs** : Tous les services lancent des exceptions en cas d'erreur. Il faut les gérer avec try-catch dans le provider.

---

## 🐛 Dépannage

### Erreur : "Connection refused"
- Vérifier que le backend Spring Boot est démarré
- Vérifier le port (8081)
- Vérifier l'URL dans `api_config.dart`

### Erreur : "Network error"
- Vérifier la connexion réseau
- Pour téléphone physique : vérifier que l'IP est correcte et que le pare-feu autorise les connexions

### Erreur : "Failed to load data: 404"
- Vérifier que l'utilisateur existe dans la base de données
- Vérifier que le script SQL a été exécuté correctement

### Erreur : "Failed to load data: 500"
- Vérifier les logs du backend Spring Boot
- Vérifier que la base de données est accessible
- Vérifier que les tables existent

---

## ✅ Prochaines étapes

1. ✅ Services API créés
2. ✅ Script SQL créé
3. ⏳ Adapter `BudgetProvider` pour utiliser les services API
4. ⏳ Ajouter la gestion d'erreurs et les états de chargement
5. ⏳ Implémenter la mise en cache locale si nécessaire
6. ⏳ Ajouter l'authentification si nécessaire

