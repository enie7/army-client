package game.actions
{
   import game.battlefield.MapArea;
   import game.battlefield.MapData;
   import game.characters.AnimationController;
   import game.characters.EnemyUnit;
   import game.characters.PlayerUnit;
   import game.gameElements.DecorationObject;
   import game.gameElements.EnemyInstallationObject;
   import game.gameElements.FireMissionObject;
   import game.gameElements.HFEPlotObject;
   import game.gameElements.PlayerBuildingObject;
   import game.gameElements.PlayerInstallationObject;
   import game.gameElements.ResourceBuildingObject;
   import game.gameElements.SignalObject;
   import game.gameElements.SpawningBeaconObject;
   import game.isometric.GridCell;
   import game.isometric.IsometricScene;
   import game.isometric.elements.Renderable;
   import game.items.DecorationItem;
   import game.items.EnemyInstallationItem;
   import game.items.FireMissionItem;
   import game.items.Item;
   import game.items.ItemManager;
   import game.items.TargetItem;
   import game.magicBox.MagicBoxTracker;
   import game.missions.MissionManager;
   import game.net.MyServer;
   import game.net.ServiceIDs;
   import game.player.GamePlayerProfile;
   import game.player.Inventory;
   import game.states.GameState;
   
   public class FireMissionAction extends Action
   {
      
      protected static const COORD_PAIR_DELIMITER_STR:String = ";";
      
      protected static const COORD_XY_DELIMITER_STR:String = ",";
      
      protected var mObject:FireMissionObject;
      
      protected var mGC:GridCell;
      
      protected var mItem:FireMissionItem;
      
      protected var mTargets:Array;
      
      protected var mKilledEnemyCount:int;
      
      private var mLastAttackDamageInstallations:Array;
      
      public function FireMissionAction(param1:GridCell, param2:FireMissionItem)
      {
         super("FireMission");
         this.mGC = param1;
         this.mItem = param2;
         this.mLastAttackDamageInstallations = new Array();
      }
      
      override public function update(param1:int) : void
      {
         if(this.mObject)
         {
            this.mObject.update();
            if(this.mObject.isOver())
            {
               if(!mSkipped)
               {
                  this.execute();
               }
            }
            if(this.mObject.isOver() || mSkipped)
            {
               this.mObject.destroy();
            }
         }
      }
      
      override public function isOver() : Boolean
      {
         return (this.mObject ? this.mObject.isOver() : true) || mSkipped;
      }
      
      protected function hasIngredients() : Boolean
      {
         var _loc1_:String = null;
         var _loc2_:Item = null;
         var _loc3_:Inventory = GameState.mInstance.mPlayerProfile.mInventory;
         for(_loc1_ in this.mItem.mRequiredItemSet.mItems)
         {
            _loc2_ = this.mItem.mRequiredItemSet.mItems[_loc1_];
            if(_loc3_.getNumberOfItems(_loc2_) < this.mItem.mRequiredItemSet.mAmounts[_loc1_])
            {
               if(Config.DEBUG_MODE)
               {
               }
               return false;
            }
         }
         return true;
      }
      
      override public function start() : void
      {
         var _loc1_:GameState = null;
         _loc1_ = null;
         var _loc2_:Renderable = null;
         var _loc3_:GridCell = null;
         if(!this.hasIngredients())
         {
            this.skip();
         }
         if(mSkipped)
         {
            return;
         }
         _loc1_ = GameState.mInstance;
         var _loc4_:Array = MapArea.getArea(_loc1_.mScene,this.mGC.mPosI,this.mGC.mPosJ,this.mItem.mSize.x,this.mItem.mSize.y).getCells();
         this.mObject = new FireMissionObject(this.mItem,_loc4_);
         this.mTargets = new Array();
         var _loc5_:int = 0;
         while(_loc5_ < _loc4_.length)
         {
            _loc3_ = _loc4_[_loc5_];
            if(_loc3_.mCharacter)
            {
               this.mTargets.push(_loc3_.mCharacter);
            }
            else if(_loc3_.mObject)
            {
               this.mTargets.push(_loc3_.mObject);
            }
            _loc5_++;
         }
         var _loc6_:int = int(this.mTargets.length);
         var _loc7_:int = 0;
         while(_loc7_ < _loc6_)
         {
            _loc2_ = this.mTargets[_loc7_] as Renderable;
            if(_loc2_ is EnemyInstallationObject)
            {
               if((_loc2_ as EnemyInstallationObject).isForceFieldActivated())
               {
                  (_loc2_ as EnemyInstallationObject).setAnimationAction(AnimationController.INSTALLATION_ANIMATION_HIT,false,true);
               }
            }
            _loc7_++;
         }
         this.mObject.start();
         _loc1_.mScene.mSceneHud.addChild(this.mObject);
         this.mObject.x = _loc1_.mScene.mGridDimX * this.mGC.mPosI;
         this.mObject.y = _loc1_.mScene.mGridDimY * this.mGC.mPosJ;
      }
      
      protected function execute() : void
      {
         var _loc18_:String = null;
         var _loc19_:Array = null;
         var _loc20_:int = 0;
         var _loc21_:int = 0;
         var _loc1_:Renderable = null;
         var _loc2_:Object = null;
         var _loc3_:GridCell = null;
         var _loc4_:Boolean = false;
         var _loc5_:Object = null;
         var _loc6_:Object = null;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:Item = null;
         var _loc10_:GameState = GameState.mInstance;
         var _loc11_:Array = new Array();
         var _loc12_:Array = new Array();
         var _loc13_:Array = [0,0,0,0];
         var _loc14_:int = _loc10_.mPlayerProfile.mRewardDropsCounter;
         this.mKilledEnemyCount = 0;
         var _loc15_:String = "";
         var _loc16_:int = int(this.mTargets.length);
         var _loc17_:int = 0;
         if(!GameState.mInstance.mPlayerProfile.hasEnoughMapResource(1))
         {
            GameState.mInstance.mHUD.openOutOfMapResourceWindow();
            this.skip();
            return;
         }
         for(; _loc17_ < _loc16_; _loc17_++)
         {
            _loc1_ = this.mTargets[_loc17_] as Renderable;
            if(_loc1_.mScene)
            {
               _loc4_ = true;
               if(_loc1_ is PlayerUnit)
               {
                  this.damageOwnUnit(_loc1_ as PlayerUnit);
               }
               else if(_loc1_ is PlayerBuildingObject)
               {
                  if(_loc1_ is ResourceBuildingObject || _loc1_ is SignalObject)
                  {
                     continue;
                  }
                  this.damageOwnBuilding(_loc1_ as PlayerBuildingObject);
               }
               else if(_loc1_ is PlayerInstallationObject)
               {
                  this.damageOwnInstallation(_loc1_ as PlayerInstallationObject);
               }
               else if(_loc1_ is EnemyUnit)
               {
                  _loc4_ = this.attackUnit(_loc1_ as EnemyUnit,_loc11_,_loc12_,_loc13_);
               }
               else if(_loc1_ is EnemyInstallationObject)
               {
                  if(!(_loc1_ is SpawningBeaconObject))
                  {
                     _loc4_ = this.attackInstallation(_loc1_ as EnemyInstallationObject,_loc11_,_loc12_,_loc13_);
                     if(!_loc4_)
                     {
                        if((_loc1_ as EnemyInstallationObject).isForceFieldActivated())
                        {
                           (_loc1_ as EnemyInstallationObject).setAnimationAction(AnimationController.INSTALLATION_ANIMATION_IDLE,false,true);
                        }
                     }
                  }
               }
               if(_loc4_)
               {
                  if(_loc15_.length > 0)
                  {
                     _loc15_ += COORD_PAIR_DELIMITER_STR;
                  }
                  _loc15_ = _loc15_ + _loc1_.getCell().mPosI + COORD_XY_DELIMITER_STR + _loc1_.getCell().mPosJ;
               }
            }
         }
         if(this.mItem.mlaunchWithGold)
         {
            _loc2_ = {
               "fire_mission_id":this.mItem.mId,
               "coords":_loc15_,
               "cost_energy":1,
               "gold":this.mItem.mUnlockCost,
               "reward_xp":_loc13_[0],
               "reward_money":_loc13_[1],
               "reward_supplies":_loc13_[2],
               "reward_energy":_loc13_[3]
            };
         }
         else
         {
            _loc2_ = {
               "fire_mission_id":this.mItem.mId,
               "coords":_loc15_,
               "cost_energy":1,
               "gold":0,
               "reward_xp":_loc13_[0],
               "reward_money":_loc13_[1],
               "reward_supplies":_loc13_[2],
               "reward_energy":_loc13_[3]
            };
         }
         if(_loc10_.mMapData.mMapSetupData.Resource)
         {
            _loc2_[MyServer.MAP_RESOURCE_COST_NAMES[_loc10_.mMapData.mMapSetupData.Resource]] = 1;
         }
         if(this.mKilledEnemyCount > 0)
         {
            _loc2_.reward_drop_seed_term = _loc10_.mPlayerProfile.mRewardDropSeedTerm;
            _loc2_.reward_drops_counter = _loc14_;
            _loc2_.reward_drops_counter_delta = this.mKilledEnemyCount;
         }
         if(_loc11_.length > 0)
         {
            _loc2_.reward_item_type = _loc11_.toString();
            _loc2_.reward_item_id = _loc12_.toString();
         }
         _loc18_ = null;
         if(_loc10_.visitingFriend())
         {
            _loc18_ = _loc10_.mVisitingFriend.mFacebookID;
         }
         MagicBoxTracker.generateEvent(MagicBoxTracker.GROUP_GAME,MagicBoxTracker.TYPE_FIRE_MISSION,this.mItem.mId,MagicBoxTracker.paramsObj(this.mItem.mId,_loc18_));
         if(this.mLastAttackDamageInstallations.length > 0)
         {
            _loc7_ = 0;
            while(_loc7_ < this.mLastAttackDamageInstallations.length)
            {
               if(_loc7_ == this.mLastAttackDamageInstallations.length - 1)
               {
                  GameState.mInstance.queueAction(new LastAttackAction(this.mLastAttackDamageInstallations[_loc8_],ServiceIDs.USE_FIRE_MISSION,_loc2_),true);
               }
               else
               {
                  GameState.mInstance.queueAction(new LastAttackAction(this.mLastAttackDamageInstallations[_loc8_],null,null),true);
               }
               if(Config.DEBUG_MODE)
               {
               }
               _loc7_++;
            }
         }
         else
         {
            _loc10_.mServer.serverCallServiceWithParameters(ServiceIDs.USE_FIRE_MISSION,_loc2_,false);
         }
         _loc20_ = int((_loc19_ = MapArea.getArea(_loc10_.mScene,this.mGC.mPosI,this.mGC.mPosJ,this.mItem.mSize.x,this.mItem.mSize.y).getCells()).length);
         _loc21_ = 0;
         while(_loc21_ < _loc20_)
         {
            _loc3_ = _loc19_[_loc21_] as GridCell;
            if(MapData.isTilePassable(_loc3_.mType))
            {
               if(!_loc3_.mObject && !_loc3_.mCharacter)
               {
                  _loc10_.spawnNewDebris("ScorchedGround","Debris",_loc10_.mScene.getCenterPointXOfCell(_loc3_),_loc10_.mScene.getCenterPointYOfCell(_loc3_));
               }
               else if(Boolean(_loc3_.mObject && (_loc3_.mObject is DecorationObject && DecorationObject(_loc3_.mObject).getHealth() == 0 && !DecorationItem(_loc3_.mObject.mItem).mLeaveRuins)) || Boolean(_loc3_.mObject is EnemyInstallationObject && EnemyInstallationObject(_loc3_.mObject).getHealth() == 0) || _loc3_.mObject is HFEPlotObject && HFEPlotObject(_loc3_.mObject).getHealth() == 0)
               {
                  _loc3_.mObject.mKilledByFireMission = true;
               }
               else if(_loc3_.mCharacter)
               {
                  if(_loc3_.mCharacter.getHealth() > 0)
                  {
                     _loc10_.spawnNewDebris("ScorchedGround","Debris",_loc10_.mScene.getCenterPointXOfCell(_loc3_),_loc10_.mScene.getCenterPointYOfCell(_loc3_));
                  }
                  else if(!(_loc3_.mCharacter is PlayerUnit))
                  {
                     _loc3_.mCharacter.mKilledByFireMission = true;
                  }
               }
            }
            _loc21_++;
         }
         if(!this.mItem.mlaunchWithGold)
         {
            while(_loc8_ < this.mItem.mRequiredItemSet.mItems.length)
            {
               _loc9_ = this.mItem.mRequiredItemSet.mItems[_loc8_];
               if(_loc9_)
               {
                  _loc10_.mPlayerProfile.addItem(_loc9_,-this.mItem.mRequiredItemSet.mAmounts[_loc8_]);
               }
               _loc8_++;
            }
         }
         _loc10_.reduceEnergy(mName,1,MagicBoxTracker.paramsObj(this.mItem.mType,this.mItem.mId));
         _loc10_.reduceMapResource(1);
         this.mObject.destroy();
         _loc10_.updateGrid();
         _loc10_.playerMoveMade();
         if(this.mItem.mlaunchWithGold)
         {
            this.mItem.mlaunchWithGold = false;
         }
      }
      
      protected function damageOwnBuilding(param1:PlayerBuildingObject) : void
      {
         param1.addHealth(-this.mItem.mDamage);
      }
      
      protected function damageOwnInstallation(param1:PlayerInstallationObject) : void
      {
         param1.reduceHealth(this.mItem.mDamage);
      }
      
      protected function damageOwnUnit(param1:PlayerUnit) : void
      {
         param1.reduceHealth(this.mItem.mDamage);
      }
      
      private function attackUnit(param1:EnemyUnit, param2:Array, param3:Array, param4:Array) : Boolean
      {
         var _loc6_:GameState = null;
         var _loc5_:Item = null;
         if(!param1 || !param1.isAlive())
         {
            Utils.LogError("Firemission: Enemy not found");
            return false;
         }
         _loc6_ = GameState.mInstance;
         var _loc7_:IsometricScene = _loc6_.mScene;
         var _loc8_:GamePlayerProfile = _loc6_.mPlayerProfile;
         var _loc9_:* = param1.getHealth() - this.mItem.mDamage <= 0;
         var _loc10_:int = param1.mHitRewardXP;
         var _loc11_:int = param1.mHitRewardMoney;
         var _loc12_:int = param1.mHitRewardMaterial;
         var _loc13_:int = param1.mHitRewardSupplies;
         var _loc14_:int = param1.mHitRewardEnergy;
         if(_loc9_)
         {
            _loc10_ += param1.mKillRewardXP;
            _loc11_ += param1.mKillRewardMoney;
            _loc13_ += param1.mKillRewardSupplies;
            _loc14_ += param1.mKillRewardEnergy;
            MissionManager.increaseCounter("KillWith",this.mItem,1);
         }
         param4[0] += _loc10_;
         param4[1] += _loc11_;
         param4[2] += _loc13_;
         param4[3] += _loc14_;
         _loc8_.increaseEnergyRewardCounter(_loc14_);
         var _loc15_:int = _loc8_.getBonusEnergy();
         _loc6_.mScene.addLootReward(ItemManager.getItem("XP","Resource"),_loc10_,param1.getContainer());
         _loc6_.mScene.addLootReward(ItemManager.getItem("Money","Resource"),_loc11_,param1.getContainer());
         _loc6_.mScene.addLootReward(ItemManager.getItem("Supplies","Resource"),_loc13_,param1.getContainer());
         _loc6_.mScene.addLootReward(ItemManager.getItem("Energy","Resource"),_loc15_,param1.getContainer());
         if(_loc9_)
         {
            ++this.mKilledEnemyCount;
            _loc5_ = (param1.mItem as TargetItem).getRandomItemDrop();
            _loc6_.mScene.addLootReward(_loc5_,1,param1.getContainer());
         }
         if(_loc5_)
         {
            param2.push(ItemManager.getTableNameForItem(_loc5_));
            param3.push(_loc5_.mId);
         }
         param1.reduceHealth(this.mItem.mDamage);
         param1.changeReactionState(EnemyUnit.REACT_STATE_WAIT_FOR_TIMER);
         return true;
      }
      
      private function attackInstallation(param1:EnemyInstallationObject, param2:Array, param3:Array, param4:Array) : Boolean
      {
         var _loc13_:GameState = null;
         var _loc17_:* = undefined;
         var _loc5_:EnemyInstallationItem = null;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         var _loc10_:int = 0;
         var _loc11_:int = 0;
         var _loc12_:Item = null;
         if(!param1 || !param1.isAlive())
         {
            Utils.LogError("Firemission: Enemyinstallation not found");
            return false;
         }
         if(param1.isForceFieldActivated())
         {
            return false;
         }
         _loc13_ = GameState.mInstance;
         var _loc14_:GamePlayerProfile = _loc13_.mPlayerProfile;
         var _loc15_:IsometricScene = _loc13_.mScene;
         var _loc16_:int = this.mItem.mDamage;
         _loc17_ = param1.getHealth() == 0;
         var _loc18_:Boolean = !_loc17_ && param1.getHealth() - _loc16_ <= 0;
         if(!_loc17_)
         {
            _loc5_ = param1.mItem as EnemyInstallationItem;
            _loc6_ = _loc5_.mHitRewardXP;
            _loc7_ = _loc5_.mHitRewardMoney;
            _loc8_ = _loc5_.mHitRewardMaterial;
            _loc9_ = _loc5_.mHitRewardSupplies;
            _loc10_ = _loc5_.mHitRewardEnergy;
            if(_loc18_)
            {
               _loc6_ += _loc5_.mKillRewardXP;
               _loc7_ += _loc5_.mKillRewardMoney;
               _loc9_ += _loc5_.mKillRewardSupplies;
               _loc10_ += _loc5_.mKillRewardEnergy;
               MissionManager.increaseCounter("KillWith",this.mItem,1);
            }
            param4[0] += _loc6_;
            param4[1] += _loc7_;
            param4[2] += _loc9_;
            param4[3] += _loc10_;
            _loc14_.increaseEnergyRewardCounter(_loc10_);
            _loc11_ = _loc14_.getBonusEnergy();
            _loc15_.addLootReward(ItemManager.getItem("XP","Resource"),_loc6_,param1.getContainer());
            _loc15_.addLootReward(ItemManager.getItem("Money","Resource"),_loc7_,param1.getContainer());
            _loc15_.addLootReward(ItemManager.getItem("Supplies","Resource"),_loc9_,param1.getContainer());
            _loc15_.addLootReward(ItemManager.getItem("Energy","Resource"),_loc11_,param1.getContainer());
            if(_loc18_)
            {
               ++this.mKilledEnemyCount;
               _loc12_ = _loc5_.getRandomItemDrop();
               _loc15_.addLootReward(_loc12_,1,param1.getContainer());
               if(param1.mLastAttackDamage > 0)
               {
                  this.mLastAttackDamageInstallations.push(param1);
               }
            }
            if(_loc12_)
            {
               param2.push(ItemManager.getTableNameForItem(_loc12_));
               param3.push(_loc12_.mId);
            }
            param1.reduceHealth(_loc16_);
            param1.resetReactionTimer();
         }
         return true;
      }
      
      override public function skip() : void
      {
         if(!this.mItem.mlaunchWithGold)
         {
            super.skip();
         }
      }
   }
}

