# Debug : Notifications pour Revenus Récurrents

## 🔍 Problème identifié

Vous avez créé un revenu récurrent avec une date dans le futur (13/02/2026 à 03:28) mais vous ne recevez pas de notification.

## ✅ Points à vérifier

### 1. Token FCM envoyé au backend ?

**Vérification dans les logs :**
- Si vous voyez `⚠️ UserId non défini, token FCM non envoyé` → Le token n'est pas envoyé
- Si vous voyez `✅ Token FCM envoyé au backend` → Le token est envoyé

**Solution :**
- Vous devez être connecté pour que le token soit envoyé
- Le token est envoyé automatiquement après la connexion

### 2. Le backend a-t-il un batch job pour les notifications ?

**Vérification :**
- Le backend doit avoir un service `@Scheduled` qui vérifie les revenus récurrents
- Ce service doit calculer les prochaines dates d'échéance
- Il doit envoyer des notifications via FCM

**Si le batch job n'existe pas :**
- Il faut le créer dans le backend
- Voir les instructions ci-dessous

### 3. Les revenus récurrents ont-ils un champ notificationOption ?

**Problème identifié :**
- Le modèle `Income` n'a **pas** de champ `notificationOption`
- Seul `ScheduledPayment` a ce champ
- Les revenus récurrents ne sont peut-être pas configurés pour les notifications

## 🔧 Solutions

### Solution 1 : Vérifier que le token FCM est envoyé

1. Connectez-vous à l'application
2. Vérifiez les logs : vous devriez voir `✅ Token FCM envoyé au backend`
3. Vérifiez en base de données que le token est bien enregistré :
   ```sql
   SELECT id, email, fcm_token FROM users WHERE id = VOTRE_USER_ID;
   ```

### Solution 2 : Créer le batch job dans le backend

Le backend doit avoir un service qui :
1. Vérifie les revenus récurrents avec `isRecurring = true`
2. Calcule les prochaines dates d'échéance selon `recurrenceFrequency`
3. Envoie des notifications via FCM pour les dates à venir

**Exemple de service à créer :**

```java
@Service
@EnableScheduling
public class RecurringIncomeNotificationService {
    
    @Autowired
    private IncomeRepository incomeRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private FcmNotificationService fcmService;
    
    // Exécuter toutes les heures
    @Scheduled(cron = "0 0 * * * *")
    public void checkRecurringIncomes() {
        // 1. Récupérer tous les revenus récurrents
        List<Income> recurringIncomes = incomeRepository.findByIsRecurringTrue();
        
        // 2. Pour chaque revenu récurrent
        for (Income income : recurringIncomes) {
            // 3. Calculer la prochaine date d'échéance
            DateTime nextDueDate = calculateNextDueDate(income);
            
            // 4. Si la date est aujourd'hui ou demain, envoyer notification
            if (shouldSendNotification(nextDueDate)) {
                // 5. Récupérer le token FCM de l'utilisateur
                User user = userRepository.findById(income.getUserId()).orElse(null);
                if (user != null && user.getFcmToken() != null) {
                    // 6. Envoyer la notification
                    fcmService.sendNotification(
                        user.getFcmToken(),
                        "Revenu récurrent à venir",
                        "Vous avez un revenu de " + income.getAmount() + " MAD prévu le " + nextDueDate
                    );
                }
            }
        }
    }
    
    private DateTime calculateNextDueDate(Income income) {
        // Logique pour calculer la prochaine date selon recurrenceFrequency
        // DAILY, WEEKLY, MONTHLY, YEARLY
    }
    
    private boolean shouldSendNotification(DateTime dueDate) {
        // Vérifier si on doit envoyer la notification
        // Par exemple : si c'est aujourd'hui ou demain
    }
}
```

### Solution 3 : Utiliser ScheduledPayment au lieu de Income récurrent

Si vous voulez des notifications, utilisez `ScheduledPayment` qui a déjà le champ `notificationOption` :
- `ON_DUE_DATE` : Notification à la date d'échéance
- `ONE_DAY_BEFORE` : Notification 1 jour avant
- `THREE_DAYS_BEFORE` : Notification 3 jours avant

## 📝 Checklist de debug

- [ ] Token FCM envoyé au backend (vérifier les logs)
- [ ] Token FCM présent en base de données
- [ ] Batch job existe dans le backend
- [ ] Batch job est activé (`@EnableScheduling`)
- [ ] Service FCM configuré dans le backend
- [ ] Revenu récurrent créé avec la bonne date
- [ ] Date d'échéance calculée correctement

## 🆘 Si le problème persiste

1. Vérifiez les logs du backend pour voir si le batch job s'exécute
2. Vérifiez que le service FCM est bien configuré
3. Testez avec un `ScheduledPayment` au lieu d'un `Income` récurrent

