package game.actions
{
   import game.characters.AnimationController;
   import game.characters.PlayerUnit;
   import game.gameElements.EnemyInstallationObject;
   import game.isometric.GridCell;
   import game.isometric.IsometricScene;
   import game.isometric.characters.IsometricCharacter;
   import game.items.Item;
   import game.items.ItemManager;
   import game.items.TargetItem;
   import game.net.ServiceIDs;
   import game.player.GamePlayerProfile;
   import game.states.GameState;
   import game.utils.EffectController;
   
   public class EnemyInstallationAttackAllAround extends Action
   {
      
      private static const STATE_BEFORE_ATTACK:int = 0;
      
      private static const STATE_ATTACKING:int = 1;
      
      private static const STATE_OVER:int = 2;
      
      private var mDurationAttack:int;
      
      private var mTargets:Array;
      
      private var mTimer:int;
      
      private var mState:int;
      
      private var mNewState:int;
      
      public function EnemyInstallationAttackAllAround(param1:EnemyInstallationObject)
      {
         super("EnemyInstallationAttackAllAround");
         mActor = param1;
         this.mTimer = 0;
         this.mState = -1;
         this.mNewState = -1;
      }
      
      override public function update(param1:int) : void
      {
         if(mSkipped)
         {
            return;
         }
         if(this.mNewState != this.mState)
         {
            this.changeState(this.mNewState);
         }
         this.mTimer += param1;
         switch(this.mState)
         {
            case STATE_BEFORE_ATTACK:
               break;
            case STATE_ATTACKING:
               if(this.mTimer > this.mDurationAttack)
               {
                  this.mNewState = STATE_OVER;
               }
         }
      }
      
      private function changeState(param1:int) : void
      {
         var _loc2_:Boolean = false;
         var _loc3_:int = 0;
         var _loc4_:IsometricCharacter = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:IsometricCharacter = null;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         this.mTimer = 0;
         this.mState = param1;
         this.mNewState = param1;
         switch(this.mState)
         {
            case STATE_BEFORE_ATTACK:
               _loc2_ = false;
               this.mTargets = GameState.mInstance.searchNearbyUnits(mActor.getCell(),(mActor as EnemyInstallationObject).mAttackRange,mActor.getTileSize().x,mActor.getTileSize().y,false);
               this.mNewState = STATE_ATTACKING;
               break;
            case STATE_ATTACKING:
               mActor.playCollectionSound(mActor.mAttackSounds);
               mActor.setAnimationAction(AnimationController.INSTALLATION_ANIMATION_SHOOT,false,true);
               _loc3_ = (mActor as EnemyInstallationObject).getShootingEffect();
               this.mDurationAttack = EffectController.getEffectLength(_loc3_);
               if(this.mTargets)
               {
                  _loc5_ = int(this.mTargets.length);
                  _loc6_ = 0;
                  while(_loc6_ < _loc5_)
                  {
                     _loc4_ = this.mTargets[_loc6_] as IsometricCharacter;
                     _loc4_.setAnimationAction(AnimationController.CHARACTER_ANIMATION_HIT,false,true);
                     _loc4_.showActingHealthBar();
                     GameState.mInstance.mScene.addEffect(null,_loc3_,_loc4_.mX,_loc4_.mY);
                     _loc6_++;
                  }
               }
               else
               {
                  this.mDurationAttack = 0;
               }
               this.execute();
               break;
            case STATE_OVER:
               if(this.mTargets)
               {
                  _loc8_ = int(this.mTargets.length);
                  _loc9_ = 0;
                  while(_loc9_ < _loc8_)
                  {
                     _loc7_ = this.mTargets[_loc9_] as IsometricCharacter;
                     if(_loc7_.isAlive())
                     {
                        _loc7_.setAnimationAction(AnimationController.CHARACTER_ANIMATION_IDLE,false,true);
                     }
                     _loc9_++;
                  }
               }
               this.mTargets = null;
               if(mActor.isAlive())
               {
                  mActor.setAnimationAction(AnimationController.INSTALLATION_ANIMATION_IDLE,false,true);
               }
         }
      }
      
      override public function isOver() : Boolean
      {
         return this.mState == STATE_OVER || mSkipped;
      }
      
      override public function start() : void
      {
         if(mSkipped)
         {
            return;
         }
         if(GameState.mInstance.mState == GameState.STATE_VISITING_NEIGHBOUR)
         {
            skip();
            return;
         }
         if(Boolean(mActor) && mActor.isAlive())
         {
            this.mNewState = STATE_BEFORE_ATTACK;
         }
         else
         {
            skip();
         }
      }
      
      private function execute() : void
      {
         var _loc1_:GridCell = null;
         var _loc2_:Object = null;
         var _loc3_:IsometricCharacter = null;
         var _loc4_:Boolean = false;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:GamePlayerProfile = null;
         var _loc10_:int = 0;
         var _loc11_:IsometricScene = null;
         var _loc12_:Item = null;
         if(GameState.mInstance.mState == GameState.STATE_VISITING_NEIGHBOUR)
         {
            this.mNewState = STATE_OVER;
            return;
         }
         var _loc13_:int = (mActor as EnemyInstallationObject).getPower();
         if(Config.DEBUG_MODE)
         {
         }
         if(this.mState != STATE_ATTACKING)
         {
            Utils.LogError("EnemyInstallationAttackAllAroundAction: Illegal state");
            this.mNewState = STATE_OVER;
            return;
         }
         var _loc14_:GameState = GameState.mInstance;
         var _loc15_:GridCell = mActor.getCell();
         var _loc16_:* = "";
         var _loc17_:* = "";
         var _loc18_:int = _loc14_.mPlayerProfile.mRewardDropsCounter;
         var _loc19_:int = 0;
         var _loc20_:Array = [0,0,0,0];
         var _loc21_:* = "";
         var _loc22_:* = "";
         if(this.mTargets)
         {
            for each(_loc3_ in this.mTargets)
            {
               _loc1_ = _loc3_.getCell();
               if(_loc3_ is PlayerUnit)
               {
                  if(_loc16_.length > 0)
                  {
                     _loc16_ += ";";
                  }
                  _loc16_ = _loc16_ + _loc1_.mPosI + "," + _loc1_.mPosJ;
               }
               else
               {
                  _loc4_ = _loc3_.getHealth() > 0 && _loc3_.getHealth() - _loc13_ <= 0;
                  _loc5_ = _loc3_.mHitRewardXP;
                  _loc6_ = _loc3_.mHitRewardMoney;
                  _loc7_ = _loc3_.mHitRewardSupplies;
                  _loc8_ = _loc3_.mHitRewardEnergy;
                  if(_loc4_)
                  {
                     _loc5_ += _loc3_.mKillRewardXP;
                     _loc6_ += _loc3_.mKillRewardMoney;
                     _loc7_ += _loc3_.mKillRewardSupplies;
                     _loc8_ += _loc3_.mKillRewardEnergy;
                  }
                  _loc9_ = _loc14_.mPlayerProfile;
                  _loc9_.increaseEnergyRewardCounter(_loc8_);
                  _loc10_ = _loc9_.getBonusEnergy();
                  _loc11_ = _loc14_.mScene;
                  _loc11_.addLootReward(ItemManager.getItem("XP","Resource"),_loc5_,_loc3_.getContainer());
                  _loc11_.addLootReward(ItemManager.getItem("Money","Resource"),_loc6_,_loc3_.getContainer());
                  _loc11_.addLootReward(ItemManager.getItem("Supplies","Resource"),_loc7_,_loc3_.getContainer());
                  _loc11_.addLootReward(ItemManager.getItem("Energy","Resource"),_loc10_,_loc3_.getContainer());
                  if(_loc4_)
                  {
                     _loc12_ = (_loc3_.mItem as TargetItem).getRandomItemDrop();
                     _loc11_.addLootReward(_loc12_,1,_loc3_.getContainer());
                     _loc19_++;
                  }
                  if(_loc12_)
                  {
                     if(_loc21_.length > 0)
                     {
                        _loc21_ += ",";
                     }
                     _loc21_ += ItemManager.getTableNameForItem(_loc12_);
                     if(_loc22_.length > 0)
                     {
                        _loc22_ += ",";
                     }
                     _loc22_ += _loc12_.mId;
                  }
                  if(_loc17_.length > 0)
                  {
                     _loc17_ += ";";
                  }
                  _loc17_ = _loc17_ + _loc1_.mPosI + "," + _loc1_.mPosJ;
                  _loc20_[0] += _loc5_;
                  _loc20_[1] += _loc6_;
                  _loc20_[2] += _loc7_;
                  _loc20_[3] += _loc8_;
               }
               _loc3_.reduceHealth(_loc13_);
               if(_loc13_ is PlayerUnit)
               {
                  if(!(_loc13_ as PlayerUnit).isAlive())
                  {
                     if((mActor as EnemyInstallationObject).destroysPermanently((_loc13_ as PlayerUnit).mItem))
                     {
                        (_loc13_ as PlayerUnit).destroyPermanently();
                     }
                  }
               }
            }
         }
         _loc2_ = {
            "enemy_coord_x":_loc15_.mPosI,
            "enemy_coord_y":_loc15_.mPosJ,
            "item_hit_points":_loc13_,
            "reward_xp":_loc20_[0],
            "reward_money":_loc20_[1],
            "reward_supplies":_loc20_[2],
            "reward_energy":_loc20_[3]
         };
         if(_loc16_.length > 0)
         {
            _loc2_.player_coords = _loc16_;
         }
         if(_loc17_.length > 0)
         {
            _loc2_.enemy_coords = _loc17_;
         }
         if(_loc21_.length > 0)
         {
            _loc2_.reward_item_type = _loc21_;
            _loc2_.reward_item_id = _loc22_;
         }
         if(_loc19_ > 0)
         {
            _loc2_.reward_drop_seed_term = _loc14_.mPlayerProfile.mRewardDropSeedTerm;
            _loc2_.reward_drops_counter = _loc18_;
            _loc2_.reward_drops_counter_delta = _loc19_;
         }
         _loc14_.mServer.serverCallServiceWithParameters(ServiceIDs.ACTIVATE_TURN_BASED_ENEMY,_loc2_,false);
         (mActor as EnemyInstallationObject).changeReactionState(EnemyInstallationObject.REACT_STATE_ACTION_COMPLETED);
         if(Config.DEBUG_MODE)
         {
         }
      }
   }
}

