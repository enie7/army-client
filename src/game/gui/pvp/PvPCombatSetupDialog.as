package game.gui.pvp
{
   import com.dchoc.graphics.DCResourceManager;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.ColorTransform;
   import flash.text.TextField;
   import game.environment.EnvEffectManager;
   import game.gui.AutoTextField;
   import game.gui.IconLoader;
   import game.gui.ShopDialog;
   import game.gui.StylizedHeaderClip;
   import game.gui.button.ArmyButton;
   import game.gui.popups.PopUpWindow;
   import game.items.EnemyUnitItem;
   import game.items.Item;
   import game.items.ItemManager;
   import game.items.PlayerUnitItem;
   import game.net.Friend;
   import game.net.FriendsCollection;
   import game.net.PvPMatch;
   import game.net.PvPOpponent;
   import game.net.PvPOpponentCollection;
   import game.player.GamePlayerProfile;
   import game.states.GameState;
   
   public class PvPCombatSetupDialog extends PopUpWindow
   {
      
      private static var smSelectedUnits:Array;
      
      private static var mDefaultFilters:Array;
      
      private static const UNIT_PANEL_COUNT:int = 4;
      
      private static const SELECTED_UNIT_PANEL_COUNT:int = 4;
      
      private static const OPPONENT_UNIT_PANEL_COUNT:int = 4;
      
      private static const INSUFFICIENT_RESOURCES_FILTER:Array = [];
      
      private static const INSUFFICIENT_RESOURCES_MOD:ColorTransform = new ColorTransform(5,0.7,0.7,1,127,-127,-127,0);
      
      private var mButtonCancel:ArmyButton;
      
      private var mButtonBack:ArmyButton;
      
      private var mButtonFight:ArmyButton;
      
      private var mButtonBuy:ArmyButton;
      
      private var mPlayerArmy:MovieClip;
      
      private var mPlayerCard:MovieClip;
      
      private var mOpponentArmy:MovieClip;
      
      private var mOpponentCard:MovieClip;
      
      private var mInfoPanel:MovieClip;
      
      private var mMatchUpCallback:Function;
      
      private var mStartPvPCallback:Function;
      
      private var mButtonSelectionScrollUp:ArmyButton;
      
      private var mButtonSelectionScrollDown:ArmyButton;
      
      private var mUnitPanels:Array = new Array();
      
      private var mPlayerUnits:Array = new Array();
      
      private var mPlayerUnitCounts:Array = new Array();
      
      private var mSelectedUnitPanels:Array = new Array();
      
      private var mOpponentUnitPanels:Array = new Array();
      
      private var mOpponentUnits:Array = new Array();
      
      private var mPage:int = 0;
      
      private var mPageMax:int = 0;
      
      private var mHeader:StylizedHeaderClip;
      
      public function PvPCombatSetupDialog()
      {
         var _loc1_:TextField = null;
         var _loc2_:AutoTextField = null;
         var _loc3_:MovieClip = null;
         var _loc4_:Class = DCResourceManager.getInstance().getSWFClass("swf/popups_pvp","popup_pvp_armies");
         super(new _loc4_(),true);
         this.mButtonCancel = Utils.createBasicButton(mClip,"Button_Cancel",this.closeClicked);
         this.mPlayerArmy = mClip.getChildByName("Player_Army") as MovieClip;
         this.mPlayerCard = this.mPlayerArmy.getChildByName("Player_Card") as MovieClip;
         this.mOpponentArmy = mClip.getChildByName("Opponent_Army") as MovieClip;
         this.mOpponentCard = this.mOpponentArmy.getChildByName("Player_Card") as MovieClip;
         this.mInfoPanel = mClip.getChildByName("Info_Panel") as MovieClip;
         var _loc5_:MovieClip = this.mInfoPanel.getChildByName("Toolbox") as MovieClip;
         this.mButtonBack = Utils.createBasicButton(_loc5_,"Button_Back",this.backClicked);
         this.mButtonFight = Utils.createBasicButton(_loc5_,"Button_Fight",this.fightClicked);
         this.mButtonBuy = Utils.createBasicButton(_loc5_,"Button_Buy",this.buyClicked);
         var _loc6_:Friend = FriendsCollection.smFriends.GetThePlayer();
         _loc1_ = this.mPlayerCard.getChildByName("Text_Name") as TextField;
         _loc1_.text = _loc6_.mName;
         this.mHeader = new StylizedHeaderClip(mClip.getChildByName("Header") as MovieClip);
         this.mHeader.setText(GameState.getText("PVP_SETUP_TITLE"));
         _loc1_ = this.mInfoPanel.getChildByName("Text_Costs") as TextField;
         _loc1_.text = GameState.getText("PVP_SETUP_COST_TITLE");
         _loc1_ = this.mInfoPanel.getChildByName("Text_Rewards") as TextField;
         _loc1_.text = GameState.getText("PVP_SETUP_REWARDS_TITLE");
         _loc1_ = this.mInfoPanel.getChildByName("Text_Chances") as TextField;
         _loc1_.text = GameState.getText("PVP_SETUP_TITLE");
         _loc1_ = this.mInfoPanel.getChildByName("Text_Chances") as TextField;
         _loc1_.text = GameState.getText("PVP_SETUP_CHANCE_TITLE");
         _loc2_ = new AutoTextField(this.mPlayerArmy.getChildByName("Text_Description") as TextField);
         _loc2_.setText(GameState.getText("PVP_SETUP_DESC"));
         _loc1_ = _loc5_.getChildByName("Text_Button_Back") as TextField;
         _loc1_.text = GameState.getText("PVP_SETUP_BACK");
         _loc1_ = _loc5_.getChildByName("Text_Button_Fight") as TextField;
         _loc1_.text = GameState.getText("PVP_SETUP_FIGHT");
         _loc1_ = _loc5_.getChildByName("Text_Button_Buy") as TextField;
         _loc1_.text = GameState.getText("PVP_SETUP_SHOP");
         var _loc7_:Sprite = this.mPlayerCard.getChildByName("Thumb") as Sprite;
         if(Boolean(_loc6_) && Boolean(_loc6_.mPicID != null) && _loc6_.mPicID != "")
         {
            IconLoader.addIconPicture(_loc7_,_loc6_.mPicID);
         }
         this.removeChildClip(this.mPlayerArmy,"Button_Scroll_Up");
         this.removeChildClip(this.mPlayerArmy,"Button_Scroll_Down");
         this.removeChildClip(this.mPlayerArmy,"Scrollbar");
         this.removeChildClip(this.mOpponentArmy,"Button_Scroll_Up");
         this.removeChildClip(this.mOpponentArmy,"Button_Scroll_Down");
         this.removeChildClip(this.mOpponentArmy,"Scrollbar");
         this.mButtonSelectionScrollUp = Utils.createBasicButton(this.mPlayerArmy,"Selection_Scroll_Up",this.selectionUpClicked);
         this.mButtonSelectionScrollDown = Utils.createBasicButton(this.mPlayerArmy,"Selection_Scroll_Down",this.selectionDownClicked);
         var _loc8_:int = 0;
         while(_loc8_ < UNIT_PANEL_COUNT)
         {
            _loc3_ = this.mPlayerArmy.getChildByName("Army_Slot_0" + (_loc8_ + 1)) as MovieClip;
            this.mUnitPanels[_loc8_] = new PvPUnitPanel(_loc3_,this.mPlayerArmy,this);
            _loc8_++;
         }
         var _loc9_:int = 0;
         while(_loc9_ < SELECTED_UNIT_PANEL_COUNT)
         {
            _loc3_ = this.mPlayerArmy.getChildByName("Army_Slot_Empty_0" + (_loc9_ + 1)) as MovieClip;
            this.mSelectedUnitPanels[_loc9_] = new PvPSelectedUnitPanel(_loc3_,this.mPlayerArmy,this);
            _loc9_++;
         }
         var _loc10_:int = 0;
         while(_loc10_ < OPPONENT_UNIT_PANEL_COUNT)
         {
            _loc3_ = this.mOpponentArmy.getChildByName("Army_Slot_Opponent_Active_0" + (_loc10_ + 1)) as MovieClip;
            this.mOpponentUnitPanels[_loc10_] = new PvPOpponentUnitPanel(_loc3_,this.mOpponentArmy);
            _loc10_++;
         }
      }
      
      private function removeChildClip(param1:DisplayObjectContainer, param2:String) : void
      {
         var _loc3_:DisplayObjectContainer = param1.getChildByName(param2) as DisplayObjectContainer;
         if(_loc3_.parent)
         {
            _loc3_.parent.removeChild(_loc3_);
         }
      }
      
      public function Activate(param1:Function, param2:Function, param3:Function) : void
      {
         var _loc13_:MovieClip = null;
         var _loc4_:TextField = null;
         var _loc5_:String = null;
         var _loc6_:Item = null;
         var _loc7_:int = 0;
         var _loc8_:Item = null;
         var _loc9_:PvPOpponentUnitPanel = null;
         var _loc10_:int = 0;
         mDoneCallback = param1;
         this.mMatchUpCallback = param2;
         this.mStartPvPCallback = param3;
         var _loc11_:PvPOpponent = GameState.mInstance.mPvPMatch.mOpponent;
         this.mOpponentUnits = GameState.mInstance.mPvPMatch.mOpponentUnits;
         var _loc12_:GamePlayerProfile = GameState.mInstance.mPlayerProfile;
         _loc13_ = this.mPlayerCard.getChildByName("Rank_Icon") as MovieClip;
         _loc4_ = _loc13_.getChildByName("Text_PvP_Rank") as TextField;
         _loc4_.text = _loc12_.mBadassLevel.toString();
         _loc4_ = this.mPlayerCard.getChildByName("Text_Rank") as TextField;
         _loc4_.text = _loc12_.getBadassName();
         _loc4_ = this.mOpponentCard.getChildByName("Text_Rank") as TextField;
         _loc4_.text = _loc11_.getBadassName();
         _loc4_ = this.mOpponentCard.getChildByName("Text_Name") as TextField;
         _loc4_.text = _loc11_.mName;
         var _loc14_:Sprite = this.mOpponentCard.getChildByName("Thumb") as Sprite;
         if(Boolean(_loc11_) && Boolean(_loc11_.mPicID != null) && _loc11_.mPicID != "")
         {
            IconLoader.addIconPicture(_loc14_,_loc11_.mPicID);
         }
         _loc13_ = this.mOpponentCard.getChildByName("Rank_Icon") as MovieClip;
         _loc4_ = _loc13_.getChildByName("Text_PvP_Rank") as TextField;
         _loc4_.text = _loc11_.mBadassLevel.toString();
         _loc4_ = this.mInfoPanel.getChildByName("Text_Cost_Energy") as TextField;
         _loc4_.text = GameState.mConfig.PlayerStartValues.Default.PvPCostEnergy;
         if(_loc12_.mEnergy < GameState.mConfig.PlayerStartValues.Default.PvPCostEnergy)
         {
            _loc4_.filters = INSUFFICIENT_RESOURCES_FILTER;
            _loc4_.transform.colorTransform = INSUFFICIENT_RESOURCES_MOD;
         }
         var _loc15_:Object = _loc12_.mGlobalUnitCounts;
         for(_loc5_ in _loc15_)
         {
            if(_loc15_[_loc5_] != null && _loc15_[_loc5_] > 0)
            {
               _loc8_ = ItemManager.getItemByTableName(_loc5_,"PlayerUnit");
               this.mPlayerUnits.push(_loc8_);
            }
         }
         this.mPlayerUnits.sort(this.sortUnits);
         for each(_loc6_ in this.mPlayerUnits)
         {
            this.mPlayerUnitCounts.push(_loc15_[_loc6_.mId]);
         }
         _loc7_ = 0;
         while(_loc7_ < OPPONENT_UNIT_PANEL_COUNT)
         {
            _loc9_ = PvPOpponentUnitPanel(this.mOpponentUnitPanels[_loc7_]);
            if(_loc7_ < this.mOpponentUnits.length)
            {
               _loc9_.show();
               _loc9_.setData(this.mOpponentUnits[_loc7_]);
            }
            else
            {
               _loc9_.hide();
            }
            _loc7_++;
         }
         if(smSelectedUnits == null)
         {
            smSelectedUnits = new Array();
            _loc10_ = 0;
            while(_loc10_ < this.mPlayerUnits.length)
            {
               while(this.mPlayerUnitCounts[_loc10_] > 0 && smSelectedUnits.length < 4)
               {
                  this.addUnit(_loc10_);
               }
               _loc10_++;
            }
         }
         this.updateWinRewards();
         this.updateChanceToWin();
         this.refresh();
         doOpeningTransition();
      }
      
      private function sortUnits(param1:PlayerUnitItem, param2:PlayerUnitItem) : Number
      {
         if(param1.mPvPCostSupplies > param2.mPvPCostSupplies)
         {
            return -1;
         }
         if(param1.mPvPCostSupplies < param2.mPvPCostSupplies)
         {
            return 1;
         }
         return 0;
      }
      
      private function backClicked(param1:MouseEvent) : void
      {
         this.closeDialog();
         this.mMatchUpCallback();
      }
      
      private function fightClicked(param1:MouseEvent) : void
      {
         var _loc2_:int = 0;
         var _loc3_:PlayerUnitItem = null;
         var _loc4_:PvPMatch = null;
         var _loc5_:GamePlayerProfile = GameState.mInstance.mPlayerProfile;
         if(_loc5_.mEnergy < GameState.mConfig.PlayerStartValues.Default.PvPCostEnergy)
         {
            GameState.mInstance.getHud().openOutOfEnergyWindow();
         }
         else
         {
            _loc2_ = 0;
            for each(_loc3_ in smSelectedUnits)
            {
               _loc2_ += _loc3_.mPvPCostSupplies;
            }
            if(_loc2_ > _loc5_.mSupplies)
            {
               GameState.mInstance.getHud().openOutOfSuppliesTextBox([_loc2_,_loc5_.mSupplies]);
            }
            else
            {
               _loc4_ = GameState.mInstance.mPvPMatch;
               _loc4_.mPlayerUnits = smSelectedUnits;
               _loc4_.mEnergyCost = GameState.mConfig.PlayerStartValues.Default.PvPCostEnergy;
               _loc4_.mSupplyCost = _loc2_;
               PvPOpponentCollection.smCollection.removeRecentAttack(_loc4_.mOpponent.mFacebookID);
               this.closeDialog();
               EnvEffectManager.destroy();
               GameState.mInstance.mScene.mFog.destroy();
               this.mStartPvPCallback();
            }
         }
      }
      
      private function buyClicked(param1:MouseEvent) : void
      {
         GameState.mInstance.getHud().triggerShopOpening(ShopDialog.TAB_BOOSTERS,"pvp");
      }
      
      private function closeClicked(param1:MouseEvent) : void
      {
         this.closeDialog();
         GameState.mInstance.endPvP();
      }
      
      protected function closeDialog(param1:Boolean = true) : void
      {
         if(param1)
         {
            mDoneCallback((this as Object).constructor);
         }
      }
      
      private function selectionUpClicked(param1:MouseEvent) : void
      {
         this.mPage = Math.max(0,this.mPage - 1);
         this.setScreen();
         this.setScrollButtons();
      }
      
      private function selectionDownClicked(param1:MouseEvent) : void
      {
         this.mPage = Math.min(this.mPageMax - 1,this.mPage + 1);
         this.setScreen();
         this.setScrollButtons();
      }
      
      public function refresh() : void
      {
         this.mPage = 0;
         this.mPageMax = (this.mPlayerUnits.length + UNIT_PANEL_COUNT - 1) / UNIT_PANEL_COUNT;
         this.setScreen();
         this.setScrollButtons();
         this.updateSuppliesCost();
      }
      
      private function setScreen() : void
      {
         var _loc1_:PvPUnitPanel = null;
         var _loc2_:int = 0;
         var _loc3_:PvPSelectedUnitPanel = null;
         var _loc4_:int = this.mPage * UNIT_PANEL_COUNT;
         var _loc5_:int = 0;
         while(_loc5_ < UNIT_PANEL_COUNT)
         {
            _loc1_ = PvPUnitPanel(this.mUnitPanels[_loc5_]);
            _loc2_ = _loc5_ + _loc4_;
            if(_loc2_ < this.mPlayerUnits.length)
            {
               _loc1_.show();
               _loc1_.setData(this.mPlayerUnits[_loc2_],this.mPlayerUnitCounts[_loc2_],_loc2_,smSelectedUnits.length < SELECTED_UNIT_PANEL_COUNT);
            }
            else
            {
               _loc1_.hide();
            }
            _loc5_++;
         }
         var _loc6_:int = 0;
         while(_loc6_ < SELECTED_UNIT_PANEL_COUNT)
         {
            _loc3_ = PvPSelectedUnitPanel(this.mSelectedUnitPanels[_loc6_]);
            if(_loc6_ < smSelectedUnits.length)
            {
               _loc3_.show();
               _loc3_.setData(smSelectedUnits[_loc6_],_loc6_);
            }
            else
            {
               _loc3_.hide();
            }
            _loc6_++;
         }
         this.mButtonFight.setEnabled(smSelectedUnits.length > 0);
      }
      
      private function setScrollButtons() : void
      {
         this.mButtonSelectionScrollDown.setEnabled(this.mPage < this.mPageMax - 1);
         this.mButtonSelectionScrollUp.setEnabled(this.mPage > 0);
      }
      
      public function addUnit(param1:int) : void
      {
         --this.mPlayerUnitCounts[param1];
         smSelectedUnits.push(this.mPlayerUnits[param1]);
         this.setScreen();
         this.updateSuppliesCost();
         this.updateChanceToWin();
      }
      
      public function removeUnit(param1:int) : void
      {
         var _loc2_:PlayerUnitItem = null;
         var _loc3_:PlayerUnitItem = smSelectedUnits.splice(param1,1)[0];
         var _loc4_:int = 0;
         while(_loc4_ < this.mPlayerUnits.length)
         {
            _loc2_ = this.mPlayerUnits[_loc4_];
            if(_loc3_.mId == _loc2_.mId && _loc3_.mType == _loc2_.mType)
            {
               ++this.mPlayerUnitCounts[_loc4_];
               break;
            }
            _loc4_++;
         }
         this.setScreen();
         this.updateSuppliesCost();
         this.updateChanceToWin();
      }
      
      private function updateSuppliesCost() : void
      {
         var _loc4_:GamePlayerProfile = null;
         var _loc1_:PlayerUnitItem = null;
         var _loc2_:TextField = null;
         var _loc3_:int = 0;
         for each(_loc1_ in smSelectedUnits)
         {
            _loc3_ += _loc1_.mPvPCostSupplies;
         }
         _loc2_ = this.mInfoPanel.getChildByName("Text_Cost_Supplies") as TextField;
         _loc2_.text = _loc3_.toString();
         if(!mDefaultFilters)
         {
            mDefaultFilters = _loc2_.filters;
         }
         _loc4_ = GameState.mInstance.mPlayerProfile;
         if(_loc4_.mSupplies < _loc3_)
         {
            _loc2_.filters = INSUFFICIENT_RESOURCES_FILTER;
            _loc2_.transform.colorTransform = INSUFFICIENT_RESOURCES_MOD;
         }
         else
         {
            _loc2_.filters = mDefaultFilters;
            _loc2_.transform.colorTransform = new ColorTransform();
         }
      }
      
      private function updateWinRewards() : void
      {
         var _loc1_:EnemyUnitItem = null;
         var _loc2_:TextField = null;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         for each(_loc1_ in this.mOpponentUnits)
         {
            _loc3_ += _loc1_.mWinRewardMoney;
            _loc4_ += _loc1_.mWinRewardBadass;
         }
         GameState.mInstance.mPvPMatch.mWinRewardMoney = _loc3_;
         GameState.mInstance.mPvPMatch.mWinRewardBadassXp = _loc4_;
         _loc2_ = this.mInfoPanel.getChildByName("Text_Rewards_Money") as TextField;
         _loc2_.text = _loc3_.toString();
         _loc2_ = this.mInfoPanel.getChildByName("Text_Rewards_Rank_Points") as TextField;
         _loc2_.text = _loc4_.toString();
      }
      
      private function updateChanceToWin() : void
      {
         var _loc1_:PlayerUnitItem = null;
         var _loc2_:EnemyUnitItem = null;
         var _loc3_:TextField = null;
         var _loc4_:Number = 0;
         var _loc5_:Number = 0;
         for each(_loc1_ in smSelectedUnits)
         {
            _loc4_ += _loc1_.getDefaultActorPriority();
         }
         for each(_loc2_ in this.mOpponentUnits)
         {
            _loc5_ += _loc2_.getDefaultActorPriority();
         }
         _loc3_ = this.mInfoPanel.getChildByName("Text_Chances") as TextField;
         _loc3_.text = "" + (_loc4_ - _loc5_);
      }
   }
}

