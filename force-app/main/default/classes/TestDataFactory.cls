public class TestDataFactory {

    public static Account createAccount() {
        Account acc = new Account(Name = 'Client Test');
        insert acc;
        return acc;
    }

    public static Order createOrder(Account acc, String status, Decimal shipmentCost) {
 
      Pricebook2 stdPB = [SELECT Id, IsActive, Name FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
    
  

        // Créer un produit
        Product2 prod = new Product2(Name = 'Produit Test', IsActive = true);
        insert prod;

        // Créer l’entrée de prix dans le Pricebook
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = stdPB.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // Créer une commande avec Pricebook
        Order testOrder = new Order(
            Name = 'Commande Test',
            AccountId = acc.Id,
            Status = status,
            EffectiveDate = Date.today(),
            Pricebook2Id = stdPB.Id,   // ⚠️ obligatoire
            ShipmentCost__c = shipmentCost
        );
         insert testOrder;
       

        // Ajouter des OrderItems (ici 3 articles, 2 x 100 chacun)
        List<OrderItem> items = new List<OrderItem>();
        for (Integer i = 0; i < 3; i++) {
            items.add(new OrderItem(
                OrderId = testOrder.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 2,
                UnitPrice = 100
            ));
        }
          
        insert items;
           testOrder = [SELECT Id, TotalAmount, NetAmount__c FROM Order WHERE Id = :testOrder.Id];
        System.debug('=== DEBUG Order ===');
    System.debug('TotalAmount: ' + testOrder.TotalAmount);
    System.debug('NetAmount__c: ' + testOrder.NetAmount__c);
return testOrder;
 
     
    }
}