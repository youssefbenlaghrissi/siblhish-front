# JSON - Suggestion de Budget

## 📤 JSON envoyé par le Frontend (Flutter)

### Endpoint
```
POST /api/v1/budgets/suggest
```

### Headers
```json
{
  "Content-Type": "application/json",
  "Accept": "application/json"
}
```

### Body (Request)

```json
{
  "monthlyIncome": 10000.0,
  "situation": "En couple",
  "location": "ville",
  "categoryIds": [1, 2, 4, 13, 18, 26, 30]
}
```

#### Détails des champs :

| Champ | Type | Requis | Description | Valeurs possibles |
|-------|------|--------|-------------|-------------------|
| `monthlyIncome` | `Double` | ✅ Oui | Revenu mensuel en MAD | Nombre positif (ex: 10000.0) |
| `situation` | `String` | ✅ Oui | Situation familiale | `"Célibataire"`, `"En couple"`, `"Famille"`, `"Étudiant"` |
| `location` | `String` | ✅ Oui | Localisation | `"ville"` ou `"campagne"` (en minuscules) |
| `categoryIds` | `List<Long>` | ✅ Oui | IDs des catégories sélectionnées | Tableau d'entiers (ex: [1, 2, 3]) |

#### Exemple de code Flutter pour construire la requête :

```dart
// Conversion des IDs de String à Long
List<Long> categoryIds = _selectedCategories
    .map((categoryId) => int.parse(categoryId))
    .toList();

final requestBody = {
  'monthlyIncome': double.parse(_incomeController.text),
  'situation': _selectedSituation, // "Célibataire", "En couple", "Famille", "Étudiant"
  'location': _selectedLocation,   // "ville" ou "campagne"
  'categoryIds': categoryIds,
};
```

---

## 📥 JSON attendu par le Backend (Spring Boot)

### Validation

Le backend valide automatiquement les champs avec les annotations suivantes :

- `monthlyIncome` : 
  - `@NotNull` : Ne peut pas être null
  - `@Positive` : Doit être un nombre positif
  
- `situation` : 
  - `@NotBlank` : Ne peut pas être vide
  
- `location` : 
  - `@NotBlank` : Ne peut pas être vide
  
- `categoryIds` : 
  - `@NotEmpty` : La liste ne peut pas être vide (au moins 1 catégorie)

### Exemples de requêtes valides

#### Exemple 1 : Célibataire en ville
```json
{
  "monthlyIncome": 8000.0,
  "situation": "Célibataire",
  "location": "ville",
  "categoryIds": [1, 4, 13, 18, 26]
}
```

#### Exemple 2 : Famille en campagne
```json
{
  "monthlyIncome": 15000.0,
  "situation": "Famille",
  "location": "campagne",
  "categoryIds": [1, 2, 4, 5, 13, 14, 15, 18, 26, 30, 33, 34]
}
```

#### Exemple 3 : Étudiant en ville
```json
{
  "monthlyIncome": 3000.0,
  "situation": "Étudiant",
  "location": "ville",
  "categoryIds": [1, 3, 4, 13, 20]
}
```

---

## 📤 JSON de réponse du Backend

### Structure de la réponse

```json
{
  "status": "success",
  "data": {
    "monthlyIncome": 10000.0,
    "situation": "En couple",
    "location": "ville",
    "totalSuggestedBudget": 8000.0,
    "suggestedSavings": 2000.0,
    "budgets": [
      {
        "categoryId": 1,
        "categoryName": "Alimentation",
        "amount": 2070.0,
        "percentage": 20.7,
        "icon": "🍔",
        "color": "#FF6B6B"
      },
      {
        "categoryId": 2,
        "categoryName": "Restaurant",
        "amount": 690.0,
        "percentage": 6.9,
        "icon": "🍽️",
        "color": "#E74C3C"
      },
      {
        "categoryId": 4,
        "categoryName": "Transport",
        "amount": 517.5,
        "percentage": 5.2,
        "icon": "🚗",
        "color": "#4ECDC4"
      },
      {
        "categoryId": 13,
        "categoryName": "Loyer",
        "amount": 3450.0,
        "percentage": 34.5,
        "icon": "🏠",
        "color": "#98D8C8"
      },
      {
        "categoryId": 18,
        "categoryName": "Santé",
        "amount": 517.5,
        "percentage": 5.2,
        "icon": "🏥",
        "color": "#96CEB4"
      },
      {
        "categoryId": 26,
        "categoryName": "Loisirs",
        "amount": 690.0,
        "percentage": 6.9,
        "icon": "🎬",
        "color": "#45B7D1"
      },
      {
        "categoryId": 30,
        "categoryName": "Shopping",
        "amount": 517.5,
        "percentage": 5.2,
        "icon": "🛍️",
        "color": "#FFB347"
      }
    ]
  },
  "message": "Operation successful"
}
```

### Détails des champs de réponse

#### BudgetSuggestionResponse

| Champ | Type | Description |
|-------|------|-------------|
| `monthlyIncome` | `Double` | Revenu mensuel utilisé pour le calcul |
| `situation` | `String` | Situation familiale utilisée |
| `location` | `String` | Localisation utilisée |
| `totalSuggestedBudget` | `Double` | Total des budgets suggérés (arrondi à 2 décimales) |
| `suggestedSavings` | `Double` | Épargne suggérée = monthlyIncome - totalSuggestedBudget |
| `budgets` | `List<BudgetSuggestion>` | Liste des suggestions par catégorie |

#### BudgetSuggestion (chaque élément de `budgets`)

| Champ | Type | Description |
|-------|------|-------------|
| `categoryId` | `Long` | ID de la catégorie |
| `categoryName` | `String` | Nom de la catégorie |
| `amount` | `Double` | Montant suggéré en MAD (arrondi à 2 décimales) |
| `percentage` | `Double` | Pourcentage du revenu (arrondi à 1 décimale) |
| `icon` | `String` | Icône de la catégorie (emoji) |
| `color` | `String` | Couleur hexadécimale de la catégorie |

---

## ❌ Exemples d'erreurs

### Erreur 400 - Validation échouée

```json
{
  "status": "error",
  "message": "Erreur lors du calcul des budgets suggérés: Le revenu mensuel est requis",
  "data": null
}
```

### Erreur 400 - Catégorie invalide

```json
{
  "status": "error",
  "message": "Erreur lors du calcul des budgets suggérés: Category not found with id: 999",
  "data": null
}
```

### Erreur 400 - Liste vide

```json
{
  "status": "error",
  "message": "Au moins une catégorie doit être sélectionnée",
  "data": null,
  "errors": {
    "categoryIds": "Au moins une catégorie doit être sélectionnée"
  }
}
```

---

## 🔄 Exemple complet d'intégration Flutter

```dart
Future<void> _submit() async {
  // Validation
  if (_incomeController.text.trim().isEmpty || 
      _selectedSituation == null || 
      _selectedLocation == null || 
      _selectedCategories.isEmpty) {
    return;
  }

  // Conversion des IDs
  List<int> categoryIds = _selectedCategories
      .map((categoryId) => int.parse(categoryId))
      .toList();

  // Construction de la requête
  final requestBody = {
    'monthlyIncome': double.parse(_incomeController.text),
    'situation': _selectedSituation,
    'location': _selectedLocation,
    'categoryIds': categoryIds,
  };

  try {
    // Appel API
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/budgets/suggest'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final data = jsonResponse['data'];
      
      // Traitement de la réponse
      final suggestions = data['budgets'] as List;
      final totalBudget = data['totalSuggestedBudget'];
      final savings = data['suggestedSavings'];
      
      // Afficher les résultats ou naviguer vers l'écran de résultats
      print('Total budget: $totalBudget MAD');
      print('Épargne suggérée: $savings MAD');
      print('Nombre de suggestions: ${suggestions.length}');
      
    } else {
      // Gérer l'erreur
      final error = jsonDecode(response.body);
      print('Erreur: ${error['message']}');
    }
  } catch (e) {
    print('Erreur de connexion: $e');
  }
}
```

---

## 📝 Notes importantes

1. **Conversion des IDs** : Les IDs des catégories dans Flutter sont des `String`, mais le backend attend des `Long` (entiers). Il faut convertir avec `int.parse()`.

2. **Localisation** : Le backend attend `"ville"` ou `"campagne"` en **minuscules**. Le frontend envoie déjà en minuscules grâce à `label.toLowerCase()`.

3. **Situation** : Les valeurs exactes attendues sont :
   - `"Célibataire"` (avec accent)
   - `"En couple"` (avec espace)
   - `"Famille"` (avec accent)
   - `"Étudiant"` (avec accent)

4. **Arrondi** : 
   - Les montants sont arrondis à **2 décimales**
   - Les pourcentages sont arrondis à **1 décimale**

5. **Logement automatique** : Si aucune catégorie de logement (Loyer, Électricité, Eau, Internet, Gaz) n'est sélectionnée, le système ajoute automatiquement "Loyer" avec 20% du revenu.

