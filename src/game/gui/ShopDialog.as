package game.gui
{
   import com.dchoc.GUI.DCButton;
   import com.dchoc.graphics.DCResourceManager;
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import game.gui.button.ResizingButtonSelected;
   import game.gui.popups.PopUpWindow;
   import game.items.*;
   import game.magicBox.MagicBoxTracker;
   import game.missions.MissionManager;
   import game.net.ServiceIDs;
   import game.player.GamePlayerProfile;
   import game.player.Inventory;
   import game.states.GameState;
   
   public class ShopDialog extends PopUpWindow
   {
      
      public static var mTutorialItem:Item;
      
      public static const TAB_BUTTON_SPACING:int = 3;
      
      public static const TAB_BUTTON_AREA_W:int = 1030;
      
      public static const TAB_SUPPLIES:String = "Supplies";
      
      public static const TAB_AREAS:String = "Areas";
      
      public static const TAB_UNITS:String = "Units";
      
      public static const TAB_BUILDINGS:String = "Buildings";
      
      public static const TAB_PACKS:String = "Packs";
      
      public static const TAB_DECOS:String = "Decos";
      
      public static const TAB_SPECIALS:String = "Specials";
      
      public static const TAB_STORAGE:String = "Storage";
      
      public static const TAB_BUYGOLD:String = "Buygold";
      
      public static const TAB_BUYCASH:String = "Buycash";
      
      public static const TAB_BOOSTERS:String = "Boosters";
      
      public static const TAB_BUNDLES:String = "BuyBundles";
      
      private static const PANEL_COUNT:int = 8;
      
      private static const BIG_PANEL_COUNT:int = 4;
      
      private static const TAB_COUNT:int = 10;
      
      protected var mPlayer:GamePlayerProfile;
      
      protected var mGame:GameState;
      
      private var mButtonClose:DCButton;
      
      private var mButtonPrevious:DCButton;
      
      private var mButtonNext:DCButton;
      
      private var mPanels:Array = new Array();
      
      private var mBigPanels:Array = new Array();
      
      private var mAllItems:Object;
      
      private var mItemsForSell:Array = new Array();
      
      private var mHeader:StylizedHeaderClip;
      
      private var mProfileGold:AutoTextField;
      
      private var mProfileCash:AutoTextField;
      
      private var mShopType:String;
      
      private var mPage:int = 0;
      
      private var mPageMax:int = 0;
      
      private var mTabObjects:Array;
      
      private var mTabButtons:Array;
      
      private var mTabButtonsByName:Array;
      
      private var mTutorialArrow:MovieClip;
      
      private var mIndicatorArrow:MovieClip;
      
      private var useBigPanels:* = false;
      
      public function ShopDialog()
      {
         var _loc1_:Object = null;
         var _loc2_:int = 0;
         var _loc3_:MovieClip = null;
         var _loc4_:Class = DCResourceManager.getInstance().getSWFClass(Config.SWF_POPUPS_FULLSCREEN_NAME,"New_shop_ipad");
         super(new _loc4_(),true,false);
         this.mGame = GameState.mInstance;
         this.mPlayer = this.mGame.mPlayerProfile;
         this.mHeader = new StylizedHeaderClip(mClip.getChildByName("Header") as MovieClip);
         this.mHeader.setText(GameState.getText("SHOP_HEADER"));
         this.mProfileGold = new AutoTextField(mClip.getChildByName("Gold_text") as TextField);
         this.mProfileCash = new AutoTextField(mClip.getChildByName("cash_text") as TextField);
         this.mButtonClose = Utils.createBasicButton(mClip,"Button_Cancel",this.closedPressed);
         this.mButtonPrevious = Utils.createBasicButton(mClip,"left_arrow",this.previousPressed);
         this.mButtonNext = Utils.createBasicButton(mClip,"right_arrow",this.nextPressed);
         this.mTabObjects = new Array();
         var _loc5_:int = 1;
         if(GameState.mConfig.ShopSpecial != null)
         {
            this.mTabObjects[0] = GameState.mConfig.ShopTab[TAB_SPECIALS];
            _loc5_ = 0;
         }
         for each(_loc1_ in GameState.mConfig.ShopTab)
         {
            if(_loc1_.ID != TAB_SPECIALS)
            {
               this.mTabObjects[_loc1_.Order - _loc5_] = _loc1_;
            }
         }
         _loc2_ = 0;
         while(_loc2_ < PANEL_COUNT)
         {
            _loc3_ = MovieClip(mClip.getChildByName("icon_shop_item_" + (_loc2_ + 1)));
            this.mPanels[_loc2_] = new ShopItemPanel(_loc3_,this);
            _loc2_++;
         }
         _loc2_ = 0;
         while(_loc2_ < BIG_PANEL_COUNT)
         {
            _loc3_ = MovieClip(mClip.getChildByName("icon_shop_item_big_" + (_loc2_ + 1)));
            this.mBigPanels[_loc2_] = new ShopItemPanel(_loc3_,this);
            _loc2_++;
         }
      }
      
      public function Activate(param1:Function, param2:String, param3:String) : void
      {
         var _loc4_:String = null;
         var _loc5_:Boolean = false;
         var _loc6_:String = null;
         var _loc7_:String = null;
         mDoneCallback = param1;
         this.mShopType = param3;
         this.mProfileGold.setText(this.mPlayer.mPremium.toString());
         this.mProfileCash.setText(this.mPlayer.mMoney.toString());
         var _loc8_:int = 0;
         while(_loc8_ < this.mTabObjects.length)
         {
            if((this.mTabObjects[_loc8_] as Object).TabType is Array)
            {
               _loc5_ = false;
               for each(_loc6_ in (this.mTabObjects[_loc8_] as Object).TabType)
               {
                  if(_loc6_ == this.mShopType)
                  {
                     _loc5_ = true;
                     break;
                  }
               }
               if(!_loc5_)
               {
                  this.mTabObjects.splice(_loc8_,1);
                  _loc8_--;
               }
            }
            else if((this.mTabObjects[_loc8_] as Object).TabType != this.mShopType)
            {
               this.mTabObjects.splice(_loc8_,1);
               _loc8_--;
            }
            _loc8_++;
         }
         this.activateShopTabButtons();
         if(!this.mAllItems)
         {
            this.updateItems();
         }
         for(_loc4_ in this.mTabButtonsByName)
         {
            if(_loc4_ != TAB_DECOS)
            {
               (this.mTabButtonsByName[_loc4_] as ResizingButtonSelected).setEnabled(!mTutorialItem);
            }
         }
         if(mTutorialItem)
         {
            this.setTab(TAB_DECOS);
            this.setTutorialArrow();
         }
         else if(param2)
         {
            this.setTab(param2);
         }
         else if(this.mTabButtonsByName[GameState.mInstance.getHud().getLastTab()])
         {
            for each(var tab in this.mTabObjects)
            {
               if(tab.ID == GameState.mInstance.getHud().getLastTab())
               {
                  this.useBigPanels = "BigPanels" in tab ? tab.BigPanels : false;
                  break;
               }
            }
            this.setTab(GameState.mInstance.getHud().getLastTab());
         }
         else
         {
            for(_loc7_ in this.mTabButtonsByName)
            {
               if((this.mTabButtonsByName[_loc7_] as ResizingButtonSelected).isEnable())
               {
                  this.setTab(_loc7_);
                  break;
               }
            }
         }
         doOpeningTransition();
      }
      
      public function activateShopTabButtons() : void
      {
         var _loc1_:ResizingButtonSelected = null;
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:ResizingButtonSelected = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:ResizingButtonSelected = null;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         this.mTabButtonsByName = new Array();
         this.mTabButtons = new Array();
         var _loc10_:int = 1;
         while(_loc10_ <= TAB_COUNT)
         {
            _loc1_ = Utils.createResizingButtonSelected(mClip,"Button_Tab_" + _loc10_,this.tabButtonPressed);
            _loc1_.resizeNeeded = false;
            if(!_loc1_)
            {
               break;
            }
            if(_loc10_ <= this.mTabObjects.length)
            {
               _loc1_.setText((this.mTabObjects[_loc10_ - 1] as Object).Name);
               _loc1_.setPool(this.mTabButtons);
               _loc1_.setAllowDeselection(false);
               this.mTabButtonsByName[(this.mTabObjects[_loc10_ - 1] as Object).ID] = _loc1_;
            }
            else
            {
               _loc1_.setVisible(false);
            }
            _loc10_++;
         }
         var _loc11_:Boolean = true;
         while(_loc11_)
         {
            _loc2_ = 0;
            _loc3_ = 0;
            _loc5_ = int(this.mTabButtons.length);
            _loc6_ = 0;
            while(_loc6_ < _loc5_)
            {
               _loc4_ = this.mTabButtons[_loc6_] as ResizingButtonSelected;
               _loc3_ += _loc4_.getWidth() + TAB_BUTTON_SPACING;
               if(_loc4_.mTextSize > _loc2_)
               {
                  _loc2_ = _loc4_.mTextSize;
               }
               _loc6_++;
            }
            if(_loc3_ > TAB_BUTTON_AREA_W && _loc2_ > 1)
            {
               _loc8_ = int(this.mTabButtons.length);
               _loc9_ = 0;
               while(_loc9_ < _loc8_)
               {
                  _loc7_ = this.mTabButtons[_loc9_] as ResizingButtonSelected;
                  _loc7_.setTextSize(_loc2_ - 1);
                  _loc9_++;
               }
            }
            else
            {
               _loc11_ = false;
            }
         }
      }
      
      public function updateItems() : void
      {
         var _loc1_:Object = null;
         var _loc2_:Array = null;
         var _loc3_:Object = null;
         var _loc4_:Object = null;
         var _loc5_:Object = GameState.mConfig;
         var _loc6_:Object = _loc5_.ShopTab;
         var _loc7_:Array = new Array();
         this.mAllItems = new Object();
         for each(_loc1_ in _loc6_)
         {
            _loc2_ = new Array();
            _loc3_ = _loc5_[_loc1_.ItemTable];
            for each(_loc4_ in _loc3_)
            {
               _loc2_[_loc4_.ID] = ItemManager.getItem(_loc4_.Item.ID,_loc4_.Item.Type);
               if(_loc1_.ID == TAB_SPECIALS)
               {
                  _loc7_.push(_loc2_[_loc4_.ID]);
               }
            }
            this.mAllItems[_loc1_.ID] = _loc2_;
         }
         this.mAllItems[TAB_SPECIALS] = _loc7_;
      }
      
      private function setTab(param1:String) : void
      {
         var _loc2_:Array = null;
         var _loc3_:Inventory = null;
         var _loc4_:int = 0;
         if(this.mTabButtonsByName[param1])
         {
            (this.mTabButtonsByName[param1] as ResizingButtonSelected).select();
         }
         if(param1 == TAB_AREAS || !this.mAllItems[param1] || (this.mAllItems[param1] as Array).length <= 0)
         {
            (this.mTabButtonsByName[TAB_AREAS] as ResizingButtonSelected).select();
            this.mItemsForSell = new Array();
            _loc2_ = this.mAllItems[TAB_AREAS] as Array;
            _loc3_ = this.mPlayer.mInventory;
            _loc4_ = 0;
            while(_loc4_ < _loc2_.length)
            {
               if(_loc3_.getNumberOfItems(_loc2_[_loc4_]) == 0 && this.mGame.mScene.isAreaReachable(_loc2_[_loc4_]) && _loc2_[_loc4_].mMapId == GameState.mInstance.mCurrentMapId)
               {
                  this.mItemsForSell.push(_loc2_[_loc4_]);
               }
               _loc4_++;
            }
         }
         else
         {
            this.mItemsForSell = this.mAllItems[param1];
         }
         GameState.mInstance.getHud().setLastTab(param1);
         this.refresh();
      }
      
      public function disableSpecialsButton() : void
      {
         if(this.mTabButtonsByName[TAB_SPECIALS])
         {
            (this.mTabButtonsByName[TAB_SPECIALS] as ResizingButtonSelected).setEnabled(false);
         }
      }
      
      public function setScreen() : void
      {
         var _loc1_:ShopItemPanel = null;
         var _loc2_:int = 0;
         var _loc3_:int = this.useBigPanels ? this.mPage * BIG_PANEL_COUNT : this.mPage * PANEL_COUNT;
         var _loc4_:int = 0;
         var _loc5_:int = this.useBigPanels ? BIG_PANEL_COUNT : PANEL_COUNT;
         for each(var panel in this.mBigPanels)
         {
            this.useBigPanels ? panel.show() : panel.hide();
         }
         for each(panel in this.mPanels)
         {
            this.useBigPanels ? panel.hide() : panel.show();
         }
         while(_loc4_ < _loc5_)
         {
            if(this.useBigPanels)
            {
               _loc1_ = ShopItemPanel(this.mBigPanels[_loc4_]);
            }
            else
            {
               _loc1_ = ShopItemPanel(this.mPanels[_loc4_]);
            }
            _loc2_ = _loc4_ + _loc3_;
            if(_loc2_ < this.mItemsForSell.length)
            {
               _loc1_.show();
               _loc1_.setData(this.mItemsForSell[_loc2_]);
            }
            else
            {
               _loc1_.hide();
            }
            _loc4_++;
         }
      }
      
      private function setPageNum() : void
      {
         this.mButtonNext.setEnabled(this.mPage < this.mPageMax - 1);
         this.mButtonPrevious.setEnabled(this.mPage > 0);
      }
      
      public function refresh() : void
      {
         this.mPage = 0;
         if(this.useBigPanels)
         {
            this.mPageMax = (this.mItemsForSell.length + BIG_PANEL_COUNT - 1) / BIG_PANEL_COUNT;
         }
         else
         {
            this.mPageMax = (this.mItemsForSell.length + PANEL_COUNT - 1) / PANEL_COUNT;
         }
         this.setScreen();
         this.setPageNum();
         if(GameState.mInstance.mIndicatedShopItem != null)
         {
            this.setIndicatorArrow();
         }
         else
         {
            this.removeIndicatorArrow();
         }
      }
      
      private function tabButtonPressed(param1:MouseEvent) : void
      {
         GameState.mInstance.mIndicatedShopItem = null;
         this.removeIndicatorArrow();
         var _loc2_:int = 0;
         while(_loc2_ < this.mTabButtons.length)
         {
            if((this.mTabButtons[_loc2_] as ResizingButtonSelected).getMovieClip() == param1.target)
            {
               this.useBigPanels = "BigPanels" in (this.mTabObjects[_loc2_] as Object) ? (this.mTabObjects[_loc2_] as Object).BigPanels : false;
               this.setTab((this.mTabObjects[_loc2_] as Object).ID);
               return;
            }
            _loc2_++;
         }
      }
      
      private function previousPressed(param1:MouseEvent) : void
      {
         GameState.mInstance.mIndicatedShopItem = null;
         this.removeIndicatorArrow();
         if(mTutorialItem)
         {
            return;
         }
         this.mPage = Math.max(0,this.mPage - 1);
         this.setScreen();
         this.setPageNum();
      }
      
      private function nextPressed(param1:MouseEvent) : void
      {
         if(GameState.mInstance.mIndicatedShopItem != null)
         {
            if((GameState.mInstance.mIndicatedShopItem as ShopItem).mId == "SpecialForces" || (GameState.mInstance.mIndicatedShopItem as ShopItem).mId == "MobileRocketBattery")
            {
               this.mIndicatorArrow.visible = true;
            }
            else
            {
               GameState.mInstance.mIndicatedShopItem = null;
               this.removeIndicatorArrow();
            }
         }
         if(mTutorialItem)
         {
            return;
         }
         this.mPage = Math.min(this.mPageMax - 1,this.mPage + 1);
         this.setScreen();
         this.setPageNum();
      }
      
      private function closedPressed(param1:MouseEvent) : void
      {
         if(mTutorialItem)
         {
            return;
         }
         this.closeDialog();
      }
      
      public function buyItem(param1:ShopItem) : void
      {
         var _loc2_:Object = null;
         if(param1.mType == "BuyGold" || param1.mType == "BuyCash")
         {
            if(Config.DEBUG_MODE)
            {
            }
            if(FeatureTuner.USE_GOOGLE_IN_APP_BILLING)
            {
               this.mGame.mAndroidPaymentManager.startPurchase(param1);
            }
            else
            {
               if(param1.mType == "BuyGold")
               {
                  _loc2_ = {
                     "gold":(param1 as BuyGoldItem).mGoldGain,
                     "ver":1
                  };
                  this.mGame.mPlayerProfile.addPremium((param1 as BuyGoldItem).mGoldGain,null,MagicBoxTracker.paramsObj(),param1);
               }
               else
               {
                  _loc2_ = {
                     "cash":(param1 as BuyCashItem).mCashGain,
                     "ver":1
                  };
                  this.mGame.mPlayerProfile.addMoney((param1 as BuyCashItem).mCashGain,null,MagicBoxTracker.paramsObj(),param1);
               }
               this.mGame.mServer.serverCallServiceWithParameters(ServiceIDs.ADD_GOLD_AND_CASH,_loc2_,false);
            }
            this.closeDialog();
         }
         else
         {
            if((!param1.canAffordItemWithResources() || !param1.capAvailable()) && !Config.EDITING_MODE)
            {
               if(Config.DEBUG_MODE)
               {
               }
               return;
            }
            if(param1 is MapItem)
            {
               if(this.mShopType == "pvp")
               {
                  this.mGame.mPlayerProfile.mInventory.addItems(MapItem(param1),1);
               }
               else
               {
                  this.mGame.addToWorld(MapItem(param1));
               }
               this.closeDialog();
               if(mTutorialItem)
               {
                  MissionManager.increaseCounter("OpenShop",mTutorialItem.mId,1);
                  this.removeTutorialArrow();
               }
            }
            else if(param1.getCostPremium() > 0)
            {
               GameState.mInstance.externalCallBuyItem(param1);
               this.closeDialog();
            }
            else
            {
               this.mGame.executeBuyItem(param1);
               this.closeDialog();
            }
         }
      }
      
      public function closeDialog() : void
      {
         this.removeIndicatorArrow();
         GameState.mInstance.mIndicatedShopItem = null;
         if(mDoneCallback != null)
         {
            mDoneCallback((this as Object).constructor);
         }
      }
      
      private function setTutorialArrow() : void
      {
         var _loc1_:Number = NaN;
         var _loc2_:Number = NaN;
         var _loc3_:ShopItemPanel = null;
         var _loc4_:int = 0;
         while(_loc4_ < this.mItemsForSell.length)
         {
            if((this.mItemsForSell[_loc4_] as ShopItem).mId == mTutorialItem.mId)
            {
               _loc3_ = ShopItemPanel(this.mPanels[_loc4_]);
               _loc1_ = _loc3_.mBasePanel.x;
               _loc2_ = _loc3_.mBasePanel.y - _loc3_.mBasePanel.height / 2;
               break;
            }
            _loc4_++;
         }
         var _loc5_:Class = DCResourceManager.getInstance().getSWFClass(Config.SWF_INTERFACE_NAME,"grid_highlighted");
         this.mTutorialArrow = new _loc5_();
         this.mTutorialArrow.mouseEnabled = false;
         this.mTutorialArrow.mouseChildren = false;
         this.mTutorialArrow.x = _loc1_;
         this.mTutorialArrow.y = _loc2_;
         addChild(this.mTutorialArrow);
      }
      
      private function removeTutorialArrow() : void
      {
         if(this.mTutorialArrow)
         {
            removeChild(this.mTutorialArrow);
            this.mTutorialArrow = null;
         }
      }
      
      private function setIndicatorArrow() : void
      {
         var _loc1_:Number = NaN;
         var _loc2_:Number = NaN;
         var _loc3_:ShopItemPanel = null;
         var _loc4_:int = 0;
         while(_loc4_ < this.mItemsForSell.length)
         {
            if((this.mItemsForSell[_loc4_] as ShopItem).mId == GameState.mInstance.mIndicatedShopItem.mId)
            {
               _loc3_ = ShopItemPanel(this.mPanels[_loc4_]);
               if(_loc3_ != null)
               {
                  _loc1_ = _loc3_.mBasePanel.x + _loc3_.mBasePanel.width / 2;
                  _loc2_ = _loc3_.mBasePanel.y;
               }
               break;
            }
            _loc4_++;
         }
         var _loc5_:Class = DCResourceManager.getInstance().getSWFClass(Config.SWF_INTERFACE_NAME,"T_arrow_LB");
         this.mIndicatorArrow = new _loc5_();
         this.mIndicatorArrow.mouseEnabled = false;
         this.mIndicatorArrow.mouseChildren = false;
         if(_loc3_ == null)
         {
            this.mIndicatorArrow.visible = false;
            if(GameState.mInstance.mIndicatedShopItem.mId == "SpecialForces")
            {
               _loc3_ = ShopItemPanel(this.mPanels[0]);
               _loc1_ = _loc3_.mBasePanel.x + _loc3_.mBasePanel.width / 2;
               _loc2_ = _loc3_.mBasePanel.y;
            }
            if(GameState.mInstance.mIndicatedShopItem.mId == "MobileRocketBattery")
            {
               _loc3_ = ShopItemPanel(this.mPanels[1]);
               _loc1_ = _loc3_.mBasePanel.x + _loc3_.mBasePanel.width / 2;
               _loc2_ = _loc3_.mBasePanel.y;
            }
         }
         this.mIndicatorArrow.x = _loc1_;
         this.mIndicatorArrow.y = _loc2_;
         addChild(this.mIndicatorArrow);
      }
      
      private function removeIndicatorArrow() : void
      {
         if(this.mIndicatorArrow)
         {
            removeChild(this.mIndicatorArrow);
            this.mIndicatorArrow = null;
         }
      }
   }
}

