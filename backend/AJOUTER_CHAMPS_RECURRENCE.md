# Ajout des champs de récurrence dans les DTOs de réponse

## Problème
Les DTOs de réponse (`ExpenseDto`, `IncomeDto`) ne retournent pas les champs de récurrence, donc le frontend ne peut pas afficher ces informations.

## Solution
Ajouter les champs suivants dans les DTOs de réponse :

### 1. ExpenseDto (si vous avez un DTO séparé)

```java
package ma.siblhish.dto;

import lombok.Data;
import java.time.LocalDateTime;
import java.util.List;

@Data
public class ExpenseDto {
    private Long id;
    private Double amount;
    private String method;
    private LocalDateTime date;
    private String description;
    private String location;
    private CategoryDto category;
    private String type = "expense";
    
    // Champs de récurrence à ajouter
    private Boolean isRecurring;
    private String recurrenceFrequency; // DAILY, WEEKLY, MONTHLY, YEARLY
    private LocalDateTime recurrenceEndDate;
    private List<Integer> recurrenceDaysOfWeek; // [1=Monday, 2=Tuesday, ...]
    private Integer recurrenceDayOfMonth; // 1-31
    private Integer recurrenceDayOfYear; // 1-365
}
```

### 2. IncomeDto (si vous avez un DTO séparé)

```java
package ma.siblhish.dto;

import lombok.Data;
import java.time.LocalDateTime;
import java.util.List;

@Data
public class IncomeDto {
    private Long id;
    private Double amount;
    private String method;
    private LocalDateTime date;
    private String description;
    private String source;
    private String type = "income";
    
    // Champs de récurrence à ajouter
    private Boolean isRecurring;
    private String recurrenceFrequency; // DAILY, WEEKLY, MONTHLY, YEARLY
    private LocalDateTime recurrenceEndDate;
    private List<Integer> recurrenceDaysOfWeek; // [1=Monday, 2=Tuesday, ...]
    private Integer recurrenceDayOfMonth; // 1-31
    private Integer recurrenceDayOfYear; // 1-365
}
```

### 3. Mapper dans le Service (si vous utilisez un mapper)

Si vous avez un mapper qui convertit `Expense` entity vers `ExpenseDto`, ajoutez ces lignes :

```java
// Dans ExpenseMapper ou ExpenseService
expenseDto.setIsRecurring(expense.getIsRecurring());
expenseDto.setRecurrenceFrequency(expense.getRecurrenceFrequency());
expenseDto.setRecurrenceEndDate(expense.getRecurrenceEndDate());
expenseDto.setRecurrenceDaysOfWeek(expense.getRecurrenceDaysOfWeek());
expenseDto.setRecurrenceDayOfMonth(expense.getRecurrenceDayOfMonth());
expenseDto.setRecurrenceDayOfYear(expense.getRecurrenceDayOfYear());
```

### 4. Vérifier les entités JPA

Assurez-vous que les entités `Expense` et `Income` ont bien ces champs :

```java
@Entity
public class Expense {
    // ... autres champs ...
    
    @Column(name = "is_recurring")
    private Boolean isRecurring = false;
    
    @Column(name = "recurrence_frequency")
    private String recurrenceFrequency;
    
    @Column(name = "recurrence_end_date")
    private LocalDateTime recurrenceEndDate;
    
    @ElementCollection
    @CollectionTable(name = "expense_recurrence_days_of_week", joinColumns = @JoinColumn(name = "expense_id"))
    @Column(name = "day_of_week")
    private List<Integer> recurrenceDaysOfWeek;
    
    @Column(name = "recurrence_day_of_month")
    private Integer recurrenceDayOfMonth;
    
    @Column(name = "recurrence_day_of_year")
    private Integer recurrenceDayOfYear;
}
```

### 5. Endpoint GET /home/transactions/{userId}

Vérifiez que le mapper dans cet endpoint inclut bien tous les champs de récurrence.

## Format JSON attendu par le frontend

```json
{
    "id": 19,
    "amount": 30.0,
    "method": "CREDIT_CARD",
    "date": "2026-02-14T01:47:05",
    "description": "des",
    "location": "desc",
    "category": {
        "id": 3,
        "name": "Café",
        "icon": "☕",
        "color": "#8B4513"
    },
    "type": "expense",
    "isRecurring": true,
    "recurrenceFrequency": "WEEKLY",
    "recurrenceEndDate": "2026-12-31T23:59:59",
    "recurrenceDaysOfWeek": [1, 3, 5],
    "recurrenceDayOfMonth": null,
    "recurrenceDayOfYear": null
}
```

## Notes importantes

1. **isRecurring** : Boolean (peut être `null`, le frontend gère `false` par défaut)
2. **recurrenceFrequency** : String nullable (DAILY, WEEKLY, MONTHLY, YEARLY)
3. **recurrenceEndDate** : LocalDateTime nullable (format ISO: "2026-12-31T23:59:59")
4. **recurrenceDaysOfWeek** : List<Integer> nullable (1=Monday, 7=Sunday)
5. **recurrenceDayOfMonth** : Integer nullable (1-31)
6. **recurrenceDayOfYear** : Integer nullable (1-365)

Tous ces champs peuvent être `null` si la transaction n'est pas récurrente.

