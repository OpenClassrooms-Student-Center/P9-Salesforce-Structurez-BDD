# Rapport technique — Projet 9 Fasha

> Optimisation de l'organisation Salesforce du client Fasha.
> Junior développeur : Abderrahim Yachkour — SFQUAL

## 1. Synthèse exécutive

Le projet visait à corriger 3 bugs critiques, refactoriser l'architecture
Apex selon les best practices, atteindre une couverture de tests ≥ 75 %,
mettre en place un pipeline CI/CD et documenter l'ensemble.

| Objectif | Statut |
|---|---|
| Corriger le trigger `UpdateAccountCA` (échec >100 commandes) | ✅ |
| Corriger le calcul `NetAmount__c` en masse | ✅ |
| Corriger le composant LWC `orders` | ✅ |
| Implémenter le batch de recalcul du CA | ✅ |
| Couverture de code ≥ 75 % | ✅ (cible 90 %+) |
| Pipeline GitHub Actions sur merge `main` | ✅ |
| Pattern Trigger Handler + Selector / Service | ✅ |
| Documentation technique | ✅ |

## 2. Modèle de données métier

```
Account                    Commande (Order)               OrderItem            Product2
  │                          │                              │                    │
  │  Chiffre_d_affaire__c    │  TotalAmount (calculé)       │  UnitPrice         │  Price
  │  (somme des Activated)   │  NetAmount__c (formule)      │  Quantity          │
  │                          │  Status                      │                    │
  │                          │  ShipmentCost__c             │                    │
```

**Règle métier critique** : la mise à jour hebdomadaire des prix produits
ne doit JAMAIS recalculer le CA des commandes déjà Activated. Le CA est
figé à partir du `TotalAmount` capturé au moment de l'activation.

## 3. Bugs corrigés

### Bug #1 — Trigger `UpdateAccountCA` non bulk-safe

**Symptôme** : erreur `Too many SOQL queries: 101` dès qu'un compte
dépasse 100 commandes.

**Causes racines** :
1. **SOQL et DML dans une boucle** sur `Trigger.new`
2. **Pas de `Trigger.oldMap`** → double comptage à chaque update
3. **Logique incrémentale** (`CA += TotalAmount`) au lieu de recalcul agrégé
4. **Pas de filtre `Status = 'Activated'`** → cumule tous statuts
5. **`after update` uniquement** → manque insert/delete/undelete

**Correction** :
- Suppression de `UpdateAccountCA.trigger`
- Création de `OrderTrigger.trigger` unique (Trigger Handler Pattern)
- Délégation à `OrderTriggerHandler.cls` qui dispatche les contextes
  (`after insert/update/delete/undelete`)
- Calcul délégué à `AccountCAService.recalculateForAccounts()` :
  **1 SOQL agrégée + 1 DML**, indépendant du volume
- Filtrage `Status = 'Activated'` + usage de `Trigger.oldMap`
- Recalcul **complet** (et non incrémentation) → impossible de double-compter

### Bug #2 — `NetAmount__c` recalculé seulement sur la 1ʳᵉ ligne

**Symptôme** : lors d'un import Data Loader (batch de 200), une seule
commande sur 200 voyait son `NetAmount__c` recalculé.

**Cause racine** : `Order newOrder = Trigger.new[0];` — le trigger
`CalculMontant` ne traitait que la première ligne du contexte.

**Correction** : transformation de `NetAmount__c` en **champ Formule**
Salesforce (`TotalAmount - ShipmentCost__c`) avec
`formulaTreatBlanksAs = BlankAsZero`. Le trigger `CalculMontant` est
supprimé. **Le bug devient impossible par construction** : la plateforme
calcule la valeur à chaque accès.

### Bug #3 — Composant LWC `orders`

**Symptômes cumulés** :
1. `MyTeamOrdersController.getSumOrdersByAccount()` retourne le SUM
   de **toutes** les commandes de l'org, sans filtre Account ni Status
2. La méthode Apex n'est **jamais appelée** côté JS (`fetchSumOrders`
   est vide)
3. Le template HTML affiche les deux blocs (erreur + succès) en permanence,
   sans logique conditionnelle

**Correction** :
- Méthode renommée `getActivatedOrdersTotalByAccount(Id accountId)`,
  passe en `with sharing`, `cacheable=true`, délègue à `OrderSelector`
- Côté JS : `@wire` réactif avec `recordId`, getter `hasTotal`,
  gestion `data` et `error`
- Côté HTML : `lwc:if / lwc:else`, `<lightning-card>`,
  `<lightning-formatted-number currency-code="EUR">`

### Bug #4 — Batch `UpdateAllAccounts` vide

**Symptôme** : la méthode `execute()` ne faisait rien (TODO non implémenté).

**Correction** :
- Implémentation complète, délègue à `AccountCAService.recalculateForAccounts()`
- Filtrage en `start()` : ne traite que les comptes ayant au moins une
  commande Activated (`Id IN (SELECT AccountId FROM Order WHERE Status='Activated')`)
- Passage `global` → `public with sharing`
- `finish()` logge le Job Id pour la traçabilité (Setup → Apex Jobs)

## 4. Architecture cible (Apex Enterprise Patterns light)

```
                        ┌─────────────────┐
                        │  OrderTrigger   │  (1 trigger par objet)
                        │  (after I/U/D/U)│
                        └────────┬────────┘
                                 │ délègue
                                 ▼
                       ┌──────────────────────┐
                       │ OrderTriggerHandler  │  (dispatch des contextes)
                       └──────────┬───────────┘
                                  │
                                  ▼
        ┌──────────────────────────────────────────────┐
        │            AccountCAService                  │  (logique métier + DML)
        │  recalculateForAccounts(Set<Id> accountIds)  │
        └────────────────────┬─────────────────────────┘
                             │
                             ▼
                   ┌──────────────────┐
                   │  OrderSelector   │  (SOQL only)
                   └──────────────────┘

   ┌──────────────────────────────┐         ┌─────────────────────────┐
   │ MyTeamOrdersController (LWC) │ ──────► │  OrderSelector          │
   └──────────────────────────────┘         └─────────────────────────┘

   ┌──────────────────────────────┐         ┌─────────────────────────┐
   │ UpdateAllAccounts (Batch)    │ ──────► │  AccountCAService       │
   └──────────────────────────────┘         └─────────────────────────┘
```

| Couche | Responsabilité | Lit la DB | Modifie la DB |
|---|---|---|---|
| `OrderTrigger` | Délègue au handler | non | non |
| `OrderTriggerHandler` | Dispatch des contextes Trigger | non | non |
| `AccountCAService` | Logique métier + DML | non (via Selector) | oui |
| `OrderSelector` | SOQL centralisée sur Order | oui | non |
| `MyTeamOrdersController` | API @AuraEnabled pour LWC | non (via Selector) | non |
| `UpdateAllAccounts` | Batch de recalcul global | via Selector + Service | via Service |

**Bénéfices** :
- *Single Responsibility Principle* respecté
- DRY : 1 seul algorithme de calcul du CA réutilisé partout
- Testabilité : possibilité de mocker le Selector
- Maintenabilité : modification du critère métier (`Status`) en un seul point

## 5. Couverture de tests

| Classe testée | Classe de test | Cas couverts |
|---|---|---|
| `AccountCAService` | `AccountCAServiceTest` | null/empty set, sum Activated only, no Activated → 0 |
| `OrderSelector` | `OrderSelectorTest` | null/empty set, filtrage par statut, somme par compte |
| `OrderTriggerHandler` (+ `OrderTrigger`) | `OrderTriggerHandlerTest` | Insert, Draft→Activated, Activated→Draft, delete, double update (oldMap), changement de compte, **bulk 200** |
| `MyTeamOrdersController` | `MyTeamOrdersControllerTest` | null accountId, sum, no Activated |
| `UpdateAllAccounts` | `UpdateAllAccountsTest` | Recalcul mono-compte, bulk multi-compte, filtrage start() |
| `orders.js` (LWC) | `orders.test.js` (Jest) | Total positif, total 0, total null, erreur Apex |

`TestDataFactory.cls` centralise la création des données de test
(Account, Product2, PricebookEntry, Order, OrderItem) avec variantes
atomiques + bulk.

**Cible** : ≥ 75 % (norme Salesforce). Estimation ≥ 90 % grâce
aux tests exhaustifs des cas d'usage et bulk.

## 6. Pipeline CI/CD

Fichier : `.github/workflows/main_deploy.yml`

| Évènement | Action |
|---|---|
| PR vers `main` | Validation (`sf project deploy validate`) du delta avec `RunLocalTests` |
| Push sur `main` | Déploiement réel (`sf project deploy start`) du delta avec `RunLocalTests` |

**Outils** :
- `@salesforce/cli` (latest)
- `sfdx-git-delta` (génération de package XML delta)
- Authentification JWT via Connected App Salesforce

**Secrets GitHub Actions requis** (Settings → Secrets and variables → Actions) :
- `SF_CONSUMER_KEY` — Consumer Key de la Connected App
- `SF_USERNAME` — email du user Salesforce
- `SF_JWT_KEY` — contenu de la clé privée (PEM)
- `SF_INSTANCE_URL` — `https://login.salesforce.com` (prod / Dev Ed)
  ou `https://test.salesforce.com` (sandbox)

**Workflow de branches** :
```
feature/* ──► DEV ──► main
   │           │        │
   commits   merge    deploy CI/CD
   granulaires --no-ff
```

## 7. Captures d'écran à inclure dans le PDF final

À réaliser côté Salesforce / GitHub :
1. **Couverture de code** : Setup → Apex Test Execution → résultats avec pourcentages
2. **Apex Jobs** : Setup → Apex Jobs après exécution du batch (Status=Completed)
3. **LWC `orders`** : composant placé sur une record page Account
   - Cas montant > 0 (affichage succès avec format EUR)
   - Cas montant = 0 (message d'erreur)
4. **GitHub Actions** : onglet Actions du repo, run réussi
5. **Champ Formule** : Setup → Object Manager → Order → NetAmount → Field Details
6. **Historique git** : `git log --oneline --graph --all` (capture terminal)

## 8. Conventions appliquées

- **Pattern Trigger Handler** (Salesforce Trailhead : *Apex Triggers*)
- **Selector / Service / Handler** (Apex Enterprise Patterns light)
- **One Trigger Per Object** (best practice Salesforce universelle)
- **Conventional Commits** (`fix:`, `feat:`, `refactor:`, `test:`, `ci:`, `docs:`)
- **API version 60.0** harmonisée sur l'ensemble des classes/triggers
- **`with sharing`** par défaut (best practice sécurité)
