# Rapport projet — Optimisation org Salesforce Fasha

> **Auteur** : Abderrahim Yachkour — Junior développeur Salesforce
> **Entreprise** : SFQUAL
> **Client** : Fasha (distributeur de vêtements)
> **Projet** : P9 — Améliorez l'organisation Salesforce de votre entreprise

## 1. Contexte et objectifs

Le client **Fasha**, distributeur de vêtements, utilise une org Salesforce
pour gérer ses comptes, ses commandes et ses produits. L'org existante
présentait plusieurs **bugs critiques** détectés par l'équipe interne :

1. Un trigger qui plantait dès qu'un compte dépassait 100 commandes
2. Un calcul de montant net qui ne se faisait que sur la 1ʳᵉ ligne d'un import
3. Un composant Lightning Web Component (LWC) cassé sur la fiche compte
4. Un batch Apex de mise à jour du CA jamais implémenté

En tant que junior développeur chez **SFQUAL**, ma mission était de :
- Corriger ces bugs en identifiant leur **cause racine**
- **Refactoriser** le code selon les conventions et best practices Salesforce
- Atteindre une couverture de tests **≥ 75 %** (norme Salesforce)
- Mettre en place un **pipeline CI/CD GitHub Actions** pour déployer
  automatiquement sur l'org à chaque merge dans `main`
- Produire la **documentation technique** complète

## 2. Modèle métier

```
   Account                Order                  OrderItem            Product2
     │                      │                       │                    │
     │ Chiffre_d_affaire__c │ TotalAmount (système) │ UnitPrice          │ Price
     │ (somme des Order     │ NetAmount__c          │ Quantity           │
     │  Activated)          │ Status                │                    │
     │                      │ ShipmentCost__c       │                    │
```

- Le **CA** d'un compte est la somme des `TotalAmount` des commandes au
  statut **`Activated`**.
- Le `TotalAmount` d'une commande est calculé automatiquement par Salesforce
  à partir des `OrderItem` rattachés.
- Le **`NetAmount__c`** est le montant net (`TotalAmount - ShipmentCost__c`).

### Règle métier critique

> Une commande validée (`Status = 'Activated'`) est **figée**.
> Le batch de mise à jour hebdomadaire des prix produits ne doit **JAMAIS**
> recalculer le CA des commandes déjà activées.

Cette règle a guidé toute la conception : **recalculer le CA depuis la
base** plutôt que de l'incrémenter au fil des évènements (sinon, à chaque
update d'un produit, le CA risque de bouger).

## 3. Workflow Git suivi

Le projet a été conduit avec une stratégie de branches stricte :

```
feature/* ──► DEV ──► main
   │           │        │
   commits   merge    déploiement CI/CD
   granulaires --no-ff
```

- **`main`** : branche de production (déclencheur du déploiement)
- **`DEV`** : branche d'intégration où sont mergées les features
- **`feature/*`, `fix/*`, `test/*`, `ci/*`, `docs/*`** : branches éphémères,
  une par tâche, supprimées après merge

Chaque **commit** suit la convention **Conventional Commits** en français :
- `fix:` correction d'un bug
- `feat:` ajout d'une fonctionnalité
- `refactor:` réécriture sans changement de comportement
- `test:` ajout/modification de tests
- `ci:` modification du pipeline
- `docs:` documentation
- `chore:` tâches de maintenance (`.gitignore`, etc.)

## 4. Étapes du projet (ordre chronologique)

### Étape 0 — Diagnostic
Lecture complète du repo, identification des 4 bugs, vérification des
incohérences (versions API, conventions, fichiers manquants).

### Étape 1 — Corrections des bugs

| # | Bug | Branche | Approche |
|---|---|---|---|
| 1 | Trigger `UpdateAccountCA` non bulk-safe | `fix/trigger-updateaccountca` | Bulkification + Trigger Handler Pattern |
| 2 | `NetAmount__c` recalculé sur 1 ligne | `feat/netamount-as-formula` | Transformation en **champ Formule** (solution idiomatique) |
| 3 | LWC `orders` cassé | `fix/lwc-orders` | Refonte du contrôleur, JS, HTML |
| 4 | Batch `UpdateAllAccounts` vide | `feat/batch-updateallaccounts` | Implémentation déléguant au Service |

### Étape 2 — Refactorisation
Application du **pattern Trigger Handler** + **Selector / Service** :

```
                       OrderTrigger
                            │
                            ▼
                  OrderTriggerHandler        (dispatch des contextes)
                            │
                            ▼
                   AccountCAService          (logique métier + DML)
                            │
                            ▼
                    OrderSelector            (SOQL only)
```

Bénéfices :
- **DRY** : un seul algorithme de calcul du CA, réutilisé par le trigger,
  le batch et le contrôleur LWC
- **Single Responsibility** : chaque classe a une responsabilité unique
- **Testabilité** : le Selector peut être mocké
- **Maintenabilité** : modification d'un critère métier en un seul point

### Étape 3 — Tests
- **`TestDataFactory.cls`** : factory réutilisable (Account, Product2,
  PricebookEntry, Order, OrderItem)
- 5 classes de tests Apex + 1 fichier Jest LWC
- Cas couverts : null/empty, transitions de statut, delete, bulk 200+,
  oldMap (non-double-comptage), changement de compte, erreurs Apex côté LWC
- Couverture estimée **≥ 90 %**

### Étape 4 — Performance
Mesures avant/après documentées dans `docs/RAPPORT_PERFORMANCE.md` :

| Scénario | AVANT | APRÈS |
|---|---|---|
| 200 commandes activées | ❌ Exception `Too many SOQL queries: 101` | ✅ 2 SOQL, 1 DML, ~150 ms |
| 200 lignes via Data Loader | 0,5 % de lignes traitées | 100 % (calcul natif Formule) |
| Batch 10k comptes | 0 (vide) | Filtré, ~1 SOQL/scope de 200 |

### Étape 5 — CI/CD
Pipeline GitHub Actions (`.github/workflows/main_deploy.yml`) :
- **PR vers main** → validation (`sf project deploy validate`) avec
  `RunLocalTests`
- **Push sur main** → déploiement réel avec `RunLocalTests`
- Authentification **JWT** via Connected App + secrets GitHub
- Génération de package **delta** via `sfdx-git-delta` (évite de
  redéployer toute la base à chaque push)

### Étape 6 — Documentation
- `docs/RAPPORT_TECHNIQUE.md` — synthèse globale
- `docs/RAPPORT_PERFORMANCE.md` — métriques et efficacité énergétique
- `docs/CI_CD_SETUP.md` — guide de configuration Connected App + secrets
- `livrables/Rapport.md` — ce document
- `livrables/Code.md` — détail avant/après de chaque fichier
- `livrables/interfaceUtilisateurs.md` — configuration de l'App Manager Fasha

## 5. Vue d'ensemble du code

### Couche Trigger (point d'entrée évènementiel)
- **`OrderTrigger.trigger`** : ultra-mince, délègue tout au handler
- **`OrderTriggerHandler.cls`** : route les contextes (`after insert`,
  `after update` avec `Trigger.oldMap` pour détecter les transitions,
  `after delete`, `after undelete`)

### Couche Service (logique métier)
- **`AccountCAService.recalculateForAccounts(Set<Id>)`** :
  pour un set d'`AccountId`, requête la SUM des `TotalAmount` des Orders
  Activated (via le Selector), puis met à jour les comptes en **1 seul DML**

### Couche Selector (SOQL)
- **`OrderSelector.getTotalsByAccount(Set<Id>, String status)`** :
  retourne une `Map<AccountId, Decimal>` agrégée par SOQL `GROUP BY`

### Couche présentation (LWC)
- **`MyTeamOrdersController.cls`** : méthode `@AuraEnabled(cacheable=true)`
  qui prend un `accountId`, délègue au Selector, retourne le total
- **`orders.js`** : appel **`@wire`** réactif, getter `hasTotal` pour
  le rendu conditionnel
- **`orders.html`** : `lwc:if / lwc:else`, `<lightning-card>`,
  `<lightning-formatted-number currency-code="EUR">`

### Couche batch
- **`UpdateAllAccounts.cls`** : Database.Batchable, filtre en `start()`
  les comptes ayant au moins une commande Activated, délègue à
  `AccountCAService` dans `execute()`

### Champ Formule (zéro code)
- **`NetAmount__c`** sur Order : `TotalAmount - ShipmentCost__c`
  avec `formulaTreatBlanksAs=BlankAsZero` → calcul natif, plus de trigger

## 6. Résultats

| Objectif | Cible | Résultat |
|---|---|---|
| Bugs corrigés | 4/4 | ✅ |
| Couverture de tests | ≥ 75 % | ✅ ≥ 90 % (estimé) |
| Tests bulk (200+) | Oui | ✅ |
| Pipeline CI/CD opérationnel | Oui | ✅ |
| Documentation technique | Oui | ✅ (3 documents) |
| Conventions Apex/Salesforce | Oui | ✅ Trigger Handler, Selector/Service |

## 7. Conclusion et apprentissages

Ce projet m'a permis de mettre en application :
- **Best practices Apex** : bulk-safe, gouverneurs, séparation des couches
- **Patterns Salesforce** : Trigger Handler, Apex Enterprise Patterns (light)
- **Modern LWC** : `@wire`, `lwc:if/else`, `lightning-formatted-number`
- **Workflow Git avancé** : branches feature, merges `--no-ff`, conventions
  de commit, stratégie d'intégration
- **CI/CD Salesforce** : sfdx-git-delta, JWT auth, RunLocalTests
- **Efficacité énergétique** : réduire les SOQL/DML = réduire la conso
  serveur Force.com

**Pour aller plus loin** :
- Ajouter un **Scheduler** pour exécuter le batch automatiquement chaque semaine
- Introduire `fflib` (Apex Enterprise Patterns complet) sur un projet plus gros
- Ajouter un **dashboard** Salesforce mesurant la cohérence du CA en temps réel
