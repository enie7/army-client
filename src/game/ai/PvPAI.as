package game.ai
{
   import game.actions.Action;
   import game.actions.PvPEnemyAttackingAction;
   import game.actions.PvPEnemyMovingAction;
   import game.characters.PlayerUnit;
   import game.characters.PvPEnemyUnit;
   import game.gameElements.PowerUpObject;
   import game.isometric.GridCell;
   import game.isometric.IsometricScene;
   import game.isometric.SceneLoader;
   import game.isometric.characters.IsometricCharacter;
   import game.isometric.elements.Element;
   import game.items.PowerUpItem;
   import game.net.PvPMatch;
   import game.states.GameState;
   
   public class PvPAI
   {
      
      public static const AI_DEBUG:Boolean = true;
      
      private var mModePreferFormat:Number = 0.5;
      
      private var mModePreferAttack:Number = 0.5;
      
      private var mGame:GameState;
      
      private var mScene:IsometricScene;
      
      private var mEnemyUnits:Array;
      
      private var mPlayerUnits:Array;
      
      private var mLeaderEnemy:PvPEnemyUnit;
      
      private var mArmyCoherence:Number;
      
      private var mStrikeKillPlayer:PlayerUnit;
      
      private var mStrikeKillEnemy:PvPEnemyUnit;
      
      private var mStrikeKillPreference:Number;
      
      private var mStrikeKillCell:GridCell;
      
      private var mStraightAttackAction:Action;
      
      private var mStraightAttackPreference:Number;
      
      private var mActionPriority:Number;
      
      private var mAction:Action;
      
      private var mIgnoreKillCheck:Boolean = false;
      
      private var mChooseRandomTarget:Boolean = false;
      
      private var mAttackWithWeakest:Boolean = false;
      
      private var mPowerUpFan:Boolean = false;
      
      private var mQuickAttack:Boolean = true;
      
      private var mRandomApproaching:Boolean = false;
      
      private var mDebugInfo:String;
      
      public function PvPAI(param1:GameState, param2:IsometricScene, param3:Object)
      {
         super();
         this.mGame = param1;
         this.mScene = param2;
         this.mIgnoreKillCheck = Math.random() * 100 < param3.IgnoreKillCheck;
         this.mChooseRandomTarget = Math.random() * 100 < param3.ChooseRandomTarget;
         this.mAttackWithWeakest = Math.random() * 100 < param3.AttackWithWeakest;
         this.mPowerUpFan = Math.random() * 100 < param3.PowerUpFan;
         this.mQuickAttack = Math.random() * 100 < param3.QuickAttack;
         this.mRandomApproaching = Math.random() * 100 < param3.RandomApproaching;
      }
      
      public function makeMove() : void
      {
         this.mEnemyUnits = this.mScene.getPvPEnemyAliveUnits();
         this.mPlayerUnits = this.mScene.getPlayerAliveUnits();
         if(this.mEnemyUnits.length <= 0 || this.mPlayerUnits.length <= 0)
         {
            return;
         }
         this.updateLeaderActor();
         if(AI_DEBUG)
         {
         }
         if(!this.mEnemyUnits || this.mEnemyUnits.length <= 0 || !this.mPlayerUnits || this.mPlayerUnits.length <= 0)
         {
            return;
         }
         if(AI_DEBUG)
         {
            this.mDebugInfo = "";
         }
         if(this.mPowerUpFan)
         {
            this.resetBestSuggestions();
            this.planCollectPowerUp();
            if(this.mActionPriority > 0 && Boolean(this.mAction))
            {
               if(AI_DEBUG)
               {
               }
               this.mGame.queueAction(this.mAction);
               return;
            }
         }
         this.planStrikeKill();
         if(AI_DEBUG)
         {
         }
         if(this.mStrikeKillPreference > 0.5 - (this.mModePreferAttack + (1 - this.mModePreferFormat)) / 4)
         {
            if(AI_DEBUG)
            {
            }
            if(this.mStrikeKillEnemy.getCell() == this.mStrikeKillCell)
            {
               this.mGame.queueAction(new PvPEnemyAttackingAction(null,this.mStrikeKillPlayer));
            }
            else
            {
               this.mGame.queueAction(new PvPEnemyMovingAction(this.mStrikeKillEnemy,this.mStrikeKillCell,true));
            }
            return;
         }
         this.resetBestSuggestions();
         this.planStraightAttack();
         if(AI_DEBUG)
         {
         }
         if(this.mActionPriority > 0 && Boolean(this.mAction))
         {
            if(AI_DEBUG)
            {
            }
            this.mGame.queueAction(this.mAction);
            return;
         }
         this.updateArmyCoherence();
         this.resetBestSuggestions();
         this.planAttack();
         if(!this.mQuickAttack)
         {
            this.planCollectPowerUp();
         }
         if(AI_DEBUG)
         {
         }
         if(this.mActionPriority > 0 && Boolean(this.mAction))
         {
            if(AI_DEBUG)
            {
            }
            this.mGame.queueAction(this.mAction);
            return;
         }
         var _loc1_:PvPEnemyUnit = this.mEnemyUnits[Math.floor(Math.random() * this.mEnemyUnits.length)] as PvPEnemyUnit;
         if(!_loc1_.isAlive())
         {
            return;
         }
         var _loc2_:PlayerUnit = _loc1_.getPlayerInShootRange();
         if(_loc2_)
         {
            this.mGame.queueAction(new PvPEnemyAttackingAction(null,_loc2_));
         }
         else
         {
            this.mGame.queueAction(new PvPEnemyMovingAction(_loc1_));
         }
      }
      
      private function resetBestSuggestions() : void
      {
         this.mAction = null;
         this.mActionPriority = 0;
      }
      
      private function updateLeaderActor() : void
      {
         var _loc1_:PvPEnemyUnit = null;
         var _loc2_:Number = NaN;
         this.mLeaderEnemy = null;
         var _loc3_:Number = this.mAttackWithWeakest ? 1.1 : 0;
         for each(_loc1_ in this.mEnemyUnits)
         {
            _loc2_ = _loc1_.getActorPriority();
            if(this.mQuickAttack)
            {
               _loc2_ = _loc1_.getMovementRadius() / 10;
            }
            if(this.mAttackWithWeakest && _loc2_ < _loc3_ || !this.mAttackWithWeakest && _loc2_ > _loc3_)
            {
               _loc3_ = _loc2_;
               this.mLeaderEnemy = _loc1_;
            }
         }
      }
      
      private function suggestAction(param1:Action, param2:Number) : void
      {
         if(this.mRandomApproaching)
         {
            if(Math.random() < 0.1 || this.mActionPriority <= 0)
            {
               this.mAction = param1;
               this.mActionPriority = param2;
            }
         }
         else if(param2 > this.mActionPriority)
         {
            this.mAction = param1;
            this.mActionPriority = param2;
         }
      }
      
      private function planStrikeKill() : void
      {
         var _loc1_:PvPEnemyUnit = null;
         var _loc2_:PlayerUnit = null;
         var _loc3_:GridCell = null;
         var _loc4_:Number = NaN;
         var _loc5_:PlayerUnit = null;
         var _loc6_:Number = NaN;
         this.mStrikeKillPreference = 0;
         this.mStrikeKillPlayer = null;
         this.mStrikeKillEnemy = null;
         this.mStrikeKillCell = null;
         if(!this.mIgnoreKillCheck)
         {
            for each(_loc1_ in this.mEnemyUnits)
            {
               for each(_loc2_ in this.mPlayerUnits)
               {
                  _loc3_ = _loc1_.getStrikeKillCell(_loc2_);
                  if(_loc3_)
                  {
                     this.mDebugInfo += "cell found, ";
                     _loc5_ = _loc2_.getClosestPlayerUnit();
                     if(_loc5_)
                     {
                        _loc6_ = _loc5_.distanceToCell(_loc3_) / SceneLoader.GRID_CELL_SIZE - _loc5_.getAttackRange();
                        _loc4_ = Math.sqrt(1 - 1 / Math.max(1,_loc6_));
                     }
                     else
                     {
                        _loc4_ = 1;
                     }
                     if(_loc4_ > this.mStrikeKillPreference)
                     {
                        this.mStrikeKillPreference = _loc4_;
                        this.mStrikeKillPlayer = _loc2_;
                        this.mStrikeKillEnemy = _loc1_;
                        this.mStrikeKillCell = _loc3_;
                     }
                  }
               }
            }
         }
      }
      
      private function planStraightAttack() : void
      {
         var _loc1_:PlayerUnit = null;
         var _loc2_:Array = null;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:Number = NaN;
         var _loc6_:Action = null;
         var _loc7_:IsometricCharacter = null;
         var _loc8_:int = 0;
         var _loc9_:PvPEnemyUnit = null;
         var _loc10_:Array = null;
         var _loc11_:Array = null;
         var _loc12_:GridCell = null;
         this.mStraightAttackPreference = 0;
         this.mStraightAttackAction = null;
         var _loc13_:PvPMatch = this.mGame.mPvPMatch;
         for each(_loc1_ in this.mPlayerUnits)
         {
            _loc2_ = this.searchAttackablePvPEnemyUnits(_loc1_);
            if(_loc2_.length > 0)
            {
               this.mDebugInfo += "attackable pvpEnemy found, ";
               _loc3_ = 0;
               _loc4_ = 0;
               while(_loc4_ < _loc2_.length)
               {
                  _loc7_ = _loc2_[_loc4_] as IsometricCharacter;
                  _loc3_ += _loc7_.getPower();
                  _loc4_++;
               }
               _loc5_ = Math.min(1,_loc3_ / 10) + _loc1_.getTargetPriority();
               _loc5_ = _loc5_ / 2;
               if(_loc3_ * _loc13_.mActionsLeft >= _loc1_.getHealth() && this.mModePreferFormat < 0.5)
               {
                  _loc5_ = (_loc5_ + 1) * 0.5;
               }
               _loc6_ = new PvPEnemyAttackingAction(null,_loc1_);
               this.suggestAction(_loc6_,_loc5_);
               this.mDebugInfo += "attack priority " + _loc5_ + "(" + Math.min(1,_loc3_ / 10) + "," + _loc1_.getTargetPriority() + "), ";
               if(_loc13_.mActionsLeft > 1 && !this.mQuickAttack)
               {
                  _loc8_ = 0;
                  while(_loc8_ < this.mEnemyUnits.length)
                  {
                     if(_loc2_.indexOf(this.mEnemyUnits[_loc8_]) < 0)
                     {
                        _loc9_ = this.mEnemyUnits[_loc8_];
                        if(_loc3_ <= _loc9_.getPower() * (_loc13_.mActionsLeft - 1))
                        {
                           _loc10_ = _loc9_.getWalkableCells();
                           _loc11_ = this.mScene.getNeighboringAvailableCellsAtChessboardDistance(_loc1_.getCell(),_loc9_.getAttackRange());
                           _loc12_ = this.mScene.chooseCellClosestToCellAvoidingPlayers(_loc11_,_loc9_.getCell());
                           if(_loc10_.indexOf(_loc12_) >= 0)
                           {
                              _loc5_ = Math.min(1,_loc3_ / 10) + _loc1_.getTargetPriority() + 1;
                              _loc5_ = _loc5_ / 3;
                              _loc6_ = new PvPEnemyMovingAction(_loc9_,_loc12_,true);
                              this.suggestAction(_loc6_,_loc5_);
                              this.mDebugInfo += "move priority " + _loc5_ + "(" + Math.min(1,_loc3_ / 10) + "," + _loc1_.getTargetPriority() + "," + 1 + "), ";
                           }
                        }
                     }
                     _loc8_++;
                  }
               }
            }
         }
      }
      
      private function getEnemyUnitIncoherence(param1:PvPEnemyUnit) : int
      {
         var _loc2_:int = Math.round(Math.max(param1.mX - this.mLeaderEnemy.mX,param1.mY - this.mLeaderEnemy.mY) / SceneLoader.GRID_CELL_SIZE);
         if(_loc2_ <= 1)
         {
            return 0;
         }
         return Math.ceil((_loc2_ - 1) / param1.mMovementRange);
      }
      
      private function updateArmyCoherence() : void
      {
         var _loc1_:PvPEnemyUnit = null;
         var _loc2_:int = 0;
         var _loc3_:Array = this.mScene.getNeighboringAvailableCellsAtChessboardDistance(this.mLeaderEnemy.getCell(),1.5);
         var _loc4_:int = int(_loc3_.length);
         if(_loc4_ <= 0)
         {
            this.mArmyCoherence = 1;
            return;
         }
         for each(_loc1_ in this.mEnemyUnits)
         {
            if(_loc1_ != this.mLeaderEnemy)
            {
               _loc2_ += this.getEnemyUnitIncoherence(_loc1_);
            }
         }
         this.mArmyCoherence = Math.max(0,1 - _loc2_ / Math.max(this.mEnemyUnits.length - 1,1));
         if(_loc4_ == 1)
         {
            this.mArmyCoherence = Math.sqrt(this.mArmyCoherence);
         }
      }
      
      private function getIntersection(param1:Array, param2:Array) : Array
      {
         var _loc3_:GridCell = null;
         var _loc4_:Array = new Array();
         for each(_loc3_ in param1)
         {
            if(param2.indexOf(_loc3_) >= 0)
            {
               _loc4_.push(_loc3_);
            }
         }
         return _loc4_;
      }
      
      private function planAttack() : void
      {
         var _loc1_:PlayerUnit = null;
         var _loc2_:Array = null;
         var _loc3_:GridCell = null;
         var _loc4_:Number = NaN;
         var _loc5_:PlayerUnit = null;
         var _loc6_:Number = NaN;
         var _loc7_:PvPEnemyUnit = null;
         var _loc8_:int = 0;
         var _loc9_:Array = null;
         var _loc10_:Array = null;
         if(!this.mLeaderEnemy)
         {
            return;
         }
         var _loc11_:PvPMatch = this.mGame.mPvPMatch;
         var _loc12_:Number = 0;
         if(this.mChooseRandomTarget)
         {
            _loc12_ = 0.6;
            _loc1_ = this.mPlayerUnits[Math.floor(Math.random() * this.mPlayerUnits.length)];
         }
         else
         {
            for each(_loc5_ in this.mPlayerUnits)
            {
               _loc6_ = this.mLeaderEnemy.getAttackPriority(_loc5_,this.mModePreferFormat);
               if(_loc6_ > _loc12_)
               {
                  _loc12_ = _loc6_;
                  _loc1_ = _loc5_;
               }
            }
         }
         _loc2_ = this.mScene.getNeighboringAvailableCellsAtChessboardDistance(_loc1_.getCell(),this.mLeaderEnemy.getAttackRange());
         _loc3_ = this.mScene.chooseCellClosestToCellAvoidingPlayers(_loc2_,this.mLeaderEnemy.getCell());
         _loc4_ = _loc12_ + this.mModePreferAttack + this.mArmyCoherence + (1 - this.mModePreferFormat);
         _loc4_ = _loc4_ / 4;
         if(_loc11_.mActionsLeft == 2)
         {
            _loc4_ *= 0.6;
         }
         else if(_loc11_.mActionsLeft == 1)
         {
            _loc4_ *= 0.2;
         }
         var _loc13_:Action = new PvPEnemyMovingAction(this.mLeaderEnemy,_loc3_,true);
         this.mDebugInfo += "suggest attack " + _loc1_.mItem.mId + " priority " + _loc4_ + "(" + _loc12_ + "," + this.mModePreferAttack + "," + this.mArmyCoherence + "," + (1 - this.mModePreferFormat) + ")" + ", ";
         this.suggestAction(_loc13_,_loc4_);
         if(!this.mQuickAttack && this.mArmyCoherence < (_loc11_.mActionsLeft == PvPMatch.ACTIONS_PER_TURN ? this.mModePreferFormat : this.mModePreferFormat + 0.2))
         {
            this.mDebugInfo += "Coherence low: " + this.mArmyCoherence + " < " + this.mModePreferFormat + ", ";
            for each(_loc7_ in this.mEnemyUnits)
            {
               if(_loc7_ != this.mLeaderEnemy)
               {
                  _loc8_ = this.getEnemyUnitIncoherence(_loc7_);
                  if(_loc8_ > 0 && _loc7_.distanceToElement(_loc1_) > this.mLeaderEnemy.distanceToElement(_loc1_))
                  {
                     _loc2_ = this.mScene.getNeighboringAvailableCellsAtChessboardDistance(this.mLeaderEnemy.getCell(),1);
                     _loc9_ = _loc7_.getWalkableCells();
                     _loc10_ = this.getIntersection(_loc2_,_loc9_);
                     if(_loc10_.length > 0)
                     {
                        _loc2_ = _loc10_;
                     }
                     _loc3_ = this.mScene.chooseCellClosestToCellAvoidingPlayers(_loc2_,_loc1_.getCell());
                     _loc4_ = (_loc11_.mActionsLeft == PvPMatch.ACTIONS_PER_TURN ? 0 : 1) + this.mModePreferAttack + this.mModePreferFormat + (this.mAttackWithWeakest ? Math.random() : _loc7_.getActorPriority()) + Math.min(1,_loc8_ / 2);
                     _loc4_ = _loc4_ / 5;
                     _loc13_ = new PvPEnemyMovingAction(_loc7_,_loc3_,true);
                     this.suggestAction(_loc13_,_loc4_);
                     this.mDebugInfo += "suggest move " + _loc7_.mUnitId + " priority " + _loc4_ + "(" + this.mModePreferAttack + "," + this.mModePreferFormat + "," + _loc7_.getActorPriority() + "," + Math.min(1,_loc8_ / 2) + "), ";
                  }
               }
            }
         }
      }
      
      private function planCollectPowerUp() : void
      {
         var _loc1_:Element = null;
         var _loc2_:PvPEnemyUnit = null;
         var _loc3_:Array = null;
         var _loc4_:PowerUpObject = null;
         var _loc5_:Number = NaN;
         var _loc6_:PowerUpObject = null;
         var _loc7_:Number = NaN;
         var _loc8_:Number = NaN;
         var _loc9_:Action = null;
         var _loc10_:Vector.<PowerUpObject> = new Vector.<PowerUpObject>();
         for each(_loc1_ in this.mScene.mAllElements)
         {
            if(_loc1_ is PowerUpObject)
            {
               _loc10_.push(_loc1_ as PowerUpObject);
            }
         }
         if(_loc10_.length <= 0 || this.mModePreferAttack <= 0)
         {
            return;
         }
         for each(_loc2_ in this.mEnemyUnits)
         {
            _loc3_ = _loc2_.getWalkableCells();
            _loc4_ = null;
            _loc5_ = Number.MAX_VALUE;
            for each(_loc6_ in _loc10_)
            {
               _loc7_ = _loc2_.distanceToElement(_loc6_);
               if(_loc7_ < _loc5_)
               {
                  _loc5_ = _loc7_;
                  _loc4_ = _loc6_;
               }
            }
            if(this.mPowerUpFan || _loc3_.indexOf(_loc4_.getCell()) >= 0)
            {
               _loc8_ = 1 - this.mModePreferAttack + Math.min(1,_loc2_.mMovementRange / 10);
               _loc8_ = _loc8_ / 2;
               if((_loc4_.mItem as PowerUpItem).mIncreasedHealth > 0 && _loc2_.getHealth() >= _loc2_.mMaxHealth)
               {
                  _loc8_ /= 3;
               }
               _loc9_ = new PvPEnemyMovingAction(_loc2_,_loc4_.getCell(),true);
               this.mDebugInfo += "suggest pickup priority " + _loc8_ + "(" + (1 - this.mModePreferAttack) + "," + Math.min(1,_loc2_.mMovementRange / 10) + "), ";
               this.suggestAction(_loc9_,_loc8_);
            }
         }
      }
      
      public function searchCellAttackablePlayerUnits(param1:GridCell) : Array
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:PlayerUnit = null;
         var _loc7_:Array = new Array();
         var _loc8_:Array = this.mScene.getPlayerAliveUnits();
         for each(_loc6_ in _loc8_)
         {
            _loc2_ = _loc6_.getCell().mPosI - _loc6_.getAttackRange();
            _loc3_ = _loc6_.getCell().mPosI + _loc6_.getAttackRange();
            _loc4_ = _loc6_.getCell().mPosJ - _loc6_.getAttackRange();
            _loc5_ = _loc6_.getCell().mPosJ + _loc6_.getAttackRange();
            if(param1.mPosI >= _loc2_ && param1.mPosI <= _loc3_ && param1.mPosJ >= _loc4_ && param1.mPosJ <= _loc5_)
            {
               _loc7_.push(_loc6_);
            }
         }
         return _loc7_;
      }
      
      public function searchAttackablePvPEnemyUnits(param1:PlayerUnit) : Array
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:IsometricCharacter = null;
         var _loc7_:PvPEnemyUnit = null;
         var _loc8_:GridCell = null;
         var _loc9_:Array = new Array();
         var _loc10_:Array = this.mScene.getEnemyUnits();
         for each(_loc6_ in _loc10_)
         {
            if(_loc6_ is PvPEnemyUnit && _loc6_.getHealth() > 0)
            {
               _loc7_ = _loc6_ as PvPEnemyUnit;
               _loc2_ = param1.getCell().mPosI - _loc7_.getAttackRange();
               _loc3_ = param1.getCell().mPosI + (param1.getTileSize().x - 1) + _loc7_.getAttackRange();
               _loc4_ = param1.getCell().mPosJ - _loc7_.getAttackRange();
               _loc5_ = param1.getCell().mPosJ + (param1.getTileSize().y - 1) + _loc7_.getAttackRange();
               if(_loc7_.isStill() && _loc7_.getCell().mPosI >= _loc2_ && _loc7_.getCell().mPosI <= _loc3_ && _loc7_.getCell().mPosJ >= _loc4_ && _loc7_.getCell().mPosJ <= _loc5_)
               {
                  _loc9_.push(_loc7_);
               }
               else
               {
                  _loc8_ = _loc7_.getMovementTargetCell();
                  if(Boolean((_loc8_) && _loc8_.mPosI >= _loc2_ && _loc8_.mPosI <= _loc3_) && Boolean(_loc8_.mPosJ >= _loc4_) && _loc8_.mPosJ <= _loc5_)
                  {
                     _loc9_.push(_loc7_);
                  }
               }
            }
         }
         return _loc9_;
      }
   }
}

