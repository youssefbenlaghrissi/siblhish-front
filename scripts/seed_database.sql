-- Script SQL pour alimenter la base de données PostgreSQL
-- Base de données: siblhish
-- Utilisateur: youssefbenlaghrissi

-- 1. Créer un utilisateur de test
INSERT INTO users (first_name, last_name, email, password, type, language, monthly_salary, creation_date, update_date)
VALUES 
  ('Youssef', 'Benlaghrissi', 'youssef@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'EMPLOYEE', 'fr', 8000.00, NOW(), NOW())
ON CONFLICT (email) DO NOTHING
RETURNING id;

-- Récupérer l'ID de l'utilisateur créé (remplacer 1 par l'ID réel après la première insertion)
-- Pour ce script, on suppose que l'ID est 1

-- 2. Créer des catégories par défaut
INSERT INTO categories (name, icon, color, creation_date, update_date)
VALUES 
  ('Alimentation', '🍔', '#FF6B6B', NOW(), NOW()),
  ('Transport', '🚗', '#4ECDC4', NOW(), NOW()),
  ('Loisirs', '🎬', '#45B7D1', NOW(), NOW()),
  ('Santé', '🏥', '#96CEB4', NOW(), NOW()),
  ('Shopping', '🛍️', '#FFEAA7', NOW(), NOW()),
  ('Éducation', '📚', '#DDA0DD', NOW(), NOW())
ON CONFLICT DO NOTHING;

-- 3. Associer les catégories à l'utilisateur (relation ManyToMany)
-- Remplacer 1 par l'ID réel de l'utilisateur
INSERT INTO user_categories (user_id, category_id)
SELECT 1, id FROM categories WHERE name IN ('Alimentation', 'Transport', 'Loisirs', 'Santé', 'Shopping', 'Éducation')
ON CONFLICT DO NOTHING;

-- 4. Créer des revenus
INSERT INTO incomes (user_id, amount, payment_method, date, description, source, is_recurring, recurrence_frequency, creation_date, update_date)
VALUES 
  (1, 8000.00, 'BANK_TRANSFER', NOW() - INTERVAL '15 days', 'Salaire mensuel', 'Salaire', true, 'MONTHLY', NOW(), NOW()),
  (1, 2000.00, 'MOBILE_PAYMENT', NOW() - INTERVAL '10 days', 'Projet freelance', 'Freelance', false, NULL, NOW(), NOW()),
  (1, 500.00, 'CASH', NOW() - INTERVAL '5 days', 'Vente occasionnelle', 'Vente', false, NULL, NOW(), NOW())
ON CONFLICT DO NOTHING;

-- 5. Créer des dépenses
INSERT INTO expenses (user_id, category_id, amount, payment_method, date, description, location, is_recurring, recurrence_frequency, creation_date, update_date)
SELECT 
  1,
  (SELECT id FROM categories WHERE name = 'Alimentation' LIMIT 1),
  500.00,
  'CREDIT_CARD',
  NOW() - INTERVAL '8 days',
  'Courses alimentaires',
  'Supermarché',
  false,
  NULL,
  NOW(),
  NOW()
ON CONFLICT DO NOTHING;

INSERT INTO expenses (user_id, category_id, amount, payment_method, date, description, location, is_recurring, recurrence_frequency, creation_date, update_date)
SELECT 
  1,
  (SELECT id FROM categories WHERE name = 'Transport' LIMIT 1),
  300.00,
  'CASH',
  NOW() - INTERVAL '6 days',
  'Essence',
  'Station-service',
  false,
  NULL,
  NOW(),
  NOW()
ON CONFLICT DO NOTHING;

INSERT INTO expenses (user_id, category_id, amount, payment_method, date, description, location, is_recurring, recurrence_frequency, creation_date, update_date)
SELECT 
  1,
  (SELECT id FROM categories WHERE name = 'Loisirs' LIMIT 1),
  200.00,
  'CREDIT_CARD',
  NOW() - INTERVAL '4 days',
  'Cinéma',
  'Cinéma',
  false,
  NULL,
  NOW(),
  NOW()
ON CONFLICT DO NOTHING;

INSERT INTO expenses (user_id, category_id, amount, payment_method, date, description, location, is_recurring, recurrence_frequency, creation_date, update_date)
SELECT 
  1,
  (SELECT id FROM categories WHERE name = 'Santé' LIMIT 1),
  100.00,
  'CASH',
  NOW() - INTERVAL '2 days',
  'Consultation médicale',
  'Cabinet médical',
  false,
  NULL,
  NOW(),
  NOW()
ON CONFLICT DO NOTHING;

-- 6. Créer des objectifs
INSERT INTO goals (user_id, category_id, name, description, target_amount, current_amount, target_date, is_achieved, creation_date, update_date)
VALUES 
  (1, NULL, 'Vacances d''été', 'Épargner pour les vacances d''été', 10000.00, 2500.00, DATE '2025-07-01', false, NOW(), NOW()),
  (1, (SELECT id FROM categories WHERE name = 'Éducation' LIMIT 1), 'Formation professionnelle', 'Épargner pour une formation', 5000.00, 1200.00, DATE '2025-06-01', false, NOW(), NOW())
ON CONFLICT DO NOTHING;

-- 7. Afficher un résumé
SELECT 
  'Utilisateurs créés: ' || COUNT(*) as summary
FROM users;

SELECT 
  'Catégories créées: ' || COUNT(*) as summary
FROM categories;

SELECT 
  'Revenus créés: ' || COUNT(*) as summary
FROM incomes WHERE user_id = 1;

SELECT 
  'Dépenses créées: ' || COUNT(*) as summary
FROM expenses WHERE user_id = 1;

SELECT 
  'Objectifs créés: ' || COUNT(*) as summary
FROM goals WHERE user_id = 1;

