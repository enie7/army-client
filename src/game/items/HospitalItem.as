package game.items
{
   public class HospitalItem extends RepairableItem
   {
      
      public var mCooldown:int;
      
      public var mHealPower:int;
      
      public var mAttackRange:int;
      
      public var mPower:int = 1;
      
      public var mReadyText:String;
      
      public var mNotReadyText:String;
      
      public function HospitalItem(param1:Object)
      {
         super(param1);
         this.mCooldown = param1.CooldownTime;
         this.mHealPower = param1.HealPower;
         this.mAttackRange = param1.AttackRange;
         this.mReadyText = param1.DescriptionReady;
         this.mNotReadyText = param1.DescriptionNotReady;
      }
   }
}

