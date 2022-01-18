public without sharing class OrderHelper {

    /**
     * @name AfterUpdate
     * @description 
     * @param List<Order> newList
     * @param List<Order> oldList
     * @return void
    **/
    public static void AfterUpdate(List<Order> newList, List<Order> oldList){
        Set<Id> orderIds = new Set<Id>();
        for ( Integer i=0; i<newList.size(); i++ ){
            if ( newList[i].Status == constants.ACTIVATED_ORDER_STATUS && oldList[i].Status != constants.ACTIVATED_ORDER_STATUS ){
                orderIds.add(newList[i].Id);
            }
        }
        if(orderIds.size() > 0)
            RollUpOrderItems(orderIds);
    }

    /**
     * @name RollUpOrderItems
     * @description Given a set of Activated Order ids, query the child Order Items and related Products to calculate Inventory levels
     * @param Set<Id> activatedOrderIds
     * @return void
    **/
    public static void RollUpOrderItems(Set<Id> activatedOrderIds){
        Map<Id,Product2> productMap;
        List<Id> productIds = new List<Id>();
        try{
            for(OrderItem OP : [SELECT Id, Product2Id, OrderId FROM OrderItem WHERE OrderId IN: activatedOrderIds]){
                if(OP.Product2Id != null)
                    productIds.add(OP.Product2Id);
            }
        }catch(EXception ex){
        
        }
        if(productIds.size() > 0){
            //ToDo: Declare a Map named "productMap" of Ids to Product2 records
            productMap =  new Map<Id,Product2>([Select id,Quantity_Ordered__c from product2 where id in :productIds]);
        
        }
        
        if(!productMap.isEmpty()){
            AggregateResult[] groupedResult = [Select Product2Id,sum(Quantity) totalQuantity 
                                                from OrderItem 
                                                where product2Id in :productMap.keySet() group by product2Id];
        
        
            for(AggregateResult result : groupedResult){
                productMap.get((String)result.get('Product2Id')).Quantity_Ordered__c = Integer.valueOf(result.get('totalQuantity'));
            }
            
            update productMap.values();
        }
    }

}
