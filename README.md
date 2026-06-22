# Projet 9 — Améliorer l'organisation Salesforce du client Fasha

Optimisation, refactorisation et fiabilisation de l'org Salesforce du
client **Fasha** (distributeur de vêtements).
Junior développeur Salesforce — **SFQUAL**.

## Documentation

| Document | Contenu |
|---|---|
| [Rapport technique](docs/RAPPORT_TECHNIQUE.md) | Synthèse, bugs corrigés, architecture, tests, conventions |
| [Rapport de performance](docs/RAPPORT_PERFORMANCE.md) | Méthodologie, mesures AVANT/APRÈS, efficacité énergétique |
| [Configuration CI/CD](docs/CI_CD_SETUP.md) | Setup Connected App, JWT, secrets GitHub Actions |

## Architecture

```
triggers/
└── OrderTrigger.trigger              (1 seul trigger par objet)

classes/
├── OrderTriggerHandler.cls           (dispatch des contextes Trigger)
├── AccountCAService.cls              (logique métier + DML)
├── OrderSelector.cls                 (SOQL Order centralisée)
├── MyTeamOrdersController.cls        (API @AuraEnabled pour LWC)
├── UpdateAllAccounts.cls             (Batch Apex)
├── TestDataFactory.cls               (fabrication de données de test)
└── *Test.cls                         (5 classes de tests)

lwc/orders/
├── orders.html                       (lwc:if/lwc:else, lightning-card)
├── orders.js                         (@wire réactif)
└── __tests__/orders.test.js          (4 tests Jest)

objects/
├── Account/fields/Chiffre_d_affaire__c.field-meta.xml   (Currency)
└── Order/fields/NetAmount__c.field-meta.xml             (Formula)

.github/workflows/
└── main_deploy.yml                   (CI/CD GitHub Actions)
```

## Patterns appliqués

- **Trigger Handler Pattern** (1 trigger par objet + handler)
- **Selector / Service** (séparation des SOQL et de la logique métier)
- **Conventional Commits** en français
- **Workflow de branches** : feature → DEV → main

## Installation locale

### 1. Cloner le dépôt
```bash
git clone https://github.com/AbderrahimYachkour/P9-Ameliorez-organisation-Salesforce-pour-votre-entreprise.git
cd P9-Ameliorez-organisation-Salesforce-pour-votre-entreprise
```

### 2. Authentifier Salesforce CLI
```bash
sf org login web --alias my-org
```

### 3. Déployer
```bash
sf project deploy start --target-org my-org
```

### 4. Lancer les tests Apex
```bash
sf apex run test --target-org my-org --test-level RunLocalTests --code-coverage
```

### 5. Lancer les tests Jest (LWC)
```bash
npm install
npm run test:unit
```

## Bugs corrigés

| # | Bug | Branche |
|---|---|---|
| 1 | `UpdateAccountCA.trigger` non bulk-safe (échec >100 commandes) | `fix/trigger-updateaccountca` |
| 2 | `NetAmount__c` recalculé seulement sur la 1ʳᵉ ligne | `feat/netamount-as-formula` |
| 3 | LWC `orders` ne fonctionne pas | `fix/lwc-orders` |
| 4 | Batch `UpdateAllAccounts` non implémenté | `feat/batch-updateallaccounts` |

Détails dans le [rapport technique](docs/RAPPORT_TECHNIQUE.md).

## Ressources

- [Salesforce Developer Documentation](https://developer.salesforce.com/docs)
- [Salesforce CLI](https://developer.salesforce.com/tools/sfdxcli)
- [Apex Trigger Best Practices (Trailhead)](https://trailhead.salesforce.com/content/learn/modules/apex_triggers)
