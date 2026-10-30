package game.items
{
   public class BundleItem extends ShopItem
   {
      
      public var mItems:Array;
      
      public var mAmount:Array;
      
      public function BundleItem(param1:Object)
      {
         var _loc2_:Object = null;
         var _loc3_:CollectibleItem = null;
         var _loc4_:int = 0;
         super(param1);
         this.mItems = new Array();
         this.mAmount = new Array();
         if(param1.Items.ID)
         {
            this.mItems.push(ItemManager.getItem(param1.Items.ID,param1.Items.Type));
            this.mAmount.push(param1.Amount);
         }
         else
         {
            if(param1.Items.length != param1.Amount.length)
            {
               throw new Error("Bundle " + mId + ": length of Items and Amount should be equal");
            }
            for each(_loc2_ in param1.Items)
            {
               this.mItems.push(ItemManager.getItem(_loc2_.ID,_loc2_.Type));
            }
            for each(_loc4_ in param1.Amount)
            {
               this.mAmount.push(_loc4_);
            }
         }
      }
      
      public function getItems() : Array
      {
         return this.mItems;
      }
   }
}

