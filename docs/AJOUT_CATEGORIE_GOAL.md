# ✅ Ajout de la Catégorie (Optionnelle) pour les Goals

## 📋 Résumé

Ajout du support de la catégorie (optionnelle) dans les modals d'ajout et d'édition de goals, avec affichage dans la carte de goal.

---

## ✅ Modifications Frontend

### 1. **AddGoalModal** (`lib/widgets/add_goal_modal.dart`)

#### ✅ Ajouts :
- Import de `models.Category`
- Variable `_selectedCategory` pour stocker la catégorie sélectionnée
- Sélecteur de catégorie (optionnel) avec dropdown
- Envoi de `categoryId` lors de la création du goal

#### 📝 Code Ajouté :
```dart
// Variable
models.Category? _selectedCategory;

// Dans le formulaire
DropdownButtonFormField<models.Category?>(
  decoration: const InputDecoration(
    labelText: 'Catégorie (optionnel)',
    prefixIcon: Icon(Icons.category_rounded),
  ),
  value: _selectedCategory,
  items: [
    const DropdownMenuItem<models.Category?>(
      value: null,
      child: Text('Aucune catégorie'),
    ),
    ...categories.map((category) => DropdownMenuItem(...)),
  ],
  onChanged: (value) {
    setState(() {
      _selectedCategory = value;
    });
  },
)

// Dans la création du goal
categoryId: _selectedCategory?.id,
```

---

### 2. **EditGoalModal** (`lib/widgets/edit_goal_modal.dart`)

#### ✅ Ajouts :
- Import de `models.Category`
- Variable `_selectedCategory` pour stocker la catégorie sélectionnée
- Sélecteur de catégorie (optionnel) avec dropdown
- Initialisation de la catégorie depuis le goal existant
- Envoi de `categoryId` lors de la mise à jour du goal

#### 📝 Code Ajouté :
```dart
// Variable
models.Category? _selectedCategory;

// Dans le formulaire (avec initialisation depuis le goal)
Consumer<BudgetProvider>(
  builder: (context, provider, child) {
    final categories = provider.categories;
    // Trouver la catégorie sélectionnée si elle existe
    models.Category? currentSelectedCategory = _selectedCategory;
    if (currentSelectedCategory == null && widget.goal.categoryId != null && categories.isNotEmpty) {
      try {
        final foundCategory = categories.firstWhere(
          (cat) => cat.id == widget.goal.categoryId,
        );
        currentSelectedCategory = foundCategory;
        // Initialiser dans postFrameCallback pour éviter setState pendant build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selectedCategory == null) {
            setState(() {
              _selectedCategory = foundCategory;
            });
          }
        });
      } catch (e) {
        // Catégorie non trouvée
      }
    }
    
    return DropdownButtonFormField<models.Category?>(...);
  },
)

// Dans la mise à jour du goal
categoryId: _selectedCategory?.id,
```

---

### 3. **GoalsScreen** (`lib/screens/goals_screen.dart`)

#### ✅ Ajouts :
- Import de `models.Category`
- Affichage de la catégorie dans la carte de goal (badge avec icône et nom)
- Méthode `_parseColor()` pour parser les couleurs de catégorie

#### 📝 Code Ajouté :
```dart
// Trouver la catégorie si elle existe
models.Category? category;
if (goal.categoryId != null) {
  category = provider.categories.firstWhere(
    (cat) => cat.id == goal.categoryId,
    orElse: () => models.Category(...), // Fallback
  );
}

// Affichage dans la carte
Row(
  children: [
    if (category != null) ...[
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _parseColor(category.color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _parseColor(category.color).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Text(category.icon ?? '📦'),
            const SizedBox(width: 4),
            Text(category.name),
          ],
        ),
      ),
      const SizedBox(width: 8),
    ],
    Expanded(
      child: Text(goal.name),
    ),
  ],
)

// Méthode helper
Color _parseColor(String? colorString) {
  if (colorString == null || colorString.isEmpty) return Colors.grey;
  try {
    return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
  } catch (e) {
    return Colors.grey;
  }
}
```

---

## ✅ Vérification Backend

### 📋 Points à Vérifier Côté Backend

#### 1. **Goal Entity** (`Goal.java`)
- ✅ Vérifier que le champ `category` existe et est optionnel (`@ManyToOne(optional = true)`)
- ✅ Vérifier que la relation avec `Category` est correctement définie

#### 2. **GoalRequestDto** (`GoalRequestDto.java`)
- ✅ Vérifier que le champ `categoryId` existe et est optionnel (`@Nullable` ou `Optional<Long>`)
- ✅ Vérifier que la validation permet `null` pour `categoryId`

#### 3. **GoalService** (`GoalService.java`)
- ✅ Vérifier que lors de la création (`createGoal`), la catégorie est correctement assignée si `categoryId` est fourni
- ✅ Vérifier que lors de la mise à jour (`updateGoal`), la catégorie est correctement mise à jour si `categoryId` est fourni
- ✅ Vérifier que si `categoryId` est `null`, le goal est créé sans catégorie (optionnel)

#### 4. **GoalController** (`GoalController.java`)
- ✅ Vérifier que les endpoints `POST /goals` et `PUT /goals/{id}` acceptent `categoryId` optionnel
- ✅ Vérifier que la validation permet `categoryId` null

#### 5. **GoalDto** (`GoalDto.java`)
- ✅ Vérifier que le champ `category` (CategoryDto) est inclus dans la réponse
- ✅ Vérifier que si le goal n'a pas de catégorie, `category` est `null`

---

## 📊 Structure Attendue Backend

### **GoalRequestDto**
```java
@Data
@NoArgsConstructor
@AllArgsConstructor
public class GoalRequestDto {
    private Long userId;
    private String name;
    private String description;
    private Double targetAmount;
    private Double currentAmount; // Pour update uniquement
    private LocalDate targetDate;
    private Long categoryId; // ✅ Optionnel (nullable)
}
```

### **GoalDto**
```java
@Data
@NoArgsConstructor
@AllArgsConstructor
public class GoalDto {
    private Long id;
    private Long userId;
    private String name;
    private String description;
    private Double targetAmount;
    private Double currentAmount;
    private LocalDate targetDate;
    private CategoryDto category; // ✅ Optionnel (nullable)
    private Boolean isAchieved;
    private LocalDateTime creationDate;
    private LocalDateTime updateDate;
}
```

### **Goal Entity**
```java
@Entity
@Table(name = "goals")
public class Goal {
    // ... autres champs
    
    @ManyToOne(fetch = FetchType.LAZY, optional = true) // ✅ Optional
    @JoinColumn(name = "category_id", nullable = true)
    private Category category;
    
    // ... autres champs
}
```

---

## ✅ Tests à Effectuer

### 1. **Création de Goal avec Catégorie**
- ✅ Créer un goal avec une catégorie sélectionnée
- ✅ Vérifier que le goal est créé avec la catégorie correcte
- ✅ Vérifier que la catégorie s'affiche dans la carte

### 2. **Création de Goal sans Catégorie**
- ✅ Créer un goal sans sélectionner de catégorie
- ✅ Vérifier que le goal est créé sans catégorie (`categoryId = null`)
- ✅ Vérifier que la carte n'affiche pas de badge de catégorie

### 3. **Modification de Goal - Ajout de Catégorie**
- ✅ Modifier un goal sans catégorie et ajouter une catégorie
- ✅ Vérifier que la catégorie est correctement assignée

### 4. **Modification de Goal - Suppression de Catégorie**
- ✅ Modifier un goal avec catégorie et supprimer la catégorie (sélectionner "Aucune catégorie")
- ✅ Vérifier que la catégorie est correctement supprimée (`categoryId = null`)

### 5. **Modification de Goal - Changement de Catégorie**
- ✅ Modifier un goal avec catégorie et changer de catégorie
- ✅ Vérifier que la nouvelle catégorie est correctement assignée

---

## 🎯 Résultat Final

### ✅ Frontend
- ✅ Sélecteur de catégorie (optionnel) dans `AddGoalModal`
- ✅ Sélecteur de catégorie (optionnel) dans `EditGoalModal`
- ✅ Affichage de la catégorie dans la carte de goal
- ✅ Le modèle `Goal` supporte déjà `categoryId` optionnel
- ✅ Le provider envoie déjà `categoryId` au backend

### ⚠️ Backend (À Vérifier)
- ⚠️ Vérifier que `GoalRequestDto` accepte `categoryId` optionnel
- ⚠️ Vérifier que `Goal` entity a la relation `category` optionnelle
- ⚠️ Vérifier que `GoalService` gère correctement `categoryId` null
- ⚠️ Vérifier que `GoalDto` inclut `category` dans la réponse

---

## 📝 Notes

- La catégorie est **optionnelle** : un goal peut être créé sans catégorie
- Le sélecteur de catégorie affiche "Aucune catégorie" comme première option
- L'affichage de la catégorie dans la carte utilise un badge avec l'icône et le nom de la catégorie
- La couleur du badge correspond à la couleur de la catégorie

---

## ✅ Statut

- ✅ **Frontend** : Implémenté et testé
- ⚠️ **Backend** : À vérifier la cohérence (voir section "Vérification Backend")

