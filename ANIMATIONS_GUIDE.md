# Guide des Animations - Application Flutter

## 📱 Vue d'ensemble

Votre application utilise deux types d'animations :
1. **flutter_animate** : Animations déclaratives simples (fadeIn, slideY, slideX, scale, shake)
2. **AnimationController** : Animations personnalisées complexes (splash screen, main screen)

---

## 🎬 1. Animations avec `flutter_animate`

### 📍 Écrans utilisant `flutter_animate` :

#### a) **LoginScreen** (`lib/screens/login_screen.dart`)

**Animations présentes :**

1. **Logo/Titre** :
   ```dart
   .animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8))
   ```
   - **Type** : FadeIn + Scale
   - **Durée** : 500ms
   - **Effet** : Le logo apparaît en fondu et grandit de 80% à 100%

2. **Titre "Siblhish"** :
   ```dart
   .animate().fadeIn(delay: 200.ms)
   ```
   - **Type** : FadeIn
   - **Délai** : 200ms
   - **Effet** : Apparition en fondu

3. **Sous-titre** :
   ```dart
   .animate().fadeIn(delay: 300.ms)
   ```
   - **Type** : FadeIn
   - **Délai** : 300ms
   - **Effet** : Apparition en fondu après le titre

4. **Message d'erreur** :
   ```dart
   .animate().shake()
   ```
   - **Type** : Shake (secousse)
   - **Effet** : Secousse horizontale pour attirer l'attention

5. **Bouton "Continuer avec Google"** :
   ```dart
   .animate().fadeIn(delay: 400.ms).slideY(begin: 0.2)
   ```
   - **Type** : FadeIn + SlideY
   - **Délai** : 400ms
   - **Effet** : Apparition en fondu + glissement depuis le bas (20%)

6. **Divider "ou"** :
   ```dart
   .animate().fadeIn(delay: 600.ms)
   ```
   - **Type** : FadeIn
   - **Délai** : 600ms

7. **Bouton "Se connecter avec email"** :
   ```dart
   .animate().fadeIn(delay: 700.ms).slideY(begin: 0.2)
   ```
   - **Type** : FadeIn + SlideY
   - **Délai** : 700ms
   - **Effet** : Apparition en fondu + glissement depuis le bas

8. **Lien "Créer un compte"** :
   ```dart
   .animate().fadeIn(delay: 800.ms)
   ```
   - **Type** : FadeIn
   - **Délai** : 800ms

9. **Lien "Continuer en tant qu'invité"** :
   ```dart
   .animate().fadeIn(delay: 900.ms)
   ```
   - **Type** : FadeIn
   - **Délai** : 900ms

**Séquence d'animation** : Les éléments apparaissent progressivement avec des délais croissants (200ms → 900ms) pour créer un effet de cascade.

---

#### b) **RegisterScreen** (`lib/screens/register_screen.dart`)

**Animations présentes :**

1. **Titre "Créer un compte"** :
   ```dart
   .animate().fadeIn(delay: 100.ms)
   ```
   - **Type** : FadeIn
   - **Délai** : 100ms

2. **Sous-titre** :
   ```dart
   .animate().fadeIn(delay: 200.ms)
   ```
   - **Type** : FadeIn
   - **Délai** : 200ms

3. **Message d'erreur** :
   ```dart
   .animate().shake()
   ```
   - **Type** : Shake
   - **Effet** : Secousse pour les erreurs de validation

4. **Champs de formulaire** (Prénom, Nom, Email, etc.) :
   ```dart
   .animate().fadeIn(delay: 300.ms).slideY(begin: 0.1)
   .animate().fadeIn(delay: 400.ms).slideY(begin: 0.1)
   .animate().fadeIn(delay: 500.ms).slideY(begin: 0.1)
   .animate().fadeIn(delay: 600.ms).slideY(begin: 0.1)
   .animate().fadeIn(delay: 700.ms).slideY(begin: 0.1)
   ```
   - **Type** : FadeIn + SlideY
   - **Délai** : 300ms → 700ms (incrément de 100ms)
   - **Effet** : Chaque champ apparaît en fondu et glisse depuis le bas (10%)

5. **Bouton "Créer un compte"** :
   ```dart
   .animate().fadeIn(delay: 800.ms).slideY(begin: 0.2)
   ```
   - **Type** : FadeIn + SlideY
   - **Délai** : 800ms
   - **Effet** : Apparition en fondu + glissement depuis le bas (20%)

6. **Lien "Déjà un compte ?"** :
   ```dart
   .animate().fadeIn(delay: 900.ms)
   ```
   - **Type** : FadeIn
   - **Délai** : 900ms

**Séquence d'animation** : Cascade progressive des champs du formulaire (100ms → 900ms).

---

#### c) **LoginEmailScreen** (`lib/screens/login_email_screen.dart`)

**Animations présentes :**

1. **Titre "Connexion"** :
   ```dart
   .animate().fadeIn(delay: 100.ms)
   ```
   - **Type** : FadeIn
   - **Délai** : 100ms

2. **Sous-titre** :
   ```dart
   .animate().fadeIn(delay: 200.ms)
   ```
   - **Type** : FadeIn
   - **Délai** : 200ms

3. **Message d'erreur** :
   ```dart
   .animate().shake()
   ```
   - **Type** : Shake
   - **Effet** : Secousse pour les erreurs

4. **Champs Email/Password** :
   ```dart
   .animate().fadeIn(delay: 300.ms).slideY(begin: 0.1)
   .animate().fadeIn(delay: 400.ms).slideY(begin: 0.1)
   ```
   - **Type** : FadeIn + SlideY
   - **Délai** : 300ms, 400ms

5. **Bouton "Se connecter"** :
   ```dart
   .animate().fadeIn(delay: 500.ms).slideY(begin: 0.2)
   ```
   - **Type** : FadeIn + SlideY
   - **Délai** : 500ms

6. **Lien "Créer un compte"** :
   ```dart
   .animate().fadeIn(delay: 600.ms)
   ```
   - **Type** : FadeIn
   - **Délai** : 600ms

---

#### d) **GoalsScreen** (`lib/screens/goals_screen.dart`)

**Animations présentes :**

1. **Cartes d'objectifs (liste)** :
   ```dart
   .animate()
   .fadeIn(duration: 300.ms, delay: (index * 50).ms)
   .slideX(begin: 0.2, end: 0, duration: 300.ms, delay: (index * 50).ms)
   ```
   - **Type** : FadeIn + SlideX
   - **Durée** : 300ms
   - **Délai** : `index * 50ms` (animation échelonnée)
   - **Effet** : Chaque carte apparaît en fondu et glisse depuis la droite (20%)
   - **Particularité** : Animation échelonnée - chaque carte a un délai différent basé sur son index

**Séquence d'animation** : Les cartes apparaissent une par une avec un délai de 50ms entre chacune.

---

## 🎨 2. Animations avec `AnimationController`

### 📍 Écrans utilisant `AnimationController` :

#### a) **SplashScreen** (`lib/screens/splash_screen.dart`)

**Animations personnalisées complexes :**

1. **Image du splash** :
   - **FadeIn** : Opacité 0 → 1 (0% → 35% de l'animation)
   - **Scale** : Échelle 0.8 → 1.0 (0% → 35% de l'animation)
   - **Curve** : `Curves.easeOut` et `Curves.easeOutCubic`
   - **Effet** : L'image apparaît en fondu et grandit légèrement

2. **Titre "Siblhish"** :
   - **FadeIn** : Opacité 0 → 1 (35% → 65% de l'animation)
   - **Slide** : Offset(0, -0.2) → Offset(0, 0) (35% → 65% de l'animation)
   - **Curve** : `Curves.easeOut` et `Curves.easeOutCubic`
   - **Effet** : Le titre apparaît en fondu et glisse depuis le haut

3. **Sous-titre** :
   - **FadeIn** : Opacité 0 → 1 (65% → 100% de l'animation)
   - **Slide** : Offset(0, 0.2) → Offset(0, 0) (65% → 100% de l'animation)
   - **Curve** : `Curves.easeOut` et `Curves.easeOutCubic`
   - **Effet** : Le sous-titre apparaît en fondu et glisse depuis le bas

**Durée totale** : 800ms
**Séquence** : Image (0-35%) → Titre (35-65%) → Sous-titre (65-100%)

---

#### b) **MainScreen** (`lib/main.dart`)

**Animation de transition entre écrans :**

```dart
_animationController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 300),
);
```

- **Durée** : 300ms
- **Usage** : Animation de transition lors du changement d'écran
- **Réinitialisation** : L'animation est réinitialisée et relancée à chaque changement d'écran

---

## 📊 Résumé des Types d'Animations

### Types utilisés :

1. **fadeIn** : Apparition en fondu (opacité 0 → 1)
   - Utilisé dans : LoginScreen, RegisterScreen, LoginEmailScreen, GoalsScreen

2. **slideY** : Glissement vertical (depuis le bas)
   - Utilisé dans : LoginScreen, RegisterScreen, LoginEmailScreen
   - Valeurs : `begin: 0.1` ou `begin: 0.2` (10% ou 20% depuis le bas)

3. **slideX** : Glissement horizontal (depuis la droite)
   - Utilisé dans : GoalsScreen
   - Valeur : `begin: 0.2` (20% depuis la droite)

4. **scale** : Agrandissement/rétrécissement
   - Utilisé dans : LoginScreen (logo)
   - Valeur : `begin: Offset(0.8, 0.8)` (80% → 100%)

5. **shake** : Secousse horizontale
   - Utilisé dans : LoginScreen, RegisterScreen, LoginEmailScreen (messages d'erreur)

6. **FadeTransition + Transform.scale** : Animation personnalisée
   - Utilisé dans : SplashScreen (image)

7. **SlideTransition + FadeTransition** : Animation personnalisée
   - Utilisé dans : SplashScreen (titre et sous-titre)

---

## ⏱️ Durées et Délais

### Durées standards :
- **fadeIn** : 200-500ms (par défaut)
- **slideY/slideX** : 300ms
- **shake** : Durée par défaut du package
- **SplashScreen** : 800ms (animation complète)

### Délais standards :
- **LoginScreen** : 200ms → 900ms (incrément de 100ms)
- **RegisterScreen** : 100ms → 900ms (incrément de 100ms)
- **LoginEmailScreen** : 100ms → 600ms (incrément de 100ms)
- **GoalsScreen** : `index * 50ms` (animation échelonnée)

---

## 🎯 Points d'Attention

### ✅ Bonnes pratiques observées :
1. **Animations échelonnées** : Les éléments apparaissent progressivement
2. **Délais cohérents** : Incréments de 100ms pour une séquence fluide
3. **Feedback visuel** : Shake pour les erreurs
4. **Performance** : Utilisation de `flutter_animate` (optimisé)

### ⚠️ Points à surveiller :
1. **TransactionsScreen** : Les animations ont été supprimées (comme demandé précédemment)
2. **Performance** : Les animations échelonnées dans GoalsScreen peuvent ralentir si beaucoup d'objectifs
3. **SplashScreen** : Animation complexe avec plusieurs AnimationControllers

---

## 🔧 Personnalisation

### Pour modifier les animations :

1. **Changer la durée** :
   ```dart
   .fadeIn(duration: 500.ms) // Au lieu de la durée par défaut
   ```

2. **Changer le délai** :
   ```dart
   .fadeIn(delay: 300.ms) // Au lieu de 200ms
   ```

3. **Changer la direction du slide** :
   ```dart
   .slideY(begin: 0.3) // Plus de distance depuis le bas
   .slideX(begin: -0.2) // Depuis la gauche au lieu de la droite
   ```

4. **Combiner plusieurs animations** :
   ```dart
   .animate()
   .fadeIn(delay: 200.ms)
   .slideY(begin: 0.2)
   .scale(begin: Offset(0.9, 0.9))
   ```

---

## 📝 Checklist des Animations

- [x] LoginScreen : Animations en cascade (200ms → 900ms)
- [x] RegisterScreen : Animations en cascade (100ms → 900ms)
- [x] LoginEmailScreen : Animations en cascade (100ms → 600ms)
- [x] GoalsScreen : Animations échelonnées (index * 50ms)
- [x] SplashScreen : Animation complexe séquencée (800ms)
- [x] MainScreen : Animation de transition (300ms)
- [x] Messages d'erreur : Shake animation
- [ ] TransactionsScreen : Animations supprimées (intentionnel)
- [ ] Autres écrans : Pas d'animations flutter_animate

