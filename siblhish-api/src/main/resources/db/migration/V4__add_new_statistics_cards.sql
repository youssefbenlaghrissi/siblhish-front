-- Migration pour ajouter les nouvelles cartes statistiques
-- Évolution du solde (ID: 11) et Progression des objectifs (ID: 12)

INSERT INTO cards (code, title) VALUES
('balance_evolution_card', 'Évolution du Solde'),
('goals_progress_card', 'Progression des Objectifs')
ON CONFLICT (code) DO NOTHING;

