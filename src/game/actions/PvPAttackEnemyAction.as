package game.actions
{
   import game.characters.PvPEnemyUnit;
   import game.gameElements.PlayerInstallationObject;
   import game.isometric.IsometricScene;
   import game.isometric.characters.IsometricCharacter;
   import game.items.Item;
   import game.items.ItemManager;
   import game.items.TargetItem;
   import game.player.GamePlayerProfile;
   import game.states.GameState;
   
   public class PvPAttackEnemyAction extends AttackEnemyAction
   {
      
      public function PvPAttackEnemyAction(param1:Array, param2:PlayerInstallationObject, param3:PvPEnemyUnit, param4:Boolean = true)
      {
         super(param1,param2,param3,param4);
      }
      
      override public function start() : void
      {
         var _loc1_:Boolean = false;
         var _loc2_:* = 0;
         if(mSkipped)
         {
            return;
         }
         if(Boolean(mTarget == null || !mTarget.isAlive()) || Boolean((mTarget as PvPEnemyUnit).mCurrentAction) || GameState.mInstance.mPvPMatch.mActionsLeft == 0)
         {
            skip();
            return;
         }
         if(mActor)
         {
            if(!(mActor as PlayerInstallationObject).canAttack())
            {
               skip();
               return;
            }
         }
         else if(mCharacterActors)
         {
            mCharacterActors = GameState.mInstance.searchAttackablePlayerUnits(mTarget as PvPEnemyUnit);
            _loc1_ = false;
            _loc2_ = 0;
            while(_loc2_ < mCharacterActors.length)
            {
               if((mCharacterActors[_loc2_] as IsometricCharacter).isAlive())
               {
                  _loc1_ = true;
               }
               else
               {
                  mCharacterActors.splice(_loc2_,1);
                  _loc2_--;
               }
               _loc2_++;
            }
            if(!_loc1_ || mCharacterActors.length == 0)
            {
               skip();
               return;
            }
         }
         setDirection(mTarget.mX);
         mNewState = STATE_BEFORE_ATTACK;
      }
      
      override protected function execute() : void
      {
         var _loc1_:Item = null;
         var _loc2_:Boolean = false;
         var _loc3_:PvPEnemyUnit = mTarget as PvPEnemyUnit;
         if(!_loc3_ || !_loc3_.isAlive())
         {
            Utils.LogError("PvPAttackEnemyAction: Enemy not found");
            mNewState = STATE_OVER;
            return;
         }
         if(mState != STATE_ATTACKING)
         {
            Utils.LogError("PvPAttackEnemyAction: Illegal state");
            mNewState = STATE_OVER;
            return;
         }
         var _loc4_:GameState = GameState.mInstance;
         var _loc5_:IsometricScene = _loc4_.mScene;
         var _loc6_:GamePlayerProfile = _loc4_.mPlayerProfile;
         var _loc7_:Boolean = _loc3_.getHealth() > 0 && _loc3_.getHealth() - getCombinedDamage() <= 0;
         var _loc8_:int = _loc3_.mHitRewardBadassXP;
         if(_loc7_)
         {
            _loc8_ += _loc3_.mKillRewardBadassXP;
         }
         _loc5_.addLootReward(ItemManager.getItem("BadAssXP","Resource"),_loc8_,_loc3_.getContainer());
         _loc4_.mPvPMatch.addIngameBaddassXp(_loc8_);
         if(_loc7_)
         {
            _loc1_ = (_loc3_.mItem as TargetItem).getRandomItemDrop();
            _loc5_.addLootReward(_loc1_,1,_loc3_.getContainer());
            _loc4_.mPvPMatch.addIngameCollectible(_loc1_);
         }
         var _loc9_:int = getCombinedDamage();
         if(!mActor && Boolean(mCharacterActors))
         {
            _loc2_ = false;
         }
         else
         {
            _loc2_ = true;
         }
         _loc3_.reduceHealth(_loc9_);
         mNewState = STATE_OVER;
         _loc4_.playerMoveMade();
      }
   }
}

