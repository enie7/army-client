package game.items
{
   import game.states.GameState;
   
   public class ItemManager
   {
      
      private static var mItemList:Array;
      
      private static var mItemListByTableName:Array;
      
      private static var mTableNameForItem:Array;
      
      public function ItemManager()
      {
         super();
      }
      
      public static function initialize() : void
      {
         mItemList = new Array();
         mItemListByTableName = new Array();
         mTableNameForItem = new Array();
         addItems("HomeFrontEffort",createHFE);
         addItems("PermanentHFE",createPermanentHFE);
         addItems("HFEDrives",createHFEDrive);
         addItems("BuildingDrives",createBuildingDrive);
         addItems("Building",createConstructionItem);
         addItems("ResourceBuilding",createResourceBuildingItem);
         addItems("HospitalBuilding",createHospitalBuildingItem);
         addItems("PlayerUnit",createPlayerUnitItem);
         addItems("EnemyUnit",createEnemyUnitItem);
         addItems("EnemyAppearanceSetup",createEnemyAppearanceSetup);
         addItems("EnemyInstallation",createEnemyInstallationItem);
         addItems("PlayerInstallation",createPlayerInstallationItem);
         addItems("EnergyRefill",createEnergyRefillItem);
         addItems("Debris",createDebrisItem);
         addItems("Deco",createDecorationItem);
         addItems("MapArea",createAreaItem);
         addItems("Booster",createBoosterItem);
         addItems("SupplyPack",createSupplyPackItem);
         addItems("BuyGold",createBuyGoldItem);
         addItems("BuyCash",createBuyGoldItem);
         addItems("Resource",createResourceItem);
         addItems("Ingredient",createResourceItem);
         addItems("Intel",createResourceItem);
         addItems("Medal",createResourceItem);
         addItems("AllyReport",createResourceItem);
         addItems("Collectible",createCollectibleItem);
         addItems("Collections",createItemCollectionItem);
         addItems("FireMission",createFireMissionItem);
         addItems("PowerUp",createPowerUpItem);
         addItems("Timers",createTimerItem);
         addItems("WaterPack",createWaterPackItem);
         addItems("Bundle",createBundleItem);
      }
      
      private static function addItems(param1:String, param2:Function) : void
      {
         var _loc3_:Object = null;
         var _loc4_:Item = null;
         var _loc5_:String = null;
         var _loc6_:Object = GameState.mConfig[param1];
         if(!_loc6_)
         {
            return;
         }
         for each(_loc3_ in _loc6_)
         {
            if(_loc3_.hasOwnProperty("RewardXp"))
            {
               _loc3_.RewardXP = _loc3_.RewardXp;
            }
            else if(_loc3_.hasOwnProperty("RewardXP"))
            {
               _loc3_.RewardXp = _loc3_.RewardXP;
            }
            _loc4_ = param2(_loc3_);
            _loc4_.initGraphics(_loc3_);
            _loc5_ = _loc4_.mType + "_" + _loc4_.mId;
            mItemList[_loc5_] = _loc4_;
            mTableNameForItem[_loc5_] = param1;
            _loc5_ = param1 + "_" + _loc4_.mId;
            mItemListByTableName[_loc5_] = _loc4_;
         }
         mItemList[_loc5_] = _loc4_;
         param2 = null;
      }
      
      private static function createHFE(param1:Object) : Item
      {
         if(param1.Type == "HFEPlot")
         {
            return new HFEPlotItem(param1);
         }
         return new HFEItem(param1);
      }
      
      private static function createPermanentHFE(param1:Object) : Item
      {
         return new PermanentHFEItem(param1);
      }
      
      private static function createEnemyAppearanceSetup(param1:Object) : Item
      {
         return new EnemyAppearanceSetupItem(param1);
      }
      
      private static function createHFEDrive(param1:Object) : Item
      {
         return new HFEDriveItem(param1);
      }
      
      private static function createBuildingDrive(param1:Object) : Item
      {
         return new BuildingDriveItem(param1);
      }
      
      private static function createPlayerUnitItem(param1:Object) : Item
      {
         return new PlayerUnitItem(param1);
      }
      
      private static function createEnemyUnitItem(param1:Object) : Item
      {
         return new EnemyUnitItem(param1);
      }
      
      private static function createEnemyInstallationItem(param1:Object) : Item
      {
         return new EnemyInstallationItem(param1);
      }
      
      private static function createPlayerInstallationItem(param1:Object) : Item
      {
         return new PlayerInstallationItem(param1);
      }
      
      private static function createEnergyRefillItem(param1:Object) : Item
      {
         return new EnergyRefillItem(param1);
      }
      
      private static function createDebrisItem(param1:Object) : Item
      {
         return new DebrisItem(param1);
      }
      
      private static function createConstructionItem(param1:Object) : Item
      {
         return new ConstructionItem(param1);
      }
      
      private static function createResourceBuildingItem(param1:Object) : Item
      {
         return new ResourceBuildingItem(param1);
      }
      
      private static function createHospitalBuildingItem(param1:Object) : Item
      {
         return new HospitalItem(param1);
      }
      
      private static function createDecorationItem(param1:Object) : Item
      {
         if(param1.Type == "Signal")
         {
            return new SignalItem(param1);
         }
         return new DecorationItem(param1);
      }
      
      private static function createResourceItem(param1:Object) : Item
      {
         return new ResourceItem(param1);
      }
      
      private static function createCollectibleItem(param1:Object) : Item
      {
         return new CollectibleItem(param1);
      }
      
      private static function createItemCollectionItem(param1:Object) : Item
      {
         return new ItemCollectionItem(param1);
      }
      
      private static function createAreaItem(param1:Object) : Item
      {
         return new AreaItem(param1);
      }
      
      private static function createPowerUpItem(param1:Object) : Item
      {
         return new PowerUpItem(param1);
      }
      
      private static function createBoosterItem(param1:Object) : Item
      {
         return new BoosterItem(param1);
      }
      
      private static function createTimerItem(param1:Object) : Item
      {
         return new TimerItem(param1);
      }
      
      private static function createFireMissionItem(param1:Object) : Item
      {
         return new FireMissionItem(param1);
      }
      
      private static function createWaterPackItem(param1:Object) : Item
      {
         return new WaterPackItem(param1);
      }
      
      private static function createBundleItem(param1:Object) : Item
      {
         return new BundleItem(param1);
      }
      
      private static function createSupplyPackItem(param1:Object) : Item
      {
         return new SupplyPackItem(param1);
      }
      
      private static function createBuyGoldItem(param1:Object) : Item
      {
         if(param1.Type == "BuyCash")
         {
            return new BuyCashItem(param1);
         }
         return new BuyGoldItem(param1);
      }
      
      public static function getItemList() : Array
      {
         return mItemList;
      }
      
      public static function getItem(param1:String, param2:String) : Item
      {
         return mItemList[param2 + "_" + param1];
      }
      
      public static function getItemByTableName(param1:String, param2:String) : Item
      {
         return mItemListByTableName[param2 + "_" + param1];
      }
      
      public static function getTableNameForItem(param1:Item) : String
      {
         return mTableNameForItem[param1.mType + "_" + param1.mId];
      }
   }
}

