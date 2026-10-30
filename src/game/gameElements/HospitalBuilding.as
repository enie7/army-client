package game.gameElements
{
   import com.dchoc.graphics.DCResourceManager;
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.geom.Point;
   import game.characters.PlayerUnit;
   import game.gui.TooltipHealth;
   import game.isometric.IsometricScene;
   import game.isometric.ObjectLoader;
   import game.items.HospitalItem;
   import game.items.MapItem;
   import game.states.GameState;
   import game.utils.TimeUtils;
   
   public class HospitalBuilding extends PlayerBuildingObject
   {
      
      private var mReadyToHeal:Boolean;
      
      private var mTimeUntilRefill:int;
      
      private var mCooldown:int;
      
      private var mHealPower:int;
      
      public var mAttackRange:int;
      
      public var mPower:int;
      
      public var mReadyText:String;
      
      public var mNotReadyText:String;
      
      public function HospitalBuilding(param1:int, param2:IsometricScene, param3:MapItem, param4:Point, param5:DisplayObject = null, param6:String = null)
      {
         super(param1,param2,param3,param4,param5,param6);
         mWalkable = false;
         mState = STATE_READY;
         this.mReadyToHeal = false;
         var _loc7_:HospitalItem = param3 as HospitalItem;
         this.mCooldown = _loc7_.mCooldown;
         this.mHealPower = _loc7_.mHealPower;
         this.mAttackRange = _loc7_.mAttackRange;
         this.mPower = _loc7_.mPower;
         this.mReadyText = _loc7_.mReadyText;
         this.mNotReadyText = _loc7_.mNotReadyText;
      }
      
      public function readyToHeal() : Boolean
      {
         if(mHealth < mMaxHealth)
         {
            return false;
         }
         return this.mReadyToHeal;
      }
      
      public function checkNeighbours() : *
      {
         var _loc3_:* = undefined;
         var _loc1_:Array = GameState.mInstance.searchNearbyUnits(getCell(),1,2,2,false);
         var _loc2_:PlayerUnit = null;
         for(_loc3_ in _loc1_)
         {
            if(!(_loc1_[_loc3_] is PlayerUnit))
            {
               return;
            }
            _loc2_ = _loc1_[_loc3_] as PlayerUnit;
            if(_loc2_.getHealth() < _loc2_.mMaxHealth)
            {
               _loc2_.setHealth(Math.min(_loc2_.mMaxHealth,_loc2_.getHealth() + this.mHealPower));
               this.mReadyToHeal = false;
               this.mTimeUntilRefill = this.mCooldown * 1000;
               this.updateGraphics(mHealth);
            }
         }
      }
      
      override public function setHealth(param1:int) : void
      {
         super.setHealth(param1);
         this.updateGraphics(mHealth);
      }
      
      override public function graphicsLoaded(param1:Sprite) : void
      {
         super.graphicsLoaded(param1);
         this.updateGraphics(mHealth);
      }
      
      override public function logicUpdate(param1:int) : Boolean
      {
         super.logicUpdate(param1);
         if(mHealth < mMaxHealth)
         {
            this.mReadyToHeal = false;
            this.mTimeUntilRefill = this.mCooldown * 1000;
         }
         if(!this.mReadyToHeal)
         {
            this.mTimeUntilRefill -= param1;
            if(this.mTimeUntilRefill <= 0)
            {
               this.mReadyToHeal = true;
               this.mTimeUntilRefill = 0;
               this.updateGraphics(mHealth);
            }
         }
         return false;
      }
      
      private function updateGraphics(param1:int) : void
      {
         var _loc2_:Sprite = null;
         var _loc3_:String = null;
         var _loc4_:DCResourceManager = null;
         var _loc5_:String = null;
         var _loc6_:String = null;
         var _loc7_:Object = null;
         if(!mGraphicsLoaded)
         {
            return;
         }
         var _loc8_:ObjectLoader = new ObjectLoader();
         if(mHealth <= 0)
         {
            _loc3_ = "swf/buildings_player";
            _loc4_ = DCResourceManager.getInstance();
            if(_loc4_.isLoaded(_loc3_))
            {
               removeSprite();
               _loc5_ = "building_destroyed_" + getTileSize().x + "x" + getTileSize().y;
               _loc6_ = "InnerMovieClip";
               _loc2_ = _loc8_[_loc6_]("swf/buildings_player",_loc5_);
               addSprite(_loc2_);
            }
            else
            {
               _loc4_.addEventListener(_loc3_ + DCResourceManager.EVENT_COMPLETE_SINGLE_FILE,this.ruinsLoadingFinished,false,0,true);
               if(!_loc4_.isAddedToLoadingList(_loc3_))
               {
                  _loc4_.load(Config.DIR_DATA + _loc3_ + ".swf",_loc3_,null,false);
               }
            }
         }
         else
         {
            _loc7_ = mContainer.getChildAt(0);
            if(param1 == 0)
            {
               _loc2_ = _loc8_[mItem.mLoader](mItem.getIconGraphicsFile(),mItem.getIconGraphics());
               removeSprite();
               addSprite(_loc2_);
            }
            else if(mHealth < mMaxHealth)
            {
               _loc7_.gotoAndStop(3);
            }
            else if(this.mReadyToHeal)
            {
               _loc7_.gotoAndStop(2);
            }
            else
            {
               _loc7_.gotoAndStop(1);
            }
         }
      }
      
      override public function updateTooltip(param1:int, param2:TooltipHealth) : void
      {
         param2.setTitleText(mItem.mName);
         param2.setHealth(this.mHealth,this.mMaxHealth);
         if(!isFullHealth())
         {
            if(mState == STATE_RUINS)
            {
               param2.setDetailsText(GameState.getText("BUILDING_STATUS_RUINS"));
            }
            else
            {
               param2.setDetailsText(GameState.getText("BUILDING_STATUS_DAMAGED"));
            }
         }
         else if(this.mReadyToHeal)
         {
            param2.setDetailsText(this.mReadyText);
         }
         else
         {
            param2.setDetailsText(GameState.replaceParameters(this.mNotReadyText,[TimeUtils.getCountDownTime(this.mTimeUntilRefill)]));
         }
      }
      
      override public function isMovable() : Boolean
      {
         if(mState == STATE_RUINS)
         {
            return false;
         }
         return mMovable;
      }
      
      override public function setupFromServer(param1:Object) : void
      {
         super.setupFromServer(param1);
         if(param1.next_action_at != null)
         {
            this.mTimeUntilRefill = param1.next_action_at * 1000;
         }
         else
         {
            this.mTimeUntilRefill = this.mCooldown * 1000;
         }
      }
      
      public function getHealCostSupplies() : int
      {
         return (mItem as HospitalItem).mHealCostSupplies * (mMaxHealth - mHealth) / mMaxHealth;
      }
      
      public function getRefillTimer() : int
      {
         return this.mTimeUntilRefill;
      }
      
      protected function ruinsLoadingFinished(param1:Event) : void
      {
         DCResourceManager.getInstance().removeEventListener(param1.type,this.ruinsLoadingFinished);
         this.updateGraphics(mHealth);
      }
   }
}

