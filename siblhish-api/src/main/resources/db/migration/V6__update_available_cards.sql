-- Insérer les cartes disponibles dans la base de données
-- Ce script met à jour la liste des cartes disponibles en excluant 'balance_evolution_card'

INSERT INTO cards (code, title) VALUES
    ('bar_chart', 'Graphique Revenus vs Dépenses'),
    ('pie_chart', 'Répartition par Catégorie'),
    ('balance_card', 'Solde Actuel'),
    ('savings_card', 'Économies du Mois'),
    ('average_expense_card', 'Moyenne Mensuelle Dépenses'),
    ('top_expense_card', 'Dépense la Plus Élevée'),
    ('average_income_card', 'Moyenne Mensuelle Revenus'),
    ('transaction_count_card', 'Nombre de Transactions'),
    ('top_category_card', 'Top Catégorie'),
    ('scheduled_payments_card', 'Paiements Planifiés'),
    ('goals_progress_card', 'Progression des Objectifs')
ON CONFLICT (code) DO UPDATE SET title = EXCLUDED.title;

