# Code — détail AVANT / APRÈS / POURQUOI

> Ce document détaille chaque fichier modifié, supprimé ou ajouté durant
> le projet. Pour chaque élément : code AVANT, code APRÈS, cause racine
> de la correction.

---

## 1. Trigger `UpdateAccountCA` → SUPPRIMÉ et remplacé

### AVANT — `force-app/main/default/triggers/UpdateAccountCA.trigger`

```apex
trigger UpdateAccountCA on Order (after update) {

    set<Id> setAccountIds = new set<Id>();          // déclarée, jamais utilisée

    for(integer i=0; i< trigger.new.size(); i++){
        Order newOrder= trigger.new[i];

        Account acc = [SELECT Id, Chiffre_d_affaire__c
                       FROM Account
                       WHERE Id =:newOrder.AccountId ];  // ❌ SOQL dans une boucle
        acc.Chiffre_d_affaire__c = acc.Chiffre_d_affaire__c
                                   + newOrder.TotalAmount;
        update acc;                                       // ❌ DML dans une boucle
    }
}
```

### POURQUOI c'était cassé

| # | Défaut | Conséquence |
|---|---|---|
| 1 | `[SELECT ...]` dans la boucle `for` | Limite gouverneur : **100 SOQL/transaction**. Plus de 100 commandes mises à jour en bulk → exception `System.LimitException: Too many SOQL queries: 101` |
| 2 | `update acc` dans la boucle `for` | Limite gouverneur : 150 DML/transaction |
| 3 | Pas de filtre `Status = 'Activated'` | Le CA cumule tous les statuts (Draft, Cancelled, etc.) |
| 4 | Pas de comparaison `Trigger.oldMap` | Chaque update — même sans changement de statut — ré-ajoute le `TotalAmount` → **double comptage** |
| 5 | Cumul `CA = CA + TotalAmount` | Modifier une commande déjà Activée gonfle artificiellement le CA |
| 6 | `after update` seulement | Insert d'une commande déjà Activated, delete, undelete → CA jamais recalculé |

### APRÈS — fichiers créés en remplacement

**`force-app/main/default/triggers/OrderTrigger.trigger`** (ultra-mince)
```apex
trigger OrderTrigger on Order (after insert, after update, after delete, after undelete) {
    OrderTriggerHandler.run();
}
```

**`force-app/main/default/classes/OrderTriggerHandler.cls`** (dispatch)
```apex
public with sharing class OrderTriggerHandler {

    public static void run() {
        if (Trigger.isAfter && Trigger.isInsert) {
            handleAfterInsert(Trigger.new);
        } else if (Trigger.isAfter && Trigger.isUpdate) {
            handleAfterUpdate(Trigger.new, Trigger.oldMap);
        } else if (Trigger.isAfter && Trigger.isDelete) {
            handleAfterDelete(Trigger.old);
        } else if (Trigger.isAfter && Trigger.isUndelete) {
            handleAfterInsert(Trigger.new);
        }
    }

    private static void handleAfterInsert(List<Order> newOrders) {
        Set<Id> accountIds = new Set<Id>();
        for (Order o : newOrders) {
            if (o.AccountId != null && o.Status == AccountCAService.ACTIVATED_STATUS) {
                accountIds.add(o.AccountId);
            }
        }
        AccountCAService.recalculateForAccounts(accountIds);
    }

    private static void handleAfterUpdate(List<Order> newOrders, Map<Id, Order> oldMap) {
        Set<Id> accountIds = new Set<Id>();
        for (Order newOrder : newOrders) {
            Order oldOrder = oldMap.get(newOrder.Id);

            Boolean statusChanged  = newOrder.Status      != oldOrder.Status;
            Boolean amountChanged  = newOrder.TotalAmount != oldOrder.TotalAmount;
            Boolean accountChanged = newOrder.AccountId   != oldOrder.AccountId;

            if (newOrder.AccountId != null
                && (statusChanged
                    || (amountChanged && newOrder.Status == AccountCAService.ACTIVATED_STATUS))) {
                accountIds.add(newOrder.AccountId);
            }
            if (accountChanged && oldOrder.AccountId != null) {
                accountIds.add(oldOrder.AccountId);
            }
        }
        AccountCAService.recalculateForAccounts(accountIds);
    }

    private static void handleAfterDelete(List<Order> oldOrders) {
        Set<Id> accountIds = new Set<Id>();
        for (Order o : oldOrders) {
            if (o.AccountId != null && o.Status == AccountCAService.ACTIVATED_STATUS) {
                accountIds.add(o.AccountId);
            }
        }
        AccountCAService.recalculateForAccounts(accountIds);
    }
}
```

**`force-app/main/default/classes/AccountCAService.cls`** (logique métier + DML)
```apex
public with sharing class AccountCAService {

    public static final String ACTIVATED_STATUS = 'Activated';

    public static void recalculateForAccounts(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }

        Map<Id, Decimal> caByAccount = OrderSelector.getTotalsByAccount(
            accountIds,
            ACTIVATED_STATUS
        );

        List<Account> toUpdate = new List<Account>();
        for (Id accId : accountIds) {
            Decimal ca = caByAccount.containsKey(accId) ? caByAccount.get(accId) : 0;
            toUpdate.add(new Account(
                Id = accId,
                Chiffre_d_affaire__c = ca
            ));
        }
        update toUpdate;
    }
}
```

**`force-app/main/default/classes/OrderSelector.cls`** (SOQL only)
```apex
public with sharing class OrderSelector {

    public static Map<Id, Decimal> getTotalsByAccount(Set<Id> accountIds, String status) {
        Map<Id, Decimal> totals = new Map<Id, Decimal>();
        if (accountIds == null || accountIds.isEmpty()) {
            return totals;
        }
        for (AggregateResult ar : [
            SELECT AccountId, SUM(TotalAmount) total
            FROM Order
            WHERE AccountId IN :accountIds
              AND Status = :status
            GROUP BY AccountId
        ]) {
            Decimal total = (Decimal) ar.get('total');
            totals.put((Id) ar.get('AccountId'), total != null ? total : 0);
        }
        return totals;
    }
}
```

### Améliorations clés

| Aspect | Avant | Après |
|---|---|---|
| Nombre de SOQL pour 200 commandes | **101 (KO)** | **1** (agrégée GROUP BY) |
| Nombre de DML pour 200 commandes | **151 (KO)** | **1** (update groupé) |
| Filtre par statut | non | `Status = 'Activated'` |
| Détection des transitions | non | `Trigger.oldMap` |
| Risque de double comptage | OUI | NON (recalcul complet, pas incrémentation) |
| Contextes couverts | `after update` | `insert / update / delete / undelete` |
| Pattern | aucun | **Trigger Handler + Selector / Service** |

---

## 2. Trigger `CalculMontant` → SUPPRIMÉ et remplacé par un champ Formule

### AVANT — `force-app/main/default/triggers/CalculMontant.trigger`

```apex
trigger CalculMontant on Order (before update) {

    Order newOrder= trigger.new[0];                          // ❌ seulement la 1ère
    newOrder.NetAmount__c = newOrder.TotalAmount
                            - newOrder.ShipmentCost__c;       // ❌ null-unsafe
}
```

### POURQUOI c'était cassé

| # | Défaut | Conséquence |
|---|---|---|
| 1 | `trigger.new[0]` au lieu d'une boucle | Data Loader envoie par batch de 200 → seules **1 commande sur 200** voit son `NetAmount__c` recalculé |
| 2 | `before update` uniquement | Pas de calcul à l'insertion |
| 3 | `null - null = null` (pas de gestion null) | NetAmount devient `null` si `ShipmentCost__c` est vide |
| 4 | Calcul fait par trigger | Solution non idiomatique : le calcul est entièrement dérivable, donc un champ Formule est la bonne approche |

### APRÈS — champ Formule (métadonnée pure, zéro code)

**`force-app/main/default/objects/Order/fields/NetAmount__c.field-meta.xml`**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>NetAmount__c</fullName>
    <externalId>false</externalId>
    <formula>TotalAmount - ShipmentCost__c</formula>
    <formulaTreatBlanksAs>BlankAsZero</formulaTreatBlanksAs>
    <label>Net amount</label>
    <precision>18</precision>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <type>Currency</type>
</CustomField>
```

### POURQUOI cette solution est meilleure

| Critère | Trigger | Champ Formule |
|---|---|---|
| Recalculé à chaque DML | ❌ Oui, coût gouverneur | ✅ Calculé à la volée, jamais désynchro |
| Risque de bulk-bug | ❌ Oui (le bug actuel) | ✅ Impossible par construction |
| Gestion `null` | manuel (oublié ici) | `formulaTreatBlanksAs=BlankAsZero` |
| Code à tester | oui (et le test était cassé) | non |

`required` retiré : un champ Formule est **toujours read-only**, Salesforce
rejette l'attribut `required`.

---

## 3. `MyTeamOrdersController.cls` → réécrit

### AVANT

```apex
public without sharing class MyTeamOrdersController {

    // TODO - Corriger l'erreur ici, nous retournons le montant TOTAL de tous les "Orders"
    // mais nous souhaitons retourner le montant TOTAL des orders aux status = 'Activated'
    // du compte sur lequel le composant LWC se situe
    @AuraEnabled
    public static Decimal getSumOrdersByAccount() {
        AggregateResult groupedResults = [SELECT SUM(TotalAmount) total FROM Order];   // ❌
        return (Decimal)groupedResults.get('total');
    }
}
```

### POURQUOI c'était cassé

1. **`without sharing`** non justifié pour une simple lecture
2. **Pas de paramètre `accountId`** → SUM de toutes les commandes de l'org
3. **Pas de filtre `Status='Activated'`**
4. **Pas de `cacheable=true`** → ne peut pas être utilisé avec `@wire` côté LWC
5. **Nom de méthode flou** (`getSumOrdersByAccount` mais sans accountId)

### APRÈS

```apex
public with sharing class MyTeamOrdersController {

    @AuraEnabled(cacheable=true)
    public static Decimal getActivatedOrdersTotalByAccount(Id accountId) {
        if (accountId == null) {
            return 0;
        }

        Map<Id, Decimal> totals = OrderSelector.getTotalsByAccount(
            new Set<Id>{ accountId },
            AccountCAService.ACTIVATED_STATUS
        );
        Decimal total = totals.get(accountId);
        return total != null ? total : 0;
    }
}
```

### Améliorations

- **Réutilise `OrderSelector` et `AccountCAService.ACTIVATED_STATUS`** :
  pas de duplication de SOQL ni de constante magique
- **`with sharing`** : respecte les permissions utilisateur
- **`cacheable=true`** : permet l'utilisation de `@wire` côté LWC
- **Nom explicite** : `getActivatedOrdersTotalByAccount(Id accountId)`

---

## 4. LWC `orders.js` → réécrit

### AVANT

```javascript
import { LightningElement, api } from 'lwc';
// TODO - récupérer la méthode apex permettant de faire ce calcul

export default class Orders extends LightningElement {

    sumOrdersOfCurrentAccount;
    @api recordId;

    connectedCallback() {
        this.fetchSumOrders();
    }

    fetchSumOrders() {
        // TODO - récupérer le montant total des Orders sur le compte avec la méthode apex
    }
}
```

### POURQUOI c'était cassé

- La méthode `fetchSumOrders()` était **vide** : l'Apex n'était jamais appelé
- Aucune gestion d'erreur

### APRÈS

```javascript
import { LightningElement, api, wire } from 'lwc';
import getTotal from '@salesforce/apex/MyTeamOrdersController.getActivatedOrdersTotalByAccount';

export default class Orders extends LightningElement {

    @api recordId;

    total;
    error;

    @wire(getTotal, { accountId: '$recordId' })
    wiredTotal({ data, error }) {
        if (data !== undefined) {
            this.total = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.total = undefined;
        }
    }

    get hasTotal() {
        return this.total !== undefined && this.total !== null && this.total > 0;
    }
}
```

### Améliorations

- **`@wire`** réactif : appel automatique quand `recordId` est disponible,
  re-cache côté Lightning Data Service
- **Syntaxe `$recordId`** : valeur réactive
- **Getter `hasTotal`** : source de vérité unique pour le rendu conditionnel
- **Gestion `data` / `error`** : affichage adapté selon le résultat

---

## 5. LWC `orders.html` → réécrit

### AVANT

```html
<template>
    <div class="slds-box slds-theme_error" >
        <h1>Erreur, pas de commandes rattachées à ce compte ou le montant
            des commandes sont inférieurs à 0.</h1>
    </div>
    <!-- Si la valeur de "sumOrdersOfCurrentAccount" est vide ou égale a Zero,
         je souhaite afficher un message d'erreur -->
    <div class="slds-box slds-theme_success" >
        <h1>Total des Commandes : {sumOrdersOfCurrentAccount}</h1>
    </div>
</template>
```

### POURQUOI c'était cassé

- Aucune logique conditionnelle → **les 2 blocs s'affichent en permanence**
- Pas de formatage de la devise
- Pas de carte Lightning

### APRÈS

```html
<template>
    <lightning-card title="Commandes du compte" icon-name="standard:orders">
        <template lwc:if={hasTotal}>
            <div class="slds-box slds-theme_success slds-p-around_medium">
                <h1 class="slds-text-heading_small">
                    Total des Commandes :
                    <lightning-formatted-number
                        value={total}
                        format-style="currency"
                        currency-code="EUR">
                    </lightning-formatted-number>
                </h1>
            </div>
        </template>

        <template lwc:else>
            <div class="slds-box slds-theme_error slds-p-around_medium">
                <h1 class="slds-text-heading_small">
                    Aucune commande activée pour ce compte ou montant total à 0.
                </h1>
            </div>
        </template>
    </lightning-card>
</template>
```

### Améliorations

- **`lwc:if / lwc:else`** : syntaxe moderne (depuis API 59), un seul bloc affiché
- **`lightning-card`** : enveloppe Lightning native, look uniforme
- **`lightning-formatted-number`** : formatage monétaire localisé (€)

---

## 6. Batch `UpdateAllAccounts.cls` → implémenté

### AVANT

```apex
global class UpdateAllAccounts implements Database.Batchable<sObject>{

    global Database.QueryLocator start(Database.BatchableContext info){
        //Requeter seulement les comptes qui ont au moins une commande avec le Status 'Activated'
        return Database.getQueryLocator('SELECT Id FROM Account');    // ❌ pas de filtre
    }

    global void execute(Database.BatchableContext info, List<Account> scope){
        Set<Id> setAccountIds = (new Map<Id,SObject>(scope)).keySet();
        // Appeler une class qui va faire la logique du code;    // ❌ rien
    }

    global void finish(Database.BatchableContext info){
        // vide
    }
}
```

### POURQUOI c'était cassé

- `execute()` ne fait littéralement rien → batch inutile
- `start()` charge tous les comptes (même ceux sans commande Activated)
- `global` non justifié (réservé aux managed packages)
- `finish()` sans log → pas de traçabilité en prod

### APRÈS

```apex
public with sharing class UpdateAllAccounts implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext info) {
        // On ne traite que les comptes ayant au moins une commande Activated.
        // Pour un audit/reinit complet, retirer la sous-requete.
        return Database.getQueryLocator(
            'SELECT Id FROM Account ' +
            'WHERE Id IN (SELECT AccountId FROM Order WHERE Status = \'' +
            AccountCAService.ACTIVATED_STATUS + '\')'
        );
    }

    public void execute(Database.BatchableContext info, List<Account> scope) {
        if (scope == null || scope.isEmpty()) {
            return;
        }
        Set<Id> accountIds = (new Map<Id, Account>(scope)).keySet();
        AccountCAService.recalculateForAccounts(accountIds);
    }

    public void finish(Database.BatchableContext info) {
        System.debug(LoggingLevel.INFO,
            'UpdateAllAccounts batch termine. Job Id: ' + info.getJobId());
    }
}
```

### Améliorations

- **Réutilise `AccountCAService`** : exactement la même logique que le trigger
- **Filtre dès `start()`** : évite de scanner les comptes inutiles
- **`public with sharing`** : best practice
- **`finish()` logge le Job Id** : visible dans Setup → Apex Jobs

### Comment l'exécuter

```apex
// Developer Console > Debug > Open Execute Anonymous
Id jobId = Database.executeBatch(new UpdateAllAccounts(), 200);
System.debug('Job lancé : ' + jobId);
```

---

## 7. `TestDataFactory.cls` → AJOUTÉ

Classe centrale qui fabrique les données de test (Account, Product2,
PricebookEntry, Order, OrderItem). Permet d'éviter la duplication dans
chaque test.

### Méthodes principales

```apex
@isTest
public class TestDataFactory {

    public static final String STATUS_DRAFT     = 'Draft';
    public static final String STATUS_ACTIVATED = 'Activated';
    public static final Decimal DEFAULT_UNIT_PRICE = 100;
    public static final Integer DEFAULT_QUANTITY  = 1;

    // Atomiques
    public static Account createAccount(String name)
    public static Product2 createProduct(String name)
    public static PricebookEntry createStandardPricebookEntry(Id productId, Decimal unitPrice)
    public static Order createOrder(Id accountId, Id pricebookId, String status)
    public static OrderItem createOrderItem(Id orderId, Id pbeId, Integer qty, Decimal unitPrice)

    // Bulk
    public static List<Account> createAccounts(Integer count)
    public static List<Order>   createOrders(Id accountId, Id pricebookId, String status, Integer count)
    public static List<OrderItem> createOrderItems(List<Id> orderIds, Id pbeId, Integer qty, Decimal unitPrice)
}
```

### POURQUOI

| Sans factory | Avec factory |
|---|---|
| Chaque test recopie 20 lignes de setup | 2 lignes : `TestDataFactory.createOrder(...)` |
| Si un champ obligatoire change, corriger 10 tests | 1 modif dans la factory |
| Risque d'oublier des champs → tests cassés en CI | Setup cohérent garanti |

---

## 8. Tests Apex → 5 classes AJOUTÉES, 1 SUPPRIMÉE

### Supprimé

- `testUpdateAllAccounts.cls` : aucune assertion, ne testait pas le batch,
  remplacé par `UpdateAllAccountsTest.cls`

### Créés

| Classe | Cas couverts |
|---|---|
| `AccountCAServiceTest` | null/empty Set, sum Activated only, no Activated → 0 |
| `OrderSelectorTest` | null/empty Set, filtrage par statut, somme par compte |
| `OrderTriggerHandlerTest` | Draft→Activated, Activated→Draft, delete, double update (oldMap), changement de compte, **bulk 200** |
| `MyTeamOrdersControllerTest` | null accountId, sum, no Activated |
| `UpdateAllAccountsTest` | Recalcul mono-compte, bulk multi-compte, filtrage start() |

### Exemple : le test bulk 200 commandes

```apex
@isTest
static void bulkUpdate_200Orders_noGovernorException() {
    Account acc = TestDataFactory.createAccount('Acc Bulk');
    Id pbId = Test.getStandardPricebookId();
    PricebookEntry pbe = getPbe();

    List<Order> orders = TestDataFactory.createOrders(
        acc.Id, pbId, TestDataFactory.STATUS_DRAFT, 200
    );

    List<Id> orderIds = new List<Id>();
    for (Order o : orders) { orderIds.add(o.Id); }
    TestDataFactory.createOrderItems(orderIds, pbe.Id, 1, 100);

    for (Order o : orders) { o.Status = TestDataFactory.STATUS_ACTIVATED; }

    Test.startTest();
    update orders;
    Test.stopTest();

    Account refreshed = [SELECT Chiffre_d_affaire__c FROM Account WHERE Id = :acc.Id];
    System.assertEquals(200 * 100, refreshed.Chiffre_d_affaire__c,
        'CA = 20000 pour 200 commandes a 100 chacune (bulk-safe valide)');
}
```

C'est ce test qui prouve la correction du bug #1 : avant, ce code aurait
levé une exception `Too many SOQL queries: 101`.

---

## 9. LWC `orders.test.js` → réécrit

### AVANT

```javascript
it('TODO: test case generated by CLI command, please fill in test logic', () => {
    const element = createElement('c-orders', { is: Orders });
    document.body.appendChild(element);
    expect(1).toBe(1);   // placeholder inutile
});
```

### APRÈS

4 tests réels avec mock `@wire` :

```javascript
jest.mock(
    '@salesforce/apex/MyTeamOrdersController.getActivatedOrdersTotalByAccount',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);

// Tests :
// - affiche le total formate en euros quand la valeur est positive
// - affiche le message d'erreur quand le total vaut 0
// - affiche le message d'erreur quand le total est null
// - affiche le message d'erreur quand l'appel Apex echoue
```

---

## 10. CI/CD `.github/workflows/main_deploy.yml` → réécrit

### AVANT — `.github/workflows/main_deploy` (sans extension !)

```yaml
- name: 'Authentification Salesforce'
  run:  # A faire

- name: 'Generate metadata delta pull request'
  run:  # A faire

- name: 'Déployer les métadonnées sur la branch main'
  if: github.ref == 'refs/heads/main'
  run:  # A faire
```

### POURQUOI c'était cassé

- **Pas d'extension `.yml`** → GitHub Actions ignorait totalement le fichier
- 3 étapes vides (`# A faire`)
- Pas de stratégie validation PR vs déploiement push

### APRÈS — `.github/workflows/main_deploy.yml` (104 lignes)

Pipeline complet avec :
- Authentification **JWT** via 4 secrets GitHub
- Génération du **delta** via `sfdx-git-delta`
- **PR vers main** → `sf project deploy validate` avec `RunLocalTests`
- **Push sur main** → `sf project deploy start` avec `RunLocalTests`
- Cleanup de la clé privée en fin de job (`if: always()`)

Détails dans `docs/CI_CD_SETUP.md`.

---

## Récap des fichiers du repo après refacto

| Action | Fichier |
|---|---|
| ❌ Supprimé | `triggers/UpdateAccountCA.trigger` (+ meta) |
| ❌ Supprimé | `triggers/CalculMontant.trigger` (+ meta) |
| ❌ Supprimé | `classes/testUpdateAllAccounts.cls` (+ meta) |
| ❌ Supprimé | `.github/workflows/main_deploy` (renommé en .yml) |
| ✅ Ajouté | `triggers/OrderTrigger.trigger` (+ meta) |
| ✅ Ajouté | `classes/OrderTriggerHandler.cls` (+ meta) |
| ✅ Ajouté | `classes/AccountCAService.cls` (+ meta) |
| ✅ Ajouté | `classes/OrderSelector.cls` (+ meta) |
| ✅ Ajouté | `classes/TestDataFactory.cls` (+ meta) |
| ✅ Ajouté | `classes/AccountCAServiceTest.cls` (+ meta) |
| ✅ Ajouté | `classes/OrderSelectorTest.cls` (+ meta) |
| ✅ Ajouté | `classes/OrderTriggerHandlerTest.cls` (+ meta) |
| ✅ Ajouté | `classes/MyTeamOrdersControllerTest.cls` (+ meta) |
| ✅ Ajouté | `classes/UpdateAllAccountsTest.cls` (+ meta) |
| ✅ Ajouté | `.github/workflows/main_deploy.yml` |
| ✅ Ajouté | `docs/RAPPORT_TECHNIQUE.md`, `RAPPORT_PERFORMANCE.md`, `CI_CD_SETUP.md` |
| ✅ Ajouté | `livrables/Rapport.md`, `Code.md`, `interfaceUtilisateurs.md` |
| 🔄 Modifié | `classes/MyTeamOrdersController.cls` |
| 🔄 Modifié | `classes/UpdateAllAccounts.cls` |
| 🔄 Modifié | `lwc/orders/orders.js` |
| 🔄 Modifié | `lwc/orders/orders.html` |
| 🔄 Modifié | `lwc/orders/__tests__/orders.test.js` |
| 🔄 Modifié | `objects/Order/fields/NetAmount__c.field-meta.xml` (Currency → Formule) |
| 🔄 Modifié | `README.md`, `.gitignore` |
