@isTest
public class TestDataFactory {

    public static final String STATUS_DRAFT     = 'Draft';
    public static final String STATUS_ACTIVATED = 'Activated';
    public static final Decimal DEFAULT_UNIT_PRICE = 100;
    public static final Integer DEFAULT_QUANTITY  = 1;

    /* ============ Account ============ */

    public static Account createAccount(String name) {
        Account a = new Account(Name = name);
        insert a;
        return a;
    }

    public static List<Account> createAccounts(Integer count) {
        List<Account> accs = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accs.add(new Account(Name = 'Test Account ' + i));
        }
        insert accs;
        return accs;
    }

    /* ============ Product + Pricebook ============ */

    public static Product2 createProduct(String name) {
        Product2 p = new Product2(Name = name, Family = 'Test', IsActive = true);
        insert p;
        return p;
    }

    public static PricebookEntry createStandardPricebookEntry(Id productId, Decimal unitPrice) {
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id     = Test.getStandardPricebookId(),
            Product2Id       = productId,
            UnitPrice        = unitPrice,
            IsActive         = true,
            UseStandardPrice = false
        );
        insert pbe;
        return pbe;
    }

    /* ============ Order ============ */

    public static Order createOrder(Id accountId, Id pricebookId, String status) {
        Order o = new Order(
            AccountId     = accountId,
            EffectiveDate = Date.today(),
            Status        = status,
            Pricebook2Id  = pricebookId
        );
        insert o;
        return o;
    }

    public static List<Order> createOrders(Id accountId, Id pricebookId, String status, Integer count) {
        List<Order> orders = new List<Order>();
        for (Integer i = 0; i < count; i++) {
            orders.add(new Order(
                AccountId     = accountId,
                EffectiveDate = Date.today(),
                Status        = status,
                Pricebook2Id  = pricebookId
            ));
        }
        insert orders;
        return orders;
    }

    /* ============ OrderItem ============ */

    public static OrderItem createOrderItem(Id orderId, Id pricebookEntryId, Integer quantity, Decimal unitPrice) {
        OrderItem oi = new OrderItem(
            OrderId          = orderId,
            PricebookEntryId = pricebookEntryId,
            Quantity         = quantity,
            UnitPrice        = unitPrice
        );
        insert oi;
        return oi;
    }

    public static List<OrderItem> createOrderItems(List<Id> orderIds, Id pricebookEntryId,
                                                   Integer quantity, Decimal unitPrice) {
        List<OrderItem> items = new List<OrderItem>();
        for (Id orderId : orderIds) {
            items.add(new OrderItem(
                OrderId          = orderId,
                PricebookEntryId = pricebookEntryId,
                Quantity         = quantity,
                UnitPrice        = unitPrice
            ));
        }
        insert items;
        return items;
    }
}
