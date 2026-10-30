package game.utils
{
   import com.dchoc.utils.Cookie;
   import game.characters.EnemyUnit;
   import game.characters.PlayerUnit;
   import game.gameElements.Production;
   import game.isometric.GridCell;
   import game.items.ItemManager;
   import game.missions.MissionManager;
   import game.net.ServerCall;
   import game.sound.ArmySoundManager;
   import game.states.GameState;
   
   public class OfflineSave
   {
      
      public static var mMaps:* = {};
      
      public static var mMissions:* = {};
      
      mMissions["missions_incomplete"] = [];
      mMissions["missions_all_complete"] = [];
      mMissions["missions_finished"] = [];
      
      public var mSwitchingMap:Boolean = false;
      
      public function OfflineSave()
      {
         super();
      }
      
      public static function generateGamefieldJson() : *
      {
         var _loc11_:* = undefined;
         var _loc1_:GridCell = null;
         var _loc2_:* = {};
         var _loc3_:* = {};
         var _loc4_:* = {};
         var _loc5_:* = [];
         var _loc6_:* = [];
         var _loc7_:* = [];
         var _loc8_:Production = undefined;
         var _loc9_:Array = undefined;
         var _loc10_:int = 0;
         var _loc12_:* = "";
         var _loc13_:* = GameState.mInstance.mMapData.mGrid;
         var _loc14_:* = {};
         _loc10_ = 0;
         while(_loc10_ < _loc13_.length)
         {
            if(_loc13_[_loc10_]["mOwner"] == 1)
            {
               _loc2_ = {};
               _loc2_["coord_x"] = _loc13_[_loc10_]["mPosI"];
               _loc2_["coord_y"] = _loc13_[_loc10_]["mPosJ"];
               _loc5_.push(_loc2_);
            }
            if(_loc13_[_loc10_]["mCharacter"])
            {
               _loc3_ = {};
               _loc3_["coord_x"] = _loc13_[_loc10_]["mPosI"];
               _loc3_["coord_y"] = _loc13_[_loc10_]["mPosJ"];
               if(_loc13_[_loc10_]["mCharacter"]["mItem"])
               {
                  _loc3_["item_id"] = _loc13_[_loc10_]["mCharacter"]["mItem"]["mId"];
                  _loc3_["item_type"] = ItemManager.getTableNameForItem(_loc13_[_loc10_]["mCharacter"]["mItem"]);
                  if(_loc13_[_loc10_]["mCharacter"] is EnemyUnit)
                  {
                     _loc3_["next_action_at"] = Math.round(_loc13_[_loc10_]["mCharacter"]["mReactionStateCounter"] / 1000);
                     _loc3_["activation_time"] = _loc13_[_loc10_]["mCharacter"].getActivationTimeInMinutes();
                  }
                  else if(_loc13_[_loc10_]["mCharacter"] is PlayerUnit)
                  {
                     _loc3_["next_action_at"] = Math.round(_loc13_[_loc10_]["mCharacter"].getDyingTimer() / 1000);
                     _loc3_["activation_time"] = 0;
                  }
                  else
                  {
                     _loc3_["activation_time"] = 0;
                  }
                  _loc3_["item_hit_points"] = _loc13_[_loc10_]["mCharacter"]["mHealth"];
                  _loc6_.push(_loc3_);
               }
            }
            if(_loc13_[_loc10_]["mObject"])
            {
               _loc4_ = {};
               if(_loc13_[_loc10_]["mObject"]["mItem"])
               {
                  _loc4_["item_id"] = _loc13_[_loc10_]["mObject"]["mItem"]["mId"];
                  _loc4_["item_type"] = ItemManager.getTableNameForItem(_loc13_[_loc10_]["mObject"]["mItem"]);
                  if(_loc4_["item_type"] == "HomeFrontEffort")
                  {
                     if(_loc13_[_loc10_]["mObject"]["mState"] == 3)
                     {
                        _loc4_["crop_state"] = "growing";
                        _loc8_ = _loc13_[_loc10_]["mObject"].getProduction();
                        _loc4_["next_action_at"] = Math.round(_loc8_.getProducingTimeLeft() / 1000);
                     }
                     else if(_loc13_[_loc10_]["mObject"]["mState"] == 4)
                     {
                        _loc4_["crop_state"] = "ready";
                        _loc8_ = _loc13_[_loc10_]["mObject"].getProduction();
                        _loc4_["next_action_at"] = Math.round(_loc8_.getTimeToWither() / 1000);
                     }
                  }
                  else if(_loc4_["item_type"] == "Building")
                  {
                     if(_loc13_[_loc10_]["mObject"]["mState"] == 3)
                     {
                        _loc8_ = _loc13_[_loc10_]["mObject"].getProduction();
                        _loc4_["produces"] = "HFEDrives." + _loc8_.getProductionID();
                        _loc4_["next_action_at"] = Math.round(_loc8_.getProducingTimeLeft() / 1000);
                     }
                     else if(_loc13_[_loc10_]["mObject"]["mState"] == 4)
                     {
                        _loc8_ = _loc13_[_loc10_]["mObject"].getProduction();
                        _loc4_["produces"] = "HFEDrives." + _loc8_.getProductionID();
                        _loc4_["next_action_at"] = 0;
                     }
                     else if(_loc13_[_loc10_]["mObject"]["mState"] >= 9 && _loc13_[_loc10_]["mObject"]["mState"] <= 12)
                     {
                        _loc4_["status"] = "SETUP";
                        _loc4_["clicks"] = _loc13_[_loc10_]["mObject"].getBuildingStepsDone();
                     }
                  }
                  else if(_loc4_["item_type"] == "ResourceBuilding")
                  {
                     if(_loc13_[_loc10_]["mObject"]["mState"] == 3)
                     {
                        _loc8_ = _loc13_[_loc10_]["mObject"].getProduction();
                        _loc4_["produces"] = "HFEDrives." + _loc8_.getProductionID();
                        _loc4_["next_action_at"] = Math.round(_loc8_.getProducingTimeLeft() / 1000);
                        _loc9_ = _loc13_[_loc10_]["mObject"].getHelpingFriends();
                        _loc11_ = 0;
                        _loc12_ = "";
                        for(_loc11_ in _loc9_)
                        {
                           _loc12_ = _loc12_ + _loc9_[_loc11_] + ",";
                        }
                        _loc4_["helping_friend_ids"] = _loc12_.slice(0,-1);
                     }
                     else if(_loc13_[_loc10_]["mObject"]["mState"] == 4)
                     {
                        _loc8_ = _loc13_[_loc10_]["mObject"].getProduction();
                        _loc4_["produces"] = "HFEDrives." + _loc8_.getProductionID();
                        _loc4_["next_action_at"] = 0;
                        _loc9_ = _loc13_[_loc10_]["mObject"].getHelpingFriends();
                        _loc11_ = 0;
                        _loc12_ = "";
                        for(_loc11_ in _loc9_)
                        {
                           _loc12_ = _loc12_ + _loc9_[_loc11_] + ",";
                        }
                        _loc4_["helping_friend_ids"] = _loc12_.slice(0,-1);
                     }
                     else if(_loc13_[_loc10_]["mObject"]["mState"] >= 9 && _loc13_[_loc10_]["mObject"]["mState"] <= 12)
                     {
                        _loc4_["status"] = "SETUP";
                        _loc4_["clicks"] = _loc13_[_loc10_]["mObject"].getBuildingStepsDone();
                     }
                  }
                  else if(_loc4_["item_type"] == "PermanentHFE")
                  {
                     if(_loc13_[_loc10_]["mObject"]["mState"] == 3)
                     {
                        _loc8_ = _loc13_[_loc10_]["mObject"].getProduction();
                        _loc4_["produces"] = "HFEDrives." + _loc8_.getProductionID();
                        _loc4_["next_action_at"] = Math.round(_loc8_.getProducingTimeLeft() / 1000);
                     }
                     else if(_loc13_[_loc10_]["mObject"]["mState"] == 4)
                     {
                        _loc8_ = _loc13_[_loc10_]["mObject"].getProduction();
                        _loc4_["produces"] = "HFEDrives." + _loc8_.getProductionID();
                        _loc4_["next_action_at"] = 0;
                     }
                  }
                  else if(_loc4_["item_type"] == "HospitalBuilding")
                  {
                     _loc4_["next_action_at"] = Math.round(_loc13_[_loc10_]["mObject"].getRefillTimer() / 1000);
                  }
                  _loc4_["activation_time"] = 0;
                  _loc4_["item_hit_points"] = _loc13_[_loc10_]["mObject"].getHealth();
                  _loc1_ = _loc13_[_loc10_]["mObject"].getCell();
                  _loc4_["coord_x"] = _loc1_["mPosI"];
                  _loc4_["coord_y"] = _loc1_["mPosJ"];
                  if(_loc7_.indexOf(String(_loc4_["coord_x"]) + String(_loc4_["coord_y"])) == -1)
                  {
                     _loc7_.push(String(_loc4_["coord_x"]) + String(_loc4_["coord_y"]));
                     _loc6_.push(_loc4_);
                  }
               }
            }
            _loc14_["player_tiles"] = _loc5_;
            _loc14_["gamefield_items"] = _loc6_;
            _loc14_["map_id"] = GameState.mInstance.mCurrentMapId;
            _loc10_++;
         }
         return _loc14_;
      }
      
      public static function generateProfileJson() : *
      {
         var _loc11_:* = undefined;
         var _loc1_:* = 0;
         var _loc2_:* = 0;
         var _loc3_:* = {};
         var _loc4_:* = GameState.mInstance.mPlayerProfile;
         _loc3_["gained_free_units"] = 0;
         _loc3_["recently_gifted_energy_to"] = "";
         _loc3_["recently_gifted_supplies_to"] = "";
         _loc3_["wishlist"] = [];
         _loc3_["resource_experience"] = _loc4_["mXp"];
         _loc3_["resource_money"] = _loc4_["mMoney"];
         _loc3_["resource_premium"] = _loc4_["mPremium"];
         _loc3_["resource_energy"] = _loc4_["mEnergy"];
         _loc3_["resource_supplies"] = _loc4_["mSupplies"];
         _loc3_["resource_material"] = _loc4_["mMaterial"];
         _loc3_["resource_socialxp"] = _loc4_["mSocialXp"];
         _loc3_["resource_water"] = _loc4_["mWater"];
         _loc3_["supply_cap"] = _loc4_["mSuppliesCap"];
         _loc3_["secs_to_energy_gain"] = _loc4_["mSecondsToRechargeEnergy"];
         _loc3_["reward_drop_seed_term"] = _loc4_["mRewardDropSeedTerm"];
         _loc3_["reward_drops_counter"] = _loc4_["mRewardDropsCounter"];
         _loc3_["energy_cap"] = _loc4_["mMaxEnergy"];
         _loc3_["energy_recharge_time"] = _loc4_["mTimeBetweenEnergyRecharges"];
         _loc3_["resource_energy_percentiles"] = _loc4_.getEnergyRewardCounter();
         _loc3_["resource_energy_percentiles"] = _loc4_.getEnergyRewardCounter();
         _loc3_["secs_since_last_enemy_spawn"] = Math.round(Number(GameState.mInstance.getSpawnEnemyTimer()) / 1000);
         _loc2_ = 0;
         var _loc5_:int = 0;
         var _loc6_:Array = [];
         var _loc7_:* = GameState.mInstance.mPlayerProfile.mInventory.getInventory();
         var _loc8_:Array = [];
         var _loc9_:* = {};
         var _loc10_:int = 0;
         for(_loc2_ in _loc7_)
         {
            _loc6_ = _loc7_[_loc2_];
            _loc5_ = 0;
            while(_loc5_ < _loc6_.length)
            {
               _loc9_ = {};
               _loc9_["item_id"] = _loc6_[_loc5_]["mId"];
               if(_loc6_[_loc5_]["mType"] == "Area")
               {
                  _loc9_["item_type"] = "MapArea";
               }
               else if(_loc6_[_loc5_]["mType"] == "Infantry" || _loc6_[_loc5_]["mType"] == "Armor" || _loc6_[_loc5_]["mType"] == "Artillery" || _loc6_[_loc5_]["mType"] == "Lab")
               {
                  _loc9_["item_type"] = "PlayerUnit";
               }
               else
               {
                  _loc9_["item_type"] = _loc6_[_loc5_]["mType"];
               }
               _loc5_++;
               _loc10_ = int(_loc6_[_loc5_]);
               _loc9_["item_count"] = _loc10_;
               _loc8_.push(_loc9_);
               _loc5_++;
            }
         }
         _loc3_["inventory_items"] = _loc8_;
         _loc11_ = {};
         _loc11_["score"] = _loc4_["mBadassXp"];
         _loc11_["wins"] = _loc4_["mBadassWins"];
         _loc3_["pvp_data"] = _loc11_;
         return _loc3_;
      }
      
      internal static function getIndexByName(param1:Array, param2:String) : int
      {
         var _loc3_:int = 0;
         while(_loc3_ < param1.length)
         {
            if(param1[_loc3_].mission_id == param2)
            {
               return _loc3_;
            }
            _loc3_++;
         }
         return -1;
      }
      
      public static function generateMissionJson() : *
      {
         var _loc1_:Array = undefined;
         var _loc2_:* = 0;
         var _loc3_:* = 0;
         var _loc4_:* = {};
         var _loc5_:* = {};
         var _loc6_:Array = [];
         var _loc7_:* = {};
         _loc7_["missions_incomplete"] = [];
         _loc7_["missions_all_complete"] = [];
         _loc7_["missions_finished"] = [];
         _loc6_ = MissionManager.getMissions();
         for(_loc2_ in _loc6_)
         {
            _loc4_ = {};
            if(_loc6_[_loc2_]["mState"] == 1)
            {
               _loc4_["mission_id"] = _loc6_[_loc2_]["mId"];
               _loc1_ = _loc6_[_loc2_].getObjectives();
               _loc4_["objectives"] = [];
               _loc3_ = 0;
               for(_loc3_ in _loc1_)
               {
                  _loc5_ = {};
                  _loc5_["objectiveId"] = _loc1_[_loc3_]["mId"];
                  _loc5_["startValue"] = 0;
                  _loc5_["goal"] = _loc1_[_loc3_]["mGoal"];
                  _loc5_["counterValue"] = _loc1_[_loc3_]["mCounter"];
                  _loc5_["purchased"] = _loc1_[_loc3_]["mPurchased"];
                  _loc4_["objectives"].push(_loc5_);
               }
               _loc7_["missions_incomplete"].push(_loc4_);
            }
            else if(_loc6_[_loc2_]["mState"] == 2)
            {
               _loc4_["mission_id"] = _loc6_[_loc2_]["mId"];
               _loc7_["missions_all_complete"].push(_loc4_);
            }
            else if(_loc6_[_loc2_]["mState"] == 3)
            {
               _loc4_["mission_id"] = _loc6_[_loc2_]["mId"];
               _loc7_["missions_finished"].push(_loc4_);
            }
         }
         return _loc7_;
      }
      
      public static function saveOldMap() : void
      {
         var _loc1_:String = GameState.mInstance.mCurrentMapId;
         if(_loc1_.indexOf("pvp_") == -1)
         {
            mMaps[_loc1_] = {
               "map_name":_loc1_,
               "map_data":generateGamefieldJson()
            };
         }
         mMissions = generateMissionJson();
      }
      
      public static function switchMap() : void
      {
         var _loc1_:String = GameState.mInstance.mCurrentMapId;
         GameState.mInstance.mLoadingStatesOver = false;
         GameState.mInstance.mCurrentMapGraphicsId = Math.max(GameState.GRAPHICS_MAP_ID_LIST.indexOf(_loc1_),0);
         GameState.mInstance.mPlayerProfile.mInventory.getAreas();
         GameState.mInstance.changeState(0);
         GameState.mInstance.mMapData.destroy();
         var _loc2_:* = new ServerCall("GetMapData",null,null,null);
         _loc2_["mData"] = mMissions;
         if(mMaps[_loc1_])
         {
            _loc2_["mData"]["missions_incomplete"] = mMissions["missions_incomplete"];
            GameState.mInstance.initObjects(null);
            loadMap(mMaps[_loc1_]);
         }
         else
         {
            GameState.mInstance.initObjects(null);
            GameState.mInstance.initMap(null,_loc1_);
         }
         GameState.mInstance.updateGrid();
         GameState.mInstance.mScene.mFog.init();
         MissionManager.initialize();
         GameState.mInstance.mMissionIconsManager.reset();
         MissionManager.setupFromServer(_loc2_);
         MissionManager.findNewActiveMissions();
         if(_loc1_ == "Desert")
         {
            (GameState.mInstance.getMainClip() as GameMain).changeDiscordMap("Desert");
            GameState.mInstance.mHUD.changeWaterVisibility(true);
         }
         else if(_loc1_ == "Home")
         {
            (GameState.mInstance.getMainClip() as GameMain).changeDiscordMap("Homeland");
            GameState.mInstance.mHUD.changeWaterVisibility(false);
         }
         GameState.mInstance.mLoadingStatesOver = true;
      }
      
      public static function generateSaveJson() : *
      {
         var _loc3_:String = null;
         var _loc4_:Date = null;
         var _loc1_:String = GameState.mInstance.mCurrentMapId;
         if(_loc1_.indexOf("pvp_") == -1)
         {
            mMaps[_loc1_] = {
               "map_name":_loc1_,
               "map_data":generateGamefieldJson(),
               "last_camera_position":Cookie.readCookieVariable(Config.COOKIE_SESSION_NAME,Config.COOKIE_SESSION_NAME_CAM_POS + "_" + _loc1_)
            };
         }
         var _loc2_:* = {};
         _loc2_ = generateMissionJson();
         _loc2_["profile"] = generateProfileJson();
         _loc2_["maps"] = [];
         for(_loc3_ in mMaps)
         {
            _loc2_["maps"].push(mMaps[_loc3_]);
         }
         _loc2_["isFogOfWarOff"] = GameState.mInstance.isFogOfWarOn();
         _loc4_ = new Date();
         _loc2_["time_of_last_save"] = _loc4_.valueOf();
         _loc2_["saveversion"] = 5;
         return _loc2_;
      }
      
      public static function fixOldSave(param1:*, param2:int) : *
      {
         var _loc3_:* = undefined;
         var _loc4_:* = undefined;
         var _loc5_:* = undefined;
         var _loc6_:* = undefined;
         var _loc7_:* = undefined;
         if(param2 < 3)
         {
            param1["isFogOfWarOff"] = true;
         }
         if(param2 < 4)
         {
            param1["maps"] = [];
            _loc3_ = {};
            _loc3_["map_name"] = "Home";
            _loc3_["secs_since_last_enemy_spawn"] = param1["profile"]["secs_since_last_enemy_spawn"];
            _loc4_ = {};
            _loc4_["player_tiles"] = param1["player_tiles"];
            _loc4_["gamefield_items"] = param1["gamefield_items"];
            _loc4_["map_id"] = "Home";
            _loc3_["map_data"] = _loc4_;
            param1["maps"].push(_loc3_);
            delete param1["profile"]["player_tiles"];
            delete param1["profile"]["gamefield_items"];
            delete param1["secs_since_last_enemy_spawn"];
         }
         if(param2 < 5)
         {
            param1["profile"]["pvp_data"] = {};
            param1["profile"]["pvp_data"]["wins"] = 0;
            param1["profile"]["pvp_data"]["score"] = 0;
            _loc5_ = 0;
            for(_loc5_ in param1["maps"])
            {
               param1["maps"][_loc5_]["last_camera_position"] = "";
            }
            _loc5_ = 0;
            for(_loc5_ in param1["maps"])
            {
               _loc7_ = 0;
               for(_loc7_ in param1["maps"][_loc5_]["map_data"]["gamefield_items"])
               {
                  _loc6_ = param1["maps"][_loc5_]["map_data"]["gamefield_items"][_loc7_];
                  if(_loc6_["coord_x"] == 0 && _loc6_["coord_y"] == 0)
                  {
                     param1["maps"][_loc5_]["map_data"]["gamefield_items"].splice(_loc7_,1);
                  }
               }
            }
         }
         return param1;
      }
      
      public static function updateMapTimers(param1:*, param2:*) : *
      {
         var _loc3_:* = 0;
         for(_loc3_ in param1["map_data"]["gamefield_items"])
         {
            if(param1["map_data"]["gamefield_items"][_loc3_]["next_action_at"] != null)
            {
               param1["map_data"]["gamefield_items"][_loc3_]["next_action_at"] -= param2;
               param1["map_data"]["gamefield_items"][_loc3_]["time_into_wither"] = -1;
               if(param1["map_data"]["gamefield_items"][_loc3_]["next_action_at"] < 0)
               {
                  param1["map_data"]["gamefield_items"][_loc3_]["time_into_wither"] = Math.abs(param1["map_data"]["gamefield_items"][_loc3_]["next_action_at"]);
                  param1["map_data"]["gamefield_items"][_loc3_]["next_action_at"] = 0;
               }
            }
            if(param1["map_data"]["gamefield_items"][_loc3_]["activation_time"] != 0)
            {
               param1["map_data"]["gamefield_items"][_loc3_]["activation_time"] -= param2;
               if(param1["map_data"]["gamefield_items"][_loc3_]["activation_time"] < 0)
               {
                  param1["map_data"]["gamefield_items"][_loc3_]["activation_time"] = 0;
               }
            }
         }
         return param1;
      }
      
      public static function selectMissionsByMap(param1:*, param2:String) : Array
      {
         var _loc5_:* = undefined;
         var _loc3_:* = 0;
         var _loc4_:Array = [];
         for(_loc3_ in param1)
         {
            _loc5_ = MissionManager.getMission(param1[_loc3_]["mission_id"]);
            if(_loc5_)
            {
               if(_loc5_.mMapId == param2)
               {
                  _loc4_.push(param1[_loc3_]);
               }
            }
         }
         return _loc4_;
      }
      
      public static function calculateGlobalUnits(param1:*) : Array
      {
         var _loc4_:String = null;
         var _loc7_:* = undefined;
         var _loc8_:* = undefined;
         var _loc9_:int = 0;
         var _loc2_:Array = [];
         var _loc3_:Array = [];
         var _loc5_:Array = [];
         var _loc6_:* = {};
         _loc7_ = 0;
         for(_loc7_ in param1)
         {
            _loc8_ = 0;
            for(_loc8_ in param1[_loc7_]["map_data"]["gamefield_items"])
            {
               if(param1[_loc7_]["map_data"]["gamefield_items"][_loc8_]["item_type"] == "PlayerUnit")
               {
                  _loc4_ = param1[_loc7_]["map_data"]["gamefield_items"][_loc8_]["item_id"];
                  _loc9_ = int(_loc3_.indexOf(_loc4_));
                  if(_loc9_ == -1)
                  {
                     _loc3_.push(_loc4_);
                     _loc2_.push(1);
                  }
                  else
                  {
                     _loc2_[_loc9_] += 1;
                  }
               }
            }
         }
         _loc7_ = 0;
         for(_loc7_ in _loc3_)
         {
            _loc6_ = {};
            _loc6_["item_id"] = _loc3_[_loc7_];
            _loc6_["item_count"] = _loc2_[_loc7_];
            _loc5_.push(_loc6_);
         }
         return _loc5_;
      }
      
      public static function startEmptyPvPProgress() : void
      {
         var _loc1_:* = {};
         var _loc2_:* = {};
         _loc2_["score"] = 0;
         _loc2_["wins"] = 0;
         _loc1_["pvp_data"] = _loc2_;
         _loc1_["allies"] = new Array();
         var _loc3_:Array = GameState.mPvPOpponentsConfig["pvp_opponents"];
         _loc1_["possible_opponents"] = _loc3_;
         _loc1_["recent_attacks"] = new Array();
         saveOldMap();
         _loc1_["player_unit_count"] = calculateGlobalUnits(mMaps);
         GameState.mInstance.mPlayerProfile.setupPvPData(_loc1_);
         GameState.mInstance.mPlayerProfile.setupGlobalUnitCounts(_loc1_);
      }
      
      public static function loadMap(param1:*) : void
      {
         var _loc2_:* = new ServerCall("GetMapData",null,null,null);
         _loc2_["mData"] = param1["map_data"];
         GameState.mInstance.initMap(_loc2_,GameState.mInstance.mCurrentMapId);
         GameState.mInstance.initObjects(_loc2_);
      }
      
      public static function loadProgress(param1:*) : void
      {
         var _loc15_:* = undefined;
         var _loc16_:Array = null;
         var _loc2_:int = int(param1["saveversion"]);
         param1 = fixOldSave(param1,_loc2_);
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:* = undefined;
         var _loc7_:* = undefined;
         var _loc8_:Date = new Date();
         var _loc9_:int = Math.round(_loc8_.valueOf() / 1000);
         var _loc10_:int = Math.round(Number(param1["time_of_last_save"]) / 1000);
         var _loc11_:* = _loc9_ - _loc10_;
         param1["profile"]["secs_since_last_enemy_spawn"] += _loc11_;
         if(param1["profile"]["resource_energy"] < param1["profile"]["energy_cap"])
         {
            if(_loc11_ >= param1["profile"]["secs_to_energy_gain"])
            {
               ++param1["profile"]["resource_energy"];
               if(param1["profile"]["resource_energy"] >= param1["profile"]["energy_cap"])
               {
                  param1["profile"]["resource_energy"] = param1["profile"]["energy_cap"];
                  param1["profile"]["secs_to_energy_gain"] = param1["profile"]["energy_recharge_time"];
               }
               else
               {
                  _loc3_ = _loc11_ - Number(param1["profile"]["secs_to_energy_gain"]);
                  _loc4_ = Math.floor(_loc3_ / Number(param1["profile"]["energy_recharge_time"]));
                  param1["profile"]["resource_energy"] += _loc4_;
                  if(param1["profile"]["resource_energy"] >= param1["profile"]["energy_cap"])
                  {
                     param1["profile"]["resource_energy"] = param1["profile"]["energy_cap"];
                     param1["profile"]["secs_to_energy_gain"] = param1["profile"]["energy_recharge_time"];
                  }
                  else
                  {
                     _loc5_ = _loc4_ * Number(param1["profile"]["energy_recharge_time"]);
                     param1["profile"]["secs_to_energy_gain"] = _loc3_ - _loc5_;
                  }
               }
            }
            else
            {
               param1["profile"]["secs_to_energy_gain"] -= _loc11_;
            }
         }
         else
         {
            param1["profile"]["secs_to_energy_gain"] = param1["profile"]["energy_recharge_time"];
         }
         GameState.mInstance.mCurrentMapId = "Home";
         var _loc12_:* = new ServerCall("GetMapData",null,null,null);
         _loc12_["mData"] = param1;
         var _loc13_:* = new ServerCall("GetUserData",null,null,null);
         _loc13_["mData"] = param1["profile"];
         GameState.mInstance.restoreFogOfWar(param1["isFogOfWarOff"]);
         GameState.mInstance.mLoadingStatesOver = false;
         GameState.mInstance.mCurrentMapGraphicsId = Math.max(GameState.GRAPHICS_MAP_ID_LIST.indexOf(GameState.mInstance.mCurrentMapId),0);
         GameState.mInstance.loadingFirstFinished();
         GameState.mInstance.initPlayerProfile(_loc13_);
         GameState.mInstance.mPlayerProfile.mInventory.getAreas();
         GameState.mInstance.changeState(0);
         GameState.mInstance.mMapData.destroy();
         mMaps = {};
         var _loc14_:* = 0;
         for(_loc14_ in param1["maps"])
         {
            mMaps[param1["maps"][_loc14_]["map_name"]] = updateMapTimers(param1["maps"][_loc14_],_loc11_);
            Cookie.saveCookieVariable(Config.COOKIE_SESSION_NAME,Config.COOKIE_SESSION_NAME_CAM_POS + "_" + param1["maps"][_loc14_]["map_name"],param1["maps"][_loc14_]["last_camera_position"]);
         }
         GameState.mInstance.initObjects(null);
         _loc15_ = {};
         _loc15_["pvp_data"] = param1["profile"]["pvp_data"];
         _loc15_["allies"] = new Array();
         _loc16_ = GameState.mPvPOpponentsConfig["pvp_opponents"];
         _loc15_["possible_opponents"] = _loc16_;
         _loc15_["recent_attacks"] = new Array();
         _loc15_["player_unit_count"] = calculateGlobalUnits(param1["maps"]);
         GameState.mInstance.mPlayerProfile.setupPvPData(_loc15_);
         GameState.mInstance.mPlayerProfile.setupGlobalUnitCounts(_loc15_);
         loadMap(mMaps["Home"]);
         GameState.mInstance.updateGrid();
         GameState.mInstance.mScene.mFog.init();
         mMissions = {};
         mMissions["missions_incomplete"] = param1["missions_incomplete"];
         mMissions["missions_all_complete"] = param1["missions_all_complete"];
         mMissions["missions_finished"] = param1["missions_finished"];
         MissionManager.initialize();
         MissionManager.setupFromServer(_loc12_);
         MissionManager.findNewActiveMissions();
         GameState.mInstance.mLoadingStatesOver = true;
         GameState.mInstance.mCurrentMusic = GameState.mInstance.getMapMusic();
         ArmySoundManager.loadMusic(GameState.mInstance.mCurrentMusic);
         GameState.mInstance.startMusic();
         (GameState.mInstance.getMainClip() as GameMain).changeDiscordMap("Homeland");
         GameState.mInstance.mHUD.changeWaterVisibility(false);
      }
   }
}

