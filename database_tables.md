# Base de données `emploi` — Inventaire des tables

> Snapshot du **2026-05-10** • Connexion : `mysql://root@127.0.0.1:3306/emploi`
> **Total : 65 tables réelles** (compté via `information_schema.tables`)

---

## Note sur les migrations Laravel

Le nombre de **fichiers de migration** ne correspond **pas** au nombre de tables :

| Mesure | Valeur |
|---|---:|
| Fichiers de migration sur disque (`database/migrations/`) | **99** |
| Migrations effectivement exécutées (table `migrations`) | **54** |
| Dont `create_*_table` (créent une ou plusieurs tables) | **32** |
| Dont `add_* / fix_* / ensure_* / extend_* / sync_* / optimize_*` (alter / index / corrections de colonnes) | **67** |
| **Tables présentes en base** | **65** |

Pourquoi 32 migrations *create* → 65 tables ? Plusieurs migrations créent **plusieurs tables d'un coup** (groupées) :

- `create_training_core_tables`
- `create_training_quiz_tables`
- `create_essential_orphan_tables`
- `create_support_orphan_tables`
- `create_permission_tables`
- `create_queue_tables_if_missing`

Et beaucoup d'autres migrations sont uniquement des **`ALTER TABLE`** : ajout de colonnes (`fcm_token`, `remember_token`, `is_boosted`, `cv_snapshot_*`…), corrections de types (UUID, longueur de phone…), backfill d'index de performance, etc. Elles **n'ajoutent pas** de table — elles font évoluer le schéma existant.

---

## Vue d'ensemble par domaine

| Domaine | Nb de tables |
|---|---|
| Auth & Utilisateurs | 16 |
| CV & Portfolio | 7 |
| Offres d'emploi & Candidatures | 8 |
| Formations & Quiz | 11 |
| Messagerie & Notifications | 4 |
| Équipes recruteurs | 2 |
| Administration & Audit | 3 |
| Appels d'offres & Concours | 3 |
| Référentiels | 1 |
| Système Laravel (queue, cache, telescope) | 10 |
| **Total** | **65** |

---

## 1. Auth & Utilisateurs (16)

| Table | Lignes | Colonnes | Taille (Mo) |
|---|---:|---:|---:|
| `users` | 15 | 24 | 0.16 |
| `candidate_accounts` | 7 | 8 | 0.03 |
| `candidate_profiles` | 7 | 37 | 0.06 |
| `employer_accounts` | 0 | 7 | 0.03 |
| `employer_profiles` | 5 | 31 | 0.08 |
| `admin_accounts` | 3 | 9 | 0.05 |
| `login_attempts` | 2 | 7 | 0.02 |
| `otp_codes` | 34 | 9 | 0.08 |
| `sessions` | 5 | 6 | 0.05 |
| `personal_access_tokens` | 22 | 10 | 0.06 |
| `connected_devices` | 0 | 9 | 0.03 |
| `roles` | 4 | 5 | 0.03 |
| `permissions` | 9 | 5 | 0.03 |
| `model_has_roles` | 11 | 3 | 0.03 |
| `model_has_permissions` | 0 | 3 | 0.02 |
| `role_has_permissions` | 18 | 2 | 0.02 |

## 2. CV & Portfolio (7)

| Table | Lignes | Colonnes | Taille (Mo) |
|---|---:|---:|---:|
| `user_cvs` | 4 | 35 | 0.03 |
| `cv_sections` | 0 | 21 | 0.05 |
| `cv_versions` | 0 | 8 | 0.05 |
| `imported_cvs` | 0 | 8 | 0.03 |
| `portfolio_items` | 0 | 21 | 0.05 |
| `candidate_documents` | 9 | 10 | 0.03 |
| `experience_verifications` | 2 | 23 | 0.16 |

## 3. Offres d'emploi & Candidatures (8)

| Table | Lignes | Colonnes | Taille (Mo) |
|---|---:|---:|---:|
| `job_offers` | 23 | 40 | 0.30 |
| `applications` | 36 | 22 | 0.23 |
| `saved_items` | 0 | 6 | 0.06 |
| `talent_shortlists` | 0 | 7 | 0.05 |
| `selected_candidates` | 0 | 8 | 0.06 |
| `offer_reports` | 0 | 8 | 0.05 |
| `ai_match_logs` | 0 | 8 | 0.06 |
| `interview_suggestions` | 0 | 7 | 0.03 |

## 4. Formations & Quiz (11)

| Table | Lignes | Colonnes | Taille (Mo) |
|---|---:|---:|---:|
| `training_offers` | 6 | 31 | 0.13 |
| `training_modules` | 6 | 12 | 0.05 |
| `training_module_sequences` | 7 | 12 | 0.05 |
| `training_enrollments` | 4 | 19 | 0.11 |
| `training_module_quizzes` | 0 | 21 | 0.06 |
| `training_quiz_questions` | 0 | 11 | 0.03 |
| `training_quiz_options` | 8 | 7 | 0.03 |
| `training_quiz_attempts` | 3 | 22 | 0.09 |
| `training_quiz_versions` | 0 | 9 | 0.08 |
| `training_question_bank_items` | 0 | 12 | 0.03 |
| `training_reviews` | 0 | 7 | 0.05 |

## 5. Messagerie & Notifications (4)

| Table | Lignes | Colonnes | Taille (Mo) |
|---|---:|---:|---:|
| `conversations` | 21 | 9 | 0.14 |
| `messages` | 13 | 10 | 0.09 |
| `notifications` | 46 | 12 | 0.08 |
| `chatbot_sessions` | 0 | 7 | 0.05 |

## 6. Équipes recruteurs (2)

| Table | Lignes | Colonnes | Taille (Mo) |
|---|---:|---:|---:|
| `team_members` | 4 | 9 | 0.06 |
| `team_invitations` | 5 | 14 | 0.08 |

## 7. Administration & Audit (3)

| Table | Lignes | Colonnes | Taille (Mo) |
|---|---:|---:|---:|
| `admin_invitations` | 9 | 11 | 0.05 |
| `admin_audit_logs` | 0 | 10 | 0.02 |
| `activity_logs` | 43 | 8 | 0.09 |

## 8. Appels d'offres & Concours (3)

| Table | Lignes | Colonnes | Taille (Mo) |
|---|---:|---:|---:|
| `tenders` | 0 | 27 | 0.06 |
| `fp_contests` | 0 | 21 | 0.03 |
| `internal_votes` | 0 | 7 | 0.05 |

## 9. Référentiels (1)

| Table | Lignes | Colonnes | Taille (Mo) |
|---|---:|---:|---:|
| `sectors` | 12 | 9 | 0.05 |

## 10. Système Laravel (10)

| Table | Lignes | Colonnes | Taille (Mo) |
|---|---:|---:|---:|
| `migrations` | 54 | 3 | 0.02 |
| `jobs` | 3 | 7 | 0.05 |
| `job_batches` | 0 | 10 | 0.02 |
| `failed_jobs` | 0 | 7 | 0.02 |
| `cache` | 12 | 3 | 0.23 |
| `cache_locks` | 0 | 3 | 0.02 |
| `telescope_entries` | 0 | 8 | 0.02 |
| `telescope_entries_tags` | 0 | 2 | 0.03 |
| `telescope_monitoring` | 0 | 1 | 0.02 |
| `test_schema` | 0 | 1 | 0.02 |

---

## Liste alphabétique complète (65)

`activity_logs`, `admin_accounts`, `admin_audit_logs`, `admin_invitations`, `ai_match_logs`, `applications`, `cache`, `cache_locks`, `candidate_accounts`, `candidate_documents`, `candidate_profiles`, `chatbot_sessions`, `connected_devices`, `conversations`, `cv_sections`, `cv_versions`, `employer_accounts`, `employer_profiles`, `experience_verifications`, `failed_jobs`, `fp_contests`, `imported_cvs`, `internal_votes`, `interview_suggestions`, `job_batches`, `job_offers`, `jobs`, `login_attempts`, `messages`, `migrations`, `model_has_permissions`, `model_has_roles`, `notifications`, `offer_reports`, `otp_codes`, `permissions`, `personal_access_tokens`, `portfolio_items`, `role_has_permissions`, `roles`, `saved_items`, `sectors`, `selected_candidates`, `sessions`, `talent_shortlists`, `team_invitations`, `team_members`, `telescope_entries`, `telescope_entries_tags`, `telescope_monitoring`, `tenders`, `test_schema`, `training_enrollments`, `training_module_quizzes`, `training_module_sequences`, `training_modules`, `training_offers`, `training_question_bank_items`, `training_quiz_attempts`, `training_quiz_options`, `training_quiz_questions`, `training_quiz_versions`, `training_reviews`, `user_cvs`, `users`
