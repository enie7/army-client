package game.actions
{
   import game.gameElements.EnemyInstallationObject;
   import game.gameElements.FriendSuppressObject;
   import game.gui.TextEffect;
   import game.isometric.GridCell;
   import game.isometric.IsometricScene;
   import game.isometric.SceneLoader;
   import game.items.EnemyInstallationItem;
   import game.items.Item;
   import game.items.ItemManager;
   import game.missions.MissionManager;
   import game.net.ServiceIDs;
   import game.player.GamePlayerProfile;
   import game.states.GameState;
   
   public class VisitNeighborSuppressEnemyInstallationAction extends Action
   {
      
      private var mSuppressMortar:FriendSuppressObject;
      
      public function VisitNeighborSuppressEnemyInstallationAction(param1:EnemyInstallationObject)
      {
         super("Suppress Enemy Installation");
         mTarget = param1;
         mSkipped = false;
      }
      
      override public function update(param1:int) : void
      {
         if(mSkipped)
         {
            (mTarget as EnemyInstallationObject).skipSuppress();
         }
         else if(Boolean(this.mSuppressMortar) && this.mSuppressMortar.isOver())
         {
            this.mSuppressMortar.destroy();
         }
         else
         {
            this.mSuppressMortar.update();
         }
         if((mTarget as EnemyInstallationObject).isSuppressOver())
         {
            if(Boolean(this.mSuppressMortar) && Boolean(this.mSuppressMortar.isOver()) && !mSkipped)
            {
               this.execute();
            }
         }
      }
      
      override public function isOver() : Boolean
      {
         if(!this.mSuppressMortar)
         {
            return true;
         }
         return (mTarget as EnemyInstallationObject).isSuppressOver() && this.mSuppressMortar.isOver() || mSkipped;
      }
      
      override public function start() : void
      {
         if(mSkipped)
         {
            return;
         }
         if(Boolean(mTarget == null || !mTarget.isAlive()) || Boolean((mTarget as EnemyInstallationObject).mCurrentAction) || (mTarget as EnemyInstallationObject).getHealth() == 0)
         {
            mSkipped = true;
            return;
         }
         var _loc1_:GameState = GameState.mInstance;
         if(_loc1_.mPlayerProfile.mNeighborActionsLeft <= 0)
         {
            (mTarget as EnemyInstallationObject).addTextEffect(TextEffect.TYPE_GAIN,GameState.getText("SOCIAL_ENERGY_ZERO_FLOATING"));
            mSkipped = true;
            return;
         }
         this.mSuppressMortar = new FriendSuppressObject();
         this.mSuppressMortar.start();
         _loc1_.mScene.mSceneHud.addChild(this.mSuppressMortar);
         this.mSuppressMortar.x = mTarget.mX + (mTarget.getTileSize().x - 2) * SceneLoader.GRID_CELL_SIZE / 2;
         this.mSuppressMortar.y = mTarget.mY + (mTarget.getTileSize().y - 2) * SceneLoader.GRID_CELL_SIZE / 2;
         (mTarget as EnemyInstallationObject).startSuppress();
      }
      
      private function execute() : void
      {
         var _loc6_:Object = null;
         var _loc1_:Item = null;
         var _loc2_:EnemyInstallationObject = mTarget as EnemyInstallationObject;
         if(_loc2_.hasForceField())
         {
            return;
         }
         var _loc3_:GameState = GameState.mInstance;
         var _loc4_:IsometricScene = _loc3_.mScene;
         var _loc5_:GamePlayerProfile = _loc3_.mPlayerProfile;
         var _loc7_:int = int((_loc6_ = GameState.mConfig.AllyAction.SabotageEnemyInstallation).Damage);
         var _loc8_:* = _loc2_.getHealth() - _loc7_ <= 0;
         var _loc9_:EnemyInstallationItem = _loc2_.mItem as EnemyInstallationItem;
         var _loc10_:int = int(_loc6_.RewardSocialXP);
         var _loc11_:int = _loc9_.mHitRewardMoney;
         var _loc12_:int = _loc9_.mHitRewardSupplies;
         var _loc13_:int = _loc9_.mHitRewardEnergy;
         if(_loc8_)
         {
            _loc11_ += _loc9_.mKillRewardMoney;
            _loc12_ += _loc9_.mKillRewardSupplies;
            _loc13_ += _loc9_.mKillRewardEnergy;
         }
         _loc5_.increaseEnergyRewardCounter(_loc13_);
         var _loc14_:int = _loc5_.getBonusEnergy();
         _loc4_.addLootReward(ItemManager.getItem("SocialXP","Resource"),_loc10_,_loc2_.getContainer());
         _loc4_.addLootReward(ItemManager.getItem("Money","Resource"),_loc11_,_loc2_.getContainer());
         _loc4_.addLootReward(ItemManager.getItem("Supplies","Resource"),_loc12_,_loc2_.getContainer());
         _loc4_.addLootReward(ItemManager.getItem("Energy","Resource"),_loc14_,_loc2_.getContainer());
         var _loc15_:int = _loc5_.mRewardDropsCounter;
         if(_loc8_)
         {
            _loc1_ = _loc9_.getRandomItemDrop();
            _loc4_.addLootReward(_loc1_,1,_loc2_.getContainer());
         }
         _loc2_.getCell().mNeighborActionAvailable = false;
         _loc2_.handleSuppress();
         _loc5_.addNeighborActions(-1);
         MissionManager.increaseCounter("HelpNeighborSuppress",_loc2_,1);
         var _loc16_:GridCell = mTarget.getCell();
         var _loc17_:Object = {
            "coord_x":_loc16_.mPosI,
            "coord_y":_loc16_.mPosJ,
            "item_hit_points":_loc7_,
            "neighbor_user_id":_loc3_.mVisitingFriend.mUserID,
            "reward_social_xp":_loc10_,
            "reward_money":_loc11_,
            "reward_supplies":_loc12_,
            "reward_energy":_loc13_,
            "neighbor_counter":"Suppress",
            "target_type":ItemManager.getTableNameForItem(_loc2_.mItem),
            "target_id":_loc2_.mItem.mId
         };
         if(_loc8_)
         {
            _loc17_.reward_drop_seed_term = _loc5_.mRewardDropSeedTerm;
            _loc17_.reward_drops_counter = _loc15_;
         }
         if(_loc1_)
         {
            _loc17_.reward_item_type = ItemManager.getTableNameForItem(_loc1_);
            _loc17_.reward_item_id = _loc1_.mId;
         }
         if(_loc3_.visitingTutor())
         {
            _loc17_.tutor_map = 2;
         }
         GameState.mInstance.mServer.serverCallServiceWithParameters(ServiceIDs.SCHEDULE_ACTION_AT_NEIGHBOR,_loc17_,false);
         if(Config.DEBUG_MODE)
         {
         }
      }
   }
}

