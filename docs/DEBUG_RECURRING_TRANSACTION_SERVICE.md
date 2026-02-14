# Debug : RecurringTransactionService - Notifications non reçues

## 🔍 Problème

Vous avez créé un revenu récurrent (date = 13/02/2026 à 03:28) mais vous ne recevez pas de notification via le batch qui génère les notifications.

## ✅ Vérifications à faire dans le backend

### 1. Le service existe et est activé

**Fichier :** `src/main/java/ma/siblhish/service/RecurringTransactionService.java`

Vérifiez que :
- ✅ Le service a l'annotation `@Service`
- ✅ `@EnableScheduling` est activé (dans la classe de configuration ou le service)
- ✅ La méthode `@Scheduled` est bien configurée

**Exemple attendu :**
```java
@Service
public class RecurringTransactionService {
    
    @Scheduled(cron = "0 0 * * * *") // Toutes les heures
    // ou
    @Scheduled(fixedRate = 3600000) // Toutes les heures
    public void processRecurringTransactions() {
        // Logique
    }
}
```

### 2. Le service crée les nouveaux revenus

Vérifiez que le service :
1. ✅ Récupère les revenus récurrents avec `isRecurring = true`
2. ✅ Calcule les prochaines dates d'échéance selon `recurrenceFrequency`
3. ✅ Crée de nouveaux revenus pour les dates échues

### 3. Le service génère les notifications

Vérifiez que le service :
1. ✅ Récupère le token FCM de l'utilisateur depuis la base de données
2. ✅ Appelle le service FCM pour envoyer la notification
3. ✅ Gère les erreurs (token null, erreur FCM, etc.)

## 🐛 Problèmes possibles

### Problème 1 : La date est dans le futur

**Votre cas :** Date = 13/02/2026 à 03:28

**Solution :**
- Le service ne créera le revenu que quand cette date sera atteinte
- Pour tester, créez un revenu récurrent avec une date **aujourd'hui** ou **demain**
- Ou modifiez temporairement la date dans la base de données pour tester

### Problème 2 : Le token FCM n'est pas présent

**Vérification :**
```sql
SELECT id, email, fcm_token FROM users WHERE id = VOTRE_USER_ID;
```

**Solution :**
- Connectez-vous à l'application pour envoyer le token FCM
- Vérifiez les logs : `✅ Token FCM envoyé au backend`

### Problème 3 : Le service FCM n'est pas configuré

**Vérification :**
- Le service FCM existe et est injecté
- Les credentials Firebase sont configurés
- Le service peut envoyer des notifications

### Problème 4 : Le service ne s'exécute pas

**Vérification :**
- Vérifiez les logs du backend pour voir si le service démarre
- Vérifiez que `@EnableScheduling` est présent dans la configuration
- Vérifiez que le cron expression est correct

### Problème 5 : La logique de calcul de date est incorrecte

**Vérification :**
- Vérifiez comment le service calcule les prochaines dates
- Vérifiez que la date 13/02/2026 à 03:28 est bien prise en compte
- Vérifiez que le fuseau horaire est correct

## 📝 Checklist de debug

### Dans le backend :

- [ ] Le service `RecurringTransactionService` existe
- [ ] Le service a l'annotation `@Service`
- [ ] `@EnableScheduling` est activé
- [ ] La méthode `@Scheduled` s'exécute (vérifier les logs)
- [ ] Les revenus récurrents sont trouvés
- [ ] Les nouveaux revenus sont créés
- [ ] Le service FCM est injecté et fonctionne
- [ ] Les notifications sont envoyées (vérifier les logs FCM)

### Dans la base de données :

- [ ] Le revenu récurrent existe avec `is_recurring = true`
- [ ] La date d'échéance est correcte (13/02/2026 à 03:28)
- [ ] Le token FCM de l'utilisateur est présent dans `users.fcm_token`

### Dans l'application :

- [ ] Vous êtes connecté (pour envoyer le token FCM)
- [ ] Le token FCM est envoyé au backend (vérifier les logs)
- [ ] Les permissions de notifications sont accordées

## 🧪 Test rapide

Pour tester rapidement :

1. **Modifiez temporairement la date** dans la base de données :
   ```sql
   UPDATE incomes 
   SET date = CURRENT_DATE + INTERVAL '1 day'
   WHERE is_recurring = true AND user_id = VOTRE_USER_ID;
   ```

2. **Attendez que le batch job s'exécute** (selon la fréquence configurée)

3. **Vérifiez les logs du backend** pour voir :
   - Si le service s'exécute
   - Si un nouveau revenu est créé
   - Si une notification est envoyée

4. **Vérifiez en base de données** :
   ```sql
   -- Vérifier si un nouveau revenu a été créé
   SELECT * FROM incomes WHERE user_id = VOTRE_USER_ID ORDER BY date DESC LIMIT 5;
   ```

## 🔧 Code à vérifier dans RecurringTransactionService

Le service doit avoir quelque chose comme :

```java
@Service
public class RecurringTransactionService {
    
    @Autowired
    private IncomeRepository incomeRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private FcmNotificationService fcmService;
    
    @Scheduled(cron = "0 0 * * * *") // Toutes les heures
    public void processRecurringTransactions() {
        // 1. Récupérer les revenus récurrents
        List<Income> recurringIncomes = incomeRepository.findByIsRecurringTrue();
        
        for (Income income : recurringIncomes) {
            // 2. Calculer la prochaine date
            LocalDateTime nextDueDate = calculateNextDueDate(income);
            
            // 3. Si la date est échue, créer le nouveau revenu
            if (isDueDateReached(nextDueDate)) {
                createNewIncome(income, nextDueDate);
                
                // 4. Envoyer la notification
                sendNotification(income, nextDueDate);
            }
        }
    }
    
    private void sendNotification(Income income, LocalDateTime dueDate) {
        User user = userRepository.findById(income.getUserId()).orElse(null);
        
        if (user != null && user.getFcmToken() != null) {
            String title = "Nouveau revenu récurrent";
            String body = String.format("Vous avez un revenu de %.2f MAD prévu le %s", 
                income.getAmount(), dueDate);
            
            fcmService.sendNotification(user.getFcmToken(), title, body);
        } else {
            // Logger l'erreur : token FCM manquant
            log.warn("Token FCM manquant pour l'utilisateur {}", income.getUserId());
        }
    }
}
```

## 🆘 Si le problème persiste

1. **Vérifiez les logs du backend** pour voir les erreurs exactes
2. **Testez avec une date proche** (aujourd'hui ou demain)
3. **Vérifiez que le token FCM est bien envoyé** depuis l'application
4. **Testez l'envoi manuel d'une notification** pour vérifier que FCM fonctionne

