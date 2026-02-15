# Guide de Performance - Application Flutter

## 📊 Outils de Mesure de Performance

### 1. Flutter DevTools (Recommandé)

#### Accès à DevTools
Quand vous lancez l'app avec `flutter run`, vous verrez une URL comme :
```
The Flutter DevTools debugger and profiler on Pixel 9 is available at:
http://127.0.0.1:60045/PKQWjSoJPoo=/devtools/?uri=ws://127.0.0.1:60045/PKQWjSoJPoo=/ws
```

**Ouvrez cette URL dans votre navigateur** pour accéder à DevTools.

#### Outils disponibles dans DevTools :

##### a) **Performance Tab**
- **FPS (Frames Per Second)** : Doit être stable à 60 FPS
- **Frame Rendering Time** : Chaque frame doit prendre < 16.67ms (60 FPS)
- **Jank Detection** : Détecte les frames qui prennent > 16.67ms
- **Timeline** : Visualise l'exécution de votre code

**Comment utiliser :**
1. Cliquez sur "Performance" dans DevTools
2. Cliquez sur "Record" (bouton rouge)
3. Interagissez avec votre app (navigation, actions, etc.)
4. Cliquez sur "Stoimage.png
p"
5. Analysez les frames lents (rouges) et les widgets qui causent des problèmes

##### b) **Memory Tab**
- **Memory Usage** : Consommation mémoire en temps réel
- **Memory Leaks** : Détecte les objets non libérés
- **Heap Snapshot** : Capture l'état de la mémoire à un moment donné

**Comment utiliser :**
1. Cliquez sur "Memory" dans DevTools
2. Observez le graphique de consommation mémoire
3. Cliquez sur "Take Heap Snapshot" pour capturer l'état actuel
4. Comparez les snapshots avant/après une action
5. Recherchez les objets qui ne sont pas libérés

**Test de fuite mémoire :**
- Utilisez l'app pendant 30 minutes
- Observez si la consommation mémoire augmente continuellement
- Si stable = pas de fuite ✅
- Si augmente = fuite mémoire ❌

##### c) **Network Tab**
- **Requêtes HTTP** : Toutes les requêtes API
- **Temps de réponse** : Latence de chaque requête
- **Taille des données** : Données envoyées/reçues

##### d) **CPU Profiler**
- **CPU Usage** : Utilisation du CPU en temps réel
- **Hot Methods** : Méthodes qui consomment le plus de CPU
- **Call Tree** : Arbre d'appels des fonctions

### 2. Commandes Flutter CLI

#### Mode Profile
```bash
# Lancer l'app en mode profile (meilleures performances que debug)
flutter run --profile
```

#### Analyse de la taille de l'application
```bash
# Android
flutter build apk --analyze-size

# iOS
flutter build ios --analyze-size
```

#### Performance Overlay
Ajoutez ceci dans votre `main.dart` pour voir les FPS en temps réel :
```dart
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Activez l'overlay de performance
      showPerformanceOverlay: true, // À activer seulement pour les tests
      // ... reste du code
    );
  }
}
```

### 3. Métriques à Surveiller

#### ✅ Performance UI
- **FPS** : Doit être stable à 60 FPS
- **Frame Time** : < 16.67ms par frame
- **Jank** : < 1% de frames lents
- **Build Time** : Temps de reconstruction des widgets

#### ✅ Mémoire
- **Memory Usage** : Consommation mémoire de base
- **Memory Leaks** : Pas d'augmentation continue
- **Heap Size** : Taille du heap mémoire
- **GC (Garbage Collection)** : Fréquence des collectes

#### ✅ Réseau
- **API Response Time** : < 1 seconde pour la plupart des requêtes
- **Network Errors** : Taux d'erreur < 1%
- **Data Transfer** : Taille des données transférées

#### ✅ CPU
- **CPU Usage** : < 50% en moyenne
- **Battery Impact** : Impact sur la batterie

### 4. Tests de Performance Recommandés

#### Test 1 : Navigation Fluide
1. Ouvrez DevTools Performance
2. Enregistrez une session
3. Naviguez entre tous les écrans
4. Vérifiez qu'il n'y a pas de jank (> 16.67ms)

#### Test 2 : Consommation Mémoire (30 minutes)
1. Ouvrez DevTools Memory
2. Prenez un snapshot initial
3. Utilisez l'app normalement pendant 30 minutes
4. Prenez un snapshot final
5. Comparez : la consommation doit être stable

#### Test 3 : Performance des Listes
1. Ouvrez l'écran Transactions
2. Scrollez rapidement
3. Vérifiez que le scroll est fluide (60 FPS)
4. Vérifiez qu'il n'y a pas de lag

#### Test 4 : Performance des API
1. Ouvrez DevTools Network
2. Effectuez toutes les actions (créer, modifier, supprimer)
3. Vérifiez les temps de réponse
4. Identifiez les requêtes lentes

### 5. Optimisations Recommandées

#### Pour améliorer les performances :

1. **Utilisez `const` widgets** quand possible
2. **Évitez les rebuilds inutiles** avec `const` constructors
3. **Utilisez `ListView.builder`** au lieu de `ListView` pour les longues listes
4. **Lazy loading** : chargez les données au fur et à mesure
5. **Cache** : Mettez en cache les données fréquemment utilisées
6. **Images** : Optimisez la taille des images
7. **Animations** : Utilisez `flutter_animate` efficacement

### 6. Checklist de Performance

- [ ] FPS stable à 60 FPS
- [ ] Pas de jank visible (< 1% de frames lents)
- [ ] Consommation mémoire stable (pas de fuite)
- [ ] Temps de réponse API < 1 seconde
- [ ] Navigation fluide entre les écrans
- [ ] Scroll fluide dans les listes
- [ ] Pas de lag lors des animations
- [ ] Taille de l'application raisonnable

### 7. Outils Externes (Optionnels)

#### Firebase Performance Monitoring
Pour surveiller la performance en production :
```yaml
dependencies:
  firebase_performance: ^0.9.0
```

#### Sentry Performance
Pour le monitoring d'erreurs et performance :
```yaml
dependencies:
  sentry_flutter: ^7.0.0
```

## 📝 Exemple de Rapport de Performance

### Test : Consommation Mémoire
- **Durée** : 30 minutes
- **Résultat** : ✅ Pas de fuite mémoire, consommation stable
- **Mémoire initiale** : 45 MB
- **Mémoire finale** : 47 MB
- **Variation** : +2 MB (acceptable)

### Test : Performance UI
- **FPS moyen** : 60 FPS
- **Jank** : 0.2% (excellent)
- **Frame time moyen** : 12ms
- **Résultat** : ✅ Performance excellente

## 🔍 Dépannage

### Si vous voyez des janks :
1. Ouvrez DevTools Performance
2. Identifiez les frames rouges (lents)
3. Regardez quels widgets/fonctions causent le problème
4. Optimisez ces parties du code

### Si vous voyez une fuite mémoire :
1. Ouvrez DevTools Memory
2. Prenez des snapshots avant/après
3. Comparez les objets en mémoire
4. Identifiez les objets qui ne sont pas libérés
5. Vérifiez les listeners, streams, timers non fermés

