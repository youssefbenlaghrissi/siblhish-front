# Explication : Quand `@PostConstruct` est exécuté

## 🔄 Cycle de vie d'un Bean Spring

Quand Spring crée un bean (comme `FcmNotificationService`), voici l'ordre d'exécution :

```
1. Constructeur appelé
   ↓
2. Injection des dépendances (@Autowired, @Value, etc.)
   ↓
3. @PostConstruct exécuté ← VOTRE MÉTHODE initialize()
   ↓
4. Bean prêt à être utilisé
```

## ⏰ Quand `initialize()` est appelée ?

La méthode `initialize()` avec `@PostConstruct` est appelée :

1. **Après** que Spring ait créé l'instance de `FcmNotificationService`
2. **Après** que toutes les dépendances soient injectées (`@Value` pour `serviceAccountPath` et `serviceAccountClasspath`)
3. **Avant** que le bean soit disponible pour être utilisé par d'autres services
4. **Une seule fois** au démarrage de l'application

## 📋 Ordre d'exécution au démarrage

Quand vous démarrez votre application Spring Boot :

```
1. Spring Boot démarre
   ↓
2. Spring scanne les packages pour trouver les beans
   ↓
3. Spring crée les beans (dans un ordre dépendant des dépendances)
   ↓
4. Pour chaque bean avec @PostConstruct :
   - Constructeur appelé
   - Dépendances injectées
   - @PostConstruct exécuté ← initialize() ici
   ↓
5. Application prête (SiblhishApiApplication.main() continue)
   ↓
6. Les endpoints REST sont disponibles
```

## ⚠️ Problèmes possibles

### 1. Exception silencieuse

Si une exception est levée dans `@PostConstruct`, elle peut :
- Empêcher le bean d'être créé
- Ou être catchée et ignorée (dans votre cas, elle est catchée mais `firebaseMessaging` reste `null`)

### 2. Ordre d'exécution

Si `NotificationService` essaie d'utiliser `FcmNotificationService` avant que `initialize()` soit terminé, il y aura un problème.

### 3. Fichier non trouvé

Si le fichier JSON n'est pas trouvé au moment de `@PostConstruct`, l'initialisation échoue silencieusement.

## 🔍 Comment vérifier que `initialize()` est appelée ?

Avec les nouveaux logs que j'ai ajoutés, vous devriez voir au démarrage :

```
🔧 Début de l'initialisation de Firebase...
🔧 Chemin du service account (classpath): firebase/siblhish-app-firebase-adminsdk-fbsvc-05ce4c5f95.json
...
```

**Si vous ne voyez PAS ces logs**, cela signifie que :
- Le bean `FcmNotificationService` n'est pas créé
- Ou il y a une erreur avant même d'arriver à `initialize()`

## 🛠️ Solutions

### Solution 1 : Vérifier les logs au démarrage

Redémarrez votre backend et cherchez les logs qui commencent par `🔧` ou `✅` ou `❌`.

### Solution 2 : Vérifier que le bean est créé

Ajoutez un log dans le constructeur (s'il existe) ou créez-en un :

```java
public FcmNotificationService() {
    log.info("🏗️ FcmNotificationService créé");
}
```

### Solution 3 : Vérifier les dépendances

Assurez-vous que `firebase-admin` est bien dans votre `pom.xml` ou `build.gradle`.

## 📝 Résumé

- `@PostConstruct` est exécuté **automatiquement** par Spring
- C'est exécuté **une seule fois** au démarrage
- C'est exécuté **après** l'injection des dépendances
- Si ça échoue, le bean peut être créé mais `firebaseMessaging` reste `null`

**Action :** Redémarrez le backend et partagez les logs complets du démarrage, surtout ceux qui commencent par `🔧`, `✅`, ou `❌`.

