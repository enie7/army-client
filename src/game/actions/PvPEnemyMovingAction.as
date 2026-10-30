package game.actions
{
   import flash.geom.Point;
   import game.characters.AnimationController;
   import game.characters.PlayerUnit;
   import game.characters.PvPEnemyUnit;
   import game.isometric.GridCell;
   import game.isometric.IsometricScene;
   import game.isometric.characters.IsometricCharacter;
   import game.isometric.elements.Element;
   import game.isometric.pathfinding.AStarPathfinder;
   import game.states.GameState;
   
   public class PvPEnemyMovingAction extends EnemyMovingAction
   {
      
      private var mCheckPathLength:Boolean;
      
      public function PvPEnemyMovingAction(param1:PvPEnemyUnit, param2:GridCell = null, param3:Boolean = false)
      {
         super(param1,param2,"PvPEnemyMove");
         mDestinationCell = param2;
         this.mCheckPathLength = param3;
      }
      
      private function findDestinationCell() : GridCell
      {
         var _loc1_:int = 0;
         var _loc2_:GridCell = null;
         var _loc3_:GridCell = null;
         var _loc4_:int = 0;
         var _loc5_:IsometricScene = GameState.mInstance.mScene;
         var _loc6_:Array = new Array();
         var _loc7_:PvPEnemyUnit = mActor as PvPEnemyUnit;
         var _loc8_:PlayerUnit = _loc7_.getClosestPlayerUnit();
         var _loc9_:GridCell = null;
         if(_loc8_)
         {
            _loc9_ = _loc8_.getCell();
         }
         if(_loc9_)
         {
            _loc5_.getNeighboringCellsAtDistance(mActor as IsometricCharacter,_loc7_.mMovementRange,_loc6_);
            _loc1_ = int.MAX_VALUE;
            _loc2_ = GameState.mInstance.mScene.getSurroundingFreeCell((mActor as PvPEnemyUnit).getCell().mPosI,(mActor as PvPEnemyUnit).getCell().mPosJ);
            for each(_loc3_ in _loc6_)
            {
               if(_loc3_ != _loc9_)
               {
                  _loc4_ = Math.abs(_loc9_.mPosI - _loc3_.mPosI) + Math.abs(_loc9_.mPosJ - _loc3_.mPosJ);
                  if(_loc4_ < _loc1_)
                  {
                     _loc1_ = _loc4_;
                     _loc2_ = _loc3_;
                  }
               }
            }
         }
         return _loc2_;
      }
      
      override public function isOver() : Boolean
      {
         if(mSkipped)
         {
            return true;
         }
         if((mActor as IsometricCharacter).isStill())
         {
            if((mActor as IsometricCharacter).mDestinationCell)
            {
               if(mOriginCell)
               {
                  this.execute();
               }
            }
            return true;
         }
         return false;
      }
      
      override public function start() : void
      {
         var _loc1_:PvPEnemyUnit = null;
         var _loc2_:Array = null;
         var _loc3_:Number = NaN;
         var _loc4_:Number = NaN;
         var _loc5_:int = 0;
         var _loc6_:GridCell = null;
         if(mSkipped)
         {
            return;
         }
         if(mDestinationCell)
         {
            if(this.mCheckPathLength)
            {
               _loc1_ = mActor as PvPEnemyUnit;
               _loc2_ = new Array();
               _loc3_ = GameState.mInstance.mScene.getCenterPointXOfCell(mDestinationCell);
               _loc4_ = GameState.mInstance.mScene.getCenterPointYOfCell(mDestinationCell);
               AStarPathfinder.mOptimizeStraightPaths = false;
               if(AStarPathfinder.findPathAStar(_loc2_,GameState.mInstance.mScene,new Point(_loc1_.mX,_loc1_.mY),new Point(_loc3_,_loc4_),_loc1_.mMovementFlags))
               {
                  _loc5_ = 3;
                  _loc6_ = GameState.mInstance.mScene.getCellAtLocation(_loc2_[0],_loc2_[1]);
                  while(Boolean(_loc6_) && Boolean(_loc6_.mParent) && (Boolean(_loc6_.mCharacter || _loc6_.mObject && !_loc6_.mObject.isWalkable()) || Boolean(_loc6_.mG > (mActor as PvPEnemyUnit).mMovementRange + 0.5)))
                  {
                     if(Boolean((_loc6_ = _loc6_.mParent).mCharacter) || Boolean(_loc6_.mObject) && Boolean(!_loc6_.mObject.isWalkable()))
                     {
                        if(--_loc5_ < 0)
                        {
                           break;
                        }
                     }
                     else
                     {
                        _loc5_ = 3;
                     }
                  }
                  if(_loc5_ >= 0)
                  {
                     mDestinationCell = _loc6_;
                  }
                  else
                  {
                     mDestinationCell = null;
                  }
               }
               else
               {
                  mDestinationCell = null;
               }
               AStarPathfinder.mOptimizeStraightPaths = true;
            }
         }
         if(mDestinationCell == null)
         {
            (mActor as IsometricCharacter).mDestinationCell = this.findDestinationCell();
         }
         else
         {
            (mActor as IsometricCharacter).mDestinationCell = mDestinationCell;
         }
         if((mActor as IsometricCharacter).mDestinationCell)
         {
            (mActor as IsometricCharacter).mDestinationCell.mCharacterComingToThisTile = mActor as PvPEnemyUnit;
            mTargetX = (mActor as Element).mScene.getCenterPointXOfCell((mActor as IsometricCharacter).mDestinationCell);
            mTargetY = (mActor as Element).mScene.getCenterPointYOfCell((mActor as IsometricCharacter).mDestinationCell);
            mOriginCell = mActor.getCell();
            (mActor as IsometricCharacter).moveTo(mTargetX,mTargetY);
            mActor.playCollectionSound(mActor.mMoveSounds);
         }
         else
         {
            skip();
         }
      }
      
      override protected function execute() : void
      {
         (mActor as Element).mScene.characterArrivedInCell(mActor as PvPEnemyUnit,mActor.getCell());
         mActor.getCell().mCharacterComingToThisTile = null;
         mActor.setAnimationAction(AnimationController.CHARACTER_ANIMATION_IDLE,false,true);
         (mActor as IsometricCharacter).mPreviousTile = mOriginCell;
         GameState.mInstance.enemyMoveMade();
      }
   }
}

