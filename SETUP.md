# Guide de Configuration - Siblhish Front

## 📋 Prérequis

- Flutter SDK (version 3.0.0 ou supérieure)
- Dart SDK
- Un éditeur de code (VS Code, Android Studio, etc.)

## 🚀 Installation

### 1. Installer les dépendances

```bash
flutter pub get
```

### 2. Générer les adapters Hive

Les modèles de données utilisent Hive pour le stockage local. Vous devez générer les adapters :

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Cette commande va générer les fichiers `.g.dart` nécessaires pour chaque modèle :
- `expense.g.dart`
- `income.g.dart`
- `category.g.dart`
- `budget.g.dart`
- `goal.g.dart`
- `user.g.dart`

### 3. Vérifier la configuration

Assurez-vous que tous les fichiers `.g.dart` ont été générés dans le dossier `lib/models/`.

### 4. Lancer l'application

```bash
flutter run
```

## 🔧 Résolution de problèmes

### Erreur : "TypeAdapter not found"

Si vous obtenez une erreur concernant les adapters Hive, exécutez à nouveau :

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Erreur : "Box not found"

Assurez-vous que Hive est correctement initialisé dans `main.dart` et que toutes les boxes sont ouvertes.

### Erreur de compilation

Vérifiez que toutes les dépendances sont installées :

```bash
flutter pub get
flutter clean
flutter pub get
```

## 📱 Plateformes supportées

- ✅ Android
- ✅ iOS
- ✅ Web (avec limitations pour Hive)
- ✅ Desktop (Windows, macOS, Linux)

## 🎨 Personnalisation

### Modifier les couleurs

Les couleurs sont définies dans `lib/theme/app_theme.dart`. Vous pouvez modifier :
- `primaryColor` : Couleur principale
- `incomeColor` : Couleur des revenus (vert)
- `expenseColor` : Couleur des dépenses (rouge)
- `categoryColors` : Palette de couleurs pour les catégories

### Modifier les polices

L'application utilise Google Fonts (Poppins). Pour changer la police, modifiez les imports dans `app_theme.dart`.

## 📦 Structure des données

### Catégories par défaut

L'application crée automatiquement 6 catégories par défaut :
- 🍔 Alimentation
- 🚗 Transport
- 🎬 Loisirs
- 🏥 Santé
- 🛍️ Shopping
- 📚 Éducation

### Utilisateur par défaut

Un utilisateur par défaut est créé automatiquement si aucun utilisateur n'existe :
- Nom : "Utilisateur Test"
- Email : "user@example.com"
- Salaire mensuel : 8000 MAD

## 🔄 Mise à jour des modèles

Si vous modifiez un modèle Hive :

1. Modifiez le fichier du modèle (ex: `expense.dart`)
2. Régénérez les adapters :
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
3. Si vous changez le `typeId`, vous devrez peut-être supprimer les données existantes.

## 📝 Notes importantes

- Les données sont stockées localement avec Hive (Bolt Database)
- Les données persistent entre les sessions
- Pour réinitialiser les données, supprimez l'application et réinstallez-la
- Les adapters Hive doivent être régénérés après chaque modification des modèles

---

**Besoin d'aide ?** Consultez la documentation Flutter et Hive.

