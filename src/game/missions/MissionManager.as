package game.missions
{
   import com.dchoc.utils.Cookie;
   import game.magicBox.MagicBoxTracker;
   import game.net.ServerCall;
   import game.net.ServiceIDs;
   import game.player.RankManager;
   import game.states.GameState;
   
   public class MissionManager
   {
      
      private static var mMissions:Array;
      
      private static var mCompletedMissionsGlobal:Array;
      
      private static var mOrderedMissions:Array;
      
      private static var mCompletedMissions:Array;
      
      public static var smFindNewMissionsPending:Boolean;
      
      public static var mBuildingNeedtoOpen:Boolean;
      
      public static var mInventoryNeedtoOpen:Boolean;
      
      private static var mCompletedCOsWithMissions:Array;
      
      private static var smNodes:Array;
      
      public static var smIsModalMissionActive:int = -1;
      
      public function MissionManager()
      {
         super();
      }
      
      public static function initialize() : void
      {
         var _loc1_:* = undefined;
         var _loc2_:* = null;
         var _loc3_:* = GameState.mConfig.Mission;
         mMissions = new Array();
         mOrderedMissions = new Array();
         mCompletedMissions = new Array();
         mCompletedCOsWithMissions = new Array();
         mCompletedMissionsGlobal = new Array();
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         for(_loc2_ in _loc3_)
         {
            mMissions[_loc5_] = new Mission(_loc3_[_loc2_]);
            var _loc6_:*;
            mOrderedMissions[_loc6_ = _loc1_ = _loc4_++] = mMissions[_loc5_];
            _loc5_++;
         }
         mOrderedMissions.sort(sortMissions);
      }
      
      public static function clearAllMissions() : void
      {
         mMissions = new Array();
         mOrderedMissions = new Array();
         mCompletedMissions = new Array();
         mCompletedCOsWithMissions = new Array();
         mCompletedMissionsGlobal = new Array();
         smNodes = new Array();
      }
      
      private static function sortMissions(param1:Mission, param2:Mission) : int
      {
         if(param1.mType == Mission.TYPE_CAMPAIGN)
         {
            return -1;
         }
         if(param2.mType == Mission.TYPE_CAMPAIGN)
         {
            return 1;
         }
         if(param1.mTitle < param2.mTitle || param2.mTitle == null)
         {
            return -1;
         }
         if(param1.mTitle > param2.mTitle || param1.mTitle == null)
         {
            return 1;
         }
         return 0;
      }
      
      public static function findNewActiveMissions() : void
      {
         var _loc1_:Mission = null;
         var _loc2_:Mission = null;
         var _loc3_:Boolean = false;
         var _loc4_:* = null;
         var _loc5_:* = null;
         if(isTutorialCompleted() || Config.CHEAT_SKIP_TUTORIAL)
         {
            for each(_loc2_ in mMissions)
            {
               if(_loc2_.mId == "SelectUnit" || _loc2_.mId == "MoveUnit" || _loc2_.mId == "DestroyEnemy" || _loc2_.mId == "SelectRepair" || _loc2_.mId == "Repair" || _loc2_.mId == "GetSupplies" || _loc2_.mId == "CollectSupplies" || _loc2_.mId == "CollectSupplies2" || _loc2_.mId == "MissionsInfo" || _loc2_.mId == "FirstScroll")
               {
                  _loc2_.mState = Mission.STATE_REWARDS_COLLECTED;
               }
            }
         }
         for each(_loc1_ in mMissions)
         {
            if(_loc1_.mMapId == GameState.mInstance.mCurrentMapId)
            {
               if(modalMissionActive())
               {
                  smFindNewMissionsPending = true;
                  return;
               }
               _loc3_ = false;
               if(_loc1_.mState == Mission.STATE_INACTIVE)
               {
                  if(_loc1_.mObsolete)
                  {
                     _loc1_.mState = Mission.STATE_REWARDS_COLLECTED;
                     smFindNewMissionsPending = true;
                     return;
                  }
                  for each(_loc4_ in _loc1_.mRequiredMissions)
                  {
                     if(!isCollected(_loc4_))
                     {
                        _loc3_ = true;
                        break;
                     }
                  }
                  if(!_loc3_)
                  {
                     _loc1_.activate();
                     if(smIsModalMissionActive == 0)
                     {
                        smIsModalMissionActive = -1;
                     }
                     GameState.mInstance.mUpdateMissionButtonsPending = true;
                     GameState.mInstance.mServer.serverCallServiceWithParameters(ServiceIDs.ACCEPT_MISSION,{
                        "mission_id":_loc1_.mId,
                        "map_id":_loc1_.mMapId
                     },false);
                     if(Config.DEBUG_MODE)
                     {
                     }
                     MagicBoxTracker.generateEvent(MagicBoxTracker.GROUP_LEVEL,MagicBoxTracker.TYPE_MISSION_ACCEPTED,_loc1_.mId);
                  }
               }
            }
         }
         smFindNewMissionsPending = false;
         checkCompletedMissions();
      }
      
      public static function increaseCounter(param1:String, param2:*, param3:int) : void
      {
         var _loc4_:Mission = null;
         for each(_loc4_ in mMissions)
         {
            if(_loc4_.mState == Mission.STATE_ACTIVE && GameState.mInstance.mLoadingStatesOver)
            {
               if(_loc4_.increaseCounter(param1,param2,param3))
               {
                  GameState.mInstance.checkMissionProgress();
                  checkCompletedMissions();
               }
            }
         }
      }
      
      public static function getNextCompleteCampaignObjective() : Array
      {
         return mCompletedCOsWithMissions.shift();
      }
      
      public static function addCompleteCampaignObjective(param1:Mission, param2:Objective) : void
      {
         mCompletedCOsWithMissions.push([param1,param2]);
      }
      
      public static function isShowMissionButtonCompleted() : Boolean
      {
         var _loc1_:Mission = null;
         var _loc2_:String = null;
         for each(_loc1_ in mMissions)
         {
            if(_loc1_.mId == "COMBAT_S_0_OUTRO")
            {
               return _loc1_.mState == Mission.STATE_REWARDS_COLLECTED;
            }
         }
         for each(_loc2_ in mCompletedMissionsGlobal)
         {
            if("COMBAT_S_0_OUTRO" == _loc2_)
            {
               return true;
            }
         }
         return false;
      }
      
      public static function isMissionCompleted(param1:String) : Boolean
      {
         var _loc2_:Mission = null;
         var _loc3_:String = null;
         for each(_loc2_ in mMissions)
         {
            if(_loc2_.mId == param1)
            {
               return _loc2_.mState == Mission.STATE_REWARDS_COLLECTED;
            }
         }
         for each(_loc3_ in mCompletedMissionsGlobal)
         {
            if(param1 == _loc3_)
            {
               return true;
            }
         }
         return false;
      }
      
      public static function getNumCompletedMissions() : int
      {
         return mCompletedMissions.length;
      }
      
      public static function getNextCompletedMission() : Mission
      {
         if(mCompletedMissions.length > 0)
         {
            return mCompletedMissions.shift();
         }
         return null;
      }
      
      public static function getNumMissions() : int
      {
         return mOrderedMissions.length;
      }
      
      public static function getMissionByIndex(param1:int) : Mission
      {
         return mOrderedMissions[param1];
      }
      
      public static function getMission(param1:String) : Mission
      {
         var _loc2_:int = getMissionIndexFromID(param1);
         if(_loc2_ == -1)
         {
            return null;
         }
         return mMissions[_loc2_] as Mission;
      }
      
      public static function getMissionIndexFromID(param1:String) : int
      {
         var _loc2_:* = undefined;
         var _loc3_:Mission = null;
         var _loc4_:String = GameState.mInstance.mCurrentMapId;
         for(_loc2_ in mMissions)
         {
            _loc3_ = mMissions[_loc2_] as Mission;
            if(_loc3_.mId == param1)
            {
               return _loc2_;
            }
         }
         return -1;
      }
      
      private static function isCollected(param1:*) : Boolean
      {
         var _loc2_:Mission = null;
         if(param1)
         {
            _loc2_ = getMission(param1.ID);
            if(_loc2_)
            {
               return _loc2_.mState == Mission.STATE_REWARDS_COLLECTED;
            }
            return false;
         }
         return true;
      }
      
      public static function modalMissionActive() : Boolean
      {
         var _loc1_:Mission = null;
         if(smIsModalMissionActive >= 0)
         {
            return smIsModalMissionActive == 1;
         }
         for each(_loc1_ in mMissions)
         {
            if(_loc1_.mState == Mission.STATE_ACTIVE && _loc1_.mId == "COMBAT_S_1_OUTRO")
            {
               mBuildingNeedtoOpen = true;
            }
            if(_loc1_.mState == Mission.STATE_ACTIVE && _loc1_.mId == "COMBAT_S_2_OUTRO_3")
            {
               mInventoryNeedtoOpen = true;
            }
            if(_loc1_.mState == Mission.STATE_ACTIVE && (_loc1_.mType == Mission.TYPE_MODAL_ARROW || _loc1_.mType == Mission.TYPE_MODAL_DIALOG || _loc1_.mType == Mission.TYPE_INTEL || _loc1_.mType == Mission.TYPE_INTEL_DIALOG || _loc1_.mType == Mission.TYPE_INSTANT_TIP))
            {
               smIsModalMissionActive = 1;
               return true;
            }
         }
         smIsModalMissionActive = 0;
         return false;
      }
      
      public static function isTutorialCompleted() : Boolean
      {
         var _loc1_:Boolean = false;
         var _loc2_:String = String(GameState.mConfig.PlayerStartValues.Default.TutorialEndMission.ID);
         _loc1_ = Cookie.readCookieVariable(Config.COOKIE_SESSION_NAME,Config.COOKIE_SESSION_NAME_TUTOTRIAL_INDEX);
         if(_loc1_)
         {
            return _loc1_;
         }
         if(!_loc1_)
         {
            _loc1_ = mCompletedMissionsGlobal.indexOf(_loc2_) >= 0 || Boolean(mMissions[getMissionIndexFromID(_loc2_)]) && (mMissions[getMissionIndexFromID(_loc2_)] as Mission).mState == Mission.STATE_REWARDS_COLLECTED;
            if(_loc1_)
            {
               Cookie.saveCookieVariable(Config.COOKIE_SESSION_NAME,Config.COOKIE_SESSION_NAME_TUTOTRIAL_INDEX,_loc1_);
            }
         }
         return _loc1_;
      }
      
      public static function showTutor() : Boolean
      {
         var _loc1_:String = String(GameState.mConfig.PlayerStartValues.Default.ShowTutorMission.ID);
         return mCompletedMissionsGlobal.indexOf(_loc1_) >= 0 || Boolean(mMissions[getMissionIndexFromID(_loc1_)]) && (mMissions[getMissionIndexFromID(_loc1_)] as Mission).mState == Mission.STATE_REWARDS_COLLECTED;
      }
      
      public static function isMapButtonEnabled() : Boolean
      {
         if(GameState.mInstance.visitingFriend())
         {
            return false;
         }
         if(Config.CHEAT_OPEN_ALL_MAPS)
         {
            return true;
         }
         var _loc1_:String = String(GameState.mConfig.PlayerStartValues.Default.ShowMapMission.ID);
         return mCompletedMissionsGlobal.indexOf(_loc1_) >= 0 || Boolean(mMissions[getMissionIndexFromID(_loc1_)]) && (mMissions[getMissionIndexFromID(_loc1_)] as Mission).mState == Mission.STATE_REWARDS_COLLECTED;
      }
      
      public static function isSpawnBeaconMissionCompleted() : Boolean
      {
         if(!GameState.mInstance.mMapData)
         {
            return false;
         }
         if(!GameState.mInstance.mMapData.mMapSetupData.SpawnBeaconTriggerMission)
         {
            return false;
         }
         var _loc1_:String = String(GameState.mInstance.mMapData.mMapSetupData.SpawnBeaconTriggerMission.ID);
         return mCompletedMissionsGlobal.indexOf(_loc1_) >= 0 || Boolean(mMissions[getMissionIndexFromID(_loc1_)]) && (mMissions[getMissionIndexFromID(_loc1_)] as Mission).mState == Mission.STATE_REWARDS_COLLECTED;
      }
      
      public static function isParatroopersMissionCompleted() : Boolean
      {
         if(!GameState.mInstance.mMapData)
         {
            return false;
         }
         if(!GameState.mInstance.mMapData.mMapSetupData.ParatroopersTriggerMission)
         {
            return false;
         }
         var _loc1_:String = String(GameState.mInstance.mMapData.mMapSetupData.ParatroopersTriggerMission.ID);
         return mCompletedMissionsGlobal.indexOf(_loc1_) >= 0 || Boolean(mMissions[getMissionIndexFromID(_loc1_)]) && (mMissions[getMissionIndexFromID(_loc1_)] as Mission).mState == Mission.STATE_REWARDS_COLLECTED;
      }
      
      public static function isMapLocked(param1:String) : Boolean
      {
         var _loc2_:String = null;
         var _loc3_:* = null;
         if(Config.CHEAT_OPEN_ALL_MAPS)
         {
            return false;
         }
         if(GameState.mConfig.MapSetup[param1])
         {
            _loc3_ = GameState.mConfig.MapSetup[param1].UnlockMission;
            if(_loc3_)
            {
               _loc2_ = String(_loc3_.ID);
               return mCompletedMissionsGlobal.indexOf(_loc2_) < 0 && !(mMissions[getMissionIndexFromID(_loc2_)] && (mMissions[getMissionIndexFromID(_loc2_)] as Mission).mState == Mission.STATE_REWARDS_COLLECTED);
            }
            _loc3_ = GameState.mConfig.MapSetup[param1].UnlockLevel;
            if(_loc3_)
            {
               return GameState.mInstance.mPlayerProfile.mLevel < _loc3_;
            }
            _loc3_ = GameState.mConfig.MapSetup[param1].UnlockBadassLevel;
            if(_loc3_)
            {
               return GameState.mInstance.mPlayerProfile.mBadassLevel < _loc3_;
            }
            return false;
         }
         return true;
      }
      
      public static function selectRepairMissionActive() : Boolean
      {
         var _loc1_:Mission = null;
         if(mMissions)
         {
            for each(_loc1_ in mMissions)
            {
               if(_loc1_.mId == "SelectRepair")
               {
                  if(_loc1_.mState == Mission.STATE_ACTIVE)
                  {
                     return true;
                  }
                  return false;
               }
            }
         }
         return false;
      }
      
      public static function openShopMissionActive() : Boolean
      {
         return false;
      }
      
      public static function setupFromServer(param1:ServerCall) : void
      {
         var _loc2_:Array = null;
         var _loc3_:Mission = null;
         var _loc4_:int = 0;
         var _loc5_:* = null;
         var _loc6_:int = 0;
         var _loc7_:* = null;
         if(param1 == null)
         {
            return;
         }
         var _loc8_:Array = param1.mData.missions_all_complete;
         if(_loc8_)
         {
            _loc4_ = 0;
            while(_loc4_ < _loc8_.length)
            {
               mCompletedMissionsGlobal[_loc4_] = _loc8_[_loc4_];
               _loc4_++;
            }
         }
         var _loc9_:Array = param1.mData.missions_finished;
         if(_loc9_)
         {
            for each(_loc5_ in _loc9_)
            {
               _loc3_ = getMission(_loc5_.mission_id);
               if(_loc3_)
               {
                  _loc3_.mState = Mission.STATE_REWARDS_COLLECTED;
                  if(_loc3_.mType == Mission.TYPE_RANK)
                  {
                     _loc6_ = RankManager.getIndexOfMission(_loc3_) + 1;
                     if(_loc6_ > GameState.mInstance.mPlayerProfile.mRankIdx)
                     {
                        GameState.mInstance.mPlayerProfile.mRankIdx = _loc6_;
                     }
                  }
               }
               else if(Config.DEBUG_MODE)
               {
               }
            }
         }
         _loc2_ = param1.mData.missions_incomplete;
         if(_loc2_)
         {
            for each(_loc7_ in _loc2_)
            {
               _loc3_ = getMission(_loc7_.mission_id);
               if(_loc3_)
               {
                  _loc3_.setup(_loc7_);
               }
               else
               {
                  Utils.LogError("Trying to setup unknown mission \"" + _loc5_.mission_id);
               }
            }
         }
         treeCheckForExcludedMissions();
         checkCompletedMissions();
         GameState.mInstance.mMissionIconsManager.reset();
         GameState.mInstance.mMissionIconsManager.updateMissionButtons();
      }
      
      public static function update() : void
      {
         smIsModalMissionActive = -1;
      }
      
      private static function checkCompletedMissions() : void
      {
         var _loc1_:Mission = null;
         for each(_loc1_ in mMissions)
         {
            if(_loc1_.mState == Mission.STATE_ACTIVE)
            {
               if(_loc1_.allObjectivesDone())
               {
                  if(Config.DEBUG_MISSIONS)
                  {
                  }
                  mCompletedMissions.push(_loc1_);
                  _loc1_.mState = Mission.STATE_COMPLETED;
               }
            }
         }
         if(Config.USE_WORLD_MAP)
         {
            GameState.mInstance.mHUD.updateMapButtonEnablation();
         }
      }
      
      public static function buyObjective(param1:Objective) : void
      {
         param1.buy();
         checkCompletedMissions();
      }
      
      private static function treeCheckForExcludedMissions() : void
      {
         var _loc1_:Mission = null;
         var _loc2_:MissionNode = null;
         var _loc3_:MissionNode = null;
         var _loc4_:* = null;
         smNodes = new Array();
         for each(_loc1_ in mMissions)
         {
            smNodes.push(new MissionNode(_loc1_));
         }
         for each(_loc2_ in smNodes)
         {
            for each(_loc4_ in _loc2_.mMission.mRequiredMissions)
            {
               _loc1_ = getMission(_loc4_.ID);
               if(_loc1_ == null)
               {
                  getMission(_loc4_.ID);
               }
               _loc2_.mParentNodes.push(getNodeForMission(_loc1_));
            }
         }
         for each(_loc3_ in smNodes)
         {
            if(!_loc3_.mIsProcessed)
            {
               if(_loc3_.mMission.mState != Mission.STATE_INACTIVE)
               {
                  _loc3_.markParentsCompleted();
               }
            }
         }
         smNodes = null;
      }
      
      private static function getNodeForMission(param1:Mission) : MissionNode
      {
         var _loc2_:MissionNode = null;
         for each(_loc2_ in smNodes)
         {
            if(_loc2_.mMission.mId == param1.mId)
            {
               return _loc2_;
            }
         }
         return null;
      }
      
      public static function getMissions() : Array
      {
         return mMissions;
      }
      
      public static function getCompletedMissions() : Array
      {
         return mCompletedMissionsGlobal;
      }
   }
}

