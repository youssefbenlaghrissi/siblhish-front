# Vérifier RecurringTransactionService

## 🔍 Problème

Le service `RecurringTransactionService` doit créer un nouveau revenu et générer une notification, mais vous ne recevez pas de notification.

## ✅ Points à vérifier dans le backend

### 1. Le service existe et est activé

Vérifiez que le service `RecurringTransactionService` existe dans votre projet backend Spring Boot :

**Fichier :** `src/main/java/ma/siblhish/service/RecurringTransactionService.java`

Le service doit avoir :
- `@Service` annotation
- `@EnableScheduling` ou être dans une classe avec `@EnableScheduling`
- Une méthode `@Scheduled` qui s'exécute régulièrement

### 2. La méthode scheduled s'exécute

Vérifiez que la méthode scheduled est bien configurée :

```java
@Scheduled(cron = "0 0 * * * *") // Toutes les heures
// ou
@Scheduled(fixedRate = 3600000) // Toutes les heures
public void processRecurringTransactions() {
    // Logique pour créer les nouveaux revenus
}
```

### 3. Le service crée les nouveaux revenus

Vérifiez que le service :
1. Récupère les revenus récurrents avec `isRecurring = true`
2. Calcule les prochaines dates d'échéance
3. Crée de nouveaux revenus pour les dates échues

### 4. Le service génère les notifications

Vérifiez que le service :
1. Récupère le token FCM de l'utilisateur
2. Appelle le service FCM pour envoyer la notification
3. Crée une entrée dans la table `notifications` (si applicable)

## 🔧 Vérifications à faire

### Vérification 1 : Logs du backend

Vérifiez les logs du backend pour voir si :
- Le service s'exécute (logs de démarrage)
- Les revenus récurrents sont trouvés
- Les nouveaux revenus sont créés
- Les notifications sont envoyées

### Vérification 2 : Base de données

Vérifiez en base de données :
1. Le revenu récurrent existe avec `isRecurring = true`
2. La date d'échéance est correcte (13/02/2026 à 03:28)
3. Le token FCM de l'utilisateur est présent dans la table `users`

```sql
-- Vérifier le revenu récurrent
SELECT * FROM incomes WHERE is_recurring = true AND user_id = VOTRE_USER_ID;

-- Vérifier le token FCM
SELECT id, email, fcm_token FROM users WHERE id = VOTRE_USER_ID;
```

### Vérification 3 : Service FCM

Vérifiez que le service FCM est bien configuré :
- Les credentials Firebase sont configurés
- Le service peut envoyer des notifications
- Les erreurs FCM sont loggées

## 🐛 Problèmes possibles

### Problème 1 : Le service ne s'exécute pas

**Solution :**
- Vérifiez que `@EnableScheduling` est présent dans la classe de configuration
- Vérifiez que le cron expression est correct
- Vérifiez les logs pour voir si le service démarre

### Problème 2 : La date n'est pas encore échue

**Solution :**
- Si la date est 13/02/2026 à 03:28, le service ne créera le revenu que quand cette date sera atteinte
- Pour tester, créez un revenu récurrent avec une date dans le passé ou aujourd'hui

### Problème 3 : Le token FCM n'est pas présent

**Solution :**
- Connectez-vous à l'application pour envoyer le token FCM
- Vérifiez que le token est bien enregistré en base de données

### Problème 4 : Le service FCM n'est pas configuré

**Solution :**
- Vérifiez que le service FCM est bien injecté
- Vérifiez que les credentials Firebase sont corrects
- Testez l'envoi d'une notification manuellement

## 📝 Checklist de debug

- [ ] Le service `RecurringTransactionService` existe
- [ ] Le service a l'annotation `@Service`
- [ ] `@EnableScheduling` est activé
- [ ] La méthode `@Scheduled` s'exécute (vérifier les logs)
- [ ] Les revenus récurrents sont trouvés
- [ ] Les nouveaux revenus sont créés
- [ ] Le token FCM est présent en base de données
- [ ] Le service FCM est configuré
- [ ] Les notifications sont envoyées (vérifier les logs FCM)
- [ ] La date d'échéance est correcte (pas dans le futur trop lointain pour les tests)

## 🧪 Test rapide

Pour tester rapidement :
1. Créez un revenu récurrent avec une date **aujourd'hui** ou **demain**
2. Attendez que le batch job s'exécute (selon la fréquence configurée)
3. Vérifiez les logs du backend
4. Vérifiez si un nouveau revenu a été créé
5. Vérifiez si une notification a été envoyée

