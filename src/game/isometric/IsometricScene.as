package game.isometric
{
   import com.dchoc.graphics.DCResourceManager;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.events.TransformGestureEvent;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.geom.Vector3D;
   import flash.utils.Timer;
   import game.actions.NeighborActionQueue;
   import game.actions.RepairConstructionAction;
   import game.actions.RepairDecorationAction;
   import game.actions.RepairHospitalAction;
   import game.actions.RepairPlayerInstallationAction;
   import game.actions.RepairPlayerUnitAction;
   import game.actions.RepairResourceBuildingAction;
   import game.actions.WalkingAction;
   import game.battlefield.FogOfWar;
   import game.battlefield.MapArea;
   import game.battlefield.MapData;
   import game.battlefield.MapGUIEffectsLayer;
   import game.battlefield.TileMapGraphic;
   import game.characters.AnimationController;
   import game.characters.EnemyUnit;
   import game.characters.PlayerUnit;
   import game.characters.PvPEnemyUnit;
   import game.environment.EnvEffectManager;
   import game.gameElements.*;
   import game.gui.CursorManager;
   import game.gui.HUDInterface;
   import game.gui.popups.PopUpManager;
   import game.isometric.camera.IsoCamera;
   import game.isometric.characters.IsometricCharacter;
   import game.isometric.elements.DisplayContainer;
   import game.isometric.elements.DynamicObject;
   import game.isometric.elements.Element;
   import game.isometric.elements.Floor;
   import game.isometric.elements.Renderable;
   import game.isometric.elements.StaticObject;
   import game.isometric.pathfinding.AStarPathfinder;
   import game.items.AreaItem;
   import game.items.DebrisItem;
   import game.items.EnemyInstallationItem;
   import game.items.FireMissionItem;
   import game.items.Item;
   import game.items.ItemManager;
   import game.items.MapItem;
   import game.items.PlayerUnitItem;
   import game.items.ShopItem;
   import game.items.TimerItem;
   import game.missions.MissionManager;
   import game.net.ServiceIDs;
   import game.player.GamePlayerProfile;
   import game.sound.ArmySoundManager;
   import game.states.GameState;
   import game.utils.EffectController;
   import game.utils.FrameProfiler;
   
   public class IsometricScene
   {
      
      public static var mouseDownAction:Boolean;
      
      public static var mMinAreaX:Number = Number.MAX_VALUE;
      
      public static var mMinAreaY:Number = Number.MAX_VALUE;
      
      public static var mMaxAreaX:Number = Number.MIN_VALUE;
      
      public static var mMaxAreaY:Number = Number.MIN_VALUE;
      
      private static const CAM_SPEED:int = 15;
      
      private static const MINUTE_MS:int = 60000;
      
      private static var mRemoveArray:Array = new Array();
      
      private static const MOUSE_CURSOR_STATE_DOWN:int = 1;
      
      private static const MOUSE_CURSOR_STATE_UP:int = 2;
      
      public static const TUTORIAL_HIGHLIGHT_CIRCLE:int = 0;
      
      public static const TUTORIAL_HIGHLIGHT_TARGET:int = 1;
      
      public static const TUTORIAL_HIGHLIGHT_MOVE:int = 2;
      
      private static var smTmpSolution:Array = new Array();
      
      private static var counter:int = 0;
      
      private var mGame:GameState;
      
      public var mContainer:Sprite;
      
      public var mGridDimX:Number;
      
      public var mGridDimY:Number;
      
      public var mGridDimZ:Number;
      
      public var mSizeX:int;
      
      public var mSizeY:int;
      
      public var mTilemapGraphic:TileMapGraphic;
      
      public var mFog:FogOfWar;
      
      public var mSceneHud:Sprite;
      
      private var mFloor:Floor;
      
      public var mAllElements:Array;
      
      public var mCamera:IsoCamera;
      
      private var mPointTmp:Point = new Point();
      
      private var mPointTmp2:Point = new Point();
      
      private var mSceneActive:Boolean = false;
      
      private var mRubberBandTimer:int;
      
      public var mVisibleObjectCnt:int = 0;
      
      public var mObjectBeingMoved:Renderable;
      
      public var mFireMissionBeingUsed:FireMissionItem;
      
      public var mObjectBeingMovedStartX:Number;
      
      public var mObjectBeingMovedStartY:Number;
      
      public var mMovedObjectIndicator:Sprite;
      
      public var mMapGUIEffectsLayer:MapGUIEffectsLayer;
      
      private var mObjectLoader:ObjectLoader;
      
      public var mTutorialHighlight:MovieClip;
      
      private var mMouseDisabled:Boolean = false;
      
      private var mAllowMouseX:int = -1;
      
      private var mAllowMouseY:int = -1;
      
      private var mEffectController:EffectController;
      
      private var mPatrolAppearTimer:int;
      
      private var mDebrisRandomSpawnTimer:int;
      
      public var mSoundMakers:Array;
      
      private var mSwitch:int = 0;
      
      private var mTimer:int = 0;
      
      private var mParatrooperAnimationName:String = "enemy_airdrop_01";
      
      public var mParatrooperAnimation:MovieClip = null;
      
      private var mParatrooperLocation:GridCell = null;
      
      private var mAllowedToCheckMisplacedDebris:Boolean = true;
      
      public var mSpawningBeaconObject:SpawningBeaconObject;
      
      public var mSpawningBeaconAppearTimer:int;
      
      private var mSpawningBeaconAppearTimerItem:TimerItem;
      
      public var mNeighborAvatars:Array;
      
      private var mEffectPending:Boolean;
      
      private var mEffectPendingMC:MovieClip;
      
      private var mEffectPendingType:int;
      
      private var mEffectPendingX:int;
      
      private var mEffectPendingY:int;
      
      private var mEffectPendingClipName:String;
      
      private var mAppearTimer:Timer;
      
      private const mAppearDelayMs:int = Math.ceil(1000 / GameState.mInstance.getMainClip().stage.frameRate);
      
      private var mZoomActivated:Boolean;
      
      public var mMouseScrolling:Boolean = false;
      
      private var mMouseX:Number = 0;
      
      private var mMouseY:Number = 0;
      
      private var mMouseScrollStartX:Number = 0;
      
      private var mMouseScrollStartY:Number = 0;
      
      private var mKeyScrollStartX:Number = 0;
      
      private var mKeyScrollStartY:Number = 0;
      
      public var mAnyScrollKeyPressed:Boolean = false;
      
      public var mRightPressed:Boolean;
      
      public var mLeftPressed:Boolean;
      
      public var mDownPressed:Boolean;
      
      public var mUpPressed:Boolean;
      
      public var mFlagDrag:Boolean;
      
      public var mPlacePressed:Boolean;
      
      public var mDisabledCellsForMoving:Array;
      
      private var mTick:Number = 0;
      
      private var mRemoveCharactersArray:Array = new Array();
      
      private var mAllEnemies:Array;
      
      private var mHighlightedDebris:DebrisObject;
      
      public var mInfoBoxBG:Sprite;
      
      private var mPreviousCell:GridCell;
      
      public var mMouseLocalX:int;
      
      public var mMouseLocalY:int;
      
      private var mMouseCursorState:int;
      
      private var mPreviousCursorCell:GridCell;
      
      public var mTickCrossActive:Boolean;
      
      private var mFireItemX:int;
      
      private var mFireItemY:int;
      
      public var mAbsoluteVisibleArea:Shape;
      
      public var mRelativeVisibleArea:Shape;
      
      private var mVisibleObjects:Array = new Array();
      
      private var mSortingOrderChanged:Boolean;
      
      public function IsometricScene(param1:GameState, param2:Number, param3:Number, param4:Number)
      {
         super();
         mouseDownAction = false;
         this.mGame = param1;
         this.mSoundMakers = new Array();
         this.mContainer = new Sprite();
         this.mGridDimX = param2;
         this.mGridDimY = param3;
         this.mGridDimZ = param4;
         this.mSwitch = 0;
         this.mTimer = 0;
         this.mZoomActivated = false;
         this.mObjectLoader = new ObjectLoader();
         this.mAllElements = new Array();
         if(FeatureTuner.USE_ZOOM_IN_OUT)
         {
            this.mContainer.addEventListener(TransformGestureEvent.GESTURE_ZOOM,this.ZoomInOut,false);
         }
         this.mContainer.addEventListener(MouseEvent.MOUSE_MOVE,this.mouseMove);
         this.mContainer.addEventListener(MouseEvent.MOUSE_DOWN,this.mouseDown);
         this.mContainer.addEventListener(MouseEvent.MOUSE_UP,this.mouseUp);
         this.mEffectController = new EffectController();
         EnvEffectManager.init();
      }
      
      private function ZoomInOut(param1:TransformGestureEvent) : void
      {
         if(this.mGame.getStageHeight() > 725)
         {
            this.mZoomActivated = true;
            this.setZoomInOut(param1.scaleX);
         }
         else
         {
            this.mContainer.removeEventListener(TransformGestureEvent.GESTURE_ZOOM,this.ZoomInOut);
         }
      }
      
      private function setZoomInOut(param1:Number) : void
      {
         if(!PopUpManager.isModalPopupActive())
         {
            if(param1 < 1)
            {
               GameState.mInstance.getHud().buttonZoomOutPressed(null);
            }
            else if(param1 > 1)
            {
               GameState.mInstance.getHud().buttonZoomInPressed(null);
            }
         }
      }
      
      public function startToolTipTimer() : void
      {
         if(this.mAppearTimer)
         {
            this.mAppearTimer.removeEventListener(TimerEvent.TIMER,this.appearTimerTick);
            this.mAppearTimer.stop();
            this.mAppearTimer = null;
         }
         this.mAppearTimer = new Timer(this.mAppearDelayMs);
         this.mAppearTimer.addEventListener(TimerEvent.TIMER,this.appearTimerTick);
         this.mAppearTimer.start();
      }
      
      public function appearTimerTick(param1:TimerEvent) : void
      {
         if(this.mAppearTimer)
         {
            if(this.mAppearTimer.currentCount > this.mAppearDelayMs)
            {
               this.mAppearTimer.removeEventListener(TimerEvent.TIMER,this.appearTimerTick);
               this.mAppearTimer.stop();
               this.mAppearTimer = null;
               this.hideObjectTooltip();
            }
         }
      }
      
      public function initTileMap() : void
      {
         var _loc1_:Item = null;
         var _loc2_:AreaItem = null;
         var _loc3_:GridCell = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         this.mTilemapGraphic = new TileMapGraphic(this);
         this.mFog = new FogOfWar(this);
         this.mMapGUIEffectsLayer = new MapGUIEffectsLayer(this);
         this.mSceneHud = new Sprite();
         this.mTilemapGraphic.updateTilemap();
         this.mTilemapGraphic.drawFog();
         var _loc8_:Array = ItemManager.getItemList();
         for each(_loc1_ in _loc8_)
         {
            if(_loc1_ is AreaItem && AreaItem(_loc1_).mMapId == this.mGame.mCurrentMapId)
            {
               _loc2_ = _loc1_ as AreaItem;
               _loc3_ = this.getCellAt(_loc2_.mX + (_loc2_.mWidth >> 1),_loc2_.mY + (_loc2_.mHeight >> 1));
               if(this.isInsideOpenArea(_loc3_))
               {
                  if(_loc2_.mAreaLockedIcon)
                  {
                     if(_loc2_.mAreaLockedIcon.parent)
                     {
                        _loc2_.mAreaLockedIcon.parent.removeChild(_loc2_.mAreaLockedIcon);
                     }
                  }
               }
               else
               {
                  _loc6_ = 2;
                  _loc7_ = 2;
                  if(_loc2_.mId == "AreaSW")
                  {
                     _loc6_ = 3;
                  }
                  else if(_loc2_.mId == "AreaSE")
                  {
                     _loc6_ = 1;
                  }
                  else
                  {
                     _loc6_ = 2;
                     _loc7_ = 3;
                  }
                  _loc4_ = (_loc2_.mX + (_loc6_ * _loc2_.mWidth >> 2)) * this.mGridDimX;
                  _loc5_ = (_loc2_.mY + (_loc7_ * _loc2_.mHeight >> 2)) * this.mGridDimY;
                  if(!GameState.mInstance.visitingFriend())
                  {
                     _loc2_.addAreaLockedIcon(this.mSceneHud,_loc4_,_loc5_);
                  }
               }
            }
         }
      }
      
      public function initCamera() : void
      {
         this.mCamera = new IsoCamera();
         this.mCamera.setMargins(mMinAreaX,mMinAreaY,mMaxAreaX,mMaxAreaY,this.mContainer.scaleX);
      }
      
      public function reCheckCameraLimits(param1:Event = null) : void
      {
         var _loc2_:Item = null;
         mMinAreaX = Number.MAX_VALUE;
         mMinAreaY = Number.MAX_VALUE;
         mMaxAreaX = Number.MIN_VALUE;
         mMaxAreaY = Number.MIN_VALUE;
         for each(_loc2_ in ItemManager.getItemList())
         {
            if(_loc2_ is AreaItem)
            {
               (_loc2_ as AreaItem).checkLimits();
            }
         }
      }
      
      public function reCalculateCameraMargins(param1:Event = null) : void
      {
         this.mCamera.setMargins(mMinAreaX,mMinAreaY,mMaxAreaX,mMaxAreaY,this.mContainer.scaleX);
      }
      
      public function setMousePos(param1:MouseEvent) : void
      {
         this.mMouseX = param1.stageX;
         this.mMouseY = param1.stageY;
      }
      
      public function setMouseScrolling(param1:Boolean) : void
      {
         this.mMouseScrolling = param1;
      }
      
      private function mouseDown(param1:MouseEvent) : void
      {
         Config.DISABLE_SORT = true;
         if(this.mGame.resumeMusicOnMouseEvent)
         {
            this.mGame.startMusic();
            this.mGame.resumeMusicOnMouseEvent = false;
         }
         this.setMousePos(param1);
         mouseDownAction = true;
         this.mMouseCursorState = MOUSE_CURSOR_STATE_DOWN;
         this.mMouseScrollStartX = param1.stageX;
         this.mMouseScrollStartY = param1.stageY;
      }
      
      public function cancelPlaceClicked() : void
      {
         this.mGame.mHUD.cancelTools();
         this.setVisiblePlacementButton(false);
         this.mPlacePressed = false;
      }
      
      public function mouseUp(param1:MouseEvent) : void
      {
         var _loc2_:Boolean = false;
         var _loc3_:GridCell = null;
         this.mZoomActivated = false;
         Config.DISABLE_SORT = false;
         mouseDownAction = false;
         if(!this.mMouseScrolling)
         {
            if(this.mGame.isEditMode())
            {
               if(!this.mGame.mHUD.mBlock)
               {
                  if(this.mGame.mState == GameState.STATE_USE_INVENTORY_ITEM)
                  {
                     _loc2_ = false;
                     if(!this.mObjectBeingMoved)
                     {
                        _loc3_ = this.getTileUnderMouse();
                        if(_loc3_)
                        {
                           if(_loc3_.mObject)
                           {
                              if(_loc3_.mObject is PlayerBuildingObject)
                              {
                                 _loc2_ = (_loc3_.mObject as PlayerBuildingObject).setProductionReady();
                              }
                           }
                        }
                     }
                     else if(Boolean(this.mObjectBeingMoved) && this.isInLegalPlacementArea(this.mObjectBeingMoved))
                     {
                        this.setVisiblePlacementButton(true);
                        _loc2_ = true;
                     }
                     else if(Boolean(this.mObjectBeingMoved) && !this.isInLegalPlacementArea(this.mObjectBeingMoved))
                     {
                        this.setVisiblePlacementButton(false);
                        _loc2_ = false;
                        this.mPlacePressed = false;
                     }
                     if(_loc2_ && (this.mPlacePressed || FeatureTuner.USE_MOUSE_FOR_PLACE_ITEMS))
                     {
                        this.mGame.objectPlaced(this.mObjectBeingMoved,this.mObjectBeingMovedStartX,this.mObjectBeingMovedStartY);
                        this.mGame.inventoryItemUsed();
                        this.exitMoveMode();
                        this.setVisiblePlacementButton(false);
                     }
                  }
                  else if(this.mObjectBeingMoved)
                  {
                     if(this.isInLegalPlacementArea(this.mObjectBeingMoved))
                     {
                        this.setVisiblePlacementButton(true);
                        if(this.mGame.mState == GameState.STATE_PLACE_ITEM && this.mObjectBeingMoved.mItem is ShopItem && ShopItem(this.mObjectBeingMoved.mItem).getCostPremium() > 0)
                        {
                           if(this.mPlacePressed || FeatureTuner.USE_MOUSE_FOR_PLACE_ITEMS)
                           {
                              this.mGame.externalCallBuyItem(this.mObjectBeingMoved.mItem as ShopItem);
                           }
                        }
                        else if(this.mFlagDrag || this.mGame.mState != GameState.STATE_MOVE_ITEM)
                        {
                           if(this.mPlacePressed || FeatureTuner.USE_MOUSE_FOR_PLACE_ITEMS)
                           {
                              this.placeObjectBeingMoved();
                           }
                        }
                     }
                     else if(!this.isInLegalPlacementArea(this.mObjectBeingMoved))
                     {
                        this.mPlacePressed = false;
                        this.setVisiblePlacementButton(false);
                     }
                  }
               }
            }
            else if(this.mGame.mState == GameState.STATE_PLACE_FIRE_MISSION)
            {
               if(FeatureTuner.USE_MOUSE_FOR_PLACE_ITEMS)
               {
                  this.fireActive(param1);
               }
            }
         }
         this.mGame.getHud().enableMouse(true);
         this.mMouseScrolling = false;
         this.mTickCrossActive = false;
         this.mMouseCursorState = MOUSE_CURSOR_STATE_UP;
      }
      
      public function incrementViewersForPlacedObject() : void
      {
         if(this.mObjectBeingMoved is PlayerBuildingObject)
         {
            this.incrementViewersForBuilding(PlayerBuildingObject(this.mObjectBeingMoved),PlayerBuildingObject(this.mObjectBeingMoved).getSightRangeAccordingToCondition());
         }
         else if(this.mObjectBeingMoved is PlayerInstallationObject)
         {
            this.incrementViewersForInstallation(PlayerInstallationObject(this.mObjectBeingMoved),PlayerInstallationObject(this.mObjectBeingMoved).getSightRangeAccordingToCondition());
         }
         else if(this.mObjectBeingMoved is PlayerUnit)
         {
            this.mFog.incrementUnitSightArea(PlayerUnit(this.mObjectBeingMoved));
         }
      }
      
      public function placeObjectBeingMoved() : void
      {
         if(this.mObjectBeingMoved is HFEObject)
         {
            if(this.mGame.mState != GameState.STATE_MOVE_ITEM)
            {
               this.removeObject(this.mObjectBeingMoved.getCell().mObject,false,false);
            }
         }
         this.incrementViewersForPlacedObject();
         this.mGame.objectPlaced(this.mObjectBeingMoved,this.mObjectBeingMovedStartX,this.mObjectBeingMovedStartY);
         if(this.mGame.mState != GameState.STATE_PLACE_ITEM && this.mGame.mState != GameState.STATE_USE_INVENTORY_ITEM)
         {
            this.exitMoveMode();
            if(this.mGame.mState == GameState.STATE_MOVE_ITEM)
            {
               this.mMapGUIEffectsLayer.highlightMovableObjects();
            }
         }
         else
         {
            this.mMapGUIEffectsLayer.highlightPlacingArea();
         }
      }
      
      public function cancelEditMode() : void
      {
         this.mObjectBeingMoved = null;
         this.mFlagDrag = false;
         if(this.mMovedObjectIndicator)
         {
            this.mMovedObjectIndicator.graphics.clear();
            this.mMapGUIEffectsLayer.clearHighlights();
            this.mMapGUIEffectsLayer.clearMoveDisabledArea();
         }
      }
      
      public function getTilesUnderObject(param1:Renderable) : Array
      {
         var _loc2_:GridCell = this.getCellAtLocation(param1.mX,param1.mY);
         return MapArea.getArea(this,_loc2_.mPosI,_loc2_.mPosJ,param1.getTileSize().x,param1.getTileSize().y).getCells();
      }
      
      public function getTilesUnderObjectSightArea(param1:Renderable, param2:int) : Array
      {
         var _loc3_:int = 0;
         var _loc4_:GridCell = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:GridCell = this.getCellAtLocation(param1.mX,param1.mY);
         var _loc8_:int = param1.getTileSize().x + param2 * 2;
         var _loc9_:int = param1.getTileSize().y + param2 * 2;
         var _loc10_:Array = MapArea.getArea(this,_loc7_.mPosI - param2,_loc7_.mPosJ - param2,_loc8_,_loc9_).getCells();
         if(param2 > 0)
         {
            _loc8_ = param1.getTileSize().x;
            _loc9_ = param1.getTileSize().y;
            _loc3_ = 0;
            while(_loc3_ < _loc10_.length)
            {
               _loc4_ = _loc10_[_loc3_];
               _loc5_ = 0;
               _loc6_ = 0;
               if(_loc4_.mPosI < _loc7_.mPosI)
               {
                  _loc5_ = _loc4_.mPosI - _loc7_.mPosI;
               }
               else if(_loc4_.mPosI >= _loc7_.mPosI + _loc8_)
               {
                  _loc5_ = _loc4_.mPosI - (_loc7_.mPosI + _loc8_ - 1);
               }
               if(_loc4_.mPosJ < _loc7_.mPosJ)
               {
                  _loc6_ = _loc4_.mPosJ - _loc7_.mPosJ;
               }
               else if(_loc4_.mPosJ >= _loc7_.mPosJ + _loc9_)
               {
                  _loc6_ = _loc4_.mPosJ - (_loc7_.mPosJ + _loc9_ - 1);
               }
               if(Math.sqrt(_loc5_ * _loc5_ + _loc6_ * _loc6_) - 0.5 > param2)
               {
                  _loc10_.splice(_loc3_,1);
                  _loc3_--;
               }
               _loc3_++;
            }
         }
         return _loc10_;
      }
      
      private function isInLegalPlacementArea(param1:Renderable) : Boolean
      {
         var _loc2_:GridCell = null;
         var _loc3_:GridCell = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:Array = this.getTilesUnderObject(param1);
         var _loc7_:int = int(_loc6_.length);
         var _loc8_:int = 0;
         while(_loc8_ < _loc7_)
         {
            _loc2_ = _loc6_[_loc8_] as GridCell;
            _loc4_ = int(this.mDisabledCellsForMoving.length);
            _loc5_ = 0;
            while(_loc5_ < _loc4_)
            {
               _loc3_ = this.mDisabledCellsForMoving[_loc5_] as GridCell;
               if(_loc2_ == _loc3_)
               {
                  return false;
               }
               _loc5_++;
            }
            if(_loc2_.mCharacter != null)
            {
               if(_loc2_.mCharacter != param1)
               {
                  return false;
               }
            }
            if(!param1.isPlaceableOnAllTiles())
            {
               if(_loc2_.mOwner != MapData.TILE_OWNER_FRIENDLY)
               {
                  return false;
               }
            }
            if(param1 is HFEObject)
            {
               if(this.mGame.mState == GameState.STATE_MOVE_ITEM)
               {
                  if(_loc2_.mObject != null)
                  {
                     if(_loc2_.mObject != param1)
                     {
                        return false;
                     }
                  }
               }
               else if(_loc2_.mObject == null || !(_loc2_.mObject is HFEPlotObject))
               {
                  return false;
               }
            }
            if(!(param1 is HFEObject))
            {
               if(_loc2_.mObject != null)
               {
                  if(_loc2_.mObject != param1)
                  {
                     return false;
                  }
               }
            }
            _loc8_++;
         }
         return true;
      }
      
      private function isObjectInLegalPosition(param1:Renderable) : Boolean
      {
         var _loc2_:GridCell = this.getCellAtLocation(param1.mX,param1.mY);
         if(!_loc2_)
         {
            return false;
         }
         return !this.willIntesectWithObjectAtTile(_loc2_.mPosI,_loc2_.mPosJ,param1.getTileSize().x,param1.getTileSize().y,param1);
      }
      
      private function willIntesectWithObjectAtTile(param1:int, param2:int, param3:int, param4:int, param5:Renderable) : Boolean
      {
         var _loc6_:Element = null;
         var _loc7_:Renderable = null;
         var _loc8_:Vector3D = null;
         var _loc9_:GridCell = null;
         var _loc10_:int = int(this.mAllElements.length);
         var _loc11_:int = 0;
         for(; _loc11_ < _loc10_; _loc11_++)
         {
            _loc6_ = this.mAllElements[_loc11_] as Element;
            _loc7_ = _loc6_ as Renderable;
            if(_loc7_)
            {
               if(_loc7_ != param5)
               {
                  if(_loc7_ is PlayerUnit)
                  {
                     if(param5.isWalkable())
                     {
                        continue;
                     }
                  }
                  _loc8_ = _loc7_.getTileSize();
                  _loc9_ = this.getCellAtLocation(_loc7_.mX,_loc7_.mY);
                  if(param1 + param3 - 1 >= _loc9_.mPosI)
                  {
                     if(param1 < _loc9_.mPosI + _loc8_.x)
                     {
                        if(param2 + param4 - 1 >= _loc9_.mPosJ)
                        {
                           if(param2 < _loc9_.mPosJ + _loc8_.y)
                           {
                              return true;
                           }
                        }
                     }
                  }
               }
            }
         }
         return false;
      }
      
      public function updateBorderTiles() : void
      {
         var _loc1_:int = 0;
         var _loc2_:GridCell = null;
         var _loc3_:* = 0;
         var _loc4_:int = 0;
         while(_loc4_ < this.mSizeX)
         {
            _loc1_ = 0;
            while(_loc1_ < this.mSizeY)
            {
               _loc2_ = this.getCellAt(_loc4_,_loc1_);
               _loc2_.mCloudBits = TileMapGraphic.CLOUD_BIT_NONE;
               if(!this.isInsideOpenArea(_loc2_))
               {
                  _loc3_ = TileMapGraphic.CLOUD_BIT_FULL;
                  if(this.isInsideOpenArea(this.getCellAt(_loc4_ + 1,_loc1_)))
                  {
                     _loc3_ |= TileMapGraphic.CLOUD_BIT_RIGHT;
                  }
                  if(this.isInsideOpenArea(this.getCellAt(_loc4_ - 1,_loc1_)))
                  {
                     _loc3_ |= TileMapGraphic.CLOUD_BIT_LEFT;
                  }
                  if(this.isInsideOpenArea(this.getCellAt(_loc4_,_loc1_ + 1)))
                  {
                     _loc3_ |= TileMapGraphic.CLOUD_BIT_BOTTOM;
                  }
                  if(this.isInsideOpenArea(this.getCellAt(_loc4_,_loc1_ - 1)))
                  {
                     _loc3_ |= TileMapGraphic.CLOUD_BIT_TOP;
                  }
                  if(_loc3_ == 0)
                  {
                     if(this.isInsideOpenArea(this.getCellAt(_loc4_ - 1,_loc1_ - 1)))
                     {
                        _loc3_ = TileMapGraphic.CLOUD_BIT_BR;
                     }
                     else if(this.isInsideOpenArea(this.getCellAt(_loc4_ + 1,_loc1_ - 1)))
                     {
                        _loc3_ = TileMapGraphic.CLOUD_BIT_BL;
                     }
                     else if(this.isInsideOpenArea(this.getCellAt(_loc4_ - 1,_loc1_ + 1)))
                     {
                        _loc3_ = TileMapGraphic.CLOUD_BIT_TR;
                     }
                     else if(this.isInsideOpenArea(this.getCellAt(_loc4_ + 1,_loc1_ + 1)))
                     {
                        _loc3_ = TileMapGraphic.CLOUD_BIT_TL;
                     }
                  }
                  else if(Boolean(_loc3_ & TileMapGraphic.CLOUD_BIT_BOTTOM) && Boolean(_loc3_ & TileMapGraphic.CLOUD_BIT_RIGHT))
                  {
                     _loc3_ = TileMapGraphic.CLOUD_BIT_CONVEX_BR;
                  }
                  else if(Boolean(_loc3_ & TileMapGraphic.CLOUD_BIT_BOTTOM) && Boolean(_loc3_ & TileMapGraphic.CLOUD_BIT_LEFT))
                  {
                     _loc3_ = TileMapGraphic.CLOUD_BIT_CONVEX_BL;
                  }
                  else if(Boolean(_loc3_ & TileMapGraphic.CLOUD_BIT_TOP) && Boolean(_loc3_ & TileMapGraphic.CLOUD_BIT_RIGHT))
                  {
                     _loc3_ = TileMapGraphic.CLOUD_BIT_CONVEX_TR;
                  }
                  else if(Boolean(_loc3_ & TileMapGraphic.CLOUD_BIT_TOP) && Boolean(_loc3_ & TileMapGraphic.CLOUD_BIT_LEFT))
                  {
                     _loc3_ = TileMapGraphic.CLOUD_BIT_CONVEX_TL;
                  }
                  _loc2_.mCloudBits = _loc3_;
               }
               _loc1_++;
            }
            _loc4_++;
         }
      }
      
      public function isInsideOpenArea(param1:GridCell) : Boolean
      {
         var _loc2_:Array = null;
         var _loc3_:int = 0;
         var _loc4_:AreaItem = null;
         if(GameState.mInstance.visitingTutor() || GameState.mInstance.mState == GameState.STATE_PVP)
         {
            return true;
         }
         if(param1)
         {
            _loc2_ = this.mGame.mPlayerProfile.mInventory.getAreas();
            _loc3_ = 0;
            while(_loc3_ < _loc2_.length)
            {
               _loc4_ = _loc2_[_loc3_] as AreaItem;
               if(_loc4_.mMapId == this.mGame.mCurrentMapId)
               {
                  if(_loc4_.mAreaLockedIcon)
                  {
                     _loc4_.mAreaLockedIcon.visible = false;
                     _loc4_.mAreaLockedIcon.parent.removeChild(_loc4_.mAreaLockedIcon);
                     _loc4_.mAreaLockedIcon = null;
                  }
                  if(param1.mPosI >= _loc4_.mX)
                  {
                     if(param1.mPosI < _loc4_.mRightX)
                     {
                        if(param1.mPosJ >= _loc4_.mY)
                        {
                           if(param1.mPosJ < _loc4_.mBottomY)
                           {
                              return true;
                           }
                        }
                     }
                  }
               }
               _loc3_ += 2;
            }
         }
         return false;
      }
      
      public function getContainingArea(param1:GridCell) : AreaItem
      {
         var _loc2_:Object = null;
         for each(_loc2_ in ItemManager.getItemList())
         {
            if(_loc2_ is AreaItem)
            {
               if(param1.mPosI >= _loc2_.mX)
               {
                  if(param1.mPosI < _loc2_.mRightX)
                  {
                     if(param1.mPosJ >= _loc2_.mY)
                     {
                        if(param1.mPosJ < _loc2_.mBottomY)
                        {
                           return _loc2_ as AreaItem;
                        }
                     }
                  }
               }
            }
         }
         return null;
      }
      
      public function isAreaReachable(param1:AreaItem) : Boolean
      {
         var _loc2_:GridCell = null;
         _loc2_ = this.getCellAt(param1.mX,param1.mY - 1);
         if(this.isInsideOpenArea(_loc2_))
         {
            return true;
         }
         _loc2_ = this.getCellAt(param1.mX,param1.mY + param1.mHeight);
         if(this.isInsideOpenArea(_loc2_))
         {
            return true;
         }
         _loc2_ = this.getCellAt(param1.mX - 1,param1.mY);
         if(this.isInsideOpenArea(_loc2_))
         {
            return true;
         }
         _loc2_ = this.getCellAt(param1.mX + param1.mWidth,param1.mY);
         if(this.isInsideOpenArea(_loc2_))
         {
            return true;
         }
         return false;
      }
      
      public function isInsideVisibleArea(param1:GridCell) : Boolean
      {
         var _loc2_:Array = null;
         var _loc3_:int = 0;
         var _loc4_:AreaItem = null;
         if(GameState.mInstance.visitingTutor() || GameState.mInstance.mState == GameState.STATE_PVP)
         {
            return true;
         }
         if(param1)
         {
            _loc2_ = this.mGame.mPlayerProfile.mInventory.getAreas(true);
            _loc3_ = 0;
            while(_loc3_ < _loc2_.length)
            {
               _loc4_ = _loc2_[_loc3_] as AreaItem;
               if(param1.mPosI >= _loc4_.mX - 1)
               {
                  if(param1.mPosI < _loc4_.mRightX + 1)
                  {
                     if(param1.mPosJ >= _loc4_.mY - 1)
                     {
                        if(param1.mPosJ < _loc4_.mBottomY + 1)
                        {
                           return true;
                        }
                     }
                  }
               }
               _loc3_ += 2;
            }
         }
         return false;
      }
      
      public function isUnderCloudBorder(param1:GridCell) : Boolean
      {
         var _loc2_:MapArea = null;
         var _loc3_:Array = null;
         var _loc4_:GridCell = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         if(GameState.mInstance.visitingTutor() || GameState.mInstance.mState == GameState.STATE_PVP)
         {
            return true;
         }
         if(param1)
         {
            if(!this.isInsideVisibleArea(param1))
            {
               _loc2_ = MapArea.getAreaAroundCell(this,param1,1);
               _loc3_ = _loc2_.getCells();
               _loc5_ = int(_loc3_.length);
               _loc6_ = 0;
               while(_loc6_ < _loc5_)
               {
                  _loc4_ = _loc3_[_loc6_] as GridCell;
                  if(this.isInsideVisibleArea(_loc4_))
                  {
                     return true;
                  }
                  _loc6_++;
               }
            }
         }
         return false;
      }
      
      public function getEnabledCellsForMovingObject() : Array
      {
         var _loc1_:Array = null;
         var _loc2_:GridCell = null;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:Array = new Array();
         if(this.mObjectBeingMoved)
         {
            _loc1_ = this.mGame.mMapData.mGrid;
            this.mDisabledCellsForMoving = new Array();
            _loc3_ = int(_loc1_.length);
            _loc4_ = 0;
            while(_loc4_ < _loc3_)
            {
               _loc2_ = _loc1_[_loc4_] as GridCell;
               if(this.isCellEnableForMovingObject(_loc2_,false))
               {
                  _loc5_.push(_loc2_);
               }
               _loc4_++;
            }
         }
         return _loc5_;
      }
      
      public function getMovableObjects() : Array
      {
         var _loc1_:Boolean = false;
         var _loc2_:Renderable = null;
         var _loc3_:Array = new Array();
         var _loc4_:int = int(this.mAllElements.length);
         var _loc5_:int = 0;
         while(_loc5_ < _loc4_)
         {
            _loc2_ = this.mAllElements[_loc5_] as Renderable;
            if(_loc2_.isMovable())
            {
               _loc3_.push(_loc2_);
            }
            _loc5_++;
         }
         return _loc3_;
      }
      
      public function getSellableObjects() : Array
      {
         var _loc1_:Boolean = false;
         var _loc2_:Renderable = null;
         var _loc3_:Array = new Array();
         var _loc4_:int = int(this.mAllElements.length);
         var _loc5_:int = 0;
         while(_loc5_ < _loc4_)
         {
            _loc2_ = this.mAllElements[_loc5_] as Renderable;
            if(this.isCellEnableForSellObject(_loc2_.getCell()))
            {
               _loc3_.push(_loc2_);
            }
            _loc5_++;
         }
         return _loc3_;
      }
      
      private function isCellEnableForMovingObject(param1:GridCell, param2:Boolean) : Boolean
      {
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:GridCell = null;
         var _loc6_:Boolean = false;
         if(param1 && (param1.mOwner == MapData.TILE_OWNER_FRIENDLY || this.mObjectBeingMoved && this.mObjectBeingMoved.isPlaceableOnAllTiles()) && (param1.mCharacter == null || param1.mCharacter == this.mObjectBeingMoved) && (param1.mObject == null || param1.mObject == this.mObjectBeingMoved || (this.mGame.mState == GameState.STATE_PLACE_ITEM || this.mGame.mState == GameState.STATE_USE_INVENTORY_ITEM) && this.mObjectBeingMoved is HFEObject))
         {
            if(this.mGame.mState == GameState.STATE_PLACE_ITEM && this.mObjectBeingMoved is HFEObject && !(param1.mObject is HFEPlotObject))
            {
               _loc6_ = false;
            }
            else if(this.mGame.mState == GameState.STATE_USE_INVENTORY_ITEM && this.mObjectBeingMoved is HFEObject && !(param1.mObject is HFEPlotObject))
            {
               _loc6_ = false;
            }
            else
            {
               _loc6_ = true;
            }
            if(_loc6_)
            {
               if(this.mObjectBeingMoved)
               {
                  if(!this.mObjectBeingMoved.isPlaceableOnAllTiles())
                  {
                     _loc3_ = -1;
                     while(_loc3_ <= 1)
                     {
                        _loc4_ = -1;
                        while(_loc4_ <= 1)
                        {
                           _loc5_ = this.getCellAt(param1.mPosI + _loc3_,param1.mPosJ + _loc4_);
                           if(_loc5_)
                           {
                              if(_loc5_.mCharacter && _loc5_.mCharacter is EnemyUnit || _loc5_.mObject && _loc5_.mObject is EnemyInstallationObject && (_loc5_.mObject as EnemyInstallationObject).canAttack())
                              {
                                 _loc6_ = false;
                                 this.mDisabledCellsForMoving.push(param1);
                                 break;
                              }
                           }
                           _loc4_++;
                        }
                        if(!_loc6_)
                        {
                           break;
                        }
                        _loc3_++;
                     }
                  }
               }
            }
         }
         var _loc7_:int = this.mObjectBeingMoved.getTileSize().x;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         var _loc10_:Array = null;
         var _loc11_:Boolean = false;
         var _loc12_:GridCell = null;
         var _loc13_:int = 0;
         var _loc14_:int = 0;
         if(!param2)
         {
            if(_loc6_)
            {
               if(_loc7_ > 1)
               {
                  _loc8_ = -(_loc7_ - 1);
                  if(_loc8_ > 0)
                  {
                     return false;
                  }
                  _loc9_ = -(_loc7_ - 1);
                  while(false)
                  {
                     if(_loc9_ > 0)
                     {
                        _loc8_++;
                     }
                     else
                     {
                        _loc5_ = this.getCellAt(param1.mPosI + _loc9_,param1.mPosJ + _loc8_);
                        if(_loc5_)
                        {
                           _loc10_ = MapArea.getArea(this,_loc5_.mPosI,_loc5_.mPosJ,_loc7_,_loc7_).getCells();
                           _loc11_ = true;
                           _loc13_ = int(_loc10_.length);
                           _loc14_ = 0;
                           while(_loc14_ < _loc13_)
                           {
                              _loc12_ = _loc10_[_loc14_] as GridCell;
                              if(!this.isCellEnableForMovingObject(_loc12_,true))
                              {
                                 _loc11_ = false;
                                 break;
                              }
                              _loc14_++;
                           }
                           if(_loc11_)
                           {
                              break;
                           }
                        }
                        _loc9_++;
                     }
                  }
                  return true;
               }
            }
         }
         return _loc6_;
      }
      
      public function getEnabledCellsForPickupUnit() : Array
      {
         var _loc1_:GridCell = null;
         var _loc2_:Array = new Array();
         var _loc3_:Array = this.mGame.mMapData.mGrid;
         var _loc4_:int = int(_loc3_.length);
         var _loc5_:int = 0;
         while(_loc5_ < _loc4_)
         {
            _loc1_ = _loc3_[_loc5_] as GridCell;
            if(this.isCellEnableForPickupUnit(_loc1_))
            {
               _loc2_.push(_loc1_);
            }
            _loc5_++;
         }
         return _loc2_;
      }
      
      public function getEnabledCellsForRepairObject() : Array
      {
         var _loc1_:GridCell = null;
         var _loc2_:Array = new Array();
         var _loc3_:Array = this.mGame.mMapData.mGrid;
         var _loc4_:int = int(_loc3_.length);
         var _loc5_:int = 0;
         while(_loc5_ < _loc4_)
         {
            _loc1_ = _loc3_[_loc5_] as GridCell;
            if(this.isCellEnableForRepairObject(_loc1_))
            {
               _loc2_.push(_loc1_);
            }
            _loc5_++;
         }
         return _loc2_;
      }
      
      private function isCellEnableForPickupUnit(param1:GridCell) : Boolean
      {
         if(param1.mCharacter)
         {
            if(param1.mCharacter is PlayerUnit)
            {
               if(param1.mCharacter.isFullHealth())
               {
                  if(this.mGame.mPlayerProfile.mSupplies >= PlayerUnitItem(param1.mCharacter.mItem).mPickupCostSupplies)
                  {
                     return true;
                  }
               }
            }
         }
         return false;
      }
      
      private function isCellEnableForRepairObject(param1:GridCell) : Boolean
      {
         if(param1.mCharacter && param1.mCharacter is PlayerUnit && !param1.mCharacter.isFullHealth())
         {
            return true;
         }
         if(Boolean(param1.mObject) && (param1.mObject is PlayerBuildingObject && PlayerBuildingObject(param1.mObject).isRepairable() || param1.mObject is PlayerInstallationObject && !PlayerInstallationObject(param1.mObject).isFullHealth()))
         {
            return true;
         }
         return false;
      }
      
      private function isCellEnableForSellObject(param1:GridCell) : Boolean
      {
         if(Boolean(param1.mCharacter) && param1.mCharacter is PlayerUnit)
         {
            return true;
         }
         if(Boolean(param1.mObject) && (param1.mObject is ConstructionObject || param1.mObject is DecorationObject || param1.mObject is PlayerInstallationObject || param1.mObject is HFEObject || param1.mObject is HFEPlotObject || param1.mObject is ResourceBuildingObject || param1.mObject is HospitalBuilding))
         {
            return true;
         }
         return false;
      }
      
      private function isCellEnableForRedeploying(param1:GridCell) : Boolean
      {
         var _loc2_:PlayerUnit = null;
         if(param1.mCharacter)
         {
            if(param1.mCharacter is PlayerUnit)
            {
               _loc2_ = param1.mCharacter as PlayerUnit;
               return _loc2_.isFullHealth() && this.mGame.mPlayerProfile.mSupplies >= PlayerUnitItem(_loc2_.mItem).mPickupCostSupplies;
            }
         }
         return false;
      }
      
      private function mouseOut(param1:MouseEvent) : void
      {
         this.mGame.getHud().enableMouse(true);
      }
      
      private function mouseMove(param1:MouseEvent) : void
      {
         var _loc2_:Number = NaN;
         var _loc3_:Number = NaN;
         var _loc4_:Number = NaN;
         Config.DISABLE_SORT = true;
         if(!MissionManager.isTutorialCompleted() || this.mZoomActivated)
         {
            return;
         }
         if(param1.buttonDown)
         {
            _loc2_ = param1.stageX - this.mMouseX;
            _loc3_ = param1.stageY - this.mMouseY;
            _loc4_ = Math.abs(_loc2_) + Math.abs(_loc3_);
            if(!this.mMouseScrolling)
            {
               if(_loc4_ > 5)
               {
                  this.mMouseScrolling = true;
                  this.mGame.getHud().enableMouse(false);
                  this.setMousePos(param1);
               }
            }
         }
         else
         {
            this.mMouseScrolling = false;
         }
         if(this.mMouseScrolling)
         {
            _loc2_ = param1.stageX - this.mMouseX;
            _loc3_ = param1.stageY - this.mMouseY;
            _loc2_ /= this.mContainer.scaleX;
            _loc3_ /= this.mContainer.scaleY;
            this.mCamera.moveTo(-_loc2_ + this.mCamera.getCameraX(),-_loc3_ + this.mCamera.getCameraY());
            this.setMousePos(param1);
         }
      }
      
      public function addFloor(param1:Floor) : void
      {
         this.mFloor = param1;
      }
      
      public function addObject(param1:Element) : void
      {
         this.mAllElements.push(param1);
         var _loc2_:Renderable = param1 as Renderable;
         if(_loc2_)
         {
            if(!this.isObjectInLegalPosition(_loc2_))
            {
               Utils.LogError("Overlapping objects");
            }
            if(_loc2_.getContainer() != null)
            {
               if(_loc2_.getTileSize().z == 0)
               {
                  this.mContainer.addChildAt(_loc2_.getContainer(),0);
               }
               else
               {
                  this.mContainer.addChild(_loc2_.getContainer());
               }
            }
            _loc2_.addListenerObjectMouseReleased(this.FloorClicked);
         }
      }
      
      private function updateStaticObjects(param1:int) : void
      {
         var _loc2_:Element = null;
         var _loc3_:StaticObject = null;
         var _loc4_:Boolean = false;
         var _loc5_:EnemyInstallationObject = null;
         var _loc6_:PlayerInstallationObject = null;
         var _loc7_:StaticObject = null;
         mRemoveArray.length = 0;
         this.mSceneActive = false;
         if(this.mInfoBoxBG)
         {
            this.mInfoBoxBG.visible = false;
         }
         for each(_loc2_ in this.mAllElements)
         {
            _loc3_ = _loc2_ as StaticObject;
            if(_loc3_)
            {
               _loc4_ = _loc3_.logicUpdate(param1);
               if(_loc3_ is EnemyInstallationObject)
               {
                  _loc5_ = _loc3_ as EnemyInstallationObject;
                  _loc5_.updateActions(param1);
               }
               if(_loc3_ is PlayerInstallationObject)
               {
                  _loc6_ = _loc3_ as PlayerInstallationObject;
                  _loc6_.updateActions(param1);
               }
               if(_loc4_)
               {
                  mRemoveArray.push(_loc3_);
               }
            }
         }
         if(mRemoveArray.length > 0)
         {
            for each(_loc7_ in mRemoveArray)
            {
               this.removeObject(_loc7_,true);
            }
            this.updateGridInformation();
            this.updateGridCharacterInfo();
            if(this.mGame.mState != GameState.STATE_VISITING_NEIGHBOUR)
            {
               this.mGame.updateWalkableCellsForActiveCharacter();
            }
         }
      }
      
      private function updateCharacters(param1:int) : void
      {
         var _loc2_:Element = null;
         var _loc3_:IsometricCharacter = null;
         var _loc4_:IsometricCharacter = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         this.mRemoveCharactersArray.length = 0;
         var _loc7_:Boolean = false;
         this.mTick += param1;
         if(this.mTick > 1000)
         {
            _loc7_ = true;
            this.mTick -= 1000;
         }
         if(this.mInfoBoxBG)
         {
            this.mInfoBoxBG.visible = false;
         }
         var _loc8_:int = int(this.mAllElements.length);
         var _loc9_:int = 0;
         while(_loc9_ < _loc8_)
         {
            _loc2_ = this.mAllElements[_loc9_] as Element;
            if(_loc2_ is IsometricCharacter)
            {
               _loc3_ = _loc2_ as IsometricCharacter;
               _loc3_.update(param1);
               if(_loc3_.isReadyToBeRemoved())
               {
                  this.mRemoveCharactersArray.push(_loc3_);
               }
               else
               {
                  _loc3_.updateActions(param1);
                  _loc3_.updateMovement(param1);
               }
            }
            _loc9_++;
         }
         if(this.mRemoveCharactersArray.length > 0)
         {
            _loc5_ = int(this.mRemoveCharactersArray.length);
            _loc6_ = 0;
            while(_loc6_ < _loc5_)
            {
               _loc4_ = this.mRemoveCharactersArray[_loc6_] as IsometricCharacter;
               this.removeObject(_loc4_,false);
               if(_loc4_ is PlayerUnit)
               {
                  if(this.mGame.mState != GameState.STATE_PVP)
                  {
                     this.mGame.mHUD.openUnitDiedTextBox();
                     this.mGame.mPlayerProfile.updateUnitCaps();
                     this.mGame.mPlayerProfile.removeUnit((_loc4_ as PlayerUnit).mItem as PlayerUnitItem);
                  }
               }
               _loc6_++;
            }
            this.updateGridInformation();
            this.updateGridCharacterInfo();
            if(this.mGame.mState != GameState.STATE_VISITING_NEIGHBOUR)
            {
               this.mGame.updateWalkableCellsForActiveCharacter();
            }
         }
      }
      
      public function startCharacterAnimations() : void
      {
         var _loc1_:Element = null;
         var _loc2_:IsometricCharacter = null;
         var _loc3_:int = int(this.mAllElements.length);
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_)
         {
            _loc1_ = this.mAllElements[_loc4_] as Element;
            if(_loc1_ is IsometricCharacter)
            {
               _loc2_ = _loc1_ as IsometricCharacter;
               _loc2_.startAction();
            }
            _loc4_++;
         }
      }
      
      public function stopCharacterAnimations() : void
      {
         var _loc1_:Element = null;
         var _loc2_:IsometricCharacter = null;
         var _loc3_:int = int(this.mAllElements.length);
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_)
         {
            _loc1_ = this.mAllElements[_loc4_] as Element;
            if(_loc1_ is IsometricCharacter)
            {
               _loc2_ = _loc1_ as IsometricCharacter;
               _loc2_.stopAction();
            }
            _loc4_++;
         }
      }
      
      public function getEnemyUnits() : Array
      {
         var _loc1_:Element = null;
         var _loc2_:EnemyUnit = null;
         var _loc3_:Array = new Array();
         var _loc4_:int = int(this.mAllElements.length);
         var _loc5_:int = 0;
         while(_loc5_ < _loc4_)
         {
            _loc1_ = this.mAllElements[_loc5_] as Element;
            if(_loc1_ is EnemyUnit)
            {
               _loc2_ = _loc1_ as EnemyUnit;
               _loc3_.push(_loc2_);
            }
            else if(_loc1_ is PvPEnemyUnit)
            {
               _loc3_.push(_loc1_ as PvPEnemyUnit);
            }
            _loc5_++;
         }
         return _loc3_;
      }
      
      public function getPvPEnemyAliveUnits() : Array
      {
         var _loc1_:Element = null;
         var _loc2_:Array = new Array();
         var _loc3_:int = int(this.mAllElements.length);
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_)
         {
            _loc1_ = this.mAllElements[_loc4_] as Element;
            if(_loc1_ is PvPEnemyUnit)
            {
               if((_loc1_ as PvPEnemyUnit).getHealth() > 0)
               {
                  _loc2_.push(_loc1_ as PvPEnemyUnit);
               }
            }
            _loc4_++;
         }
         return _loc2_;
      }
      
      public function getNumberOfEnemiesReadyToAct() : int
      {
         var _loc1_:Element = null;
         var _loc2_:EnemyUnit = null;
         var _loc3_:int = 0;
         var _loc4_:int = int(this.mAllElements.length);
         var _loc5_:int = 0;
         while(_loc5_ < _loc4_)
         {
            _loc1_ = this.mAllElements[_loc5_] as Element;
            if(_loc1_ is EnemyUnit)
            {
               _loc2_ = _loc1_ as EnemyUnit;
               if(_loc2_.mVisible)
               {
                  if(_loc2_.mRemainingTimeToNextAction == 0)
                  {
                     _loc3_++;
                  }
               }
            }
            _loc5_++;
         }
         return _loc3_;
      }
      
      public function getEnemyInstallations() : Array
      {
         var _loc1_:Element = null;
         var _loc2_:Array = new Array();
         var _loc3_:int = int(this.mAllElements.length);
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_)
         {
            _loc1_ = this.mAllElements[_loc4_] as Element;
            if(_loc1_ is EnemyInstallationObject)
            {
               _loc2_.push(_loc1_ as EnemyInstallationObject);
            }
            _loc4_++;
         }
         return _loc2_;
      }
      
      public function getAllEnemies() : Array
      {
         var _loc1_:Element = null;
         if(this.mAllEnemies == null)
         {
            this.mAllEnemies = new Array();
         }
         this.mAllEnemies.splice(0,this.mAllEnemies.length);
         var _loc2_:int = int(this.mAllElements.length);
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_)
         {
            _loc1_ = this.mAllElements[_loc3_] as Element;
            if(_loc1_ is EnemyUnit)
            {
               this.mAllEnemies.push(_loc1_ as EnemyUnit);
            }
            else if(_loc1_ is EnemyInstallationObject)
            {
               this.mAllEnemies.push(_loc1_ as EnemyInstallationObject);
            }
            else if(_loc1_ is PvPEnemyUnit)
            {
               this.mAllEnemies.push(_loc1_ as PvPEnemyUnit);
            }
            _loc3_++;
         }
         return this.mAllEnemies;
      }
      
      public function getNextEnemyUnitActionQueueNumber() : int
      {
         var _loc1_:Renderable = null;
         var _loc2_:EnemyUnit = null;
         var _loc3_:int = 1;
         var _loc4_:int = int(GameState.mConfig.EnemySetup.MovementCounterInterval.Value);
         var _loc5_:Array = this.getAllEnemies();
         var _loc6_:int = int(_loc5_.length);
         var _loc7_:int = 0;
         while(_loc7_ < _loc6_)
         {
            _loc1_ = _loc5_[_loc7_] as Renderable;
            if(_loc1_ is EnemyUnit)
            {
               _loc2_ = _loc1_ as EnemyUnit;
               if(_loc2_.getReactionState() == EnemyUnit.REACT_STATE_WAIT_FOR_ORDERS)
               {
                  if(_loc2_.mReactionStateCounter >= _loc3_)
                  {
                     _loc3_ = _loc2_.mReactionStateCounter + _loc4_;
                  }
               }
            }
            _loc7_++;
         }
         return _loc3_;
      }
      
      public function setPremiumEnemyUnitActionQueueNumber(param1:EnemyUnit) : void
      {
         var _loc2_:EnemyUnit = null;
         var _loc3_:int = 1;
         var _loc4_:int = 4;
         var _loc5_:Array = this.getEnemyUnits();
         var _loc6_:int = 0;
         while(_loc6_ < _loc5_.length)
         {
            _loc2_ = _loc5_[_loc6_] as EnemyUnit;
            if(_loc2_ != param1)
            {
               if(_loc2_.getReactionState() == EnemyUnit.REACT_STATE_WAIT_FOR_ORDERS)
               {
                  if(_loc3_ == _loc4_)
                  {
                     if(_loc2_.mReactionStateCounter >= _loc3_)
                     {
                        ++_loc2_.mReactionStateCounter;
                     }
                  }
                  else if(_loc2_.mReactionStateCounter == _loc3_)
                  {
                     _loc3_++;
                     _loc5_.splice(_loc6_,1);
                     _loc6_ = -1;
                     if(_loc3_ >= param1.mReactionStateCounter)
                     {
                        break;
                     }
                  }
               }
            }
            _loc6_++;
         }
         if(_loc3_ < param1.mReactionStateCounter)
         {
            param1.mReactionStateCounter = _loc3_;
         }
      }
      
      public function reduceEnemyUnitQueueNumber() : void
      {
         var _loc1_:EnemyUnit = null;
         var _loc2_:Array = this.getEnemyUnits();
         var _loc3_:int = int(_loc2_.length);
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_)
         {
            _loc1_ = _loc2_[_loc4_] as EnemyUnit;
            if(_loc1_.getReactionState() == EnemyUnit.REACT_STATE_WAIT_FOR_ORDERS)
            {
               --_loc1_.mReactionStateCounter;
            }
            _loc4_++;
         }
      }
      
      private function launchParatrooperAirplane(param1:GridCell) : void
      {
         var _loc2_:String = null;
         var _loc3_:DCResourceManager = DCResourceManager.getInstance();
         var _loc4_:String = Config.SWF_EFFECTS_NAME;
         this.mParatrooperLocation = param1;
         if(_loc3_.isLoaded(_loc4_))
         {
            this.addParatrooperAnimaion();
         }
         else
         {
            _loc2_ = _loc4_ + DCResourceManager.EVENT_COMPLETE_SINGLE_FILE;
            _loc3_.addEventListener(_loc2_,this.paratroopAnimationLoaded,false,0,true);
            if(!_loc3_.isAddedToLoadingList(_loc4_))
            {
               _loc3_.load(Config.DIR_DATA + _loc4_ + ".swf",_loc4_,null,false);
            }
         }
      }
      
      private function paratroopAnimationLoaded(param1:Event) : void
      {
         DCResourceManager.getInstance().removeEventListener(param1.type,this.paratroopAnimationLoaded);
         this.addParatrooperAnimaion();
      }
      
      private function addParatrooperAnimaion() : void
      {
         var _loc1_:Class = null;
         if(this.mParatrooperLocation)
         {
            _loc1_ = DCResourceManager.getInstance().getSWFClass(Config.SWF_EFFECTS_NAME,this.mParatrooperAnimationName);
            this.mParatrooperAnimation = new _loc1_();
            this.mParatrooperAnimation.addEventListener(Event.ENTER_FRAME,this.checkParatrooperFrame);
            this.mParatrooperAnimation.x = this.getCenterPointXOfCell(this.mParatrooperLocation);
            this.mParatrooperAnimation.y = this.getCenterPointYOfCell(this.mParatrooperLocation);
            this.mParatrooperAnimation.mouseChildren = false;
            this.mParatrooperAnimation.mouseEnabled = false;
            this.mSceneHud.addChild(this.mParatrooperAnimation);
            this.mParatrooperLocation = null;
         }
      }
      
      private function checkParatrooperFrame(param1:Event) : void
      {
         var _loc2_:MovieClip = (param1.target as MovieClip).getChildAt(0) as MovieClip;
         if(_loc2_.totalFrames == _loc2_.currentFrame)
         {
            if(this.mParatrooperAnimation)
            {
               this.mParatrooperAnimation.removeEventListener(Event.ENTER_FRAME,this.checkParatrooperFrame);
               this.mParatrooperAnimation.stop();
               if(this.mParatrooperAnimation.parent)
               {
                  this.mParatrooperAnimation.parent.removeChild(this.mParatrooperAnimation);
               }
               this.mParatrooperAnimation = null;
            }
         }
      }
      
      private function updateBeaconSpawnerAppearing(param1:int) : void
      {
         var _loc2_:int = 0;
         var _loc3_:Array = null;
         var _loc4_:GridCell = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:EnemyInstallationItem = null;
         var _loc8_:GridCell = null;
         if(!this.mSpawningBeaconAppearTimerItem)
         {
            this.mSpawningBeaconAppearTimerItem = ItemManager.getItemByTableName("EnemySmokeTimer","Timers") as TimerItem;
            _loc2_ = int(GameState.mInstance.mTimers[this.mSpawningBeaconAppearTimerItem.mId]);
            if(_loc2_ == -1)
            {
               this.resetSpawningBeaconTimer();
               this.mSpawningBeaconAppearTimer = this.mSpawningBeaconAppearTimerItem.mDuration * MINUTE_MS;
            }
            else
            {
               this.mSpawningBeaconAppearTimer = _loc2_;
            }
         }
         if(this.mSpawningBeaconObject || this.mGame.mState == GameState.STATE_VISITING_NEIGHBOUR || this.mGame.mState == GameState.STATE_PVP || this.mGame.mCurrentMapId != "Home" || !MissionManager.isSpawnBeaconMissionCompleted())
         {
            return;
         }
         this.mSpawningBeaconAppearTimer += param1;
         if(this.mSpawningBeaconAppearTimer / MINUTE_MS >= this.mSpawningBeaconAppearTimerItem.mDuration)
         {
            if(this.mSpawningBeaconAppearTimerItem.mProbability > Math.random() * 100)
            {
               _loc3_ = new Array();
               _loc5_ = int(this.mGame.mMapData.mGrid.length);
               _loc6_ = 0;
               while(_loc6_ < _loc5_)
               {
                  _loc4_ = this.mGame.mMapData.mGrid[_loc6_] as GridCell;
                  if(_loc4_.mOwner == MapData.TILE_OWNER_FRIENDLY)
                  {
                     if(!_loc4_.mObject)
                     {
                        if(!_loc4_.mCharacter)
                        {
                           if(!_loc4_.mCharacterComingToThisTile)
                           {
                              if(this.isInsideOpenArea(_loc4_))
                              {
                                 _loc3_.push(_loc4_);
                              }
                           }
                        }
                     }
                  }
                  _loc6_++;
               }
               if(_loc3_.length > 0)
               {
                  _loc7_ = ItemManager.getItem("EnemySmokeSignal","SpawningBeacon") as EnemyInstallationItem;
                  _loc8_ = _loc3_[int(Math.random() * _loc3_.length)];
                  this.createSpawningBeacon(_loc7_,_loc8_);
               }
            }
            else
            {
               this.resetSpawningBeaconTimer();
            }
         }
      }
      
      public function resetSpawningBeaconTimer() : void
      {
         var _loc1_:Object = null;
         if(this.mGame.mState != GameState.STATE_PVP && this.mGame.mState != GameState.STATE_VISITING_NEIGHBOUR)
         {
            this.mSpawningBeaconAppearTimer = 0;
            _loc1_ = {
               "timer_name":this.mSpawningBeaconAppearTimerItem.mId,
               "timer_duration":this.mSpawningBeaconAppearTimerItem.mDuration * MINUTE_MS
            };
            this.mGame.mServer.serverCallServiceWithParameters(ServiceIDs.START_TIMER,_loc1_,false);
         }
      }
      
      public function findSpawningBeacon() : void
      {
         var _loc1_:Renderable = null;
         this.mSpawningBeaconObject = null;
         var _loc2_:int = int(this.mAllElements.length);
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_)
         {
            _loc1_ = this.mAllElements[_loc3_] as Renderable;
            if(_loc1_ is SpawningBeaconObject)
            {
               this.mSpawningBeaconObject = _loc1_ as SpawningBeaconObject;
               return;
            }
            _loc3_++;
         }
      }
      
      private function createSpawningBeacon(param1:EnemyInstallationItem, param2:GridCell) : void
      {
         var _loc3_:Object = null;
         if(!this.mSpawningBeaconObject)
         {
            if(this.mGame.mCurrentMapId == "Home")
            {
               this.mSpawningBeaconObject = this.createObject(param1,new Point()) as SpawningBeaconObject;
               this.mSpawningBeaconObject.setPos(this.getCenterPointXOfCell(param2),this.getCenterPointYOfCell(param2),0);
               this.mSpawningBeaconObject.getContainer().visible = true;
               this.mSpawningBeaconObject.mVisible = true;
               _loc3_ = {
                  "coord_x":param2.mPosI,
                  "coord_y":param2.mPosJ,
                  "item_id":param1.mId,
                  "claim_player_tile":true
               };
               this.mGame.mServer.serverCallServiceWithParameters(ServiceIDs.PLACE_ENEMY_INSTALLATION,_loc3_,false);
               if(param2.mOwner == MapData.TILE_OWNER_FRIENDLY)
               {
                  this.changeCellOwner(param2);
               }
               this.updateGridInformation();
               this.updateGridCharacterInfo();
               this.resetSpawningBeaconTimer();
               GameState.mInstance.moveCameraToSeeRenderable(this.mSpawningBeaconObject,true);
            }
         }
      }
      
      private function updateParatroops(param1:int) : void
      {
      }
      
      private function updatePatrols(param1:int) : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:Array = null;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         var _loc10_:int = 0;
         var _loc11_:GridCell = null;
         var _loc12_:Boolean = false;
         var _loc13_:MapArea = null;
         var _loc14_:Array = null;
         var _loc15_:GridCell = null;
         var _loc16_:int = 0;
         var _loc17_:int = 0;
         var _loc18_:int = 0;
         var _loc19_:int = 0;
         var _loc20_:String = null;
         var _loc21_:Renderable = null;
         var _loc22_:Number = NaN;
         var _loc23_:Number = NaN;
         if(GameState.mConfig.EnemyAppearanceSetup.Patrol.Probability > 0)
         {
            this.mPatrolAppearTimer += param1;
            if(this.mPatrolAppearTimer / MINUTE_MS >= GameState.mConfig.EnemyAppearanceSetup.Patrol.ActivationTime)
            {
               this.mPatrolAppearTimer = 0;
               _loc2_ = this.mFloor.getGridTop();
               _loc3_ = this.mFloor.getGridBottom();
               _loc4_ = this.mFloor.getGridLeft();
               _loc5_ = this.mFloor.getGridRight();
               _loc6_ = this.mSizeX * this.mSizeY;
               _loc7_ = this.mGame.mMapData.mGrid;
               _loc8_ = _loc4_;
               while(_loc8_ < _loc5_)
               {
                  _loc9_ = _loc2_;
                  while(_loc9_ < _loc3_)
                  {
                     _loc10_ = _loc9_ * this.mSizeX + _loc8_;
                     if(!(_loc10_ < 0 || _loc10_ >= _loc6_))
                     {
                        _loc11_ = _loc7_[_loc10_] as GridCell;
                        if(!_loc11_.mCharacter)
                        {
                           if(!_loc11_.hasFog())
                           {
                              if(_loc11_.mOwner == MapData.TILE_OWNER_ENEMY)
                              {
                                 if(Math.random() * 100 < GameState.mConfig.EnemyAppearanceSetup.Patrol.Probability)
                                 {
                                    _loc12_ = false;
                                    _loc13_ = MapArea.getAreaAroundCell(this,_loc11_,1);
                                    _loc14_ = _loc13_.getCells();
                                    _loc16_ = 0;
                                    while(_loc16_ < _loc14_.length)
                                    {
                                       if(Boolean((_loc15_ = _loc14_[_loc16_]).mCharacter) && _loc15_.mCharacter is PlayerUnit)
                                       {
                                          _loc12_ = true;
                                          break;
                                       }
                                       _loc16_++;
                                    }
                                    if(!_loc12_)
                                    {
                                       _loc17_ = 0;
                                       _loc18_ = Math.random() * 100;
                                       _loc19_ = 0;
                                       while(_loc19_ < GameState.mConfig.EnemyAppearanceSetup.Patrol.EnemyUnits.length)
                                       {
                                          _loc17_ += int(GameState.mConfig.EnemyAppearanceSetup.Patrol.EnemyUnitsP[_loc19_]);
                                          if(_loc18_ < _loc17_)
                                          {
                                             _loc20_ = String((GameState.mConfig.EnemyAppearanceSetup.Patrol.EnemyUnits[_loc19_] as Object).ID);
                                             _loc21_ = this.createObject(ItemManager.getItem(_loc20_,"EnemyUnit") as MapItem,new Point(0,0));
                                             _loc22_ = this.getCenterPointXAtIJ(_loc11_.mPosI,_loc11_.mPosJ);
                                             _loc23_ = this.getCenterPointYAtIJ(_loc11_.mPosI,_loc11_.mPosJ);
                                             _loc21_.setPos(_loc22_,_loc23_,0);
                                             _loc21_.getContainer().visible = true;
                                             _loc21_.mVisible = true;
                                             break;
                                          }
                                          _loc19_++;
                                       }
                                    }
                                 }
                              }
                           }
                        }
                     }
                     _loc9_++;
                  }
                  _loc8_++;
               }
            }
         }
      }
      
      private function updateDebrisSpawn(param1:int) : void
      {
         var _loc2_:Array = null;
         var _loc3_:Array = null;
         var _loc4_:int = 0;
         var _loc5_:GridCell = null;
         var _loc6_:int = 0;
         var _loc7_:GridCell = null;
         var _loc8_:Number = NaN;
         var _loc9_:Number = NaN;
         if(GameState.mConfig.DebrisSetup.RandomSpawn.Probability > 0)
         {
            this.mDebrisRandomSpawnTimer += param1;
            if(this.mDebrisRandomSpawnTimer / MINUTE_MS > GameState.mConfig.DebrisSetup.RandomSpawn.ActivationTime)
            {
               this.mDebrisRandomSpawnTimer = 0;
               if(Math.random() * 100 < GameState.mConfig.DebrisSetup.RandomSpawn.Probability)
               {
                  _loc2_ = new Array();
                  _loc3_ = MapArea.getArea(this,0,0,this.mSizeX,this.mSizeY).getCells();
                  _loc4_ = 0;
                  while(_loc4_ < _loc3_.length)
                  {
                     _loc5_ = _loc3_[_loc4_] as GridCell;
                     if(_loc5_.mWalkable)
                     {
                        if(_loc5_.mOwner == MapData.TILE_OWNER_ENEMY)
                        {
                           if(!_loc5_.mCharacter)
                           {
                              if(!_loc5_.mObject)
                              {
                                 _loc2_.push(_loc3_[_loc4_]);
                              }
                           }
                        }
                     }
                     _loc4_++;
                  }
                  if(_loc2_.length > 0)
                  {
                     _loc6_ = Math.random() * _loc2_.length;
                     _loc7_ = _loc2_[_loc6_];
                     _loc8_ = this.getCenterPointXAtIJ(_loc7_.mPosI,_loc7_.mPosJ);
                     _loc9_ = this.getCenterPointYAtIJ(_loc7_.mPosI,_loc7_.mPosJ);
                     this.mGame.spawnNewDebris(GameState.mConfig.DebrisSetup.RandomSpawn.DebrisObject.ID,GameState.mConfig.DebrisSetup.RandomSpawn.DebrisObject.Type,_loc8_,_loc9_);
                  }
               }
            }
         }
      }
      
      public function castSaboteurs(param1:GridCell) : void
      {
         var _loc2_:MapArea = null;
         var _loc3_:Array = null;
         var _loc4_:GridCell = null;
         var _loc5_:Array = null;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:GridCell = null;
         var _loc9_:int = 0;
         var _loc10_:int = 0;
         var _loc11_:int = 0;
         var _loc12_:String = null;
         var _loc13_:Renderable = null;
         var _loc14_:Number = NaN;
         var _loc15_:Number = NaN;
         if(GameState.mConfig.EnemyAppearanceSetup.Saboteur.Probability == 0)
         {
            return;
         }
         if(Math.random() * 100 < GameState.mConfig.EnemyAppearanceSetup.Saboteur.Probability)
         {
            _loc2_ = MapArea.getAreaAroundCell(this,param1,1);
            _loc3_ = _loc2_.getCells();
            _loc5_ = new Array();
            _loc6_ = 0;
            while(_loc6_ < _loc3_.length)
            {
               _loc4_ = _loc3_[_loc6_];
               if(_loc4_.mWalkable)
               {
                  if(!_loc4_.hasFog())
                  {
                     if(!_loc4_.mCharacter)
                     {
                        if(!_loc4_.mObject)
                        {
                           _loc5_.push(_loc4_);
                        }
                     }
                  }
               }
               _loc6_++;
            }
            if(_loc5_.length > 0)
            {
               _loc7_ = Math.random() * _loc5_.length;
               _loc8_ = _loc5_[_loc7_] as GridCell;
               if(GameState.mConfig.EnemyAppearanceSetup.Saboteur.EnemyUnits is Array)
               {
                  _loc9_ = 0;
                  _loc10_ = Math.random() * 100;
                  _loc11_ = 0;
                  while(_loc11_ < GameState.mConfig.EnemyAppearanceSetup.Saboteur.EnemyUnits.length)
                  {
                     _loc9_ += int(GameState.mConfig.EnemyAppearanceSetup.Saboteur.EnemyUnitsP[_loc11_]);
                     if(_loc10_ < _loc9_)
                     {
                        _loc12_ = String((GameState.mConfig.EnemyAppearanceSetup.Saboteur.EnemyUnits[_loc11_] as Object).ID);
                        _loc13_ = this.createObject(ItemManager.getItem(_loc12_,"EnemyUnit") as MapItem,new Point(0,0));
                        _loc14_ = this.getCenterPointXAtIJ(_loc8_.mPosI,_loc8_.mPosJ);
                        _loc15_ = this.getCenterPointYAtIJ(_loc8_.mPosI,_loc8_.mPosJ);
                        _loc13_.setPos(_loc14_,_loc15_,0);
                        _loc13_.getContainer().visible = true;
                        _loc13_.mVisible = true;
                        break;
                     }
                     _loc11_++;
                  }
               }
               else
               {
                  _loc13_ = this.createObject(ItemManager.getItem(GameState.mConfig.EnemyAppearanceSetup.Saboteur.EnemyUnits.ID,"EnemyUnit") as MapItem,new Point(0,0));
                  _loc14_ = this.getCenterPointXAtIJ(_loc8_.mPosI,_loc8_.mPosJ);
                  _loc15_ = this.getCenterPointYAtIJ(_loc8_.mPosI,_loc8_.mPosJ);
                  _loc13_.setPos(_loc14_,_loc15_,0);
                  _loc13_.getContainer().visible = true;
                  _loc13_.mVisible = true;
               }
            }
         }
      }
      
      public function getPlayerUnitsAndObjects() : Array
      {
         var _loc1_:Element = null;
         var _loc2_:Array = new Array();
         var _loc3_:int = int(this.mAllElements.length);
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_)
         {
            _loc1_ = this.mAllElements[_loc4_] as Element;
            if(_loc1_ is PlayerUnit)
            {
               if((_loc1_ as PlayerUnit).isAlive())
               {
                  _loc2_.push(_loc1_);
               }
            }
            else if(_loc1_ is PlayerInstallationObject && (_loc1_ as PlayerInstallationObject).isAlive())
            {
               _loc2_.push(_loc1_);
            }
            else if(_loc1_ is PlayerBuildingObject)
            {
               if(_loc1_ is ConstructionObject)
               {
                  if((_loc1_ as ConstructionObject).mHasBeenCompleted)
                  {
                     if((_loc1_ as ConstructionObject).mState != PlayerBuildingObject.STATE_RUINS)
                     {
                        _loc2_.push(_loc1_);
                     }
                  }
               }
               else if(!(_loc1_ is ResourceBuildingObject))
               {
                  if((_loc1_ as PlayerBuildingObject).getHealth() > 0)
                  {
                     _loc2_.push(_loc1_);
                  }
               }
               else if(!(_loc1_ is HospitalBuilding))
               {
                  if((_loc1_ as PlayerBuildingObject).getHealth() > 0)
                  {
                     _loc2_.push(_loc1_);
                  }
               }
            }
            _loc4_++;
         }
         return _loc2_;
      }
      
      public function getPlayerBuildingTargets() : Array
      {
         var _loc1_:Element = null;
         var _loc2_:Array = new Array();
         var _loc3_:int = int(this.mAllElements.length);
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_)
         {
            _loc1_ = this.mAllElements[_loc4_] as Element;
            if(_loc1_ is ConstructionObject)
            {
               if((_loc1_ as ConstructionObject).mHasBeenCompleted)
               {
                  if((_loc1_ as ConstructionObject).mState != PlayerBuildingObject.STATE_RUINS)
                  {
                     _loc2_.push(_loc1_);
                  }
               }
            }
            else if(_loc1_ is ResourceBuildingObject)
            {
            }
            _loc4_++;
         }
         return _loc2_;
      }
      
      public function getPlayerInstallations() : Array
      {
         var _loc1_:Element = null;
         var _loc2_:Array = new Array();
         var _loc3_:int = int(this.mAllElements.length);
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_)
         {
            _loc1_ = this.mAllElements[_loc4_] as Element;
            if(_loc1_ is PlayerInstallationObject)
            {
               _loc2_.push(_loc1_);
            }
            _loc4_++;
         }
         return _loc2_;
      }
      
      public function getPlayerAliveUnits() : Array
      {
         var _loc1_:Element = null;
         var _loc2_:Array = new Array();
         var _loc3_:int = int(this.mAllElements.length);
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_)
         {
            _loc1_ = this.mAllElements[_loc4_] as Element;
            if(_loc1_ is PlayerUnit && (_loc1_ as PlayerUnit).isAlive())
            {
               _loc2_.push(_loc1_ as PlayerUnit);
            }
            _loc4_++;
         }
         return _loc2_;
      }
      
      private function highlightCell(param1:GridCell) : void
      {
         switch(this.mGame.mState)
         {
            case GameState.STATE_PVP:
            case GameState.STATE_PLAY:
               if(param1 != this.mPreviousCell)
               {
                  if(this.mGame.mActivatedPlayerUnit)
                  {
                     this.mMapGUIEffectsLayer.highlightSelectedGridCell(param1,true);
                     this.mMapGUIEffectsLayer.highlightSelectedGridCell(this.mPreviousCell,false);
                  }
               }
               break;
            case GameState.STATE_MOVE_ITEM:
            case GameState.STATE_PLACE_ITEM:
            case GameState.STATE_USE_INVENTORY_ITEM:
         }
      }
      
      public function highlightDebris(param1:GridCell) : void
      {
         if(this.mHighlightedDebris)
         {
            if(this.mHighlightedDebris.getContainer())
            {
               this.mHighlightedDebris.getContainer().mouseEnabled = false;
               this.mHighlightedDebris.getContainer().mouseChildren = false;
            }
         }
         if(param1 && param1.mObject && param1.mObject is DebrisObject && !this.mGame.mActivatedPlayerUnit && param1.mCharacter == null)
         {
            this.mHighlightedDebris = DebrisObject(param1.mObject);
            if(!Config.MOBILE_MODE || Config.MOBILE_MODE && mouseDownAction)
            {
               this.showObjectTooltip(this.mHighlightedDebris);
               this.startToolTipTimer();
            }
            if(param1.mOwner == MapData.TILE_OWNER_FRIENDLY && (this.mAllowMouseX == param1.mPosI && this.mAllowMouseY == param1.mPosJ || !this.mMouseDisabled))
            {
               this.setHandCursor(this.mHighlightedDebris.getContainer(),true);
               this.mHighlightedDebris.getContainer().mouseEnabled = true;
               this.mHighlightedDebris.getContainer().mouseChildren = true;
            }
         }
         else if(param1 && !param1.mObject && !param1.mCharacter && !param1.mPowerUp)
         {
            this.hideObjectTooltip();
         }
      }
      
      private function highlightCharacter(param1:GridCell, param2:int) : void
      {
         var _loc3_:Array = null;
         var _loc4_:PlayerUnit = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:PlayerUnit = null;
         var _loc9_:int = 0;
         var _loc10_:int = 0;
         var _loc11_:int = 0;
         if(param1 != this.mPreviousCell)
         {
            if(this.mPreviousCell)
            {
               if(this.mPreviousCell.mCharacter)
               {
                  if(this.mPreviousCell.mCharacter is EnemyUnit)
                  {
                     _loc3_ = this.mGame.searchAttackablePlayerUnits(this.mPreviousCell.mCharacter);
                     if(_loc3_)
                     {
                        _loc5_ = int(_loc3_.length);
                        _loc6_ = 0;
                        while(_loc6_ < _loc5_)
                        {
                           _loc4_ = _loc3_[_loc6_] as PlayerUnit;
                           if(!_loc4_.isShooting())
                           {
                              _loc4_.setAnimationAction(AnimationController.CHARACTER_ANIMATION_IDLE,false,true);
                           }
                           _loc6_++;
                        }
                        this.mMapGUIEffectsLayer.hideAttackGridCells();
                     }
                  }
                  if(!param1 || this.mPreviousCell.mCharacter != param1.mCharacter)
                  {
                     this.hideObjectTooltip();
                  }
                  this.setHandCursor(this.mPreviousCell.mCharacter.getContainer(),false);
               }
            }
         }
         if(!this.isInsideVisibleArea(param1))
         {
            return;
         }
         if(param1)
         {
            if(param1.mCharacter)
            {
               if(!param1.hasFog())
               {
                  this.setHandCursor(param1.mCharacter.getContainer(),true);
                  if(param1.mCharacter is EnemyUnit && !this.mGame.mVisitingFriend)
                  {
                     _loc3_ = this.mGame.searchAttackablePlayerUnits(param1.mCharacter);
                     _loc7_ = 0;
                     if(_loc3_)
                     {
                        _loc9_ = int(_loc3_.length);
                        _loc10_ = 0;
                        while(_loc10_ < _loc9_)
                        {
                           _loc8_ = _loc3_[_loc10_] as PlayerUnit;
                           _loc8_.aimTo(param1.mCharacter.mX,param1.mCharacter.mY);
                           _loc7_ += _loc8_.getPower();
                           _loc11_ = Math.floor(_loc8_.mX / this.mGridDimX);
                           if(_loc11_ < param1.mPosI)
                           {
                              _loc8_.setAnimationDirection(AnimationController.DIR_RIGHT);
                           }
                           else if(_loc11_ > param1.mPosI)
                           {
                              _loc8_.setAnimationDirection(AnimationController.DIR_LEFT);
                           }
                           if(_loc8_.isStill())
                           {
                              this.mMapGUIEffectsLayer.highlightAttackerGridCell(_loc8_.getCell());
                           }
                           _loc10_++;
                        }
                     }
                     if(!Config.MOBILE_MODE || Config.MOBILE_MODE && mouseDownAction)
                     {
                        this.showObjectTooltip(param1.mCharacter,_loc7_);
                        this.startToolTipTimer();
                     }
                  }
                  else if(!Config.MOBILE_MODE || Config.MOBILE_MODE && mouseDownAction)
                  {
                     this.showObjectTooltip(param1.mCharacter);
                     this.startToolTipTimer();
                  }
               }
            }
         }
      }
      
      public function showObjectTooltip(param1:Renderable, param2:int = 0) : void
      {
         if(LootReward.smActivatedCounter == 0)
         {
            this.mGame.getHud().showObjectTooltip(param1,param2);
         }
      }
      
      public function hideObjectTooltip() : void
      {
         var _loc1_:HUDInterface = this.mGame.getHud();
         if(_loc1_ != null)
         {
            _loc1_.hideObjectTooltip();
         }
      }
      
      private function highlightEnemyInstallation(param1:GridCell, param2:int) : void
      {
         var _loc3_:Array = null;
         var _loc4_:PlayerUnit = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:PlayerUnit = null;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         var _loc10_:int = 0;
         if(param1 != this.mPreviousCell)
         {
            if(this.mPreviousCell)
            {
               if(this.mPreviousCell.mObject)
               {
                  if(this.mPreviousCell.mObject is EnemyInstallationObject)
                  {
                     if(!(Boolean(param1) && Boolean(param1.mObject) && param1.mObject == this.mPreviousCell.mObject))
                     {
                        _loc3_ = this.mGame.searchAttackablePlayerUnits(this.mPreviousCell.mObject);
                        if(_loc3_)
                        {
                           _loc5_ = int(_loc3_.length);
                           _loc6_ = 0;
                           while(_loc6_ < _loc5_)
                           {
                              _loc4_ = _loc3_[_loc6_] as PlayerUnit;
                              if(!_loc4_.isShooting())
                              {
                                 _loc4_.setAnimationAction(AnimationController.CHARACTER_ANIMATION_IDLE,false,true);
                              }
                              _loc6_++;
                           }
                           this.mMapGUIEffectsLayer.hideAttackGridCells();
                        }
                        if(!param1 || this.mPreviousCell.mObject != param1.mObject)
                        {
                           this.hideObjectTooltip();
                           this.setHandCursor(this.mPreviousCell.mObject.getContainer(),false);
                        }
                     }
                  }
               }
            }
         }
         if(param1)
         {
            if(!param1.hasFog())
            {
               if(param1.mObject)
               {
                  if(param1.mObject is EnemyInstallationObject)
                  {
                     if((param1.mObject as EnemyInstallationObject).isAlive())
                     {
                        if(!Config.MOBILE_MODE || Config.MOBILE_MODE && mouseDownAction)
                        {
                           this.showObjectTooltip(param1.mObject);
                           this.startToolTipTimer();
                        }
                        this.setHandCursor(param1.mObject.getContainer(),true);
                     }
                     if(!param1.mObject.isWalkable())
                     {
                        if(!this.mGame.mVisitingFriend)
                        {
                           if(!(param1.mObject is SpawningBeaconObject))
                           {
                              _loc3_ = this.mGame.searchAttackablePlayerUnits(param1.mObject);
                              if(_loc3_)
                              {
                                 _loc8_ = int(_loc3_.length);
                                 _loc9_ = 0;
                                 while(_loc9_ < _loc8_)
                                 {
                                    _loc7_ = _loc3_[_loc9_] as PlayerUnit;
                                    _loc7_.aimTo(param1.mObject.mX,param1.mObject.mY + (param1.mObject.getTileSize().y * this.mGridDimX >> 1));
                                    _loc10_ = Math.floor(_loc7_.mX / this.mGridDimX);
                                    if(_loc10_ < param1.mPosI)
                                    {
                                       _loc7_.setAnimationDirection(AnimationController.DIR_RIGHT);
                                    }
                                    else if(_loc10_ > param1.mPosI)
                                    {
                                       _loc7_.setAnimationDirection(AnimationController.DIR_LEFT);
                                    }
                                    if(_loc7_.isStill())
                                    {
                                       this.mMapGUIEffectsLayer.highlightAttackerGridCell(_loc7_.getCell());
                                    }
                                    _loc9_++;
                                 }
                              }
                           }
                        }
                     }
                  }
               }
            }
         }
      }
      
      private function highlightFriendlyInstallation(param1:GridCell, param2:int) : void
      {
         var _loc3_:Array = null;
         var _loc4_:PlayerUnit = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:PlayerUnit = null;
         var _loc9_:int = 0;
         var _loc10_:int = 0;
         var _loc11_:int = 0;
         if(param1 != this.mPreviousCell)
         {
            if(this.mPreviousCell && this.mPreviousCell.mObject && (this.mPreviousCell.mObject is PlayerBuildingObject || this.mPreviousCell.mObject is PlayerInstallationObject || this.mPreviousCell.mObject is SignalObject))
            {
               if(param1 && param1.mObject && param1.mObject == this.mPreviousCell.mObject)
               {
                  if(param1.mCharacter)
                  {
                     if(this.mPreviousCell.mObject is PlayerBuildingObject)
                     {
                        this.hideObjectTooltip();
                     }
                     else
                     {
                        this.hideObjectTooltip();
                     }
                  }
               }
               else
               {
                  _loc3_ = this.mGame.searchUnitsInRange(this.mPreviousCell.mObject);
                  if(_loc3_)
                  {
                     _loc5_ = int(_loc3_.length);
                     _loc6_ = 0;
                     while(_loc6_ < _loc5_)
                     {
                        _loc4_ = _loc3_[_loc6_] as PlayerUnit;
                        if(!_loc4_.isShooting())
                        {
                           _loc4_.setAnimationAction(AnimationController.CHARACTER_ANIMATION_IDLE,false,true);
                        }
                        _loc6_++;
                     }
                     this.mMapGUIEffectsLayer.hideAttackGridCells();
                  }
                  if(!param1 || this.mPreviousCell.mObject != param1.mObject)
                  {
                     if(this.mPreviousCell.mObject is PlayerBuildingObject)
                     {
                        this.hideObjectTooltip();
                     }
                     else
                     {
                        this.hideObjectTooltip();
                     }
                  }
               }
            }
         }
         if(param1)
         {
            if(!param1.hasFog())
            {
               if(param1.mObject)
               {
                  if(param1.mObject is PlayerBuildingObject)
                  {
                     if((param1.mObject as PlayerBuildingObject).getState() != PlayerBuildingObject.STATE_RUINS)
                     {
                        _loc7_ = (param1.mObject as PlayerBuildingObject).getState();
                        if(this.mGame.mActivatedPlayerUnit || !(param1.mObject as PlayerBuildingObject).isFullHealth() || _loc7_ == PlayerBuildingObject.STATE_BEING_HARVESTED || _loc7_ == PlayerBuildingObject.STATE_PLACING_ON_MAP || _loc7_ == PlayerBuildingObject.STATE_PRODUCING || _loc7_ == PlayerBuildingObject.STATE_REMOVE)
                        {
                           this.setHandCursor(param1.mObject.getContainer(),false);
                        }
                        else
                        {
                           this.setHandCursor(param1.mObject.getContainer(),true);
                        }
                     }
                     if(!param1.mCharacter)
                     {
                        if(!Config.MOBILE_MODE || Config.MOBILE_MODE && mouseDownAction)
                        {
                           if(mouseDownAction)
                           {
                              this.showObjectTooltip(param1.mObject,1);
                           }
                           else
                           {
                              this.showObjectTooltip(param1.mObject,0);
                           }
                           this.startToolTipTimer();
                        }
                     }
                     if(param1.mObject is PermanentHFEObject)
                     {
                        if(!this.mGame.mVisitingFriend)
                        {
                           _loc3_ = this.mGame.searchUnitsInRange(param1.mObject);
                           if(_loc3_)
                           {
                              _loc9_ = int(_loc3_.length);
                              _loc10_ = 0;
                              while(_loc10_ < _loc9_)
                              {
                                 _loc8_ = _loc3_[_loc10_] as PlayerUnit;
                                 _loc8_.aimTo(param1.mObject.mX,param1.mObject.mY + (param1.mObject.getTileSize().y * this.mGridDimX >> 1));
                                 _loc11_ = Math.floor(_loc8_.mX / this.mGridDimX);
                                 if(_loc11_ < param1.mPosI)
                                 {
                                    _loc8_.setAnimationDirection(AnimationController.DIR_RIGHT);
                                 }
                                 else if(_loc11_ > param1.mPosI)
                                 {
                                    _loc8_.setAnimationDirection(AnimationController.DIR_LEFT);
                                 }
                                 if(!(param1.mObject as PermanentHFEObject).isFullHealth())
                                 {
                                    if(_loc8_.isStill())
                                    {
                                       this.mMapGUIEffectsLayer.highlightAttackerGridCell(_loc8_.getCell());
                                    }
                                 }
                                 _loc10_++;
                              }
                           }
                        }
                     }
                  }
                  else if(param1.mObject is PlayerInstallationObject)
                  {
                     if(!Config.MOBILE_MODE || Config.MOBILE_MODE && mouseDownAction)
                     {
                        this.showObjectTooltip(param1.mObject);
                        this.startToolTipTimer();
                     }
                  }
                  else if(param1.mObject is SignalObject)
                  {
                     if(!Config.MOBILE_MODE || Config.MOBILE_MODE && mouseDownAction)
                     {
                        this.showObjectTooltip(param1.mObject);
                        this.startToolTipTimer();
                     }
                  }
               }
            }
         }
      }
      
      public function addEffect(param1:MovieClip, param2:int, param3:int, param4:int, param5:String = "") : void
      {
         this.mEffectPending = !this.mEffectController.startEffect(this,param1,param2,param3,param4,param5);
         if(this.mEffectPending)
         {
            this.mEffectPendingMC = param1;
            this.mEffectPendingType = param2;
            this.mEffectPendingX = param3;
            this.mEffectPendingY = param4;
            this.mEffectPendingClipName = param5;
         }
      }
      
      private function setHandCursor(param1:DisplayContainer, param2:Boolean) : void
      {
         param1.buttonMode = param2;
         param1.useHandCursor = param2;
         param1.mouseEnabled = param2;
      }
      
      public function initCursors() : void
      {
         CursorManager.getInstance().initCursorImages();
      }
      
      private function shouldShowSelectCursorOnBuilding(param1:Renderable) : Boolean
      {
         return param1 is PlayerBuildingObject && (!(param1 is ConstructionObject) || (param1 as ConstructionObject).mState != PlayerBuildingObject.STATE_RUINS) && (!(param1 is ResourceBuildingObject) || (param1 as ResourceBuildingObject).mState != PlayerBuildingObject.STATE_RUINS) && (!(param1 is PermanentHFEObject) || param1 is PermanentHFEObject && PermanentHFEObject(param1).isFullHealth()) && (!(param1 is HospitalBuilding) || (param1 as HospitalBuilding).mState != PlayerBuildingObject.STATE_RUINS) || param1 is PlayerInstallationObject || param1 is DebrisObject;
      }
      
      private function shouldShowAttackCursorOnBuilding(param1:Renderable) : Boolean
      {
         return param1 is EnemyInstallationObject && EnemyInstallationObject(param1).isAlive() || param1 is PermanentHFEObject && !PermanentHFEObject(param1).isFullHealth();
      }
      
      private function shouldShowSelectCursorAtNeighbourCell(param1:GridCell) : Boolean
      {
         if(this.mGame.mPlayerProfile.mNeighborActionsLeft <= 0)
         {
            return false;
         }
         if(param1.mViewers <= 0)
         {
            if(param1.mOwner != MapData.TILE_OWNER_FRIENDLY)
            {
               return false;
            }
         }
         if(param1.mCharacter)
         {
            return true;
         }
         if(param1.mObject)
         {
            if(param1.mObject is EnemyInstallationObject)
            {
               if((param1.mObject as EnemyInstallationObject).hasForceField())
               {
                  return false;
               }
            }
            if(param1.mObject is DebrisObject)
            {
               if(param1.mOwner == MapData.TILE_OWNER_FRIENDLY)
               {
                  return true;
               }
            }
            if(param1.mObject is HFEObject)
            {
               return true;
            }
            if(param1.mObject is EnemyInstallationObject)
            {
               return true;
            }
            if(param1.mObject.isPlaceableOnAllTiles())
            {
               return true;
            }
         }
         return false;
      }
      
      public function setVisiblePlacementButton(param1:Boolean) : void
      {
         if(!this.mTickCrossActive && param1)
         {
            this.mTickCrossActive = true;
         }
         if(this.mGame.mHUD)
         {
            this.mGame.mHUD.mPlaceButton.setVisible(param1);
         }
         if(this.mGame.mHUD)
         {
            this.mGame.mHUD.mPlaceCancelButton.setVisible(param1);
         }
      }
      
      private function moveButton(param1:GridCell) : void
      {
         var _loc2_:Number = NaN;
         var _loc3_:Number = NaN;
         var _loc4_:Point = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         var _loc10_:int = 0;
         var _loc11_:Point = null;
         var _loc12_:int = 0;
         var _loc13_:int = 0;
         if(this.mObjectBeingMoved)
         {
            _loc2_ = this.mObjectBeingMoved.getContainer().width;
            _loc3_ = this.mObjectBeingMoved.getContainer().height;
            _loc4_ = new Point(this.mObjectBeingMoved.mX,this.mObjectBeingMoved.mY);
            _loc4_ = this.mSceneHud.localToGlobal(_loc4_);
            _loc12_ = _loc4_.x;
            _loc13_ = _loc4_.y;
            _loc5_ = this.mObjectBeingMoved.getTileSize().x - 1;
            _loc6_ = this.mObjectBeingMoved.getTileSize().y - 1;
            _loc7_ = 0;
            _loc8_ = CursorManager.CURSOR_TYPE_RELOCATE_WITH_COST_1 + _loc5_;
            switch(_loc8_)
            {
               case CursorManager.CURSOR_TYPE_RELOCATE_WITH_COST_1:
                  _loc7_ = _loc12_ - 25 - this.mGame.mHUD.mPlaceCancelButton.getWidth();
                  _loc12_ = _loc12_ - 180 - this.mGame.mHUD.mPlaceButton.getWidth();
                  break;
               case CursorManager.CURSOR_TYPE_RELOCATE_WITH_COST_2:
                  _loc7_ = _loc12_ + 75 - this.mGame.mHUD.mPlaceCancelButton.getWidth();
                  _loc12_ = _loc12_ - 180 - this.mGame.mHUD.mPlaceButton.getWidth();
                  break;
               case CursorManager.CURSOR_TYPE_RELOCATE_WITH_COST_3:
                  _loc7_ = _loc12_ + 170 - this.mGame.mHUD.mPlaceCancelButton.getWidth();
                  _loc12_ = _loc12_ - 180 - this.mGame.mHUD.mPlaceButton.getWidth();
                  break;
               case CursorManager.CURSOR_TYPE_RELOCATE_WITH_COST_4:
                  _loc7_ = _loc12_ + 270 - this.mGame.mHUD.mPlaceCancelButton.getWidth();
                  _loc12_ = _loc12_ - 180 - this.mGame.mHUD.mPlaceButton.getWidth();
            }
            this.mGame.mHUD.mPlaceButton.setX(_loc12_);
            this.mGame.mHUD.mPlaceButton.setY(_loc13_ - 30);
            this.mGame.mHUD.mPlaceCancelButton.setX(_loc7_);
            this.mGame.mHUD.mPlaceCancelButton.setY(_loc13_ - 30);
         }
         else
         {
            _loc9_ = this.mGridDimX * param1.mPosI;
            _loc10_ = this.mGridDimY * param1.mPosJ;
            _loc11_ = new Point(_loc9_,_loc10_);
            _loc11_ = this.mSceneHud.localToGlobal(_loc11_);
            this.mGame.mHUD.mPlaceButton.setX(_loc11_.x - 140);
            this.mGame.mHUD.mPlaceButton.setY(_loc11_.y - 40);
            this.mGame.mHUD.mPlaceCancelButton.setX(_loc11_.x - 60);
            this.mGame.mHUD.mPlaceCancelButton.setY(_loc11_.y - 40);
         }
      }
      
      public function updateCursors(param1:int, param2:Boolean = false) : void
      {
         var _loc3_:GridCell = null;
         var _loc4_:MapArea = null;
         if(this.isLootRewardActivated() || this.mGame.mHUD && this.mGame.mHUD.mBlock)
         {
            this.hideCursors();
            this.mPreviousCursorCell = null;
            this.mMapGUIEffectsLayer.removeHighlightRange();
            this.mMapGUIEffectsLayer.clearEnemyMovementHighlights();
            return;
         }
         _loc3_ = this.getTileUnderMouse();
         if(!_loc3_ || !this.isInsideVisibleArea(_loc3_))
         {
            this.mPreviousCursorCell = null;
            this.hideCursors();
            return;
         }
         if(_loc3_ != this.mPreviousCursorCell || param2)
         {
            this.mPreviousCursorCell = _loc3_;
            this.hideCursors();
            this.mMapGUIEffectsLayer.removeHighlightRange();
            this.mMapGUIEffectsLayer.clearEnemyMovementHighlights();
         }
         var _loc5_:Boolean = true;
         var _loc6_:CursorManager = CursorManager.getInstance();
         var _loc7_:int = 0;
         var _loc8_:int = -1;
         var _loc9_:* = false;
         var _loc10_:IsometricCharacter = _loc3_.mCharacter;
         var _loc11_:Renderable = _loc3_.mObject;
         var _loc12_:int = 0;
         var _loc13_:int = 0;
         if(this.mObjectBeingMoved)
         {
            if(this.mObjectBeingMoved.mScene)
            {
               _loc12_ = this.mObjectBeingMoved.getTileSize().x - 1;
               _loc13_ = this.mObjectBeingMoved.getTileSize().y - 1;
               _loc6_.setPos(this.mObjectBeingMoved.getCell());
               if(this.isInLegalPlacementArea(this.mObjectBeingMoved))
               {
                  this.setVisiblePlacementButton(true);
               }
               else
               {
                  this.setVisiblePlacementButton(false);
               }
               this.moveButton(this.mObjectBeingMoved.getCell());
            }
         }
         else if(_loc11_ && _loc11_.getContainer().visible && this.mGame.mState != GameState.STATE_PLACE_FIRE_MISSION)
         {
            _loc12_ = _loc11_.getTileSize().x - 1;
            _loc13_ = _loc11_.getTileSize().y - 1;
            _loc6_.setPos(_loc11_.getCell());
         }
         else
         {
            _loc6_.setPos(_loc3_);
         }
         switch(this.mGame.mState)
         {
            case GameState.STATE_PVP:
            case GameState.STATE_PLAY:
               if(Boolean(_loc10_) && _loc10_.getContainer().visible)
               {
                  _loc6_.setPos(_loc3_);
                  if(_loc10_ is PlayerUnit)
                  {
                     if(this.mGame.mCurrentAction)
                     {
                        _loc9_ = true;
                     }
                     _loc8_ = CursorManager.CURSOR_TYPE_SELECT_1;
                  }
                  else if(_loc10_ is EnemyUnit && _loc10_.isAlive())
                  {
                     if(this.mGame.searchUnitsInRange(_loc10_).length > 0)
                     {
                        _loc8_ = CursorManager.CURSOR_TYPE_ATTACK_1;
                     }
                     else
                     {
                        _loc8_ = CursorManager.CURSOR_TYPE_SELECT_1;
                     }
                  }
                  else if(FeatureTuner.USE_PVP_MATCH && _loc10_ is PvPEnemyUnit)
                  {
                     this.mGame.updateWalkableCellsForPvPEnemy(_loc10_ as PvPEnemyUnit);
                  }
                  this.mMapGUIEffectsLayer.highlightRange(_loc3_,_loc10_);
               }
               else if(Boolean(_loc11_) && _loc11_.getContainer().visible)
               {
                  _loc6_.setPos(_loc11_.getCell());
                  if(this.shouldShowSelectCursorOnBuilding(_loc11_))
                  {
                     if(_loc12_ == _loc13_)
                     {
                        _loc8_ = CursorManager.CURSOR_TYPE_SELECT_1 + _loc12_;
                     }
                     else
                     {
                        _loc8_ = this.getSpecialCursor(CursorManager.CURSOR_TYPE_SELECT_1,_loc12_,_loc13_);
                     }
                  }
                  else if(this.shouldShowAttackCursorOnBuilding(_loc11_))
                  {
                     if(this.mGame.searchUnitsInRange(_loc11_).length > 0)
                     {
                        if(_loc12_ == _loc13_)
                        {
                           _loc8_ = CursorManager.CURSOR_TYPE_ATTACK_1 + _loc12_;
                        }
                        else
                        {
                           _loc8_ = this.getSpecialCursor(CursorManager.CURSOR_TYPE_ATTACK_1,_loc12_,_loc13_);
                        }
                     }
                     else if(_loc12_ == _loc13_)
                     {
                        _loc8_ = CursorManager.CURSOR_TYPE_SELECT_1 + _loc12_;
                     }
                     else
                     {
                        _loc8_ = this.getSpecialCursor(CursorManager.CURSOR_TYPE_SELECT_1,_loc12_,_loc13_);
                     }
                  }
                  this.mMapGUIEffectsLayer.highlightRange(_loc3_,_loc11_);
               }
               if(_loc8_ == -1)
               {
                  if(this.mGame.mActivatedPlayerUnit)
                  {
                     if(this.mGame.mActiveCharacteWalkableCells.indexOf(_loc3_) != -1)
                     {
                        _loc6_.setPos(_loc3_);
                        _loc8_ = CursorManager.CURSOR_TYPE_SELECT_1;
                        _loc7_ = -1;
                     }
                  }
               }
               break;
            case GameState.STATE_MOVE_ITEM:
               if(this.mObjectBeingMoved)
               {
                  this.mFlagDrag = true;
                  _loc8_ = CursorManager.CURSOR_TYPE_RELOCATE_WITH_COST_1 + _loc12_;
                  _loc9_ = !this.isCellEnableForMovingObject(_loc3_,false) || !this.isInLegalPlacementArea(this.mObjectBeingMoved);
               }
               else
               {
                  _loc8_ = CursorManager.CURSOR_TYPE_RELOCATE_WITH_COST_1 + _loc12_;
                  _loc9_ = !_loc11_ || !_loc11_.isMovable();
               }
               if(this.mObjectBeingMoved)
               {
                  if(!_loc9_)
                  {
                     if(!this.mGame.mHUD.mBlock)
                     {
                        this.mMapGUIEffectsLayer.highlightRange(_loc3_,this.mObjectBeingMoved);
                     }
                  }
               }
               break;
            case GameState.STATE_PLACE_ITEM:
               _loc8_ = CursorManager.CURSOR_TYPE_RELOCATE_1 + _loc12_;
               _loc9_ = !this.isCellEnableForMovingObject(_loc3_,false) || !this.isInLegalPlacementArea(this.mObjectBeingMoved);
               if(this.mObjectBeingMoved)
               {
                  if(!_loc9_)
                  {
                     this.mMapGUIEffectsLayer.highlightRange(_loc3_,this.mObjectBeingMoved);
                  }
               }
               break;
            case GameState.STATE_PLACE_FIRE_MISSION:
               _loc8_ = CursorManager.CURSOR_TYPE_FM_1 + this.mGame.mFireMisssionToBePlaced.mCursorOffset;
               this.setVisiblePlacementButton(true);
               this.moveButton(_loc3_);
               _loc4_ = MapArea.getArea(this,_loc3_.mPosI,_loc3_.mPosJ,this.mGame.mFireMisssionToBePlaced.mSize.x,this.mGame.mFireMisssionToBePlaced.mSize.y);
               if(!this.mPlacePressed)
               {
                  this.mFireItemX = _loc3_.mPosI;
                  this.mFireItemY = _loc3_.mPosJ;
               }
               _loc9_ = false;
               break;
            case GameState.STATE_USE_INVENTORY_ITEM:
               if(_loc11_ && _loc11_.isMovable() || Boolean(this.mObjectBeingMoved))
               {
                  if(this.mObjectBeingMoved)
                  {
                     _loc12_ = this.mObjectBeingMoved.getTileSize().x - 1;
                     _loc13_ = this.mObjectBeingMoved.getTileSize().y - 1;
                     _loc9_ = !this.isCellEnableForMovingObject(_loc3_,false) || !this.isInLegalPlacementArea(this.mObjectBeingMoved);
                     if(!_loc9_)
                     {
                        this.mMapGUIEffectsLayer.highlightRange(_loc3_,this.mObjectBeingMoved);
                     }
                  }
                  _loc8_ = CursorManager.CURSOR_TYPE_RELOCATE_1 + _loc12_;
               }
               break;
            case GameState.STATE_REPAIR_ITEM:
               if(_loc12_ == _loc13_)
               {
                  _loc8_ = CursorManager.CURSOR_TYPE_REPAIR_1 + _loc12_;
               }
               else
               {
                  _loc8_ = CursorManager.CURSOR_TYPE_REPAIR_1;
                  _loc6_.setPos(_loc3_);
               }
               _loc9_ = !this.isCellEnableForRepairObject(_loc3_);
               break;
            case GameState.STATE_SELL_ITEM:
               _loc8_ = CursorManager.CURSOR_TYPE_SELL_1 + _loc12_;
               _loc9_ = !this.isCellEnableForSellObject(_loc3_);
               break;
            case GameState.STATE_PICKUP_UNIT:
               _loc8_ = CursorManager.CURSOR_TYPE_REDEPLOY;
               _loc9_ = !this.isCellEnableForRedeploying(_loc3_);
               break;
            case GameState.STATE_VISITING_NEIGHBOUR:
               if(this.shouldShowSelectCursorAtNeighbourCell(_loc3_))
               {
                  if(_loc12_ == _loc13_)
                  {
                     _loc8_ = CursorManager.CURSOR_TYPE_SELECT_1 + _loc12_;
                  }
                  else
                  {
                     _loc8_ = this.getSpecialCursor(CursorManager.CURSOR_TYPE_SELECT_1,_loc12_,_loc13_);
                  }
                  this.mMapGUIEffectsLayer.highlightNeighbourClickableCell(_loc3_);
               }
               if(_loc8_ == -1)
               {
                  this.mMapGUIEffectsLayer.clearHighlights();
               }
         }
         if(_loc8_ != -1)
         {
            _loc6_.addCursorImage(_loc8_,_loc9_,_loc7_);
         }
      }
      
      private function getSpecialCursor(param1:int, param2:int, param3:int) : int
      {
         var _loc4_:int = -1;
         if(param1 == CursorManager.CURSOR_TYPE_SELECT_1)
         {
            if(param2 == 1 && param3 == 0)
            {
               _loc4_ = CursorManager.CURSOR_TYPE_SELECT_SPECIAL_2X1;
            }
            else if(param2 == 3 && param3 == 0)
            {
               _loc4_ = CursorManager.CURSOR_TYPE_SELECT_SPECIAL_4X1;
            }
            else if(param2 == 3 && param3 == 1)
            {
               _loc4_ = CursorManager.CURSOR_TYPE_SELECT_SPECIAL_4X2;
            }
            else if(param2 == 2 && param3 == 1)
            {
               _loc4_ = CursorManager.CURSOR_TYPE_SELECT_SPECIAL_3X2;
            }
         }
         else if(param1 == CursorManager.CURSOR_TYPE_ATTACK_1)
         {
            if(param2 == 1 && param3 == 0)
            {
               _loc4_ = CursorManager.CURSOR_TYPE_ATTACK_SPECIAL_2X1;
            }
            else if(param2 == 3 && param3 == 0)
            {
               _loc4_ = CursorManager.CURSOR_TYPE_ATTACK_SPECIAL_4X1;
            }
            else if(param2 == 3 && param3 == 1)
            {
               _loc4_ = CursorManager.CURSOR_TYPE_ATTACK_SPECIAL_4X2;
            }
            else if(param2 == 2 && param3 == 1)
            {
               _loc4_ = CursorManager.CURSOR_TYPE_ATTACK_SPECIAL_3X2;
            }
         }
         return _loc4_;
      }
      
      private function hideCursors() : void
      {
         CursorManager.getInstance().hideCursorImages();
         this.setVisiblePlacementButton(false);
      }
      
      public function updateKeyScrolling() : void
      {
         var _loc1_:int = 0;
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:Boolean = false;
         var _loc6_:Number = NaN;
         var _loc7_:Number = NaN;
         var _loc8_:Number = NaN;
         if(!this.mMouseScrolling)
         {
            _loc1_ = this.mCamera.getCameraX();
            _loc2_ = this.mCamera.getCameraY();
            _loc3_ = this.mCamera.getTargetX();
            _loc4_ = this.mCamera.getTargetY();
            _loc5_ = false;
            if(this.mLeftPressed)
            {
               this.mCamera.setTargetTo(_loc3_ - CAM_SPEED,_loc4_);
               _loc3_ = this.mCamera.getTargetX();
               _loc5_ = true;
            }
            if(this.mRightPressed)
            {
               this.mCamera.setTargetTo(_loc3_ + CAM_SPEED,_loc4_);
               _loc3_ = this.mCamera.getTargetX();
               _loc5_ = true;
            }
            if(this.mUpPressed)
            {
               this.mCamera.setTargetTo(_loc3_,_loc4_ - CAM_SPEED);
               _loc4_ = this.mCamera.getTargetY();
               _loc5_ = true;
            }
            if(this.mDownPressed)
            {
               this.mCamera.setTargetTo(_loc3_,_loc4_ + CAM_SPEED);
               _loc4_ = this.mCamera.getTargetY();
               _loc5_ = true;
            }
            if(!this.mAnyScrollKeyPressed && _loc5_)
            {
               this.mKeyScrollStartX = _loc1_;
               this.mKeyScrollStartY = _loc2_;
            }
            else if(this.mAnyScrollKeyPressed && !_loc5_)
            {
               _loc6_ = _loc1_ - this.mKeyScrollStartX;
               _loc7_ = _loc2_ - this.mKeyScrollStartY;
               _loc8_ = Math.abs(_loc6_) + Math.abs(_loc7_);
               MissionManager.increaseCounter("Scroll",null,_loc8_);
               if(this.mAllowMouseX >= 0)
               {
                  if(this.mAllowMouseY >= 0)
                  {
                     this.mRubberBandTimer = this.mGame.mMapData.mMapSetupData.CenterCamOnArrowDelay;
                  }
               }
            }
            this.mAnyScrollKeyPressed = _loc5_;
         }
      }
      
      public function update(param1:int) : void
      {
         FrameProfiler.begin("scene");
         this.updateScene(param1);
         FrameProfiler.end("scene");
      }
      
      private function updateScene(param1:int) : void
      {
         var _loc2_:int = 0;
         var _loc3_:GridCell = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:Point = null;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         var _loc10_:int = 0;
         if(PopUpManager.isModalPopupActive())
         {
            return;
         }
         _loc2_ = 25;
         var _loc11_:* = this.mSwitch % _loc2_ == _loc2_ - 1;
         if(FeatureTuner.USE_CAMERA_TRANSITION)
         {
            if(this.mAllowMouseX >= 0)
            {
               if(this.mAllowMouseY >= 0)
               {
                  if(this.mRubberBandTimer > 0)
                  {
                     this.mRubberBandTimer -= param1;
                     if(this.mRubberBandTimer < 0)
                     {
                        this.mCamera.setTargetTo(this.mGridDimX * this.mAllowMouseX,this.mGridDimY * this.mAllowMouseY);
                     }
                  }
               }
            }
         }
         EnvEffectManager.update(param1);
         this.mTimer += param1;
         this.updateKeyScrolling();
         this.updateCharacters(param1);
         this.updateStaticObjects(param1);
         this.updateHudObjects(param1);
         this.updatePatrols(param1);
         this.updateDebrisSpawn(param1);
         var _loc12_:GridCell = this.getTileUnderMouse();
         if(this.mGame.mState == GameState.STATE_PLAY || this.mGame.mState == GameState.STATE_PVP || this.mGame.mState == GameState.STATE_VISITING_NEIGHBOUR)
         {
            this.highlightDebris(_loc12_);
            this.highlightCell(_loc12_);
            this.highlightCharacter(_loc12_,param1);
            this.highlightEnemyInstallation(_loc12_,param1);
            this.highlightFriendlyInstallation(_loc12_,param1);
            if(_loc12_)
            {
               if(_loc12_.mPowerUp)
               {
                  if(!Config.MOBILE_MODE || Config.MOBILE_MODE && mouseDownAction)
                  {
                     this.showObjectTooltip(_loc12_.mPowerUp);
                     this.startToolTipTimer();
                  }
               }
            }
         }
         if(!Config.DISABLE_SORT)
         {
            FrameProfiler.begin("sort");
            this.sortAll(Boolean(_loc11_) || this.mMouseScrolling || Boolean(this.mObjectBeingMoved),_loc11_);
            FrameProfiler.end("sort");
         }
         if(_loc12_ != this.mPreviousCell)
         {
            this.mPreviousCell = _loc12_;
            if(this.mGame.mActivatedPlayerUnit)
            {
               _loc4_ = Math.floor(this.mGame.mActivatedPlayerUnit.mX / this.mGridDimX);
               _loc3_ = this.getTileUnderMouse();
               if(_loc3_)
               {
                  _loc5_ = _loc3_.mPosI;
                  if(_loc4_ < _loc5_)
                  {
                     this.mGame.mActivatedPlayerUnit.setAnimationDirection(AnimationController.DIR_RIGHT);
                  }
                  else if(_loc4_ > _loc5_)
                  {
                     this.mGame.mActivatedPlayerUnit.setAnimationDirection(AnimationController.DIR_LEFT);
                  }
               }
            }
            this.mSwitch = _loc2_ - 2;
         }
         switch(this.mGame.mState)
         {
            case GameState.STATE_PVP:
            case GameState.STATE_PLAY:
            case GameState.STATE_REPAIR_ITEM:
            case GameState.STATE_SELL_ITEM:
               break;
            case GameState.STATE_MOVE_ITEM:
            case GameState.STATE_PLACE_ITEM:
            case GameState.STATE_USE_INVENTORY_ITEM:
               if(this.mObjectBeingMoved)
               {
                  if(this.mGame.mHUD.mBlock)
                  {
                     this.mObjectBeingMoved.getContainer().visible = false;
                     break;
                  }
                  this.mObjectBeingMoved.getContainer().visible = true;
                  this.mPointTmp.x = 0;
                  this.mPointTmp.y = 0;
                  _loc6_ = this.mContainer.localToGlobal(this.mPointTmp);
                  _loc7_ = _loc6_.x;
                  _loc8_ = _loc6_.y;
                  _loc9_ = (this.mGame.mMouseX - _loc7_) / this.mContainer.scaleX;
                  _loc10_ = (this.mGame.mMouseY - _loc8_) / this.mContainer.scaleY;
                  ToScreen.inverseTransform(this.mPointTmp,_loc9_,_loc10_,0);
                  this.mPointTmp.x = this.mGridDimX * Math.floor(this.mPointTmp.x / this.mGridDimX) - 0.5 * (this.mObjectBeingMoved.getTileSize().x - 1) * this.mGridDimX;
                  this.mPointTmp.y = this.mGridDimY * Math.floor(this.mPointTmp.y / this.mGridDimY) - 0.5 * (this.mObjectBeingMoved.getTileSize().y - 1) * this.mGridDimY;
                  _loc3_ = this.getCellAtLocation(this.mPointTmp.x,this.mPointTmp.y);
                  if(_loc3_)
                  {
                     this.mObjectBeingMoved.setPos(this.getCenterPointXOfCell(_loc3_),this.getCenterPointYOfCell(_loc3_),0);
                  }
                  if(!this.mMovedObjectIndicator)
                  {
                     this.mMovedObjectIndicator = new Sprite();
                     this.mMapGUIEffectsLayer.mTopLayer.addChild(this.mMovedObjectIndicator);
                  }
               }
         }
         this.updateCursors(param1);
         this.updateCamera(param1);
         var _loc13_:Boolean = false;
         if(this.mFog.mUpdateRequired)
         {
            _loc13_ = true;
            this.mFog.recalculateFogEdges();
            this.mFog.mUpdateRequired = false;
         }
         if(this.mGame.mMapData.mUpdateRequired)
         {
            _loc13_ = true;
            this.mGame.mMapData.mUpdateRequired = false;
            this.mGame.mMapData.countFriendlyTiles();
            this.mTilemapGraphic.recalculateBorderEdges();
            MissionManager.increaseCounter("Control",null,1);
         }
         if(_loc13_)
         {
            FrameProfiler.begin("tilemap");
            this.mTilemapGraphic.updateTilemap();
            FrameProfiler.end("tilemap");
         }
         this.mEffectController.update(param1);
         if(this.mEffectPending)
         {
            this.mEffectPending = !this.mEffectController.startEffect(this,this.mEffectPendingMC,this.mEffectPendingType,this.mEffectPendingX,this.mEffectPendingY,this.mEffectPendingClipName);
         }
         this.mSwitch = ++this.mSwitch % _loc2_;
      }
      
      public function exitMoveMode(param1:Boolean = false) : void
      {
         if(this.mObjectBeingMoved)
         {
            if(!this.mGame.visitingFriend())
            {
               if(param1 || !this.isObjectInLegalPosition(this.mObjectBeingMoved))
               {
                  this.mObjectBeingMoved.setPos(this.mObjectBeingMovedStartX,this.mObjectBeingMovedStartY,0);
                  this.mObjectBeingMoved.getContainer().alpha = 1;
                  this.mObjectBeingMoved.getContainer().visible = true;
                  this.incrementViewersForPlacedObject();
               }
            }
         }
         this.cancelEditMode();
      }
      
      public function getTileUnderMouse() : GridCell
      {
         if(this.mGame.mHUD)
         {
            if(this.mGame.mHUD.mBlock)
            {
               return null;
            }
         }
         if(NeighborAvatar.smMouseOver)
         {
            return null;
         }
         this.mPointTmp.x = 0;
         this.mPointTmp.y = 0;
         var _loc1_:Point = this.mContainer.localToGlobal(this.mPointTmp);
         var _loc2_:int = _loc1_.x;
         var _loc3_:int = _loc1_.y;
         var _loc4_:int = (this.mGame.mMouseX - _loc2_) / this.mContainer.scaleX;
         var _loc5_:int = (this.mGame.mMouseY - _loc3_) / this.mContainer.scaleY;
         ToScreen.inverseTransform(this.mPointTmp,_loc4_,_loc5_,0);
         this.mPointTmp.x = this.mGridDimX * Math.floor(this.mPointTmp.x / this.mGridDimX);
         this.mPointTmp.y = this.mGridDimY * Math.floor(this.mPointTmp.y / this.mGridDimY);
         this.mMouseLocalX = _loc4_;
         this.mMouseLocalY = _loc5_;
         return this.getCellAtLocation(this.mPointTmp.x,this.mPointTmp.y);
      }
      
      public function active() : Boolean
      {
         return this.mSceneActive;
      }
      
      public function updateCamera(param1:Number) : void
      {
         var _loc2_:Renderable = null;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:int = this.mContainer.scaleX * -this.mCamera.getCameraX() + this.mGame.getStageWidth() / 2;
         var _loc6_:int = this.mContainer.scaleY * -this.mCamera.getCameraY() + this.mGame.getStageHeight() / 2;
         if(this.mContainer.x != _loc5_)
         {
            _loc3_ = int(this.mSoundMakers.length);
            _loc4_ = 0;
            while(_loc4_ < _loc3_)
            {
               _loc2_ = this.mSoundMakers[_loc4_] as Renderable;
               if(_loc2_)
               {
                  _loc2_.updateSoundtransform();
               }
               _loc4_++;
            }
         }
         if(this.mContainer.x != _loc5_ || this.mContainer.y != _loc6_)
         {
            this.mContainer.x = _loc5_;
            this.mContainer.y = _loc6_;
            this.mSceneHud.x = _loc5_;
            this.mSceneHud.y = _loc6_;
            FrameProfiler.begin("tilemap");
            this.mTilemapGraphic.updateTilemap(true);
            FrameProfiler.end("tilemap");
         }
      }
      
      public function areaDamage(param1:Number, param2:Number, param3:int, param4:Number) : void
      {
         this.areaDamageImpl(Math.floor(param1 / this.mGridDimX),Math.floor(param2 / this.mGridDimY),param3,param4);
      }
      
      private function areaDamageImpl(param1:int, param2:int, param3:int, param4:Number) : void
      {
         var _loc5_:int = 0;
         var _loc6_:GridCell = null;
         var _loc7_:Number = NaN;
         var _loc8_:Number = NaN;
         var _loc9_:int = param1 - param3;
         while(_loc9_ <= param1 + param3)
         {
            _loc5_ = param2 - param3;
            while(_loc5_ <= param2 + param3)
            {
               _loc6_ = this.getCellAt(_loc9_,_loc5_);
               if(_loc6_ != null)
               {
                  _loc7_ = Math.abs(param1 - _loc9_) + Math.abs(param2 - _loc5_);
                  _loc8_ = _loc7_ == 0 ? param4 : param4 / _loc7_;
                  if(_loc6_.mCharacter)
                  {
                     _loc6_.mCharacter.reduceHealth(Math.floor(_loc8_),IsometricCharacter.HIT_BY_EXPLOSION);
                  }
               }
               _loc5_++;
            }
            _loc9_++;
         }
      }
      
      // Display container of the floor hit area; the GPU renderer forwards
      // world mouse input to it.
      public function getFloorContainer() : Sprite
      {
         return this.mFloor ? this.mFloor.getContainer() : null;
      }
      
      public function addFloorToScene() : void
      {
         this.mContainer.addChild(this.mFloor.getContainer());
         this.initializeFloorHitArea();
         this.mFloor.addListenerObjectMouseReleased(this.FloorClicked);
         this.mContainer.addChild(this.mMapGUIEffectsLayer.mGroundLayer);
         this.mContainer.addChild(this.mMapGUIEffectsLayer.mTopLayer);
         this.mSceneHud.mouseEnabled = false;
      }
      
      private function initializeFloorHitArea() : void
      {
         var _loc1_:Sprite = new Sprite();
         _loc1_.mouseEnabled = false;
         _loc1_.mouseChildren = false;
         _loc1_.graphics.lineStyle(4,11184810);
         ToScreen.transform(this.mPointTmp,0,0,0);
         _loc1_.graphics.moveTo(this.mPointTmp.x,this.mPointTmp.y);
         _loc1_.graphics.beginFill(0,0);
         var _loc2_:Number = this.mPointTmp.x;
         var _loc3_:Number = this.mPointTmp.y;
         ToScreen.transform(this.mPointTmp,this.mSizeX * this.mGridDimX,0,0);
         _loc1_.graphics.lineTo(this.mPointTmp.x,this.mPointTmp.y);
         ToScreen.transform(this.mPointTmp,this.mSizeX * this.mGridDimX,this.mSizeY * this.mGridDimY,0);
         _loc1_.graphics.lineTo(this.mPointTmp.x,this.mPointTmp.y);
         ToScreen.transform(this.mPointTmp,0 * this.mGridDimX,this.mSizeY * this.mGridDimY,0);
         _loc1_.graphics.lineTo(this.mPointTmp.x,this.mPointTmp.y);
         _loc1_.graphics.lineTo(_loc2_,_loc3_);
         _loc1_.graphics.endFill();
         this.mFloor.addSprite(_loc1_);
      }
      
      private function isObjectFrontOf(param1:Renderable, param2:Renderable) : Boolean
      {
         return param1.mY > param2.mY;
      }
      
      private function clampY(param1:int) : int
      {
         if(param1 >= this.mSizeY)
         {
            return this.mSizeY - 1;
         }
         if(param1 < 0)
         {
            return 0;
         }
         return param1;
      }
      
      private function clampX(param1:int) : int
      {
         if(param1 >= this.mSizeX)
         {
            return this.mSizeX - 1;
         }
         if(param1 < 0)
         {
            return 0;
         }
         return param1;
      }
      
      public function getTileRectSize(param1:Renderable) : int
      {
         var _loc2_:int = param1.getContainer().height / this.mGridDimY;
         var _loc3_:int = param1.getTileSize().x;
         var _loc4_:int = param1.getTileSize().y;
         return Math.max(_loc2_,_loc3_,_loc4_);
      }
      
      public function getHeightDebug(param1:Renderable) : int
      {
         return param1.getContainer().height;
      }
      
      private function nothingBehind_Fast(param1:Array, param2:Renderable) : Boolean
      {
         var _loc10_:Array = null;
         var _loc3_:Renderable = null;
         var _loc4_:int = Math.floor(param2.mX / this.mGridDimX);
         var _loc5_:int = Math.floor(param2.mY / this.mGridDimY);
         var _loc6_:int = _loc4_ - 1;
         var _loc7_:int = _loc4_ + param2.getTileSize().x + 1;
         var _loc8_:int = _loc5_ + 1;
         var _loc9_:int = _loc5_ - 1;
         _loc6_ = this.clampX(_loc6_);
         _loc7_ = this.clampX(_loc7_);
         _loc9_ = this.clampY(_loc9_);
         _loc8_ = this.clampY(_loc8_);
         var _loc11_:int = int((_loc10_ = this.getObjectsFromTiles(_loc6_,_loc7_,_loc9_,_loc8_)).length);
         var _loc12_:int = 0;
         while(_loc12_ < _loc11_)
         {
            _loc3_ = _loc10_[_loc12_] as Renderable;
            if(!(_loc3_ == param2 || _loc3_.mSorted || !_loc3_.mVisible || _loc3_.getTileSize().z == 0 || param1.indexOf(_loc3_) == -1))
            {
               if(this.isObjectFrontOf(param2,_loc3_))
               {
                  return false;
               }
            }
            _loc12_++;
         }
         return true;
      }
      
      private function nothingBehind_Slow(param1:Array, param2:Renderable) : Boolean
      {
         var _loc3_:Renderable = null;
         var _loc4_:int = int(param1.length);
         var _loc5_:int = 0;
         while(_loc5_ < _loc4_)
         {
            _loc3_ = param1[_loc5_] as Renderable;
            if(_loc3_ != param2)
            {
               if(this.isObjectFrontOf(param2,_loc3_))
               {
                  return false;
               }
            }
            _loc5_++;
         }
         return true;
      }
      
      private function sortAll(param1:Boolean = true, param2:Boolean = true) : void
      {
         var _loc3_:* = false;
         var _loc4_:Sprite = null;
         var _loc5_:Boolean = false;
         var _loc6_:Boolean = false;
         var _loc7_:DisplayObjectContainer = null;
         var _loc8_:int = 0;
         var _loc9_:Renderable = null;
         var _loc10_:int = 0;
         var _loc11_:int = 0;
         if(param1)
         {
            this.mRelativeVisibleArea.x = this.mCamera.getCameraX();
            this.mRelativeVisibleArea.y = this.mCamera.getCameraY();
            _loc5_ = false;
            _loc6_ = false;
            _loc10_ = 0;
            while(_loc10_ < this.mAllElements.length)
            {
               _loc9_ = this.mAllElements[_loc10_];
               _loc4_ = _loc9_.getContainer();
               _loc7_ = _loc4_.parent;
               if(_loc7_)
               {
                  _loc6_ = _loc4_.hitTestObject(this.mAbsoluteVisibleArea);
               }
               else
               {
                  _loc6_ = _loc4_.hitTestObject(this.mRelativeVisibleArea);
               }
               if(_loc9_ is Renderable)
               {
                  _loc6_ &&= this.isInsideVisibleArea(_loc9_.getCell());
               }
               _loc3_ = _loc9_.getTileSize().z == 0;
               _loc8_ = int(this.mVisibleObjects.indexOf(_loc9_));
               if(!_loc4_.visible)
               {
                  if(_loc7_)
                  {
                     _loc7_.removeChild(_loc4_);
                  }
                  if(_loc8_ != -1)
                  {
                     this.mVisibleObjects.splice(_loc8_,1);
                     _loc5_ = true;
                  }
               }
               else if(_loc3_)
               {
                  if(!_loc7_)
                  {
                     this.mContainer.addChildAt(_loc4_,0);
                  }
               }
               else if(_loc8_ == -1)
               {
                  this.mVisibleObjects.push(_loc9_);
                  _loc5_ = true;
               }
               _loc10_++;
            }
            this.mVisibleObjectCnt = this.mVisibleObjects.length;
         }
         if(param2)
         {
            _loc5_ ||= this.armySortObjects(this.mVisibleObjects);
         }
         if(_loc5_)
         {
            this.mContainer.addChildAt(this.mMapGUIEffectsLayer.mGroundLayer,this.mContainer.numChildren);
            _loc11_ = 0;
            while(_loc11_ < this.mVisibleObjects.length)
            {
               this.mContainer.addChildAt((this.mVisibleObjects[_loc11_] as Renderable).getContainer(),this.mContainer.numChildren);
               _loc11_++;
            }
            this.mContainer.addChildAt(this.mMapGUIEffectsLayer.mTopLayer,this.mContainer.numChildren);
            if(FeatureTuner.USE_SEA_WAVES_EFFECT)
            {
               this.mContainer.addChildAt(this.mTilemapGraphic.mWaveContainer,this.mContainer.numChildren);
            }
         }
      }
      
      public function setScale(param1:Number) : void
      {
         var _loc2_:Renderable = null;
         var _loc3_:int = int(this.mAllElements.length);
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_)
         {
            _loc2_ = this.mAllElements[_loc4_] as Renderable;
            if(_loc2_)
            {
               _loc2_.reactToZoom(param1);
            }
            _loc4_++;
         }
         this.mContainer.scaleX = param1;
         this.mContainer.scaleY = param1;
         this.mSceneHud.scaleX = param1;
         this.mSceneHud.scaleY = param1;
         this.reCalculateCameraMargins();
         this.mRelativeVisibleArea.graphics.clear();
         this.mRelativeVisibleArea.graphics.drawRect(-this.mGame.getStageWidth() / this.mContainer.scaleX / 2,-this.mGame.getStageHeight() / this.mContainer.scaleX / 2,this.mGame.getStageWidth() / this.mContainer.scaleX,this.mGame.getStageHeight() / this.mContainer.scaleX);
         this.mTilemapGraphic.createBitmaps();
         this.mTilemapGraphic.updateTilemap();
         if(!Config.DISABLE_SORT)
         {
            this.sortAll();
         }
      }
      
      private function sortStatic() : void
      {
         var _loc1_:Element = null;
         var _loc2_:Array = new Array();
         var _loc3_:int = int(this.mAllElements.length);
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_)
         {
            _loc1_ = this.mAllElements[_loc4_] as Element;
            if(_loc1_.mEnabled)
            {
               if(_loc1_.getContainer() != null)
               {
                  _loc2_.push(_loc1_);
               }
            }
            _loc4_++;
         }
         if(this.mFloor.mEnabled)
         {
            if(this.mFloor.getContainer() != null)
            {
               _loc2_.push(this.mFloor);
            }
         }
         _loc2_ = this.sortObjects(_loc2_);
      }
      
      private function sortObjectsOld(param1:Array) : void
      {
         var _loc2_:Renderable = null;
         param1.sortOn("mY",Array.NUMERIC);
         var _loc3_:int = int(param1.length);
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_)
         {
            _loc2_ = param1[_loc4_] as Renderable;
            this.mContainer.addChild(_loc2_.getContainer());
            _loc4_++;
         }
      }
      
      private function ySort(param1:Renderable, param2:Renderable) : int
      {
         if(param1.mY < param2.mY)
         {
            return -1;
         }
         if(param1.mY > param2.mY)
         {
            return 1;
         }
         return 0;
      }
      
      private function armySortObjects(param1:Array) : Boolean
      {
         var _loc2_:Renderable = null;
         var _loc3_:Renderable = null;
         var _loc4_:Renderable = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:Boolean = false;
         var _loc8_:int = 0;
         while(_loc8_ < param1.length)
         {
            _loc4_ = param1[_loc8_];
            _loc4_.mSortIdx = _loc8_;
            _loc8_++;
         }
         param1.sort(this.ySort);
         var _loc9_:int = 0;
         while(_loc9_ < param1.length)
         {
            _loc4_ = param1[_loc9_];
            if(!_loc4_.mScene)
            {
               param1.splice(_loc9_,1);
               _loc7_ = true;
               _loc9_--;
            }
            else
            {
               _loc3_ = _loc4_.getCell().mObject;
               if((_loc4_ is PlayerUnit || _loc4_ is EnemyUnit || _loc4_ == this.mObjectBeingMoved) && Boolean(_loc3_))
               {
                  _loc5_ = int(param1.indexOf(_loc3_));
                  _loc6_ = int(param1.indexOf(_loc4_));
                  if(_loc5_ > _loc6_)
                  {
                     if(_loc6_ > -1)
                     {
                        param1.splice(_loc5_,1,_loc4_);
                        param1.splice(_loc6_,1,_loc3_);
                        _loc7_ = true;
                     }
                  }
               }
               if(_loc4_.mSortIdx != _loc8_)
               {
                  _loc7_ = true;
               }
            }
            _loc9_++;
         }
         return _loc7_;
      }
      
      private function sortObjects(param1:Array) : Array
      {
         var _loc2_:Renderable = null;
         var _loc3_:Renderable = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:Renderable = null;
         var _loc7_:Renderable = null;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         var _loc10_:Array = new Array();
         param1.sortOn("mY",Array.NUMERIC);
         var _loc11_:int = int(this.mAllElements.length);
         var _loc12_:int = 0;
         while(_loc12_ < _loc11_)
         {
            _loc3_ = this.mAllElements[_loc12_] as Renderable;
            _loc3_.mSorted = false;
            _loc12_++;
         }
         var _loc13_:int = 0;
         this.mSortingOrderChanged = false;
         while(param1.length > 0)
         {
            _loc4_ = int(param1.length);
            _loc5_ = 0;
            while(_loc5_ < param1.length)
            {
               _loc6_ = param1[_loc5_];
               if(this.nothingBehind_Fast(param1,_loc6_))
               {
                  if(_loc6_.mSortIdx != _loc10_.length)
                  {
                     this.mSortingOrderChanged = true;
                  }
                  _loc6_.mSortIdx = _loc10_.length;
                  _loc6_.mSorted = true;
                  _loc10_.push(_loc6_);
                  param1.splice(_loc5_,1);
                  _loc13_ += _loc5_;
                  break;
               }
               _loc5_++;
            }
            if(_loc4_ == param1.length)
            {
               if(Config.DEBUG_MODE)
               {
                  _loc8_ = int(param1.length);
                  _loc9_ = 0;
                  while(_loc9_ < _loc8_)
                  {
                     _loc7_ = param1[_loc9_] as Renderable;
                     _loc9_++;
                  }
               }
               return _loc10_;
            }
         }
         return _loc10_;
      }
      
      public function removeObject(param1:Element, param2:Boolean = true, param3:Boolean = true) : void
      {
         var _loc6_:int = 0;
         var _loc7_:DynamicObject = null;
         var _loc8_:DisplayContainer = null;
         var _loc4_:GridCell = null;
         if(!param1)
         {
            return;
         }
         var _loc5_:Renderable = param1 as Renderable;
         if(Config.DEBUG_MODE)
         {
         }
         _loc6_ = int(this.mAllElements.indexOf(param1));
         if(_loc6_ >= 0)
         {
            this.mAllElements.splice(_loc6_,1);
         }
         _loc6_ = int(this.mVisibleObjects.indexOf(param1));
         if(_loc6_ >= 0)
         {
            this.mVisibleObjects.splice(_loc6_,1);
         }
         if(_loc5_ != this.mObjectBeingMoved)
         {
            if(param3)
            {
               if(param1 is PlayerBuildingObject)
               {
                  this.decrementViewersForBuilding(PlayerBuildingObject(param1),PlayerBuildingObject(param1).getSightRangeAccordingToCondition());
               }
               else if(param1 is PlayerInstallationObject)
               {
                  this.decrementViewersForInstallation(PlayerInstallationObject(param1),PlayerInstallationObject(param1).getSightRangeAccordingToCondition());
               }
               else if(param1 is PlayerUnit)
               {
                  this.mFog.decrementUnitSightArea(PlayerUnit(param1));
               }
            }
         }
         _loc7_ = _loc5_ as DynamicObject;
         if(_loc7_)
         {
            _loc7_.removeFromGrid();
         }
         _loc8_ = param1.getContainer();
         if(_loc8_ != null)
         {
            if(_loc8_.parent)
            {
               _loc8_.parent.removeChild(_loc8_);
            }
         }
         param1.destroy();
         if(param2)
         {
            this.updateGridInformation();
            this.updateGridCharacterInfo();
            this.updateCursors(0,true);
            if(this.mGame.mState == GameState.STATE_SELL_ITEM)
            {
               this.mMapGUIEffectsLayer.highlightSellableObjects();
            }
            this.mGame.mMapData.mUpdateRequired = true;
         }
         if(_loc5_)
         {
            if(_loc5_.mKilledByFireMission)
            {
               for each(_loc4_ in this.getTilesUnderObject(_loc5_))
               {
                  this.mGame.spawnNewDebris("ScorchedGround","Debris",this.getCenterPointXOfCell(_loc4_),this.getCenterPointYOfCell(_loc4_));
               }
            }
            if(_loc5_ is SpawningBeaconObject)
            {
               this.findSpawningBeacon();
               this.resetSpawningBeaconTimer();
            }
         }
      }
      
      public function setSelectedObject(param1:Renderable) : void
      {
         this.mObjectBeingMoved = param1;
         this.mMapGUIEffectsLayer.highlightPlacingArea();
      }
      
      public function addIntel(param1:int, param2:int) : void
      {
         var _loc3_:int = this.getCenterPointXAtIJ(param1,param2);
         var _loc4_:int = this.getCenterPointYAtIJ(param1,param2);
         var _loc5_:Rectangle = new Rectangle(_loc3_,_loc4_,1,1);
         var _loc6_:Item = ItemManager.getItem("Intel1","Intel");
         var _loc7_:LootReward = new LootReward(_loc6_,1,_loc5_);
         this.mSceneHud.addChild(_loc7_);
      }
      
      public function addLootReward(param1:Item, param2:int, param3:DisplayObject) : void
      {
         var _loc4_:int = 0;
         var _loc5_:LootReward = null;
         if(param1 != null)
         {
            _loc4_ = 50;
            if(param1.mId == "Energy" || param1.mId == "SocialXP")
            {
               _loc4_ = 5;
            }
            else if(param1.mId == "XP")
            {
               _loc4_ = 2;
            }
            else if(param1.mId == "Water")
            {
               _loc4_ = 10;
            }
            if(param2 > 0)
            {
               while(param2 > 0)
               {
                  _loc5_ = new LootReward(param1,Math.min(_loc4_,param2),param3.getBounds(this.mContainer));
                  this.mSceneHud.addChild(_loc5_);
                  param2 -= _loc4_;
               }
            }
            else if(param2 < 0)
            {
               _loc5_ = new LootReward(param1,param2,param3.getBounds(this.mContainer));
               this.mSceneHud.addChild(_loc5_);
            }
         }
      }
      
      public function addNeighborAvatar(param1:NeighborActionQueue) : void
      {
         var _loc2_:NeighborAvatar = new NeighborAvatar(param1);
         if(!this.mNeighborAvatars)
         {
            this.mNeighborAvatars = new Array();
         }
         this.mNeighborAvatars.push(_loc2_);
         this.mSceneHud.addChild(_loc2_);
      }
      
      public function removeLootAndGetRewards() : void
      {
         var _loc1_:DisplayObject = null;
         var _loc2_:LootReward = null;
         var _loc3_:int = 0;
         while(_loc3_ < this.mSceneHud.numChildren)
         {
            _loc1_ = this.mSceneHud.getChildAt(_loc3_);
            if(_loc1_ is LootReward)
            {
               _loc2_ = _loc1_ as LootReward;
               if(!_loc2_.mRewardGiven)
               {
                  _loc2_.getRewardFromLoot();
               }
               this.mSceneHud.removeChild(_loc2_);
               if(_loc2_.isIntel())
               {
                  MissionManager.increaseCounter("CollectIntel",_loc2_,1);
               }
               if(Config.DEBUG_MODE)
               {
               }
            }
            _loc3_++;
         }
      }
      
      private function updateHudObjects(param1:int) : void
      {
         var _loc2_:DisplayObject = null;
         var _loc3_:LootReward = null;
         var _loc4_:NeighborAvatar = null;
         var _loc5_:int = 0;
         var _loc6_:DisplayObject = null;
         var _loc7_:int = 0;
         while(_loc7_ < this.mSceneHud.numChildren)
         {
            _loc2_ = this.mSceneHud.getChildAt(_loc7_);
            if(_loc2_ is LootReward)
            {
               _loc3_ = _loc2_ as LootReward;
               _loc3_.Update(param1);
               if(_loc3_.canGiveReward())
               {
                  _loc3_.getRewardFromLoot();
               }
               if(_loc3_.canBeRemoved())
               {
                  _loc6_ = _loc2_;
                  if(_loc3_.isIntel())
                  {
                     MissionManager.increaseCounter("CollectIntel",_loc3_,1);
                  }
               }
            }
            else if(_loc2_ is NeighborAvatar)
            {
               _loc4_ = _loc2_ as NeighborAvatar;
               _loc4_.update(param1);
               if(_loc4_.canBeRemoved())
               {
                  _loc6_ = _loc2_;
                  _loc5_ = int(this.mNeighborAvatars.indexOf(_loc4_));
                  if(_loc5_ >= 0)
                  {
                     this.mNeighborAvatars.splice(_loc5_,1);
                  }
               }
            }
            _loc7_++;
         }
         if(_loc6_ != null)
         {
            this.mSceneHud.removeChild(_loc6_);
            if(Config.DEBUG_MODE)
            {
            }
         }
      }
      
      public function getUncollectedSupplies() : int
      {
         var _loc1_:DisplayObject = null;
         var _loc2_:LootReward = null;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         while(_loc4_ < this.mSceneHud.numChildren)
         {
            _loc1_ = this.mSceneHud.getChildAt(_loc4_);
            if(_loc1_ is LootReward)
            {
               _loc2_ = _loc1_ as LootReward;
               _loc3_ += _loc2_.getSupplies();
            }
            _loc4_++;
         }
         return _loc3_;
      }
      
      public function getUncollectedWater() : int
      {
         var _loc1_:DisplayObject = null;
         var _loc2_:LootReward = null;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         while(_loc4_ < this.mSceneHud.numChildren)
         {
            _loc1_ = this.mSceneHud.getChildAt(_loc4_);
            if(_loc1_ is LootReward)
            {
               _loc2_ = _loc1_ as LootReward;
               _loc3_ += _loc2_.getWater();
            }
            _loc4_++;
         }
         return _loc3_;
      }
      
      private function isLootRewardActivated() : Boolean
      {
         var _loc1_:DisplayObject = null;
         var _loc2_:int = 0;
         _loc1_ = null;
         _loc2_ = 0;
         while(_loc2_ < this.mSceneHud.numChildren)
         {
            _loc1_ = this.mSceneHud.getChildAt(_loc2_);
            if(_loc1_ is LootReward && (_loc1_ as LootReward).isActivated())
            {
               return true;
            }
            _loc2_++;
         }
         return false;
      }
      
      public function setTutorialHighlight(param1:int, param2:int, param3:int, param4:int = 0, param5:int = 0) : void
      {
         var _loc7_:MovieClip = null;
         var _loc8_:Number = NaN;
         var _loc9_:Number = NaN;
         var _loc6_:Class = null;
         _loc7_ = null;
         _loc8_ = this.getCenterPointXAtIJ(param2,param3);
         _loc9_ = this.getCenterPointYAtIJ(param2,param3);
         if(param1 == TUTORIAL_HIGHLIGHT_CIRCLE)
         {
            _loc6_ = DCResourceManager.getInstance().getSWFClass(Config.SWF_INTERFACE_NAME,"tutorial_circle_01");
         }
         else if(param1 == TUTORIAL_HIGHLIGHT_TARGET)
         {
            _loc6_ = DCResourceManager.getInstance().getSWFClass(Config.SWF_INTERFACE_NAME,"tutorial_target_01");
         }
         else
         {
            _loc6_ = DCResourceManager.getInstance().getSWFClass(Config.SWF_INTERFACE_NAME,"tutorial_mark_01");
         }
         this.mTutorialHighlight = new _loc6_();
         this.mTutorialHighlight.x = _loc8_;
         this.mTutorialHighlight.y = _loc9_;
         this.mTutorialHighlight.mouseEnabled = false;
         if(param1 == TUTORIAL_HIGHLIGHT_MOVE)
         {
            _loc6_ = DCResourceManager.getInstance().getSWFClass(Config.SWF_INTERFACE_NAME,"tutorial_circle_01");
            _loc7_ = new _loc6_();
            _loc7_.gotoAndStop(_loc7_.totalFrames);
            _loc7_.x = this.mGridDimX;
            _loc7_.y = this.mGridDimY * 2;
            this.mTutorialHighlight.addChild(_loc7_);
         }
         this.mSceneHud.addChild(this.mTutorialHighlight);
      }
      
      public function removeTutorialHighlight() : void
      {
         if(this.mTutorialHighlight)
         {
            this.mSceneHud.removeChild(this.mTutorialHighlight);
            this.mTutorialHighlight = null;
         }
      }
      
      public function disableMouse(param1:int, param2:int, param3:Boolean = false) : void
      {
         this.mMouseDisabled = true;
         this.mAllowMouseX = param1;
         this.mAllowMouseY = param2;
      }
      
      public function enableMouse() : void
      {
         this.mMouseDisabled = false;
         this.mAllowMouseX = -1;
         this.mAllowMouseY = -1;
      }
      
      public function initializeAfterLoading() : void
      {
         this.addFloorToScene();
         if(!Config.DISABLE_SORT)
         {
            this.sortStatic();
         }
         if(!this.mRelativeVisibleArea)
         {
            this.mAbsoluteVisibleArea = new Shape();
            this.mAbsoluteVisibleArea.graphics.clear();
            this.mAbsoluteVisibleArea.graphics.drawRect(0,0,this.mGame.getStageWidth(),this.mGame.getStageHeight());
            this.mRelativeVisibleArea = new Shape();
            this.mRelativeVisibleArea.graphics.clear();
            this.mRelativeVisibleArea.graphics.drawRect(-this.mGame.getStageWidth() / this.mContainer.scaleX / 2,-this.mGame.getStageHeight() / this.mContainer.scaleX / 2,this.mGame.getStageWidth() / this.mContainer.scaleX,this.mGame.getStageHeight() / this.mContainer.scaleX);
         }
      }
      
      public function calculateWalkManhattanDist(param1:IsometricCharacter, param2:Number, param3:Number) : int
      {
         var _loc4_:GridCell = null;
         var _loc5_:int = 0;
         _loc4_ = this.getCellAtLocation(param2,param3);
         if(_loc4_ == null)
         {
            return 100000;
         }
         if(!_loc4_.mWalkable || _loc4_.mCharacter != null)
         {
            return 100000;
         }
         AStarPathfinder.findPathAStar(smTmpSolution,this,new Point(param1.mX,param1.mY),new Point(param2,param3),param1.mMovementFlags);
         if(smTmpSolution.length == 0)
         {
            return 100000;
         }
         _loc5_ = Math.abs(param1.mX - param2) / this.mGridDimX + Math.abs(param1.mY - param3) / this.mGridDimY;
         return Math.max(0.5 * smTmpSolution.length,_loc5_);
      }
      
      public function calculateWalkEuclidianDist(param1:IsometricCharacter, param2:Number, param3:Number) : int
      {
         var _loc4_:Number = NaN;
         var _loc5_:Number = NaN;
         var _loc6_:GridCell = null;
         var _loc7_:Number = NaN;
         var _loc8_:Number = NaN;
         var _loc9_:Number = NaN;
         var _loc10_:int = 0;
         _loc4_ = NaN;
         _loc5_ = NaN;
         _loc6_ = this.getCellAtLocation(param2,param3);
         if(_loc6_ == null)
         {
            return 100000;
         }
         if(!_loc6_.mWalkable || _loc6_.mCharacter != null)
         {
            return 100000;
         }
         AStarPathfinder.findPathAStar(smTmpSolution,this,new Point(param1.mX,param1.mY),new Point(param2,param3),param1.mMovementFlags);
         if(smTmpSolution.length == 0)
         {
            return 100000;
         }
         _loc7_ = param1.mX;
         _loc8_ = param1.mY;
         _loc9_ = 0;
         _loc10_ = int(smTmpSolution.length - 1);
         while(_loc10_ >= 0)
         {
            _loc4_ = Number(smTmpSolution[_loc10_ - 1]);
            _loc5_ = Number(smTmpSolution[_loc10_]);
            _loc9_ += Math.sqrt((_loc4_ - _loc7_) * (_loc4_ - _loc7_) + (_loc5_ - _loc8_) * (_loc5_ - _loc8_));
            _loc7_ = _loc4_;
            _loc8_ = _loc5_;
            _loc10_ -= 2;
         }
         return _loc9_;
      }
      
      public function fireActive(param1:MouseEvent) : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:GridCell = null;
         _loc2_ = 0;
         _loc3_ = 0;
         _loc4_ = null;
         _loc2_ = this.mGridDimX * this.mFireItemX;
         _loc3_ = this.mGridDimY * this.mFireItemY;
         _loc4_ = this.getCellAtLocation(_loc2_,_loc3_);
         this.mGame.useFireMission(_loc4_,this.mFireItemX,this.mFireItemY,this.mGame.mFireMisssionToBePlaced);
         this.mPlacePressed = false;
      }
      
      public function FloorClicked(param1:MouseEvent) : void
      {
         var _loc2_:PlayerUnit = null;
         var _loc3_:Element = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:PlayerUnit = null;
         var _loc7_:Array = null;
         var _loc8_:EnemyUnit = null;
         var _loc9_:PvPEnemyUnit = null;
         var _loc11_:int = 0;
         var _loc12_:Point = null;
         var _loc13_:int = 0;
         var _loc14_:int = 0;
         var _loc15_:GridCell = null;
         _loc2_ = null;
         _loc3_ = null;
         _loc4_ = 0;
         _loc5_ = 0;
         _loc6_ = null;
         _loc7_ = null;
         _loc8_ = null;
         _loc9_ = null;
         var _loc10_:Boolean = false;
         if(this.mMouseScrolling || this.mAnyScrollKeyPressed || this.mTickCrossActive)
         {
            return;
         }
         if(Config.DEBUG_MODE)
         {
         }
         _loc11_ = this.mGame.mState;
         this.mPointTmp.x = 0;
         this.mPointTmp.y = 0;
         _loc12_ = this.mContainer.localToGlobal(this.mPointTmp);
         _loc13_ = _loc12_.x;
         _loc14_ = _loc12_.y;
         ToScreen.inverseTransform(this.mPointTmp,(param1.stageX - _loc13_) / this.mContainer.scaleX,(param1.stageY - _loc14_) / this.mContainer.scaleY,0);
         _loc15_ = this.getCellAtLocation(this.mPointTmp.x,this.mPointTmp.y);
         this.mPreviousCursorCell = null;
         if(!this.isInsideVisibleArea(_loc15_) || this.mMouseDisabled && (this.mAllowMouseX != _loc15_.mPosI || this.mAllowMouseY != _loc15_.mPosJ))
         {
            ArmySoundManager.getInstance().playSound(ArmySoundManager.SFX_UI_ERROR);
            return;
         }
         param1.updateAfterEvent();
         switch(_loc11_)
         {
            case GameState.STATE_PVP:
            case GameState.STATE_PLAY:
               _loc2_ = this.mGame.mActivatedPlayerUnit;
               _loc4_ = int(this.mAllElements.length);
               _loc5_ = 0;
               while(_loc5_ < _loc4_)
               {
                  _loc3_ = this.mAllElements[_loc5_] as Element;
                  if(_loc3_ is PlayerUnit)
                  {
                     _loc6_ = _loc3_ as PlayerUnit;
                     if(_loc15_ == _loc6_.getCell() && !(this.mGame.mCurrentAction is WalkingAction) && (this.mGame.mState != GameState.STATE_PVP || FeatureTuner.USE_PVP_MATCH && this.mGame.mPvPMatch.mPlayerTurn))
                     {
                        if(_loc6_.isAlive())
                        {
                           if(FeatureTuner.USE_PVP_MATCH && this.mGame.mPvPMatch.mActivatedBooster && this.mGame.mState == GameState.STATE_PVP)
                           {
                              _loc6_.useBooster(this.mGame.mPvPMatch.mActivatedBooster);
                              this.mGame.mPlayerProfile.mInventory.addItems(this.mGame.mPvPMatch.mActivatedBooster,-1);
                              this.mGame.mPvPMatch.mActivatedBooster = null;
                              this.mGame.mPvPHUD.mBoosterBar.addToScreen();
                           }
                           else
                           {
                              this.mGame.unActivatePlayerUnit();
                              this.mGame.activatePlayerUnit(_loc6_);
                              _loc7_ = new Array(_loc15_.mPosI,_loc15_.mPosJ);
                              MissionManager.increaseCounter("Select",_loc7_,1);
                           }
                           break;
                        }
                        if(MissionManager.isTutorialCompleted())
                        {
                           this.mGame.mHUD.openCorpseMarkerTextBox(_loc6_);
                        }
                     }
                  }
                  else
                  {
                     if(_loc3_ is EnemyUnit)
                     {
                        _loc8_ = _loc3_ as EnemyUnit;
                        if(_loc8_.isAlive())
                        {
                           if(_loc15_ == _loc8_.getCell())
                           {
                              if(!_loc15_.hasFog())
                              {
                                 if(_loc8_.mState != IsometricCharacter.STATE_AIR_DROP)
                                 {
                                    if(this.isInsideVisibleArea(_loc15_))
                                    {
                                       if(!(this.mGame.mCurrentAction is WalkingAction))
                                       {
                                          if(GameState.smCheatCodeTyped && this.mGame.mCtrlPressed)
                                          {
                                             _loc8_.changeReactionState(EnemyUnit.REACT_STATE_BYPASS_THE_LINE);
                                          }
                                          else
                                          {
                                             this.mGame.attackEnemy(_loc8_);
                                             this.mGame.moveCameraToSeeRenderable(_loc8_);
                                          }
                                          break;
                                       }
                                    }
                                 }
                              }
                           }
                        }
                     }
                     if(FeatureTuner.USE_PVP_MATCH && _loc3_ is PvPEnemyUnit)
                     {
                        _loc9_ = _loc3_ as PvPEnemyUnit;
                        if(_loc9_.isAlive())
                        {
                           if(_loc15_ == _loc9_.getCell())
                           {
                              if(!(this.mGame.mCurrentAction is WalkingAction))
                              {
                                 if(this.mGame.mPvPMatch.mPlayerTurn)
                                 {
                                    this.mGame.attackEnemy(_loc9_);
                                    this.mGame.moveCameraToSeeRenderable(_loc9_);
                                    break;
                                 }
                              }
                           }
                        }
                     }
                  }
                  _loc5_++;
               }
               if(_loc15_.mObject && !_loc15_.mCharacter && !(_loc15_.mObject is DebrisObject && _loc15_.mOwner == MapData.TILE_OWNER_ENEMY) && !(_loc2_ && _loc15_.mObject is DebrisObject) && !(Boolean(_loc2_) && _loc15_.mObject is ConstructionObject && ConstructionObject(_loc15_.mObject).getState() == PlayerBuildingObject.STATE_RUINS) && !(Boolean(_loc2_) && _loc15_.mObject is ResourceBuildingObject && ResourceBuildingObject(_loc15_.mObject).getState() == PlayerBuildingObject.STATE_RUINS))
               {
                  if(!(this.mGame.mCurrentAction is WalkingAction) || _loc15_.mObject is PlayerBuildingObject)
                  {
                     _loc15_.mObject.MousePressed(null);
                     this.mGame.unActivatePlayerUnit();
                  }
               }
               else if(_loc2_)
               {
                  if(!(_loc15_ != _loc2_.getCell() && !_loc15_.mCharacter))
                  {
                     ArmySoundManager.getInstance().playSound(ArmySoundManager.SFX_UI_ERROR);
                     this.mGame.unActivatePlayerUnit();
                     return;
                  }
                  _loc10_ = this.mGame.doPlayerWalkAction(this.getCenterPointXOfCell(_loc15_),this.getCenterPointYOfCell(_loc15_));
                  this.mGame.moveCameraToSeeCell(_loc15_);
                  this.mGame.unActivatePlayerUnit();
               }
               break;
            case GameState.STATE_PLACE_ITEM:
               if(!this.isCellEnableForMovingObject(_loc15_,false))
               {
                  ArmySoundManager.getInstance().playSound(ArmySoundManager.SFX_UI_ERROR);
               }
               break;
            case GameState.STATE_MOVE_ITEM:
               if(Boolean(_loc15_.mObject) && _loc15_.mObject.isMovable())
               {
                  if(!this.mObjectBeingMoved)
                  {
                     if(_loc15_.mObject.getMoveCostSupplies() > this.mGame.mPlayerProfile.mSupplies)
                     {
                        this.mGame.mHUD.openOutOfSuppliesTextBox([_loc15_.mObject.getMoveCostSupplies(),this.mGame.mPlayerProfile.mSupplies]);
                     }
                     else
                     {
                        this.setSelectedObject(_loc15_.mObject);
                        if(_loc15_.mObject is PlayerBuildingObject)
                        {
                           this.decrementViewersForBuilding(PlayerBuildingObject(_loc15_.mObject),PlayerBuildingObject(_loc15_.mObject).getSightRangeAccordingToCondition());
                        }
                        else if(_loc15_.mObject is PlayerInstallationObject)
                        {
                           this.decrementViewersForInstallation(PlayerInstallationObject(_loc15_.mObject),PlayerInstallationObject(_loc15_.mObject).getSightRangeAccordingToCondition());
                        }
                        this.mObjectBeingMovedStartX = _loc15_.mObject.mX;
                        this.mObjectBeingMovedStartY = _loc15_.mObject.mY;
                        this.mMouseScrolling = false;
                     }
                     param1.stopPropagation();
                  }
               }
               else
               {
                  ArmySoundManager.getInstance().playSound(ArmySoundManager.SFX_UI_ERROR);
               }
               break;
            case GameState.STATE_PICKUP_UNIT:
               if(Boolean(_loc15_.mCharacter) && _loc15_.mCharacter is PlayerUnit)
               {
                  if(this.mGame.checkIfUnitIsPickable(_loc15_.mCharacter as PlayerUnit))
                  {
                     this.mGame.mHUD.openRedeploymentConfirmationTextBox(_loc15_.mCharacter as PlayerUnit);
                  }
               }
               break;
            case GameState.STATE_REPAIR_ITEM:
               if(_loc15_.mCharacter && _loc15_.mCharacter is PlayerUnit && !_loc15_.mCharacter.isFullHealth())
               {
                  this.mGame.queueAction(new RepairPlayerUnitAction(_loc15_.mCharacter as PlayerUnit));
               }
               else if(_loc15_.mObject)
               {
                  if(_loc15_.mObject is ConstructionObject && !ConstructionObject(_loc15_.mObject).isFullHealth())
                  {
                     this.mGame.queueAction(new RepairConstructionAction(_loc15_.mObject as ConstructionObject));
                  }
                  else if(_loc15_.mObject is ResourceBuildingObject && !ResourceBuildingObject(_loc15_.mObject).isFullHealth())
                  {
                     this.mGame.queueAction(new RepairResourceBuildingAction(_loc15_.mObject as ResourceBuildingObject));
                  }
                  else if(_loc15_.mObject is HospitalBuilding && !HospitalBuilding(_loc15_.mObject).isFullHealth())
                  {
                     this.mGame.queueAction(new RepairHospitalAction(_loc15_.mObject as HospitalBuilding));
                  }
                  else if(_loc15_.mObject is DecorationObject && !(_loc15_.mObject is SignalObject) && !DecorationObject(_loc15_.mObject).isFullHealth())
                  {
                     this.mGame.queueAction(new RepairDecorationAction(_loc15_.mObject as DecorationObject));
                  }
                  else if(_loc15_.mObject is PlayerInstallationObject && !PlayerInstallationObject(_loc15_.mObject).isFullHealth())
                  {
                     this.mGame.queueAction(new RepairPlayerInstallationAction(_loc15_.mObject as PlayerInstallationObject));
                  }
                  else
                  {
                     ArmySoundManager.getInstance().playSound(ArmySoundManager.SFX_UI_ERROR);
                  }
               }
               else
               {
                  ArmySoundManager.getInstance().playSound(ArmySoundManager.SFX_UI_ERROR);
               }
               GameState.mInstance.mHUD.cancelTools();
               break;
            case GameState.STATE_SELL_ITEM:
               if(Boolean(_loc15_.mCharacter) && _loc15_.mCharacter is PlayerUnit)
               {
                  this.mGame.mHUD.openSellConfirmTextBox(_loc15_.mCharacter);
               }
               else if(_loc15_.mObject)
               {
                  if(_loc15_.mObject is ConstructionObject || _loc15_.mObject is DecorationObject || _loc15_.mObject is PlayerInstallationObject || _loc15_.mObject is HFEObject || _loc15_.mObject is HFEPlotObject || _loc15_.mObject is ResourceBuildingObject || _loc15_.mObject is HospitalBuilding)
                  {
                     this.mGame.mHUD.openSellConfirmTextBox(_loc15_.mObject);
                  }
                  else
                  {
                     ArmySoundManager.getInstance().playSound(ArmySoundManager.SFX_UI_ERROR);
                  }
               }
               else
               {
                  ArmySoundManager.getInstance().playSound(ArmySoundManager.SFX_UI_ERROR);
               }
               break;
            case GameState.STATE_VISITING_NEIGHBOUR:
               if(_loc15_.mCharacter)
               {
                  _loc15_.mCharacter.MousePressed(null);
               }
               else if(Boolean(_loc15_.mObject) && (_loc15_.mObject is DebrisObject && _loc15_.mOwner == MapData.TILE_OWNER_FRIENDLY || _loc15_.mObject is HFEObject || _loc15_.mObject is PermanentHFEObject || _loc15_.mObject is ConstructionObject || _loc15_.mObject is ResourceBuildingObject || _loc15_.mObject is HospitalBuilding))
               {
                  _loc15_.mObject.MousePressed(null);
               }
               else if(_loc15_.mObject && _loc15_.mObject is EnemyInstallationObject && !(_loc15_.mObject as EnemyInstallationObject).hasForceField())
               {
                  _loc15_.mObject.MousePressed(null);
               }
         }
      }
      
      private function printBoundingGrid() : void
      {
         var _loc1_:String = null;
         var _loc2_:int = 0;
         var _loc3_:GridCell = null;
      }
      
      public function updateGridInformation() : void
      {
         var _loc1_:Element = null;
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:Renderable = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:GridCell = null;
         var _loc10_:int = 0;
         var _loc12_:int = 0;
         var _loc13_:int = 0;
         var _loc14_:int = 0;
         var _loc15_:int = 0;
         var _loc16_:int = 0;
         var _loc17_:Array = null;
         var _loc18_:int = 0;
         _loc1_ = null;
         _loc2_ = 0;
         _loc3_ = 0;
         _loc4_ = null;
         _loc5_ = 0;
         _loc6_ = 0;
         _loc7_ = 0;
         _loc8_ = 0;
         _loc9_ = null;
         _loc10_ = 0;
         this.mSizeX = this.mFloor.getGridRight();
         this.mSizeY = this.mFloor.getGridBottom();
         var _loc11_:Floor = this.mFloor;
         _loc12_ = 0;
         _loc13_ = this.mSizeY;
         _loc14_ = 0;
         _loc15_ = this.mSizeX;
         _loc16_ = this.mSizeX * this.mSizeY;
         _loc17_ = this.mGame.mMapData.mGrid;
         _loc18_ = _loc14_;
         while(_loc18_ < _loc15_)
         {
            _loc2_ = _loc12_;
            while(_loc2_ < _loc13_)
            {
               _loc3_ = _loc2_ * this.mSizeX + _loc18_;
               if(_loc3_ < 0 || _loc3_ >= _loc16_)
               {
                  Utils.LogError("Piece of floor outside grid");
               }
               else
               {
                  (_loc17_[_loc3_] as GridCell).mWalkable = (_loc17_[_loc3_] as GridCell).mDefaultWalkable && MapData.isTilePassable((_loc17_[_loc3_] as GridCell).mType);
                  (_loc17_[_loc3_] as GridCell).mCharacter = null;
                  (_loc17_[_loc3_] as GridCell).mObject = null;
               }
               _loc2_++;
            }
            _loc18_++;
         }
         for each(_loc1_ in this.mAllElements)
         {
            _loc4_ = _loc1_ as Renderable;
            if(_loc4_)
            {
               if(!(_loc4_ is IsometricCharacter))
               {
                  _loc5_ = _loc4_.getTileSize().x;
                  _loc6_ = _loc4_.getTileSize().y;
                  _loc7_ = 0;
                  while(_loc7_ < _loc5_)
                  {
                     _loc8_ = 0;
                     while(_loc8_ < _loc6_)
                     {
                        _loc9_ = this.getCellAtLocation(_loc4_.mX + _loc7_ * this.mGridDimX,_loc4_.mY + _loc8_ * this.mGridDimY);
                        if(_loc9_)
                        {
                           if(_loc9_.mObject)
                           {
                              Utils.LogError("ERROR: UpdateGridInformation - Overlapping objects in cell: " + _loc9_.mPosI + "," + _loc9_.mPosJ);
                              if(this.mAllowedToCheckMisplacedDebris)
                              {
                                 if(_loc9_.mObject is DebrisObject)
                                 {
                                    this.forceClearMisplacedDebris(_loc9_.mObject as DebrisObject);
                                 }
                              }
                           }
                           else if(Boolean(_loc9_.mCharacter) && !_loc4_.isWalkable())
                           {
                              Utils.LogError("ERROR: UpdateGridInformation - Overlapping object and character in cell: " + _loc9_.mPosI + "," + _loc9_.mPosJ);
                           }
                           _loc9_.mWalkable = _loc4_.isWalkable();
                           _loc9_.mObject = _loc4_;
                           if(this.mAllowedToCheckMisplacedDebris)
                           {
                              if(_loc4_ is DebrisObject)
                              {
                                 _loc10_ = this.mGame.mMapData.getType(_loc9_.mPosI,_loc9_.mPosJ);
                                 if(!MapData.isTilePassable(_loc10_))
                                 {
                                    this.forceClearMisplacedDebris(_loc4_ as DebrisObject);
                                 }
                              }
                           }
                        }
                        _loc8_++;
                     }
                     _loc7_++;
                  }
               }
            }
         }
         this.printBoundingGrid();
         this.mAllowedToCheckMisplacedDebris = false;
      }
      
      private function forceClearMisplacedDebris(param1:DebrisObject) : void
      {
         var _loc2_:DebrisItem = null;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:Object = null;
         if(this.mGame.mPlayerProfile.mEnergy < 1)
         {
            return;
         }
         _loc2_ = DebrisItem(param1.mItem);
         _loc3_ = _loc2_.mHitRewardXP;
         _loc4_ = _loc2_.mHitRewardMoney;
         _loc5_ = _loc2_.mHitRewardMaterial;
         _loc6_ = _loc2_.mHitRewardSupplies;
         _loc7_ = _loc2_.mHitRewardEnergy;
         _loc3_ += _loc2_.mKillRewardXP;
         _loc4_ += _loc2_.mKillRewardMoney;
         _loc5_ += _loc2_.mKillRewardMaterial;
         _loc6_ += _loc2_.mKillRewardSupplies;
         _loc7_ += _loc2_.mKillRewardEnergy;
         _loc8_ = {
            "coord_x":param1.getCell().mPosI,
            "coord_y":param1.getCell().mPosJ,
            "item_hit_points":0,
            "cost_energy":1,
            "reward_xp":_loc3_,
            "reward_money":_loc4_,
            "reward_material":_loc5_,
            "reward_supplies":_loc6_,
            "reward_energy":_loc7_
         };
         this.mGame.mServer.serverCallServiceWithParameters(ServiceIDs.CLEAN_DEBRIS,_loc8_,false);
         param1.remove();
      }
      
      public function updateGridCharacterInfo() : void
      {
         var _loc1_:Element = null;
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:GridCell = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         var _loc10_:Array = null;
         var _loc11_:int = 0;
         _loc1_ = null;
         _loc2_ = 0;
         _loc3_ = 0;
         _loc4_ = null;
         _loc5_ = 0;
         _loc6_ = this.mSizeY;
         _loc7_ = 0;
         _loc8_ = this.mSizeX;
         _loc9_ = this.mSizeX * this.mSizeY;
         _loc10_ = this.mGame.mMapData.mGrid;
         _loc11_ = _loc7_;
         while(_loc11_ < _loc8_)
         {
            _loc2_ = _loc5_;
            while(_loc2_ < _loc6_)
            {
               _loc3_ = _loc2_ * this.mSizeX + _loc11_;
               if(!(_loc3_ < 0 || _loc3_ >= _loc9_))
               {
                  (_loc10_[_loc3_] as GridCell).mCharacter = null;
               }
               _loc2_++;
            }
            _loc11_++;
         }
         for each(_loc1_ in this.mAllElements)
         {
            if(_loc1_ is IsometricCharacter)
            {
               _loc4_ = this.getCellAtLocation(_loc1_.mX,_loc1_.mY);
               if(_loc4_.mCharacter)
               {
                  if(Config.DEBUG_MODE)
                  {
                  }
               }
               else if(Boolean(_loc4_.mObject) && !_loc4_.mWalkable)
               {
                  Utils.LogError("ERROR: UpdateGridCharacterInfo - Overlapping character and object in cell: " + _loc4_.mPosI + "," + _loc4_.mPosJ);
               }
               _loc4_.mCharacter = _loc1_ as IsometricCharacter;
            }
         }
      }
      
      private function addObjectTo(param1:Array, param2:Renderable) : void
      {
         var _loc3_:int = 0;
         _loc3_ = 0;
         if(param2)
         {
            if(param2.mVisible)
            {
               if(!param2.mSorted)
               {
                  _loc3_ = int(param1.indexOf(param2));
                  if(_loc3_ < 0)
                  {
                     param1.push(param2);
                  }
               }
            }
         }
      }
      
      private function getObjectsFromTiles(param1:int, param2:int, param3:int, param4:int) : Array
      {
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:GridCell = null;
         var _loc8_:Renderable = null;
         var _loc9_:Renderable = null;
         var _loc10_:int = 0;
         var _loc11_:int = 0;
         var _loc12_:Array = null;
         var _loc13_:Array = null;
         var _loc14_:int = 0;
         _loc5_ = 0;
         _loc6_ = 0;
         _loc7_ = null;
         _loc8_ = null;
         _loc9_ = null;
         _loc10_ = 0;
         _loc11_ = 0;
         _loc12_ = new Array();
         _loc13_ = this.mGame.mMapData.mGrid;
         _loc14_ = param1;
         while(_loc14_ < param2)
         {
            _loc5_ = param3;
            while(_loc5_ < param4)
            {
               _loc6_ = _loc5_ * this.mSizeX + _loc14_;
               _loc7_ = _loc13_[_loc6_];
               _loc8_ = _loc7_.mObject;
               this.addObjectTo(_loc12_,_loc8_);
               _loc10_ = int(_loc7_.mDynamicObjects.length);
               _loc11_ = 0;
               while(_loc11_ < _loc10_)
               {
                  _loc9_ = _loc7_.mDynamicObjects[_loc11_] as Renderable;
                  this.addObjectTo(_loc12_,_loc9_);
                  _loc11_++;
               }
               _loc5_++;
            }
            _loc14_++;
         }
         return _loc12_;
      }
      
      private function dangerZoneAt(param1:Array, param2:Number, param3:Number) : Boolean
      {
         var _loc4_:MovieClip = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         _loc4_ = null;
         _loc5_ = int(param1.length);
         _loc6_ = 0;
         while(_loc6_ < _loc5_)
         {
            _loc4_ = param1[_loc6_] as MovieClip;
            if(_loc4_.x == param2)
            {
               if(_loc4_.y == param3)
               {
                  return true;
               }
            }
            _loc6_++;
         }
         return false;
      }
      
      protected function MouseEnteredObject(param1:MouseEvent) : void
      {
         var _loc2_:int = 0;
         var _loc3_:DisplayContainer = null;
         var _loc4_:Renderable = null;
         _loc2_ = this.mGame.mState;
         _loc3_ = param1.currentTarget as DisplayContainer;
         _loc4_ = _loc3_.getRenderableObject();
         switch(_loc2_)
         {
            case GameState.STATE_VISITING_NEIGHBOUR:
               break;
            case GameState.STATE_PVP:
            case GameState.STATE_PLAY:
               _loc4_.MouseOver(param1);
               break;
            case GameState.STATE_MOVE_ITEM:
            case GameState.STATE_PLACE_ITEM:
            case GameState.STATE_USE_INVENTORY_ITEM:
               if(_loc4_.isMovable())
               {
                  if(!this.mObjectBeingMoved)
                  {
                     _loc4_.MouseOver(param1);
                  }
               }
         }
      }
      
      protected function MouseExitedObject(param1:MouseEvent) : void
      {
         var _loc2_:DisplayContainer = null;
         _loc2_ = param1.currentTarget as DisplayContainer;
         _loc2_.getRenderableObject().MouseOut(param1);
      }
      
      protected function MousePressedOnObject(param1:MouseEvent) : void
      {
         var _loc2_:int = 0;
         var _loc3_:DisplayContainer = null;
         var _loc4_:Renderable = null;
         if(this.mGame.mActivatedPlayerUnit)
         {
            this.mGame.unActivatePlayerUnit();
            return;
         }
         _loc2_ = this.mGame.mState;
         _loc3_ = param1.currentTarget as DisplayContainer;
         _loc4_ = _loc3_.getRenderableObject();
         switch(_loc2_)
         {
            case GameState.STATE_VISITING_NEIGHBOUR:
               break;
            case GameState.STATE_PVP:
            case GameState.STATE_PLAY:
               _loc4_.MousePressed(param1);
               break;
            case GameState.STATE_MOVE_ITEM:
               if(_loc4_.isMovable())
               {
                  if(!this.mObjectBeingMoved)
                  {
                     this.setSelectedObject(_loc4_);
                     if(_loc4_ is PlayerBuildingObject)
                     {
                        this.decrementViewersForBuilding(PlayerBuildingObject(_loc4_),PlayerBuildingObject(_loc4_).getSightRangeAccordingToCondition());
                     }
                     else if(_loc4_ is PlayerInstallationObject)
                     {
                        this.decrementViewersForInstallation(PlayerInstallationObject(_loc4_),PlayerInstallationObject(_loc4_).getSightRangeAccordingToCondition());
                     }
                     this.mObjectBeingMovedStartX = _loc4_.mX;
                     this.mObjectBeingMovedStartY = _loc4_.mY;
                     this.mMouseScrolling = false;
                     param1.stopPropagation();
                  }
               }
               break;
            case GameState.STATE_REPAIR_ITEM:
               break;
            case GameState.STATE_SELL_ITEM:
               if(_loc4_ is ConstructionObject || _loc4_ is DecorationObject || _loc4_ is PlayerInstallationObject || _loc4_ is HFEObject || _loc4_ is HFEPlotObject || _loc4_ is ResourceBuildingObject || _loc4_ is HospitalBuilding)
               {
                  this.mGame.mHUD.openSellConfirmTextBox(_loc4_);
               }
         }
      }
      
      public function getNeighboringCellsAtDistance(param1:IsometricCharacter, param2:int, param3:Array) : void
      {
         var _loc4_:int = 0;
         var _loc5_:GridCell = null;
         var _loc7_:GridCell = null;
         var _loc8_:int = 0;
         _loc4_ = 0;
         _loc5_ = null;
         var _loc6_:int = 0;
         _loc7_ = this.getCellAtLocation(param1.mX,param1.mY);
         param3.length = 0;
         _loc8_ = -param2;
         while(_loc8_ <= param2)
         {
            _loc4_ = -param2;
            while(_loc4_ <= param2)
            {
               _loc5_ = this.getCellAt(_loc7_.mPosI + _loc8_,_loc7_.mPosJ + _loc4_);
               if(_loc5_)
               {
                  if(_loc5_.mWalkable)
                  {
                     if(!_loc5_.mCharacter)
                     {
                        _loc6_ = this.calculateWalkManhattanDist(param1,(_loc7_.mPosI + _loc8_ + 0.5) * this.mGridDimX,(_loc7_.mPosJ + _loc4_ + 0.5) * this.mGridDimY);
                        if(_loc6_ <= param2)
                        {
                           param3.push(_loc5_);
                        }
                     }
                  }
               }
               _loc4_++;
            }
            _loc8_++;
         }
      }
      
      public function getNeighboringAvailableCellsAtChessboardDistance(param1:GridCell, param2:int) : Array
      {
         var _loc3_:int = 0;
         var _loc4_:GridCell = null;
         var _loc5_:Array = null;
         var _loc6_:int = 0;
         _loc3_ = 0;
         _loc4_ = null;
         _loc5_ = new Array();
         _loc6_ = -param2;
         while(_loc6_ <= param2)
         {
            _loc3_ = -param2;
            while(_loc3_ <= param2)
            {
               _loc4_ = this.getCellAt(param1.mPosI + _loc6_,param1.mPosJ + _loc3_);
               if(_loc4_)
               {
                  if(_loc4_.mWalkable)
                  {
                     if(!_loc4_.mCharacter)
                     {
                        if(!_loc4_.mObject || _loc4_.mObject.isWalkable())
                        {
                           _loc5_.push(_loc4_);
                        }
                     }
                  }
               }
               _loc3_++;
            }
            _loc6_++;
         }
         return _loc5_;
      }
      
      public function findGridLocation(param1:Number, param2:Number, param3:Point) : void
      {
         param3.x = Math.floor(param1 / this.mGridDimX);
         param3.y = Math.floor(param2 / this.mGridDimY);
      }
      
      public function findGridLocationX(param1:Number) : int
      {
         return Math.floor(param1 / this.mGridDimX);
      }
      
      public function findGridLocationY(param1:Number) : int
      {
         return Math.floor(param1 / this.mGridDimY);
      }
      
      public function getCellAt(param1:int, param2:int) : GridCell
      {
         if(param1 < 0 || param2 < 0 || param1 >= this.mSizeX || param2 >= this.mSizeY)
         {
            return null;
         }
         return this.mGame.mMapData.mGrid[param2 * this.mSizeX + param1];
      }
      
      public function getCellAtLocation(param1:int, param2:int) : GridCell
      {
         var _loc3_:Array = null;
         if(param1 < 0 || param2 < 0 || param1 >= this.mSizeX * this.mGridDimX || param2 >= this.mSizeY * this.mGridDimY)
         {
            return null;
         }
         _loc3_ = this.mGame.mMapData.mGrid;
         if(!_loc3_)
         {
            return null;
         }
         return _loc3_[Math.floor(param2 / this.mGridDimY) * this.mSizeX + Math.floor(param1 / this.mGridDimX)];
      }
      
      public function getCenterPointXAtIJ(param1:int, param2:int) : Number
      {
         return (param1 + 0.5) * this.mGridDimX;
      }
      
      public function getCenterPointYAtIJ(param1:int, param2:int) : Number
      {
         return (param2 + 0.5) * this.mGridDimY;
      }
      
      public function getCenterPointXOfCell(param1:GridCell) : Number
      {
         return (param1.mPosI + 0.5) * this.mGridDimX;
      }
      
      public function getCenterPointYOfCell(param1:GridCell) : Number
      {
         return (param1.mPosJ + 0.5) * this.mGridDimY;
      }
      
      public function getLeftUpperXOfCell(param1:GridCell) : Number
      {
         return param1.mPosI * this.mGridDimX;
      }
      
      public function getLeftUpperYOfCell(param1:GridCell) : Number
      {
         return param1.mPosJ * this.mGridDimY;
      }
      
      public function getCellManhattanDistance(param1:GridCell, param2:GridCell) : int
      {
         return Math.abs(param1.mPosJ - param2.mPosJ) + Math.abs(param1.mPosI - param2.mPosI);
      }
      
      public function getCellChebyshevDistance(param1:GridCell, param2:GridCell) : int
      {
         return Math.max(Math.abs(param1.mPosJ - param2.mPosJ),Math.abs(param1.mPosI - param2.mPosI));
      }
      
      public function getFreeCellsInTheArea(param1:int, param2:int, param3:int, param4:int) : Array
      {
         var _loc5_:int = 0;
         var _loc6_:GridCell = null;
         var _loc7_:Array = null;
         var _loc8_:int = 0;
         _loc5_ = 0;
         _loc6_ = null;
         _loc7_ = new Array();
         _loc8_ = param1;
         while(_loc8_ < param1 + param3)
         {
            _loc5_ = param2;
            while(_loc5_ < param2 + param4)
            {
               _loc6_ = this.getCellAt(_loc8_,_loc5_);
               if(_loc6_)
               {
                  if(_loc6_.mWalkable)
                  {
                     if(!_loc6_.mCharacter)
                     {
                        if(!_loc6_.mObject || _loc6_.mObject.isWalkable())
                        {
                           _loc7_.push(_loc6_);
                        }
                     }
                  }
               }
               _loc5_++;
            }
            _loc8_++;
         }
         return _loc7_;
      }
      
      public function findShortestChebyshev(param1:Renderable, param2:Renderable) : int
      {
         var _loc3_:GridCell = null;
         var _loc4_:GridCell = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:Array = null;
         var _loc9_:Array = null;
         var _loc10_:int = 0;
         var _loc11_:int = 0;
         var _loc12_:int = 0;
         _loc3_ = null;
         _loc4_ = null;
         _loc5_ = 0;
         _loc6_ = 0;
         _loc7_ = 0;
         _loc8_ = this.getTilesUnderObject(param1);
         _loc9_ = this.getTilesUnderObject(param2);
         _loc10_ = this.mGridDimX;
         _loc11_ = int(_loc8_.length);
         _loc12_ = 0;
         while(_loc12_ < _loc11_)
         {
            _loc3_ = _loc8_[_loc12_] as GridCell;
            _loc5_ = int(_loc9_.length);
            _loc6_ = 0;
            while(_loc6_ < _loc5_)
            {
               _loc4_ = _loc9_[_loc6_] as GridCell;
               _loc7_ = this.getCellChebyshevDistance(_loc3_,_loc4_);
               if(_loc7_ < _loc10_)
               {
                  _loc10_ = _loc7_;
               }
               _loc6_++;
            }
            _loc12_++;
         }
         return _loc10_;
      }
      
      public function createObject(param1:MapItem, param2:Point) : Renderable
      {
         var _loc3_:Renderable = null;
         var _loc4_:GamePlayerProfile = null;
         var _loc5_:int = 0;
         var _loc6_:Class = null;
         _loc3_ = null;
         _loc4_ = this.mGame.mPlayerProfile;
         _loc5_ = _loc4_.getNextId();
         _loc6_ = param1.mObjectClass;
         if(_loc6_ == PlayerUnit || _loc6_ == EnemyUnit || _loc6_ == PvPEnemyUnit || _loc6_ == EnemyInstallationObject || _loc6_ == PlayerInstallationObject)
         {
            _loc3_ = new _loc6_(_loc5_,this,param1);
         }
         else
         {
            _loc3_ = new _loc6_(_loc5_,this,param1,param2);
            if(_loc3_ is ImportedObject)
            {
               (_loc3_ as ImportedObject).getInternalGraphicsLoaded();
               if(!(_loc3_ is PowerUpObject))
               {
                  (_loc3_ as ImportedObject).setPositionInternally();
               }
            }
            if(this.mObjectLoader.isHitAreaChanged())
            {
               _loc3_.getContainer().mouseEnabled = false;
            }
         }
         _loc3_.showHealthWarning(false);
         _loc3_.setTileSize(param1.mSize);
         _loc3_.setWalkable(param1.mWalkable);
         _loc3_.setPlaceableOnAllTiles(param1.mPlaceableOnAllTiles);
         this.addObject(_loc3_);
         return _loc3_;
      }
      
      public function addPowerUpToMap(param1:String, param2:GridCell) : PowerUpObject
      {
         var _loc4_:MapItem = null;
         var _loc3_:PowerUpObject = null;
         _loc4_ = ItemManager.getItem(param1,"PowerUp") as MapItem;
         if(_loc4_)
         {
            return this.createObject(_loc4_,new Point(param2.mPosI,param2.mPosJ)) as PowerUpObject;
         }
         return null;
      }
      
      public function addRewardedPlayerUnit(param1:PlayerUnitItem, param2:GridCell) : void
      {
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:Renderable = null;
         _loc3_ = this.getCenterPointXOfCell(param2);
         _loc4_ = this.getCenterPointYOfCell(param2);
         _loc5_ = this.createObject(param1,new Point(0,0));
         _loc5_.setPos(_loc3_,_loc4_,0);
         _loc5_.getContainer().visible = true;
         _loc5_.mVisible = true;
         param2.mOwner = MapData.TILE_OWNER_FRIENDLY;
         this.mGame.mMapData.mUpdateRequired = true;
      }
      
      public function getObjectLoader() : ObjectLoader
      {
         return this.mObjectLoader;
      }
      
      public function getSurroundingFreeCell(param1:int, param2:int) : GridCell
      {
         var _loc4_:Array = null;
         var _loc5_:GridCell = null;
         var _loc6_:int = 0;
         var _loc7_:GridCell = null;
         var _loc3_:MapArea = null;
         _loc4_ = null;
         _loc5_ = null;
         _loc6_ = 0;
         _loc7_ = this.getCellAtLocation(param1,param2);
         if(_loc7_)
         {
            _loc3_ = MapArea.getAreaAroundCell(this,_loc7_,1);
            _loc4_ = _loc3_.getCells();
            _loc6_ = 0;
            while(_loc6_ < _loc4_.length)
            {
               _loc5_ = _loc4_[_loc6_];
               if(!_loc5_.mCharacter && !_loc5_.mObject)
               {
                  return _loc5_;
               }
               _loc6_++;
            }
         }
         return null;
      }
      
      public function isInAttackRange(param1:Renderable) : Boolean
      {
         var _loc2_:Array = null;
         _loc2_ = this.mGame.searchUnitsInRange(param1);
         if(_loc2_)
         {
            if(_loc2_.length > 0)
            {
               return true;
            }
         }
         return false;
      }
      
      public function destroy() : void
      {
         var _loc2_:String = null;
         var _loc3_:String = null;
         var _loc1_:Renderable = null;
         _loc2_ = null;
         _loc3_ = null;
         this.mContainer.removeEventListener(MouseEvent.MOUSE_MOVE,this.mouseMove);
         this.mContainer.removeEventListener(MouseEvent.MOUSE_DOWN,this.mouseDown);
         this.mContainer.removeEventListener(MouseEvent.MOUSE_UP,this.mouseUp);
         this.mContainer.removeEventListener(TransformGestureEvent.GESTURE_ZOOM,this.ZoomInOut);
         CursorManager.getInstance().clean();
         while(this.mContainer.numChildren > 0)
         {
            this.mContainer.removeChildAt(0);
         }
         if(this.mContainer.parent)
         {
            this.mContainer.parent.removeChild(this.mContainer);
            this.mContainer = null;
         }
         this.removeLootAndGetRewards();
         while(this.mSceneHud.numChildren > 0)
         {
            this.mSceneHud.removeChildAt(0);
         }
         if(this.mSceneHud.parent)
         {
            this.mSceneHud.parent.removeChild(this.mSceneHud);
            this.mSceneHud = null;
         }
         if(this.mTilemapGraphic)
         {
            this.mTilemapGraphic.destroy();
            this.mTilemapGraphic = null;
         }
         for(_loc2_ in this.mAllElements)
         {
            (this.mAllElements[_loc2_] as Element).destroy();
            this.mAllElements[_loc2_] = null;
         }
         this.mAllElements = null;
         for(_loc3_ in this.mSoundMakers)
         {
            (this.mSoundMakers[_loc3_] as Renderable).destroy();
            this.mSoundMakers[_loc3_] = null;
         }
         this.mSoundMakers = null;
         this.mFog.destroy();
         this.mFog = null;
         this.mFloor.destroy();
         this.mFloor = null;
         this.mMapGUIEffectsLayer.destroy();
         this.mMapGUIEffectsLayer = null;
         this.mGame = null;
      }
      
      public function characterArrivedInCell(param1:IsometricCharacter, param2:GridCell, param3:Boolean = true) : void
      {
         if(param1.isInOpponentsTile())
         {
            this.changeCellOwner(param2);
         }
         if(param1 is PlayerUnit)
         {
            this.mGame.updateWalkableCellsForActiveCharacter();
            if(param3)
            {
               this.mGame.setEnemyInstallationsToAttack(param1 as PlayerUnit);
            }
         }
         else if(param1 is EnemyUnit)
         {
            if(param3)
            {
               this.mGame.setPlayerInstallationsToAttack(param1 as EnemyUnit);
            }
         }
         if(param2.mPowerUp)
         {
            param2.mPowerUp.execute(param1);
            this.removeObject(param2.mPowerUp,true,false);
         }
      }
      
      public function incrementViewersForBuilding(param1:PlayerBuildingObject, param2:int) : void
      {
         var _loc3_:GridCell = null;
         var _loc4_:Array = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         _loc3_ = null;
         _loc4_ = this.getTilesUnderObjectSightArea(param1,param2);
         _loc5_ = int(_loc4_.length);
         _loc6_ = 0;
         while(_loc6_ < _loc5_)
         {
            _loc3_ = _loc4_[_loc6_] as GridCell;
            if(this.isInsideVisibleArea(_loc3_))
            {
               this.mFog.incrementViewersForCell(_loc3_);
            }
            _loc6_++;
         }
      }
      
      public function incrementViewersForInstallation(param1:PlayerInstallationObject, param2:int) : void
      {
         var _loc3_:GridCell = null;
         var _loc4_:Array = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         _loc3_ = null;
         _loc4_ = this.getTilesUnderObjectSightArea(param1,param2);
         _loc5_ = int(_loc4_.length);
         _loc6_ = 0;
         while(_loc6_ < _loc5_)
         {
            _loc3_ = _loc4_[_loc6_] as GridCell;
            if(this.isInsideVisibleArea(_loc3_))
            {
               this.mFog.incrementViewersForCell(_loc3_);
            }
            _loc6_++;
         }
      }
      
      public function decrementViewersForBuilding(param1:PlayerBuildingObject, param2:int) : void
      {
         var _loc3_:GridCell = null;
         var _loc4_:Array = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         _loc3_ = null;
         _loc4_ = this.getTilesUnderObjectSightArea(param1,param2);
         _loc5_ = int(_loc4_.length);
         _loc6_ = 0;
         while(_loc6_ < _loc5_)
         {
            _loc3_ = _loc4_[_loc6_] as GridCell;
            if(this.isInsideVisibleArea(_loc3_))
            {
               this.mFog.decrementViewersForCell(_loc3_);
            }
            _loc6_++;
         }
      }
      
      public function decrementViewersForInstallation(param1:PlayerInstallationObject, param2:int) : void
      {
         var _loc3_:GridCell = null;
         var _loc4_:Array = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         _loc3_ = null;
         _loc4_ = this.getTilesUnderObjectSightArea(param1,param2);
         _loc5_ = int(_loc4_.length);
         _loc6_ = 0;
         while(_loc6_ < _loc5_)
         {
            _loc3_ = _loc4_[_loc6_] as GridCell;
            if(this.isInsideVisibleArea(_loc3_))
            {
               this.mFog.decrementViewersForCell(_loc3_);
            }
            _loc6_++;
         }
      }
      
      private function changeCellOwner(param1:GridCell) : void
      {
         var _loc2_:Array = null;
         _loc2_ = null;
         if(param1.mOwner != MapData.TILE_OWNER_NEUTRAL)
         {
            if(param1.mOwner == MapData.TILE_OWNER_ENEMY)
            {
               param1.mOwner = MapData.TILE_OWNER_FRIENDLY;
               _loc2_ = new Array(param1.mPosI,param1.mPosJ);
               MissionManager.increaseCounter("Conquer",_loc2_,1);
            }
            else
            {
               param1.mOwner = MapData.TILE_OWNER_ENEMY;
               _loc2_ = new Array(param1.mPosI,param1.mPosJ);
               MissionManager.increaseCounter("Conquer",_loc2_,-1);
            }
            this.mGame.mMapData.mUpdateRequired = true;
         }
      }
      
      public function dumpWorldObjects() : void
      {
         var _loc1_:Element = null;
         var _loc2_:Renderable = null;
         var _loc3_:Item = null;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         _loc1_ = null;
         _loc2_ = null;
         _loc3_ = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:int = 1;
         _loc8_ = int(this.mAllElements.length);
         _loc9_ = 0;
         while(_loc9_ < _loc8_)
         {
            _loc1_ = this.mAllElements[_loc9_] as Element;
            _loc2_ = _loc1_ as Renderable;
            if(_loc2_)
            {
               _loc3_ = _loc2_.mItem;
               if(_loc3_)
               {
                  _loc4_ = 0;
                  if(_loc3_ is DebrisItem)
                  {
                  }
                  _loc5_ = int(_loc2_.mX / this.mGridDimX);
                  _loc6_ = int(_loc2_.mY / this.mGridDimY);
                  _loc7_++;
               }
            }
            _loc9_++;
         }
      }
      
      public function buildingExists(param1:String) : Boolean
      {
         var _loc2_:Renderable = null;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         _loc2_ = null;
         _loc3_ = int(this.mAllElements.length);
         _loc4_ = 0;
         while(_loc4_ < _loc3_)
         {
            _loc2_ = this.mAllElements[_loc4_] as Renderable;
            if(_loc2_ is ConstructionObject)
            {
               if(ConstructionObject(_loc2_).mHasBeenCompleted)
               {
                  if(_loc2_.mItem.mId == param1)
                  {
                     return true;
                  }
               }
            }
            if(_loc2_ is ResourceBuildingObject)
            {
               if(_loc2_.mItem.mId == param1)
               {
                  return true;
               }
            }
            if(_loc2_ is HospitalBuilding)
            {
               if(_loc2_.mItem.mId == param1)
               {
                  return true;
               }
            }
            _loc4_++;
         }
         return false;
      }
      
      public function countBuildingsWithID(param1:String) : int
      {
         var _loc2_:Renderable = null;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         _loc2_ = null;
         _loc3_ = int(this.mAllElements.length);
         _loc4_ = 0;
         _loc5_ = 0;
         while(_loc4_ < _loc3_)
         {
            _loc2_ = this.mAllElements[_loc4_] as Renderable;
            if(_loc2_.mItem.mId == param1)
            {
               _loc5_++;
            }
            _loc4_++;
         }
         return _loc5_;
      }
      
      public function chooseCellClosestToCell(param1:Array, param2:GridCell) : GridCell
      {
         var _loc3_:int = 0;
         var _loc4_:GridCell = null;
         var _loc5_:GridCell = null;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         _loc3_ = 0;
         _loc4_ = null;
         _loc5_ = null;
         _loc6_ = 0;
         _loc7_ = 0;
         _loc8_ = 0;
         if(param2 && param1 && param1.length > 0)
         {
            _loc3_ = int.MAX_VALUE;
            _loc4_ = param1[0];
            _loc6_ = int(param1.length);
            _loc7_ = 0;
            while(_loc7_ < _loc6_)
            {
               _loc5_ = param1[_loc7_] as GridCell;
               if(_loc5_ != param2)
               {
                  _loc8_ = Math.abs(param2.mPosI - _loc5_.mPosI) + Math.abs(param2.mPosJ - _loc5_.mPosJ);
                  if(_loc8_ < _loc3_)
                  {
                     _loc3_ = _loc8_;
                     _loc4_ = _loc5_;
                  }
               }
               _loc7_++;
            }
            return _loc4_;
         }
         return null;
      }
      
      public function chooseCellClosestToCellAvoidingPlayers(param1:Array, param2:GridCell) : GridCell
      {
         var _loc3_:int = 0;
         var _loc4_:GridCell = null;
         var _loc5_:GridCell = null;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:Array = null;
         var _loc11_:int = 0;
         var _loc12_:int = 0;
         _loc3_ = 0;
         _loc4_ = null;
         _loc5_ = null;
         _loc6_ = 0;
         _loc7_ = 0;
         _loc8_ = 0;
         _loc9_ = null;
         var _loc10_:PlayerUnit = null;
         _loc11_ = 0;
         _loc12_ = 0;
         if(param2 && param1 && param1.length > 0)
         {
            _loc3_ = int.MAX_VALUE;
            _loc4_ = param1[0];
            _loc6_ = int(param1.length);
            _loc7_ = 0;
            while(_loc7_ < _loc6_)
            {
               _loc5_ = param1[_loc7_] as GridCell;
               if(_loc5_ != param2)
               {
                  _loc8_ = Math.abs(param2.mPosI - _loc5_.mPosI) + Math.abs(param2.mPosJ - _loc5_.mPosJ);
                  _loc11_ = int((_loc9_ = this.mGame.mPvPMatch.mAI.searchCellAttackablePlayerUnits(_loc5_)).length);
                  _loc12_ = 0;
                  while(_loc12_ < _loc11_)
                  {
                     _loc10_ = _loc9_[_loc12_] as PlayerUnit;
                     _loc8_ *= 1.4;
                     _loc12_++;
                  }
                  if(_loc8_ < _loc3_)
                  {
                     _loc3_ = _loc8_;
                     _loc4_ = _loc5_;
                  }
               }
               _loc7_++;
            }
            return _loc4_;
         }
         return null;
      }
   }
}

