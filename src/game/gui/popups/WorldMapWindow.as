package game.gui.popups
{
   import com.dchoc.graphics.DCResourceManager;
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import game.gui.StylizedHeaderClip;
   import game.gui.TooltipMap;
   import game.gui.button.ArmyButton;
   import game.missions.MissionManager;
   import game.states.GameState;
   
   public class WorldMapWindow extends PopUpWindow
   {
      
      public static const WORLD_MAP_ID_LIST:Array = ["Home","Desert","Snow",""];
      
      private var mCampaignButtons:Array;
      
      private var mCampaignTexts:Array;
      
      private var mButtonCancel:ArmyButton;
      
      private var mTooltip:TooltipMap;
      
      private var mButtonContainer:MovieClip;
      
      public function WorldMapWindow()
      {
         var _loc1_:MovieClip = null;
         var _loc2_:MovieClip = null;
         _loc1_ = null;
         _loc2_ = null;
         var _loc3_:MovieClip = null;
         var _loc4_:MovieClip = null;
         var _loc5_:MovieClip = null;
         var _loc6_:Class = DCResourceManager.getInstance().getSWFClass("swf/map","map");
         super(new _loc6_(),true);
         var _loc7_:MovieClip = mClip.getChildByName("map_gloss") as MovieClip;
         _loc7_.mouseEnabled = false;
         this.mButtonCancel = Utils.createBasicButton(mClip,"Button_Cancel",this.closeClicked);
         this.mButtonContainer = mClip.getChildByName("Map_Container") as MovieClip;
         _loc1_ = this.mButtonContainer.getChildByName("Map_Grid") as MovieClip;
         _loc1_.mouseEnabled = false;
         _loc1_.mouseChildren = false;
         _loc2_ = this.mButtonContainer.getChildByName("Icon_Mappin") as MovieClip;
         _loc2_.mouseChildren = false;
         _loc2_.mouseEnabled = false;
         _loc2_.visible = false;
         this.mCampaignButtons = new Array();
         var _loc8_:int = 0;
         while(_loc8_ < WORLD_MAP_ID_LIST.length)
         {
            _loc3_ = this.mButtonContainer.getChildByName("Button_Campaign_0" + (_loc8_ + 1)) as MovieClip;
            _loc4_ = _loc3_.getChildByName("Hit_Area") as MovieClip;
            this.mCampaignButtons.push(_loc4_);
            _loc5_ = _loc3_.getChildByName("Conquered_Icon") as MovieClip;
            if(_loc5_)
            {
               _loc5_.visible = false;
            }
            if(WORLD_MAP_ID_LIST.indexOf(GameState.mInstance.mCurrentMapId) == _loc8_)
            {
               _loc2_.x = _loc3_.x;
               _loc2_.y = _loc3_.y;
               _loc2_.visible = true;
            }
            this.setAreaAvailability(_loc8_,!MissionManager.isMapLocked(WORLD_MAP_ID_LIST[_loc8_]));
            _loc8_++;
         }
         this.mTooltip = new TooltipMap(120);
         this.addChild(this.mTooltip);
         this.createCampaignTexts();
         mCloseTransitionName = null;
      }
      
      private function createCampaignTexts() : void
      {
         this.mCampaignTexts = new Array();
         this.mCampaignTexts.push(GameState.getText("MAP_TOOLTIP_HOMELAND_TITLE"));
         this.mCampaignTexts.push(GameState.getText("MAP_TOOLTIP_HOMELAND_DESC"));
         this.mCampaignTexts.push("");
         this.mCampaignTexts.push(GameState.getText("MAP_TOOLTIP_LIBERY_TITLE"));
         this.mCampaignTexts.push(GameState.getText("MAP_TOOLTIP_LIBERY_DESC"));
         this.mCampaignTexts.push(GameState.getText("MAP_TOOLTIP_LIBERY_LOCKED"));
         this.mCampaignTexts.push(GameState.getText("MAP_TOOLTIP_SNOW_TITLE"));
         this.mCampaignTexts.push(GameState.getText("MAP_TOOLTIP_SNOW_DESC"));
         this.mCampaignTexts.push(GameState.getText("MAP_TOOLTIP_SNOW_LOCKED"));
         this.mCampaignTexts.push(GameState.getText("MAP_TOOLTIP_COMING_SOON"));
         this.mCampaignTexts.push(GameState.getText("MAP_TOOLTIP_COMING_SOON_DESC"));
         this.mCampaignTexts.push("");
      }
      
      public function Activate(param1:Function) : void
      {
         var _loc2_:StylizedHeaderClip = null;
         mDoneCallback = param1;
         _loc2_ = new StylizedHeaderClip(mClip.getChildByName("Header") as MovieClip,GameState.getText("HUD_MAP_TOOLTIP"));
         MissionManager.increaseCounter("OpenMap",null,1);
      }
      
      private function setupIcon(param1:MovieClip) : void
      {
         param1.setMouseEnabled(false);
         param1.setMouseChildren(false);
      }
      
      private function mouseDown(param1:MouseEvent) : void
      {
         var _loc2_:int = this.getAreaIndex(param1.target) + 1;
         var _loc3_:MovieClip = this.mButtonContainer.getChildByName("Button_Campaign_0" + _loc2_) as MovieClip;
         (_loc3_.getChildByName("Background_Enabled") as MovieClip).visible = false;
         (_loc3_.getChildByName("Background_Over") as MovieClip).visible = false;
         (_loc3_.getChildByName("Background_Down") as MovieClip).visible = true;
         (_loc3_.getChildByName("Background_Out") as MovieClip).visible = false;
         (_loc3_.getChildByName("Background_Disabled") as MovieClip).visible = false;
      }
      
      private function mouseOver(param1:MouseEvent) : void
      {
         var _loc2_:MovieClip = null;
         var _loc3_:int = this.getAreaIndex(param1.target);
         if(!MissionManager.isMapLocked(WORLD_MAP_ID_LIST[_loc3_]))
         {
            _loc2_ = this.mButtonContainer.getChildByName("Button_Campaign_0" + (_loc3_ + 1)) as MovieClip;
            (_loc2_.getChildByName("Background_Enabled") as MovieClip).visible = false;
            (_loc2_.getChildByName("Background_Over") as MovieClip).visible = true;
            (_loc2_.getChildByName("Background_Down") as MovieClip).visible = false;
            (_loc2_.getChildByName("Background_Out") as MovieClip).visible = false;
            (_loc2_.getChildByName("Background_Disabled") as MovieClip).visible = false;
         }
         if(!this.mTooltip.visible)
         {
            if(MissionManager.isMapLocked(WORLD_MAP_ID_LIST[_loc3_]))
            {
               this.mTooltip.setText(this.mCampaignTexts[_loc3_ * 3],this.mCampaignTexts[_loc3_ * 3 + 2]);
            }
            else
            {
               this.mTooltip.setText(this.mCampaignTexts[_loc3_ * 3],this.mCampaignTexts[_loc3_ * 3 + 1]);
            }
            this.mTooltip.visible = true;
         }
      }
      
      private function mouseOut(param1:MouseEvent) : void
      {
         var _loc2_:MovieClip = null;
         var _loc3_:int = this.getAreaIndex(param1.target);
         if(!MissionManager.isMapLocked(WORLD_MAP_ID_LIST[_loc3_]))
         {
            _loc2_ = this.mButtonContainer.getChildByName("Button_Campaign_0" + (_loc3_ + 1)) as MovieClip;
            (_loc2_.getChildByName("Background_Enabled") as MovieClip).visible = true;
            (_loc2_.getChildByName("Background_Over") as MovieClip).visible = false;
            (_loc2_.getChildByName("Background_Down") as MovieClip).visible = false;
            (_loc2_.getChildByName("Background_Out") as MovieClip).visible = false;
            (_loc2_.getChildByName("Background_Disabled") as MovieClip).visible = false;
         }
         this.mTooltip.setText("","");
         this.mTooltip.visible = false;
      }
      
      private function mouseUp(param1:MouseEvent) : void
      {
         var _loc2_:int = this.getAreaIndex(param1.target);
         var _loc3_:MovieClip = this.mButtonContainer.getChildByName("Button_Campaign_0" + (_loc2_ + 1)) as MovieClip;
         (_loc3_.getChildByName("Background_Enabled") as MovieClip).visible = true;
         (_loc3_.getChildByName("Background_Over") as MovieClip).visible = false;
         (_loc3_.getChildByName("Background_Down") as MovieClip).visible = false;
         (_loc3_.getChildByName("Background_Out") as MovieClip).visible = false;
         (_loc3_.getChildByName("Background_Disabled") as MovieClip).visible = false;
         this.mTooltip.visible = false;
         this.goToArea(WORLD_MAP_ID_LIST[_loc2_]);
      }
      
      private function getAreaIndex(param1:*) : int
      {
         var _loc2_:int = 0;
         while(_loc2_ < this.mCampaignButtons.length)
         {
            if(this.mCampaignButtons[_loc2_] == param1)
            {
               return _loc2_;
            }
            _loc2_++;
         }
         return 0;
      }
      
      private function setAreaAvailability(param1:int, param2:Boolean) : void
      {
         var _loc4_:MovieClip = null;
         var _loc5_:MovieClip = null;
         var _loc3_:MovieClip = this.mCampaignButtons[param1];
         var _loc6_:TextField = null;
         _loc3_.buttonMode = param2;
         _loc5_ = this.mButtonContainer.getChildByName("Button_Campaign_0" + (param1 + 1)) as MovieClip;
         _loc4_ = _loc5_.getChildByName("Lock_Icon") as MovieClip;
         if(_loc4_)
         {
            if(_loc6_ = _loc4_.getChildByName("Text_Amount") as TextField)
            {
               try
               {
                  _loc6_.text = String(GameState.mConfig.MapSetup[WORLD_MAP_ID_LIST[param1]].UnlockLevel);
               }
               catch(e:Error)
               {
                  _loc6_.text = "not found";
               }
            }
            _loc4_.visible = !param2;
         }
         _loc3_.addEventListener(MouseEvent.MOUSE_OVER,this.mouseOver,false,0,true);
         _loc3_.addEventListener(MouseEvent.MOUSE_OUT,this.mouseOut,false,0,true);
         if(param2)
         {
            _loc3_.addEventListener(MouseEvent.MOUSE_DOWN,this.mouseDown,false,0,true);
            _loc3_.addEventListener(MouseEvent.MOUSE_UP,this.mouseUp,false,0,true);
         }
         if(!param2)
         {
            (_loc5_.getChildByName("Background_Enabled") as MovieClip).visible = false;
            (_loc5_.getChildByName("Background_Over") as MovieClip).visible = false;
            (_loc5_.getChildByName("Background_Down") as MovieClip).visible = false;
            (_loc5_.getChildByName("Background_Out") as MovieClip).visible = false;
            (_loc5_.getChildByName("Background_Disabled") as MovieClip).visible = true;
         }
      }
      
      private function goToArea(param1:String) : void
      {
         mDoneCallback((this as Object).constructor);
         GameState.mInstance.executeSwitchMap(param1,null);
      }
      
      private function closeClicked(param1:MouseEvent) : void
      {
         var _loc2_:MovieClip = param1.target as MovieClip;
         _loc2_.removeEventListener(MouseEvent.MOUSE_DOWN,this.mouseDown);
         _loc2_.removeEventListener(MouseEvent.MOUSE_UP,this.mouseUp);
         _loc2_.removeEventListener(MouseEvent.MOUSE_OVER,this.mouseOver);
         _loc2_.removeEventListener(MouseEvent.MOUSE_OUT,this.mouseOut);
         mDoneCallback((this as Object).constructor);
      }
   }
}

