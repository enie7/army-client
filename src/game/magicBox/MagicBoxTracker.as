package game.magicBox
{
   import com.adobe.crypto.MD5;
   import com.dchoc.magicbox.constants.PLATFORM;
   import flash.events.IOErrorEvent;
   import flash.net.URLLoader;
   import flash.net.URLRequest;
   import game.net.ErrorObject;
   import game.states.GameState;
   
   public class MagicBoxTracker
   {
      
      private static var mCRMMetrics:CRMAirMagicBox;
      
      private static const DEBUG_TRACKER:Boolean = false;
      
      public static const GROUP_LEVEL:String = "Level";
      
      public static const GROUP_ECONOMY:String = "Economy";
      
      public static const GROUP_GAME:String = "Game";
      
      public static const TYPE_SESSION_STARTED:String = "Session started";
      
      public static const TYPE_LEVEL_REACHED:String = "Level reached";
      
      public static const TYPE_LOADING:String = "Loading";
      
      public static const TYPE_SPEND_CASH:String = "Spend Cash";
      
      public static const TYPE_SPEND_PC:String = "Spend PC";
      
      public static const TYPE_SPEND_ENERGY:String = "Spend Energy";
      
      public static const TYPE_SPEND_SUPPLY:String = "Spend Supply";
      
      public static const TYPE_GAIN_ITEM:String = "Gain Item";
      
      public static const TYPE_GAME_ACTION:String = "Game Action";
      
      public static const TYPE_TRADE_COLLECTION:String = "Trade Collection";
      
      public static const TYPE_FIRE_MISSION:String = "Fire Mission";
      
      public static const TYPE_MISSION_COMPLETED:String = "Mission Completed";
      
      public static const TYPE_MISSION_ACCEPTED:String = "Mission Accepted";
      
      public static const LABEL_LOADING_TIME:String = "LoadingTime_";
      
      public static const LOADING_GROUP_10:int = 10;
      
      public static const LOADING_GROUP_20:int = 20;
      
      public static const LOADING_GROUP_40:int = 40;
      
      public static const LOADING_GROUP_80:int = 80;
      
      public static const LOADING_GROUP_160:int = 160;
      
      public static const LOADING_GROUP_320:int = 320;
      
      public static const LABEL_ON_FLASH:String = "OnAndroid";
      
      public static const LABEL_TOOL_SELL_ITEM:String = "Tool Sell Item";
      
      public static const LABEL_TOOL_MOVE_BUILDING:String = "Tool Move Building";
      
      public static const LABEL_CONSTRUCTION_FINISHED:String = "Construction Finished";
      
      public static const LABEL_CITY_SUPPLY_CONVERSION:String = "Convert Supply To Cash";
      
      public static const LABEL_RESOURCE_PRODUCTION:String = "Set Recource Production";
      
      public static const LABEL_BUY_ITEM:String = "Buy Item";
      
      public static const LABEL_BUY_ITEM_WITH_LOCATION:String = "Buy Item With Location";
      
      public static const LABEL_BUY_EARLY_UNLOCK:String = "Buy Early Unlock";
      
      public static const LABEL_BUY_INGREDIENTS:String = "Buy Ingredients";
      
      public static const LABEL_BUY_UNLOCK_MISSION_OBJECTIVE:String = "Buy Unlock MissionObj";
      
      public static const TYPE_BUY_CASH:String = "Buy Cash";
      
      public static const TYPE_BUY_PC:String = "Buy PC";
      
      public static const LABEL_SUCCESS:String = "Success";
      
      public static const LABEL_FAIL:String = "Failure";
      
      public static const GROUP_GAME_ERROR:String = "Game Error";
      
      public static const TYPE_ERR_GAME_CLIENT:String = "Game Client";
      
      public static const TYPE_ERR_NA:String = "Err Obj NA";
      
      public static const PS_RANDOM_ITEM:String = "RI";
      
      public static const PS_ID:String = "ID";
      
      private static const PROJECT_ID:int = 130;
      
      private static const ENV_ID:int = Config.USE_LIVE_BUILD ? 2 : 1;
      
      private static const P_ID:int = 3;
      
      private static const CRM_KEY:String = "E4CB8DFE1C6E829175C2D6BF0C";
      
      private static const GAME_CURRENCY:String = "GameCurrency";
      
      private static const PREMIUM_CURRENCY:String = "PaidCurrency";
      
      private static const REAL_CURRENCY:String = "RealCurrency";
      
      private static const SUPPLY_RESOURCE:String = "SupplyResource";
      
      public function MagicBoxTracker()
      {
         super();
      }
      
      public static function generateEvent(param1:String, param2:String, param3:String, param4:Object = null) : void
      {
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:String = param1;
         var _loc8_:String = param2;
         var _loc9_:String = param3;
         var _loc10_:Object = param4;
         try
         {
            if(GameState.mInstance.mServer.isServerCommError() || GameState.mInstance.mServer.isConnectionError())
            {
               return;
            }
            if(!Config.USE_MAGIC_BOX_LIB)
            {
               if(_loc10_ == null)
               {
                  _loc10_ = paramsObj(null,null,null,null,_loc9_);
                  if(_loc8_ == TYPE_SESSION_STARTED)
                  {
                     _loc10_["app_friends"] = 0;
                     _loc10_["app_neighbors"] = 0;
                     _loc10_["friends"] = 0;
                  }
               }
               else
               {
                  _loc10_["app_id"] = PROJECT_ID;
                  _loc10_["env"] = ENV_ID;
                  _loc10_["app_uid"] = MD5.hash(Config.smUserId);
                  _loc10_["p_uid"] = MD5.hash(Config.smUserId);
                  _loc10_["p_id"] = P_ID;
                  _loc10_["ts"] = Math.round(new Date().time / 1000);
                  _loc10_["sig"] = genarateSig(_loc10_);
                  if(_loc9_)
                  {
                     _loc10_["user_action"] = _loc9_;
                  }
               }
               if(DEBUG_TRACKER)
               {
                  printObject(_loc10_);
               }
               wcrmInternalTrackEvent(_loc7_,_loc8_,_loc9_,_loc10_);
            }
            else
            {
               _loc5_ = parseInt(Config.smUserId);
               _loc6_ = GameState.mInstance.mPlayerProfile.mLevel;
               if(mCRMMetrics == null)
               {
                  mCRMMetrics = new CRMAirMagicBox();
                  mCRMMetrics.init(PLATFORM.ANDROID,ENV_ID,P_ID,PROJECT_ID,_loc5_,null);
               }
               switch(_loc7_)
               {
                  case GROUP_LEVEL:
                     if(_loc8_ == TYPE_SESSION_STARTED)
                     {
                        mCRMMetrics.wcrmTrackSessionStarted();
                     }
                     else if(_loc8_ == TYPE_LEVEL_REACHED)
                     {
                        mCRMMetrics.wcrmTrackLevelUp(_loc6_);
                     }
                     else
                     {
                        mCRMMetrics.wcrmCustomEvent(_loc7_,_loc8_,_loc9_,_loc10_);
                     }
                     break;
                  case GROUP_ECONOMY:
                     mCRMMetrics.wcrmTrackEconomy(_loc8_,_loc9_,_loc10_.product,_loc10_.product_detail,_loc10_.game_currency_delta,_loc10_.game_currency_balance,_loc10_.paid_currency_delta,_loc10_.game_currency_balance,_loc10_.real_currency_delta);
                     break;
                  default:
                     mCRMMetrics.wcrmCustomEvent(_loc7_,_loc8_,_loc9_,_loc10_);
               }
            }
         }
         catch(err:Error)
         {
         }
      }
      
      private static function wcrmInternalTrackEvent(param1:String, param2:String, param3:String, param4:Object) : void
      {
         var _loc5_:URLLoader = null;
         var _loc6_:String = null;
         var _loc7_:String = null;
         var _loc8_:URLRequest = null;
         var _loc9_:String = param1;
         var _loc10_:String = param2;
         var _loc11_:String = param3;
         var _loc12_:Object = param4;
         try
         {
            if(!(GameState.mInstance.mServer.isServerCommError() || GameState.mInstance.mServer.isConnectionError()) && !Config.OFFLINE_MODE)
            {
               _loc5_ = new URLLoader();
               _loc6_ = "";
               if(_loc12_ == null)
               {
                  return;
               }
               for(_loc7_ in _loc12_)
               {
                  _loc6_ += "&" + _loc7_ + "=" + _loc12_[_loc7_];
               }
               if(_loc6_ == "")
               {
                  return;
               }
               _loc6_ = _loc6_.slice(1,_loc6_.length);
               _loc8_ = new URLRequest(wcrmGetServer() + "/event/track?" + _loc6_ + "&group=" + _loc9_ + "&event=" + _loc10_ + "&type=" + _loc10_ + "&level=" + GameState.mInstance.mPlayerProfile.mLevel);
               if(DEBUG_TRACKER)
               {
               }
               try
               {
                  _loc5_.addEventListener(IOErrorEvent.IO_ERROR,onError);
                  _loc5_.load(_loc8_);
               }
               catch(error:IOErrorEvent)
               {
               }
            }
         }
         catch(err:Error)
         {
         }
      }
      
      private static function onError(param1:IOErrorEvent) : void
      {
      }
      
      private static function wcrmGetServer() : String
      {
         if(FeatureTuner.USE_LIVE_BUILD_PRODUCTION)
         {
            return "http://crm.digitalchocolate.com";
         }
         return "http://crm-stage.digitalchocolate.com";
      }
      
      public static function generateErrorEvent(param1:ErrorObject) : void
      {
         var _loc2_:Object = null;
         var _loc3_:Object = null;
         var _loc4_:ErrorObject = param1;
         try
         {
            if(GameState.mInstance.mServer.isServerCommError() || GameState.mInstance.mServer.isConnectionError())
            {
               return;
            }
            if(!Config.USE_MAGIC_BOX_LIB)
            {
               if(_loc4_ == null)
               {
                  if(DEBUG_TRACKER)
                  {
                  }
                  _loc4_ = getErrorObject("",TYPE_ERR_NA);
               }
               _loc2_ = paramsObj(null,_loc4_.getCode(),_loc4_.getMessage(),"FV:" + _loc4_.getFlashVersion() + "_VMV:" + _loc4_.getVMVersion());
               generateEvent(MagicBoxTracker.GROUP_GAME_ERROR,_loc4_.getType(),_loc4_.getService(),_loc2_);
               if(_loc4_.getMessage().length > 0)
               {
                  GameState.mInstance.mServer.serverCallReportClientError(_loc4_);
               }
               if(DEBUG_TRACKER)
               {
               }
            }
            else
            {
               _loc3_ = paramsObj(null,_loc4_.getCode(),_loc4_.getMessage(),"FV:" + _loc4_.getFlashVersion() + "_VMV:" + _loc4_.getVMVersion());
               if(!mCRMMetrics)
               {
                  mCRMMetrics.wcrmCustomEvent(GROUP_GAME_ERROR,_loc4_.getType(),_loc4_.getService(),_loc3_);
               }
            }
         }
         catch(err:Error)
         {
         }
      }
      
      public static function getErrorObject(param1:String, param2:String, param3:String = null, param4:String = null) : ErrorObject
      {
         var _loc5_:ErrorObject = null;
         _loc5_ = new ErrorObject();
         _loc5_.setError(param1,param2,param3,param4);
         return _loc5_;
      }
      
      public static function paramsObj(param1:String = null, param2:String = null, param3:String = null, param4:String = null, param5:String = null) : Object
      {
         var _loc6_:String = param1;
         var _loc7_:String = param2;
         var _loc8_:String = param3;
         var _loc9_:String = param4;
         var _loc10_:String = param5;
         var _loc11_:Object = new Object();
         try
         {
            if(GameState.mInstance.mServer.isServerCommError() || GameState.mInstance.mServer.isConnectionError())
            {
               return _loc11_;
            }
            if(_loc6_)
            {
               _loc11_["product"] = _loc6_;
            }
            else
            {
               _loc11_["product"] = "Default";
            }
            if(_loc7_)
            {
               _loc11_["product_detail"] = _loc7_;
            }
            if(_loc8_)
            {
               _loc11_["p1"] = _loc8_;
            }
            if(_loc9_)
            {
               _loc11_["p2"] = _loc9_;
            }
            _loc11_["app_id"] = PROJECT_ID;
            _loc11_["env"] = ENV_ID;
            _loc11_["app_uid"] = MD5.hash(Config.smUserId);
            _loc11_["p_uid"] = MD5.hash(Config.smUserId);
            _loc11_["p_id"] = P_ID;
            _loc11_["ts"] = Math.round(new Date().time / 1000);
            if(_loc10_)
            {
               _loc11_["user_action"] = _loc10_;
            }
            _loc11_["sig"] = genarateSig(_loc11_);
            if(GameState.mInstance)
            {
               if(GameState.mInstance.mPlayerProfile)
               {
                  if(GameState.mInstance.mPlayerProfile.mInventory)
                  {
                     if(GameState.mInstance.mPlayerProfile.mInventory.getAreas())
                     {
                        _loc11_["p3"] = "" + GameState.mInstance.mPlayerProfile.mInventory.getAreas().length / 2;
                     }
                  }
               }
            }
            return _loc11_;
         }
         catch(err:Error)
         {
         }
         return _loc11_;
      }
      
      private static function genarateSig(param1:Object) : String
      {
         var _loc2_:String = null;
         var _loc3_:String = "";
         for(_loc2_ in param1)
         {
            _loc3_ += "" + _loc2_ + param1[_loc2_];
         }
         return MD5.hash(_loc3_ + CRM_KEY);
      }
      
      private static function printObject(param1:Object) : void
      {
         var _loc2_:String = null;
         var _loc3_:String = null;
         if(DEBUG_TRACKER)
         {
            _loc2_ = "";
            for(_loc3_ in param1)
            {
               _loc2_ += "" + _loc3_ + ":" + param1[_loc3_] + ",";
            }
         }
      }
      
      public static function paramsAddRecipientSenderAndPicture(param1:Object, param2:String, param3:String, param4:String) : void
      {
         param1["recipient_uids"] = param2;
         param1["sender"] = param3;
         param1["picture_url"] = param4;
      }
      
      public static function paramsAddGameCurrency(param1:Object, param2:int) : void
      {
         var _loc3_:int = GameState.mInstance.mPlayerProfile.mMoney;
         paramsAdd(GAME_CURRENCY,param1,param2,_loc3_);
      }
      
      public static function paramsAddSupplyResource(param1:Object, param2:int) : void
      {
         var _loc3_:int = GameState.mInstance.mPlayerProfile.mSupplies;
         paramsAdd(SUPPLY_RESOURCE,param1,param2,_loc3_);
      }
      
      public static function paramsTrackPremiumCurrency(param1:Object, param2:int) : void
      {
         var _loc3_:int = GameState.mInstance.mPlayerProfile.mPremium;
         paramsAdd(PREMIUM_CURRENCY,param1,param2,_loc3_);
      }
      
      public static function paramsTrackRealCurrency(param1:Object, param2:int, param3:int) : void
      {
         paramsAdd(PREMIUM_CURRENCY,param1,param3,GameState.mInstance.mPlayerProfile.mPremium);
         paramsAdd(REAL_CURRENCY,param1,param2,0);
      }
      
      private static function paramsAdd(param1:String, param2:Object, param3:int, param4:int) : void
      {
         if(param2 == null)
         {
            param2 = paramsObj();
         }
         switch(param1)
         {
            case REAL_CURRENCY:
               param2["real_currency_delta"] = param3.toString();
               param2["real_currency_balance"] = param4.toString();
               break;
            case PREMIUM_CURRENCY:
               param2["paid_currency_delta"] = param3.toString();
               param2["paid_currency_balance"] = param4.toString();
               break;
            case GAME_CURRENCY:
               param2["game_currency_delta"] = param3.toString();
               param2["game_currency_balance"] = param4.toString();
               param2["premier_currency_delta"] = 0;
               break;
            case SUPPLY_RESOURCE:
               param2["resource_1_delta"] = param3.toString();
               param2["resource_1_balance"] = param4.toString();
         }
      }
   }
}

