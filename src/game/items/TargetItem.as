package game.items
{
   import game.magicBox.MagicBoxTracker;
   import game.player.GamePlayerProfile;
   import game.states.GameState;
   
   public class TargetItem extends MapItem
   {
      
      public var mHitRewardXP:int;
      
      public var mHitRewardMoney:int;
      
      public var mHitRewardSupplies:int;
      
      public var mHitRewardEnergy:int;
      
      public var mHitRewardMaterial:int;
      
      public var mKillRewardXP:int;
      
      public var mKillRewardMoney:int;
      
      public var mKillRewardSupplies:int;
      
      public var mKillRewardEnergy:int;
      
      public var mKillRewardMaterial:int;
      
      public var mKillRewardUnit:Object;
      
      private var mCollectibleItems:Array;
      
      private var mCollectibleLevels:Array;
      
      private var mCollectibleProbabilities:Array;
      
      private var mRandom:RandomGenerator = new RandomGenerator();
      
      public var mPermanentDestroyArray:Array;
      
      public function TargetItem(param1:Object)
      {
         var _loc2_:int = 0;
         var _loc3_:Object = null;
         var _loc4_:Object = null;
         var _loc5_:Array = null;
         var _loc6_:int = 0;
         var _loc7_:String = null;
         var _loc8_:Array = null;
         var _loc9_:String = null;
         var _loc10_:int = 0;
         var _loc11_:int = 0;
         super(param1);
         this.mHitRewardXP = param1.HitRewardXP;
         this.mHitRewardMoney = param1.HitRewardMoney;
         this.mHitRewardSupplies = param1.HitRewardSupplies;
         this.mHitRewardMaterial = param1.HitRewardMaterial;
         this.mHitRewardEnergy = param1.HitRewardEnergy;
         this.mKillRewardXP = param1.KillRewardXP;
         this.mKillRewardMoney = param1.KillRewardMoney;
         this.mKillRewardSupplies = param1.KillRewardSupplies;
         this.mKillRewardMaterial = param1.HitRewardMaterial;
         this.mKillRewardEnergy = param1.KillRewardEnergy;
         this.mKillRewardUnit = param1.KillRewardUnit;
         this.mPermanentDestroyArray = null;
         if(param1.PermanentDestroyArray)
         {
            if(param1.PermanentDestroyArray is Array)
            {
               this.mPermanentDestroyArray = param1.PermanentDestroyArray;
            }
            else
            {
               this.mPermanentDestroyArray = new Array();
               this.mPermanentDestroyArray.push(param1.PermanentDestroyArray);
            }
         }
         if(param1.Item0 != null)
         {
            this.mCollectibleItems = new Array();
            this.mCollectibleLevels = new Array();
            this.mCollectibleProbabilities = new Array();
            _loc2_ = 0;
            while(_loc2_ < 15)
            {
               _loc3_ = param1["Item" + _loc2_];
               _loc4_ = param1["OccurItem" + _loc2_];
               if(_loc3_ != null)
               {
                  this.mCollectibleItems.push(_loc3_);
                  if(_loc4_ is Array)
                  {
                     _loc5_ = _loc4_ as Array;
                  }
                  else
                  {
                     _loc5_ = new Array();
                     _loc5_.push(_loc4_);
                  }
                  this.mCollectibleLevels[_loc2_] = new Array();
                  this.mCollectibleProbabilities[_loc2_] = new Array();
                  _loc6_ = 0;
                  while(_loc6_ < _loc5_.length)
                  {
                     _loc7_ = String(_loc5_[_loc6_]);
                     _loc8_ = _loc7_.split(":");
                     _loc9_ = JsonParser.trim(_loc8_[0] as String);
                     _loc10_ = int(parseInt(_loc9_.slice(_loc9_.indexOf("L") + 1)));
                     (this.mCollectibleLevels[_loc2_] as Array).push(_loc10_);
                     _loc9_ = JsonParser.trim(_loc8_[1] as String);
                     _loc11_ = int(parseInt(_loc9_.slice(0,_loc9_.indexOf("%"))));
                     (this.mCollectibleProbabilities[_loc2_] as Array).push(_loc11_);
                     _loc6_++;
                  }
               }
               _loc2_++;
            }
         }
      }
      
      public function getRandomItemDrop() : Item
      {
         var _loc1_:int = 0;
         var _loc2_:Object = null;
         if(this.mCollectibleItems == null)
         {
            return null;
         }
         var _loc3_:GamePlayerProfile = GameState.mInstance.mPlayerProfile;
         var _loc4_:int = _loc3_.mLevel;
         var _loc5_:int = this.mRandom.d100(_loc3_.mRewardDropSeedTerm,_loc3_.getRewardDropsCounter());
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         while(_loc7_ < this.mCollectibleItems.length)
         {
            _loc1_ = this.getItemProbabilityForLevel(_loc7_,_loc4_);
            _loc6_ += _loc1_;
            if(_loc5_ < _loc6_)
            {
               _loc2_ = this.mCollectibleItems[_loc7_];
               MagicBoxTracker.generateEvent(MagicBoxTracker.GROUP_ECONOMY,MagicBoxTracker.TYPE_GAIN_ITEM,MagicBoxTracker.PS_RANDOM_ITEM + "_" + _loc2_.ID,MagicBoxTracker.paramsObj(_loc2_.Type,_loc2_.ID));
               return ItemManager.getItem(_loc2_.ID,_loc2_.Type);
            }
            _loc7_++;
         }
         return null;
      }
      
      public function getPermanentDestroyArray() : Array
      {
         return this.mPermanentDestroyArray;
      }
      
      private function getItemProbabilityForLevel(param1:int, param2:int) : int
      {
         var _loc3_:Array = this.mCollectibleLevels[param1];
         var _loc4_:int = int(_loc3_.length - 1);
         while(_loc4_ >= 0)
         {
            if(param2 >= _loc3_[_loc4_])
            {
               return this.mCollectibleProbabilities[param1][_loc4_];
            }
            _loc4_--;
         }
         return 0;
      }
   }
}

