package game.battlefield
{
   import com.dchoc.graphics.DCResourceManager;
   import game.isometric.GridCell;
   import game.net.ServerCall;
   import game.states.GameState;
   
   public class MapData
   {
      
      public static var TILES_PASSABILITY:Array;
      
      public static var TILES_MAP_TYPE:Array;
      
      public static var SHORETILES_TYPE:Array;
      
      public static const MAP_HOME:String = "Home";
      
      public static const TILE_OWNER_ENEMY:int = 0;
      
      public static const TILE_OWNER_FRIENDLY:int = 1;
      
      public static const TILE_OWNER_NEUTRAL:int = 2;
      
      public static const TILE_LAND:int = 0;
      
      public static const TILE_MOUNTAIN:int = 1;
      
      public static const TILE_SHORE:int = 2;
      
      public static const TILE_SEA:int = 3;
      
      public static const TILE_MAP_TYPE_GRASSLANDS:int = 0;
      
      public static const TILE_MAP_TYPE_DESERT:int = 1;
      
      public static const TILE_MAP_TYPE_SNOW:int = 2;
      
      public static const TILE_TYPE_RIVER:int = 18;
      
      public static const TILE_TYPE_SHORE_S_1:int = 19;
      
      public static const TILE_TYPE_SHORE_S_2:int = 21;
      
      public static const TILE_TYPE_DESERT_SHORE_S:int = 128;
      
      public static const TILE_TYPE_DESERT_SHORE_W:int = 129;
      
      public static const TILE_TYPE_DESERT_SHORE_N:int = 126;
      
      public static const TILE_TYPE_DESERT_SHORE_E:int = 127;
      
      public static const TILE_TYPE_DESERT_SHORE_NW:int = 122;
      
      public static const TILE_TYPE_DESERT_SHORE_NE:int = 123;
      
      public static const TILE_TYPE_DESERT_SHORE_SE:int = 125;
      
      public static const TILE_TYPE_DESERT_SHORE_SW:int = 124;
      
      public static const TILE_TYPE_DESERT_SHORE_NW_INSIDE:int = 118;
      
      public static const TILE_TYPE_DESERT_SHORE_NE_INSIDE:int = 119;
      
      public static const TILE_TYPE_DESERT_SHORE_SE_INSIDE:int = 121;
      
      public static const TILE_TYPE_DESERT_SHORE_SW_INSIDE:int = 120;
      
      public static const TILE_TYPE_DESERT_DECO_31:int = 1045;
      
      private static const EXTENSIONS_TO_REMOVE_FROM_NAME:Array = [".csv"];
      
      public static const TILE_PASSABILITY_STRING_TO_ID:Object = {
         "Land":TILE_LAND,
         "Shore":TILE_SHORE,
         "Sea":TILE_SEA,
         "Mountain":TILE_MOUNTAIN
      };
      
      public var mGridWidth:int;
      
      public var mGridHeight:int;
      
      public var mGrid:Array;
      
      public var mUpdateRequired:Boolean;
      
      public var mNumberOfFriendlyTiles:int;
      
      public var mMapSetupData:Object;
      
      public function MapData()
      {
         super();
      }
      
      private static function initArrays() : void
      {
         var _loc1_:Object = null;
         var _loc2_:String = null;
         var _loc3_:Object = GameState.mConfig.TileType;
         TILES_PASSABILITY = new Array();
         TILES_MAP_TYPE = new Array();
         SHORETILES_TYPE = new Array();
         for each(_loc1_ in _loc3_)
         {
            TILES_PASSABILITY[_loc1_.ID] = TILE_PASSABILITY_STRING_TO_ID[_loc1_.Passability.ID];
            if(TILES_PASSABILITY[_loc1_.ID] == TILE_SHORE)
            {
               SHORETILES_TYPE[_loc1_.ID] = _loc1_.ShoreType;
            }
            _loc2_ = String(_loc1_.MapType.ID);
            if(_loc2_ == "Grassland")
            {
               TILES_MAP_TYPE[_loc1_.ID] = TILE_MAP_TYPE_GRASSLANDS;
            }
            else if(_loc2_ == "Desert")
            {
               TILES_MAP_TYPE[_loc1_.ID] = TILE_MAP_TYPE_DESERT;
            }
            else if(_loc2_ == "Snow")
            {
               TILES_MAP_TYPE[_loc1_.ID] = TILE_MAP_TYPE_SNOW;
            }
         }
      }
      
      public static function isTilePassable(param1:int) : Boolean
      {
         return TILES_PASSABILITY[param1] == TILE_LAND;
      }
      
      public function initFromServer(param1:ServerCall) : void
      {
         var _loc12_:int = 0;
         var _loc13_:String = null;
         var _loc2_:int = 0;
         var _loc3_:String = null;
         var _loc4_:Array = null;
         var _loc5_:GridCell = null;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         if(!param1)
         {
            this.initOfflineMap("Home",false);
         }
         initArrays();
         this.mUpdateRequired = true;
         var _loc8_:Object = GameState.mConfig;
         var _loc9_:DCResourceManager = DCResourceManager.getInstance();
         var _loc10_:String = null;
         if(param1.mData.map_id)
         {
            _loc10_ = String(param1.mData.map_id);
         }
         else if(param1.mData.tutor_map)
         {
            _loc10_ = "Tutor";
         }
         else
         {
            _loc10_ = "Home";
         }
         var _loc11_:Object = _loc8_.MapSetup[_loc10_];
         this.mMapSetupData = _loc11_;
         _loc13_ = String(_loc11_.TilemapFileName);
         _loc12_ = int(_loc13_.lastIndexOf("."));
         if(_loc12_ > 0)
         {
            if(EXTENSIONS_TO_REMOVE_FROM_NAME.indexOf(_loc13_.substr(_loc13_.lastIndexOf("."))) >= 0)
            {
               _loc13_ = _loc13_.substring(0,_loc13_.lastIndexOf("."));
            }
         }
         _loc3_ = _loc9_.get(_loc13_);
         this.mGridWidth = _loc11_.Width;
         this.mGridHeight = _loc11_.Height;
         if(FeatureTuner.LOAD_TILE_MAP_CSV)
         {
            _loc4_ = _loc3_.split(",");
         }
         _loc2_ = this.mGridWidth * this.mGridHeight;
         this.mGrid = new Array(_loc2_);
         var _loc14_:int = 0;
         while(_loc14_ < this.mGrid.length)
         {
            _loc5_ = new GridCell(_loc14_ % this.mGridWidth,_loc14_ / this.mGridWidth);
            _loc5_.mWalkable = false;
            if(FeatureTuner.LOAD_TILE_MAP_CSV)
            {
               _loc5_.mType = _loc4_[_loc14_];
               if(TILES_PASSABILITY[_loc4_[_loc14_]] == TILE_SHORE)
               {
                  _loc5_.mShoreType = SHORETILES_TYPE[_loc4_[_loc14_]];
               }
               if(isTilePassable(_loc4_[_loc14_]))
               {
                  _loc5_.mOwner = TILE_OWNER_ENEMY;
               }
               else
               {
                  _loc5_.mOwner = TILE_OWNER_NEUTRAL;
               }
            }
            else
            {
               _loc5_.mOwner = TILE_OWNER_ENEMY;
            }
            this.mGrid[_loc14_] = _loc5_;
            _loc14_++;
         }
         var _loc15_:Array = param1.mData.player_tiles;
         var _loc16_:int = 0;
         while(_loc16_ < _loc15_.length)
         {
            _loc6_ = int((_loc15_[_loc16_] as Object).coord_x);
            _loc7_ = int((_loc15_[_loc16_] as Object).coord_y);
            (this.mGrid[_loc7_ * this.mGridWidth + _loc6_] as GridCell).mOwner = TILE_OWNER_FRIENDLY;
            _loc16_++;
         }
         this.countFriendlyTiles();
      }
      
      public function initOfflineMap(param1:String, param2:Boolean = true) : void
      {
         var _loc10_:int = 0;
         var _loc11_:String = null;
         var _loc3_:int = 0;
         var _loc4_:String = null;
         var _loc5_:Array = null;
         var _loc6_:GridCell = null;
         initArrays();
         this.mUpdateRequired = true;
         var _loc7_:Object = GameState.mConfig;
         var _loc8_:DCResourceManager = DCResourceManager.getInstance();
         var _loc9_:Object = _loc7_.MapSetup[param1];
         this.mMapSetupData = _loc9_;
         _loc11_ = String(_loc9_.TilemapFileName);
         _loc10_ = int(_loc11_.lastIndexOf("."));
         if(_loc10_ > 0)
         {
            if(EXTENSIONS_TO_REMOVE_FROM_NAME.indexOf(_loc11_.substr(_loc11_.lastIndexOf("."))) >= 0)
            {
               _loc11_ = _loc11_.substring(0,_loc11_.lastIndexOf("."));
            }
         }
         _loc4_ = _loc8_.get(_loc11_);
         this.mGridWidth = _loc9_.Width;
         this.mGridHeight = _loc9_.Height;
         if(FeatureTuner.LOAD_TILE_MAP_CSV)
         {
            _loc5_ = _loc4_.split(",");
         }
         _loc3_ = this.mGridWidth * this.mGridHeight;
         this.mGrid = new Array(_loc3_);
         var _loc12_:int = 0;
         while(_loc12_ < this.mGrid.length)
         {
            _loc6_ = new GridCell(_loc12_ % this.mGridWidth,_loc12_ / this.mGridWidth);
            _loc6_.mWalkable = false;
            if(FeatureTuner.LOAD_TILE_MAP_CSV)
            {
               _loc6_.mType = _loc5_[_loc12_];
               if(TILES_PASSABILITY[_loc5_[_loc12_]] == TILE_SHORE)
               {
                  _loc6_.mShoreType = SHORETILES_TYPE[_loc5_[_loc12_]];
               }
               if(isTilePassable(_loc5_[_loc12_]))
               {
                  if(GameState.mInstance.mState == GameState.STATE_PVP)
                  {
                     _loc6_.mOwner = TILE_OWNER_FRIENDLY;
                  }
                  else
                  {
                     _loc6_.mOwner = TILE_OWNER_ENEMY;
                  }
               }
               else
               {
                  _loc6_.mOwner = TILE_OWNER_NEUTRAL;
               }
            }
            else
            {
               _loc6_.mOwner = param2 ? TILE_OWNER_FRIENDLY : TILE_OWNER_ENEMY;
            }
            this.mGrid[_loc12_] = _loc6_;
            _loc12_++;
         }
         if(this.mGrid.length > 1)
         {
            if(param1 == "Home")
            {
               (this.mGrid[4601] as GridCell).mOwner = 1;
               (this.mGrid[4602] as GridCell).mOwner = 1;
               (this.mGrid[4670] as GridCell).mOwner = 1;
               (this.mGrid[4671] as GridCell).mOwner = 1;
               (this.mGrid[4673] as GridCell).mOwner = 1;
               (this.mGrid[4674] as GridCell).mOwner = 1;
               (this.mGrid[4740] as GridCell).mOwner = 1;
               (this.mGrid[4741] as GridCell).mOwner = 1;
               (this.mGrid[4742] as GridCell).mOwner = 1;
               (this.mGrid[4743] as GridCell).mOwner = 1;
               (this.mGrid[4744] as GridCell).mOwner = 1;
               (this.mGrid[4810] as GridCell).mOwner = 1;
               (this.mGrid[4811] as GridCell).mOwner = 1;
               (this.mGrid[4812] as GridCell).mOwner = 1;
               (this.mGrid[4813] as GridCell).mOwner = 1;
               (this.mGrid[4814] as GridCell).mOwner = 1;
            }
            else if(param1 == "Desert")
            {
               (this.mGrid[4881] as GridCell).mOwner = 1;
               (this.mGrid[4882] as GridCell).mOwner = 1;
               (this.mGrid[4883] as GridCell).mOwner = 1;
               (this.mGrid[4884] as GridCell).mOwner = 1;
            }
            else if(param1 == "Snow")
            {
               (this.mGrid[1963] as GridCell).mOwner = 1;
               (this.mGrid[1964] as GridCell).mOwner = 1;
               (this.mGrid[1965] as GridCell).mOwner = 1;
               (this.mGrid[1962] as GridCell).mOwner = 1;
               (this.mGrid[2013] as GridCell).mOwner = 1;
               (this.mGrid[2014] as GridCell).mOwner = 1;
               (this.mGrid[2015] as GridCell).mOwner = 1;
               (this.mGrid[2016] as GridCell).mOwner = 1;
               (this.mGrid[2064] as GridCell).mOwner = 1;
               (this.mGrid[2065] as GridCell).mOwner = 1;
               (this.mGrid[2066] as GridCell).mOwner = 1;
               (this.mGrid[2067] as GridCell).mOwner = 1;
            }
         }
         this.countFriendlyTiles();
      }
      
      public function destroy() : void
      {
         this.mMapSetupData = null;
      }
      
      public function getType(param1:int, param2:int) : int
      {
         return (this.mGrid[param2 * this.mGridWidth + param1] as GridCell).mType;
      }
      
      public function getShoreType(param1:int, param2:int) : String
      {
         return (this.mGrid[param2 * this.mGridWidth + param1] as GridCell).mShoreType;
      }
      
      public function hasFog(param1:int, param2:int) : Boolean
      {
         return (this.mGrid[param2 * this.mGridWidth + param1] as GridCell).hasFog();
      }
      
      public function isFriendly(param1:int, param2:int) : Boolean
      {
         if(param1 < 0 || param1 >= this.mGridWidth || param2 < 0 || param2 >= this.mGridHeight)
         {
            return false;
         }
         return (this.mGrid[param2 * this.mGridWidth + param1] as GridCell).mOwner == TILE_OWNER_FRIENDLY;
      }
      
      public function getNeighbourUp(param1:GridCell) : GridCell
      {
         if((param1.mPosJ - 1) * this.mGridWidth + param1.mPosI < 0)
         {
            return null;
         }
         return this.mGrid[(param1.mPosJ - 1) * this.mGridWidth + param1.mPosI];
      }
      
      public function getNeighbourDown(param1:GridCell) : GridCell
      {
         if((param1.mPosJ + 1) * this.mGridWidth + param1.mPosI >= this.mGrid.length)
         {
            return null;
         }
         return this.mGrid[(param1.mPosJ + 1) * this.mGridWidth + param1.mPosI];
      }
      
      public function getNeighbourLeft(param1:GridCell) : GridCell
      {
         if(param1.mPosI % this.mGridWidth == 0)
         {
            return null;
         }
         return this.mGrid[param1.mPosJ * this.mGridWidth + (param1.mPosI - 1)];
      }
      
      public function getNeighbourRight(param1:GridCell) : GridCell
      {
         if(param1.mPosI % this.mGridWidth == this.mGridWidth - 1)
         {
            return null;
         }
         return this.mGrid[param1.mPosJ * this.mGridWidth + (param1.mPosI + 1)];
      }
      
      public function countFriendlyTiles() : void
      {
         var _loc1_:int = 0;
         var _loc2_:GameState = GameState.mInstance;
         if(!_loc2_.visitingFriend())
         {
            if(_loc2_.mCurrentMapId == "Home")
            {
               this.mNumberOfFriendlyTiles = 0;
               _loc1_ = 0;
               while(_loc1_ < this.mGrid.length)
               {
                  if((this.mGrid[_loc1_] as GridCell).mOwner == MapData.TILE_OWNER_FRIENDLY)
                  {
                     ++this.mNumberOfFriendlyTiles;
                  }
                  _loc1_++;
               }
            }
         }
      }
   }
}

