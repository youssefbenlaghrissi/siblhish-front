# Siblhish Front - Application de Gestion de Budget

Application mobile moderne de gestion de budget développée avec Flutter.

## 🎯 Fonctionnalités

### 📱 4 Écrans Principaux

1. **Accueil**
   - Affichage du solde actuel avec dégradé visuel
   - Transactions récentes (revenus et dépenses)
   - Actions rapides pour ajouter revenus/dépenses
   - Formulaire modal élégant pour les transactions

2. **Statistiques**
   - Vue d'ensemble des finances
   - Graphique en camembert pour la répartition des dépenses par catégorie
   - Graphique en barres pour l'évolution mensuelle des revenus et dépenses
   - Cartes récapitulatives

3. **Objectifs**
   - Suivi des objectifs d'épargne avec barres de progression visuelles
   - Conseils quotidiens pour mieux épargner
   - Ajout/modification/suppression d'objectifs
   - Suivi de progression en temps réel

4. **Profil**
   - Gestion des informations personnelles
   - Configuration du salaire mensuel
   - Gestion des catégories de dépenses personnalisées
   - Paramètres de l'application

## 🎨 Design

- **Couleurs professionnelles** : Vert pour les revenus, rouge pour les dépenses
- **Dégradés subtils** pour un design moderne
- **Animations fluides** avec flutter_animate
- **Design responsive** et cohérent
- **Thème Material 3** avec Google Fonts (Poppins)

## 🛠️ Technologies

- **Flutter** : Framework de développement
- **Hive** : Base de données locale (Bolt Database)
- **Provider** : Gestion d'état
- **fl_chart** : Graphiques et visualisations
- **flutter_animate** : Animations
- **google_fonts** : Polices personnalisées
- **intl** : Formatage des dates et devises

## 📦 Installation

1. Assurez-vous d'avoir Flutter installé :
```bash
flutter --version
```

2. Clonez ou naviguez vers le projet :
```bash
cd siblhish-front
```

3. Installez les dépendances :
```bash
flutter pub get
```

4. Générez les adapters Hive :
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

5. Lancez l'application :
```bash
flutter run
```

## 📁 Structure du Projet

```
lib/
├── main.dart                 # Point d'entrée de l'application
├── models/                   # Modèles de données (Hive)
│   ├── expense.dart
│   ├── income.dart
│   ├── category.dart
│   ├── budget.dart
│   ├── goal.dart
│   └── user.dart
├── providers/                # Gestion d'état
│   └── budget_provider.dart
├── screens/                  # Écrans principaux
│   ├── home_screen.dart
│   ├── statistics_screen.dart
│   ├── goals_screen.dart
│   └── profile_screen.dart
├── widgets/                  # Widgets réutilisables
│   ├── transaction_item.dart
│   ├── add_transaction_modal.dart
│   ├── add_goal_modal.dart
│   └── add_category_modal.dart
└── theme/                    # Thème de l'application
    └── app_theme.dart
```

## 🗄️ Base de Données

L'application utilise **Hive** (Bolt Database) pour le stockage local :

- **Boxes** :
  - `expenses` : Dépenses
  - `incomes` : Revenus
  - `categories` : Catégories
  - `budgets` : Budgets
  - `goals` : Objectifs
  - `users` : Utilisateurs
  - `settings` : Paramètres

## 🎯 Fonctionnalités Clés

- ✅ Ajout de revenus et dépenses
- ✅ Gestion des catégories personnalisées
- ✅ Suivi des objectifs d'épargne
- ✅ Statistiques visuelles avec graphiques
- ✅ Interface moderne et animée
- ✅ Stockage local sécurisé
- ✅ Design responsive

## 📱 Captures d'écran

L'application présente :
- Des cartes avec ombres et dégradés
- Des animations fluides lors des transitions
- Des graphiques interactifs
- Une navigation par onglets intuitive

## 🚀 Prochaines Étapes

- [ ] Synchronisation avec l'API backend
- [ ] Export des données (PDF, Excel)
- [ ] Notifications push
- [ ] Mode sombre
- [ ] Multi-devices sync
- [ ] Rappels de budgets

## 📄 Licence

Ce projet est développé pour Siblhish.

---

**Version** : 1.0.0  
**Dernière mise à jour** : Décembre 2024

