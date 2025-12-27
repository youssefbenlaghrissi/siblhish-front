# Correction de la requête SQL pour les budgets hebdomadaires

## Problème

L'erreur suivante se produit lors de la récupération des budgets :
```
ERROR: operator does not exist: timestamp without time zone - integer
```

## Cause

Dans la requête SQL du `BudgetService.java`, la partie `WEEKLY` essaie de soustraire un entier directement d'un `date` :

```sql
WHEN 'WEEKLY' THEN (CURRENT_DATE - (EXTRACT(DOW FROM CURRENT_DATE)::int - 1))::timestamp
```

PostgreSQL ne permet pas de soustraire directement un entier d'un `date`. Il faut utiliser `INTERVAL`.

## Solution

### Option 1 : Utiliser DATE_TRUNC (Recommandé)

Remplacer la partie WEEKLY dans la requête SQL par :

**Pour le début de la semaine (start_date) :**
```sql
WHEN 'WEEKLY' THEN DATE_TRUNC('week', CURRENT_DATE)::timestamp
```

**Pour la fin de la semaine (end_date) :**
```sql
WHEN 'WEEKLY' THEN (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '6 days 23 hours 59 minutes 59 seconds')::timestamp
```

### Option 2 : Utiliser INTERVAL avec multiplication

**Pour le début de la semaine :**
```sql
WHEN 'WEEKLY' THEN (CURRENT_DATE - INTERVAL '1 day' * (EXTRACT(DOW FROM CURRENT_DATE)::int - 1))::timestamp
```

**Pour la fin de la semaine :**
```sql
WHEN 'WEEKLY' THEN (CURRENT_DATE + INTERVAL '1 day' * (7 - EXTRACT(DOW FROM CURRENT_DATE)::int) - INTERVAL '1 second')::timestamp
```

## Fichier à modifier

Dans le backend Spring Boot, modifier le fichier :
- `src/main/java/ma/siblhish/service/BudgetService.java`

## Requête SQL complète corrigée

Voici la requête complète avec la correction pour WEEKLY :

```sql
SELECT
    b.id,
    b.user_id,
    b.amount,
    b.period,
    b.start_date,
    b.end_date,
    b.is_active,
    b.category_id,
    b.creation_date,
    b.update_date,
    COALESCE((
        SELECT SUM(e.amount)
        FROM expenses e
        WHERE e.user_id = b.user_id
          AND e.creation_date >= (
              CASE
                  WHEN b.start_date IS NOT NULL THEN b.start_date::timestamp
                  ELSE CASE b.period
                      WHEN 'DAILY' THEN CURRENT_DATE::timestamp
                      WHEN 'WEEKLY' THEN DATE_TRUNC('week', CURRENT_DATE)::timestamp
                      WHEN 'MONTHLY' THEN DATE_TRUNC('month', CURRENT_DATE)::timestamp
                      WHEN 'YEARLY' THEN DATE_TRUNC('year', CURRENT_DATE)::timestamp
                  END
              END
          )
          AND e.creation_date <= (
              CASE
                  WHEN b.end_date IS NOT NULL THEN (b.end_date + INTERVAL '1 day' - INTERVAL '1 second')::timestamp
                  ELSE CASE b.period
                      WHEN 'DAILY' THEN (CURRENT_DATE + INTERVAL '1 day' - INTERVAL '1 second')::timestamp
                      WHEN 'WEEKLY' THEN (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '6 days 23 hours 59 minutes 59 seconds')::timestamp
                      WHEN 'MONTHLY' THEN (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' - INTERVAL '1 second')::timestamp
                      WHEN 'YEARLY' THEN (DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year' - INTERVAL '1 second')::timestamp
                  END
              END
          )
          AND (b.category_id IS NULL OR e.category_id = b.category_id)
    ), 0) as spent
FROM budgets b
WHERE b.user_id = ?
```

## Note importante

`DATE_TRUNC('week', date)` dans PostgreSQL retourne le lundi de la semaine (ISO 8601 standard). Si vous voulez que la semaine commence le dimanche, utilisez :

```sql
WHEN 'WEEKLY' THEN (DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '1 day')::timestamp
```

Pour la fin de la semaine (dimanche) :
```sql
WHEN 'WEEKLY' THEN (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '5 days 23 hours 59 minutes 59 seconds')::timestamp
```

