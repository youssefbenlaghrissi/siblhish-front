# Algorithme de Suggestion de Budgets

## 📋 Vue d'ensemble

Cet algorithme calcule des budgets mensuels suggérés pour chaque catégorie sélectionnée en fonction de :
- **Revenu mensuel** de l'utilisateur
- **Situation** (Célibataire, En couple, Famille, Étudiant)
- **Localisation** (Ville, Campagne)
- **Catégories** sélectionnées

---

## 🎯 Principe de Base

### 1. Répartition Standard du Revenu (Règle 50/30/20)

```
50% → Dépenses essentielles (Alimentation, Transport, Logement, Santé)
30% → Dépenses personnelles (Loisirs, Shopping, Éducation)
20% → Épargne et investissements
```

### 2. Pourcentages par Catégorie (Base pour 1 personne)

| Catégorie | % du Revenu | Description |
|-----------|-------------|-------------|
| Alimentation | 20-25% | Nourriture, courses, restaurants |
| Transport | 10-15% | Carburant, transports en commun, maintenance |
| Logement | 25-30% | Loyer, charges, électricité, eau |
| Santé | 5-10% | Médecins, médicaments, assurance |
| Loisirs | 10-15% | Sorties, cinéma, hobbies |
| Shopping | 5-10% | Vêtements, objets personnels |
| Éducation | 5-10% | Cours, livres, formations |
| Autres | 5-10% | Divers, imprévus |

---

## 🔢 Algorithme de Calcul

### Étape 1 : Calculer le Multiplicateur de Situation

```java
public double getSituationMultiplier(String situation) {
    switch (situation) {
        case "Célibataire":
            return 1.0;  // Base
        case "En couple":
            return 1.5;  // +50% (2 personnes)
        case "Famille":
            return 2.2;  // +120% (3+ personnes avec enfants)
        case "Étudiant":
            return 0.7;  // -30% (revenus limités)
        default:
            return 1.0;
    }
}
```

### Étape 2 : Calculer le Multiplicateur de Localisation

```java
public double getLocationMultiplier(String location) {
    switch (location) {
        case "Ville":
            return 1.15;  // +15% (coût de la vie plus élevé)
        case "Campagne":
            return 0.85;  // -15% (coût de la vie plus faible)
        default:
            return 1.0;
    }
}
```

### Étape 3 : Définir les Pourcentages par Catégorie

**Rôle de `getCategoryPercentages()`** :
Cette méthode définit le **pourcentage standard du revenu** alloué à chaque catégorie. C'est une **table de référence** qui indique combien devrait coûter chaque type de dépense en moyenne.

**Exemple** : Si votre revenu est 10,000 MAD et que "Alimentation" a 22%, alors le budget suggéré sera 2,200 MAD.

**⚠️ Important** : Si l'utilisateur ne sélectionne pas "Logement", cette catégorie ne sera **pas incluse** dans le calcul. Les autres budgets seront ajustés proportionnellement.

```java
public Map<String, Double> getCategoryPercentages() {
    Map<String, Double> percentages = new HashMap<>();
    
    // Dépenses essentielles (50% du revenu)
    percentages.put("Alimentation", 0.22);      // 22%
    percentages.put("Transport", 0.12);          // 12%
    percentages.put("Logement", 0.28);           // 28% (si catégorie existe)
    percentages.put("Santé", 0.08);              // 8%
    
    // Dépenses personnelles (30% du revenu)
    percentages.put("Loisirs", 0.12);            // 12%
    percentages.put("Shopping", 0.08);            // 8%
    percentages.put("Éducation", 0.10);          // 10%
    
    // Autres
    percentages.put("Autres", 0.10);             // 10%
    
    return percentages;
}
```

### Étape 4 : Calculer le Budget pour une Catégorie

```java
public double calculateBudgetForCategory(
    double monthlyIncome,
    String categoryName,
    String situation,
    String location
) {
    // 1. Obtenir le pourcentage de base pour la catégorie
    double basePercentage = getCategoryPercentages()
        .getOrDefault(categoryName, 0.10); // 10% par défaut
    
    // 2. Appliquer le multiplicateur de situation
    double situationMultiplier = getSituationMultiplier(situation);
    
    // 3. Appliquer le multiplicateur de localisation
    double locationMultiplier = getLocationMultiplier(location);
    
    // 4. Calculer le budget
    double budget = monthlyIncome 
        * basePercentage 
        * situationMultiplier 
        * locationMultiplier;
    
    // 5. Arrondir à 2 décimales
    return Math.round(budget * 100.0) / 100.0;
}
```

### Étape 5 : Ajuster les Budgets pour Respecter le Revenu Total

**Gestion du cas où "Logement" n'est pas sélectionné** :
- Si l'utilisateur ne sélectionne pas "Logement", cette catégorie est **ignorée**
- Les budgets sont calculés **uniquement pour les catégories sélectionnées**
- Les pourcentages sont **normalisés** pour que le total reste cohérent

```java
public List<BudgetSuggestion> suggestBudgets(
    double monthlyIncome,
    String situation,
    String location,
    List<String> categoryIds
) {
    List<BudgetSuggestion> suggestions = new ArrayList<>();
    Map<String, Double> categoryPercentages = getCategoryPercentages();
    
    // Étape 1 : Calculer le total des pourcentages UNIQUEMENT pour les catégories sélectionnées
    double totalPercentage = 0.0;
    Map<String, Category> selectedCategories = new HashMap<>();
    
    for (String categoryId : categoryIds) {
        Category category = categoryService.getCategoryById(categoryId);
        String categoryName = category.getName();
        selectedCategories.put(categoryName, category);
        
        // Utiliser le pourcentage de la catégorie, ou 10% par défaut si non trouvé
        double percentage = categoryPercentages.getOrDefault(categoryName, 0.10);
        totalPercentage += percentage;
    }
    
    // Étape 2 : Normaliser les pourcentages si nécessaire
    // Si totalPercentage > 1.0 (100%), on réduit proportionnellement
    // Si totalPercentage < 0.5 (50%), on peut augmenter proportionnellement (optionnel)
    double normalizationFactor = 1.0;
    if (totalPercentage > 1.0) {
        normalizationFactor = 1.0 / totalPercentage;
    }
    // Optionnel : si totalPercentage < 0.5, on peut augmenter pour utiliser plus du revenu
    // normalizationFactor = totalPercentage < 0.5 ? 0.8 / totalPercentage : 1.0;
    
    // Étape 3 : Calculer les budgets pour chaque catégorie sélectionnée
    double totalBudget = 0.0;
    for (Map.Entry<String, Category> entry : selectedCategories.entrySet()) {
        String categoryName = entry.getKey();
        Category category = entry.getValue();
        
        // Obtenir le pourcentage de base
        double basePercentage = categoryPercentages.getOrDefault(categoryName, 0.10);
        
        // Calculer le budget avec les multiplicateurs
        double budget = calculateBudgetForCategory(
            monthlyIncome,
            categoryName,
            situation,
            location
        );
        
        // Appliquer la normalisation
        budget = budget * normalizationFactor;
        
        // Calculer le pourcentage final
        double finalPercentage = (budget / monthlyIncome) * 100;
        
        suggestions.add(new BudgetSuggestion(
            category.getId(),
            categoryName,
            budget,
            finalPercentage
        ));
        
        totalBudget += budget;
    }
    
    // Étape 4 : Vérifier que le total ne dépasse pas 80% du revenu (garder 20% pour épargne)
    double maxTotalBudget = monthlyIncome * 0.80;
    if (totalBudget > maxTotalBudget) {
        double scaleFactor = maxTotalBudget / totalBudget;
        for (BudgetSuggestion suggestion : suggestions) {
            suggestion.setAmount(suggestion.getAmount() * scaleFactor);
            suggestion.setPercentage((suggestion.getAmount() / monthlyIncome) * 100);
        }
        totalBudget = maxTotalBudget;
    }
    
    return suggestions;
}
```

**Exemple concret : Sans "Logement"**

**Données** :
- Revenu : 15,000 MAD
- Catégories sélectionnées : Alimentation, Transport, Loisirs, Santé, Shopping
- Situation : En couple, Localisation : Ville

**Calcul** :
1. Pourcentages sélectionnés : 22% + 12% + 12% + 8% + 8% = **62%**
2. Budgets bruts (avec multiplicateurs 1.5 × 1.15 = 1.725) :
   - Alimentation : 15,000 × 0.22 × 1.725 = 5,692.50 MAD
   - Transport : 15,000 × 0.12 × 1.725 = 3,105.00 MAD
   - Loisirs : 15,000 × 0.12 × 1.725 = 3,105.00 MAD
   - Santé : 15,000 × 0.08 × 1.725 = 2,070.00 MAD
   - Shopping : 15,000 × 0.08 × 1.725 = 2,070.00 MAD
   - **Total** : 16,042.50 MAD (107% du revenu)

3. Normalisation (limiter à 80% = 12,000 MAD) :
   - Facteur : 12,000 / 16,042.50 = 0.748
   - Budgets finaux :
     - Alimentation : 4,258 MAD
     - Transport : 2,324 MAD
     - Loisirs : 2,324 MAD
     - Santé : 1,548 MAD
     - Shopping : 1,548 MAD
   - **Total** : 12,002 MAD (80%)
   - **Épargne** : 2,998 MAD (20%)

**✅ Résultat** : Même sans "Logement", les budgets sont calculés et normalisés correctement !

---

## 📊 Exemple de Calcul

### Données d'entrée :
- **Revenu mensuel** : 15,000 MAD
- **Situation** : En couple
- **Localisation** : Ville
- **Catégories** : Alimentation, Transport, Loisirs, Santé, Shopping

### Calcul étape par étape :

1. **Multiplicateur situation** : 1.5 (En couple)
2. **Multiplicateur localisation** : 1.15 (Ville)
3. **Multiplicateur global** : 1.5 × 1.15 = 1.725

4. **Budgets calculés** :
   - Alimentation : 15,000 × 0.22 × 1.725 = **5,692.50 MAD**
   - Transport : 15,000 × 0.12 × 1.725 = **3,105.00 MAD**
   - Loisirs : 15,000 × 0.12 × 1.725 = **3,105.00 MAD**
   - Santé : 15,000 × 0.08 × 1.725 = **2,070.00 MAD**
   - Shopping : 15,000 × 0.08 × 1.725 = **2,070.00 MAD**

5. **Total budgets** : 16,042.50 MAD (107% du revenu)

6. **Normalisation** (limiter à 80% du revenu = 12,000 MAD) :
   - Facteur d'échelle : 12,000 / 16,042.50 = 0.748
   - Alimentation : 5,692.50 × 0.748 = **4,258.00 MAD**
   - Transport : 3,105.00 × 0.748 = **2,324.00 MAD**
   - Loisirs : 3,105.00 × 0.748 = **2,324.00 MAD**
   - Santé : 2,070.00 × 0.748 = **1,548.00 MAD**
   - Shopping : 2,070.00 × 0.748 = **1,548.00 MAD**

7. **Total final** : 12,002.00 MAD (80% du revenu)
8. **Épargne suggérée** : 2,998.00 MAD (20% du revenu)

---

## 🎨 Ajustements Spéciaux

### Pour les Étudiants
- Réduire les budgets "Loisirs" et "Shopping" de 50%
- Augmenter le budget "Éducation" de 30%
- Multiplicateur global : 0.7

### Pour les Familles
- Augmenter "Alimentation" de 30%
- Augmenter "Santé" de 20% (enfants)
- Augmenter "Éducation" de 50% (si catégorie sélectionnée)
- Multiplicateur global : 2.2

### Pour la Campagne
- Réduire "Transport" de 20% (moins de déplacements)
- Réduire "Alimentation" de 10% (coûts plus bas)
- Multiplicateur global : 0.85

---

## 📝 Structure de Réponse JSON

```json
{
  "status": "success",
  "data": {
    "monthlyIncome": 15000.0,
    "situation": "En couple",
    "location": "ville",
    "totalSuggestedBudget": 12002.0,
    "suggestedSavings": 2998.0,
    "budgets": [
      {
        "categoryId": "1",
        "categoryName": "Alimentation",
        "amount": 4258.0,
        "percentage": 28.4,
        "icon": "🍔",
        "color": "#FF6B6B"
      },
      {
        "categoryId": "2",
        "categoryName": "Transport",
        "amount": 2324.0,
        "percentage": 15.5,
        "icon": "🚗",
        "color": "#4ECDC4"
      },
      {
        "categoryId": "3",
        "categoryName": "Loisirs",
        "amount": 2324.0,
        "percentage": 15.5,
        "icon": "🎬",
        "color": "#95E1D3"
      },
      {
        "categoryId": "4",
        "categoryName": "Santé",
        "amount": 1548.0,
        "percentage": 10.3,
        "icon": "🏥",
        "color": "#F38181"
      },
      {
        "categoryId": "5",
        "categoryName": "Shopping",
        "amount": 1548.0,
        "percentage": 10.3,
        "icon": "🛍️",
        "color": "#AA96DA"
      }
    ]
  }
}
```

---

## 🔧 Implémentation Backend (Spring Boot)

### Service

```java
@Service
public class BudgetSuggestionService {
    
    @Autowired
    private CategoryService categoryService;
    
    public BudgetSuggestionResponse suggestBudgets(
        BudgetSuggestionRequest request
    ) {
        double monthlyIncome = request.getMonthlyIncome();
        String situation = request.getSituation();
        String location = request.getLocation();
        List<String> categoryIds = request.getCategoryIds();
        
        List<BudgetSuggestion> suggestions = calculateBudgets(
            monthlyIncome,
            situation,
            location,
            categoryIds
        );
        
        double totalBudget = suggestions.stream()
            .mapToDouble(BudgetSuggestion::getAmount)
            .sum();
        
        double suggestedSavings = monthlyIncome - totalBudget;
        
        return BudgetSuggestionResponse.builder()
            .monthlyIncome(monthlyIncome)
            .situation(situation)
            .location(location)
            .totalSuggestedBudget(totalBudget)
            .suggestedSavings(suggestedSavings)
            .budgets(suggestions)
            .build();
    }
    
    // ... méthodes de calcul décrites ci-dessus
}
```

### Controller

```java
@RestController
@RequestMapping("/api/v1/budgets")
public class BudgetSuggestionController {
    
    @Autowired
    private BudgetSuggestionService budgetSuggestionService;
    
    @PostMapping("/suggest")
    public ResponseEntity<ApiResponse<BudgetSuggestionResponse>> suggestBudgets(
        @RequestBody BudgetSuggestionRequest request
    ) {
        BudgetSuggestionResponse response = budgetSuggestionService
            .suggestBudgets(request);
        
        return ResponseEntity.ok(
            ApiResponse.success(response)
        );
    }
}
```

---

## ✅ Validation et Contraintes

1. **Budget total ≤ 80% du revenu** (garder 20% pour épargne)
2. **Budget minimum** : 100 MAD par catégorie
3. **Budget maximum** : 50% du revenu par catégorie
4. **Arrondi** : à 2 décimales (ou au dirham près)

---

## 🎯 Points d'Amélioration Futurs

1. **Apprentissage automatique** : Analyser les dépenses historiques pour affiner les suggestions
2. **Régions spécifiques** : Ajuster selon la ville (Casablanca vs Rabat vs autres)
3. **Saisonnalité** : Ajuster selon le mois (ex: plus de shopping en décembre)
4. **Objectifs personnels** : Prendre en compte les objectifs d'épargne de l'utilisateur

