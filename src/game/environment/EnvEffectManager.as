package game.environment
{
   import game.battlefield.MapData;
   import game.isometric.GridCell;
   import game.states.GameState;
   
   public class EnvEffectManager
   {
      
      private static var mCloudClock:int;
      
      private static var mTileClock:int;
      
      private static var mFlyClock:int;
      
      private static var mClouds:Array;
      
      private static var mFly:Array;
      
      private static var mTile:Array;
      
      private static var mRiverTiles:Array;
      
      private static const RANDOM_PRC:int = 15;
      
      private static const EFFECTS_MAX_SIMULT_CLOUD:int = 3;
      
      private static const EFFECTS_DELAY_CLOUD:int = 100000;
      
      private static const EFFECTS_MAX_SIMULT_TILE:int = 5;
      
      private static const EFFECTS_DELAY_TILE:int = 1700;
      
      private static const EFFECTS_MAX_SIMULT_FLY:int = 1;
      
      private static const EFFECTS_DELAY_FLY:int = 25000;
      
      public function EnvEffectManager()
      {
         super();
      }
      
      public static function init() : void
      {
         var _loc1_:GridCell = null;
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         if(mFly)
         {
            destroy();
         }
         mFly = new Array();
         mTile = new Array();
         mClouds = new Array();
         var _loc4_:Array = GameState.mInstance.mMapData.mGrid;
         if(!mRiverTiles)
         {
            mRiverTiles = new Array();
            _loc2_ = int(_loc4_.length);
            _loc3_ = 0;
            while(_loc3_ < _loc2_)
            {
               _loc1_ = _loc4_[_loc3_] as GridCell;
               if(_loc1_.mType == MapData.TILE_TYPE_RIVER)
               {
                  mRiverTiles.push(_loc1_);
               }
               _loc3_++;
            }
         }
      }
      
      public static function destroy() : void
      {
         var _loc1_:RandomEffect = null;
         var _loc2_:RandomEffect = null;
         var _loc3_:RandomEffect = null;
         var _loc4_:int = int(mClouds.length);
         var _loc5_:int = 0;
         while(_loc5_ < _loc4_)
         {
            _loc1_ = mClouds[_loc5_] as RandomEffect;
            _loc1_.destroy();
            _loc5_++;
         }
         var _loc6_:int = int(mFly.length);
         var _loc7_:int = 0;
         while(_loc7_ < _loc6_)
         {
            _loc2_ = mFly[_loc7_] as RandomEffect;
            _loc2_.destroy();
            _loc7_++;
         }
         var _loc8_:int = int(mTile.length);
         var _loc9_:int = 0;
         while(_loc9_ < _loc8_)
         {
            _loc3_ = mTile[_loc9_] as RandomEffect;
            _loc3_.destroy();
            _loc9_++;
         }
         mFly = null;
         mTile = null;
         mClouds = null;
         mRiverTiles = null;
      }
      
      public static function update(param1:int) : void
      {
         var _loc2_:RandomEffect = null;
         var _loc3_:* = 0;
         var _loc4_:* = 0;
         var _loc5_:* = 0;
         if(FeatureTuner.USE_AIRPLANE_WEDGE_EFFECTS)
         {
            if(mFlyClock > EFFECTS_DELAY_FLY && mFly.length < EFFECTS_MAX_SIMULT_FLY)
            {
               mFly.push(new AirplaneWedge());
               mFlyClock = Math.random() * (EFFECTS_DELAY_FLY / 100 * RANDOM_PRC);
            }
            else
            {
               mFlyClock += param1;
            }
         }
         if(FeatureTuner.USE_RIVER_TILE_EFFECTS)
         {
            if(Boolean(mRiverTiles && mRiverTiles.length > 0) && Boolean(mTileClock > EFFECTS_DELAY_TILE) && mTile.length < EFFECTS_MAX_SIMULT_TILE)
            {
               mTile.push(new RiverEffect(mRiverTiles));
               mTileClock = Math.random() * (EFFECTS_DELAY_FLY / 100 * RANDOM_PRC);
            }
            else
            {
               mTileClock += param1;
            }
         }
         if(FeatureTuner.USE_CLOUD_EFFECTS)
         {
            if(mCloudClock > EFFECTS_DELAY_CLOUD && mClouds.length < EFFECTS_MAX_SIMULT_CLOUD)
            {
               if(GameState.mInstance.mCurrentMapId == "Desert")
               {
                  mTile.push(new DesertCloud());
               }
               else
               {
                  mTile.push(new DriftingCloud());
               }
               mCloudClock = Math.random() * (EFFECTS_DELAY_CLOUD / 100 * RANDOM_PRC);
            }
            else
            {
               mCloudClock += param1;
            }
         }
         if(FeatureTuner.USE_AIRPLANE_WEDGE_EFFECTS)
         {
            _loc3_ = 0;
            while(_loc3_ < mFly.length)
            {
               _loc2_ = mFly[_loc3_];
               if(_loc2_)
               {
                  if(_loc2_.update(param1) || _loc2_.mDestroyed)
                  {
                     mFly.splice(_loc3_,1);
                     _loc3_--;
                  }
               }
               _loc3_++;
            }
         }
         if(FeatureTuner.USE_RIVER_TILE_EFFECTS)
         {
            _loc4_ = 0;
            while(_loc4_ < mTile.length)
            {
               _loc2_ = mTile[_loc4_];
               if(_loc2_)
               {
                  if(_loc2_.update(param1) || _loc2_.mDestroyed)
                  {
                     mTile.splice(_loc4_,1);
                     _loc4_--;
                  }
               }
               _loc4_++;
            }
         }
         if(FeatureTuner.USE_CLOUD_EFFECTS)
         {
            _loc5_ = 0;
            while(_loc5_ < mClouds.length)
            {
               _loc2_ = mClouds[_loc5_];
               if(_loc2_)
               {
                  if(_loc2_.update(param1) || _loc2_.mDestroyed)
                  {
                     mClouds.splice(_loc5_,1);
                     _loc5_--;
                  }
               }
               _loc5_++;
            }
         }
      }
   }
}

