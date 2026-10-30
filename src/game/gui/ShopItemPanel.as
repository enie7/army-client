package game.gui
{
   import com.dchoc.GUI.DCButton;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import game.gui.button.ArmyButton;
   import game.gui.popups.PopUpWindow;
   import game.items.AreaItem;
   import game.items.ConstructionItem;
   import game.items.DecorationItem;
   import game.items.HFEPlotItem;
   import game.items.Item;
   import game.items.ItemManager;
   import game.items.MapItem;
   import game.items.PlayerInstallationItem;
   import game.items.PlayerUnitItem;
   import game.items.ShopItem;
   import game.player.GamePlayerProfile;
   import game.states.GameState;
   import game.utils.TimeUtils;
   
   public class ShopItemPanel
   {
      
      private var mItem:ShopItem;
      
      public var mBasePanel:MovieClip;
      
      private var mDialog:PopUpWindow;
      
      private var mItemInfo:MovieClip;
      
      private var mInfoButton:DCButton;
      
      private var mItemButton:DCButton;
      
      private var mName:TextField;
      
      private var mDesc:TextField;
      
      private var mValue:TextField;
      
      private var mIconBaseEnable:MovieClip;
      
      private var mIconBaseDisable:MovieClip;
      
      private var mIconGold:MovieClip;
      
      private var mIconCash:MovieClip;
      
      private var mIconDollar:MovieClip;
      
      private var mNameInfo:TextField;
      
      private var mDescInfo:TextField;
      
      private var buyIsBeingPressed:Boolean = false;
      
      public function ShopItemPanel(param1:MovieClip, param2:PopUpWindow)
      {
         super();
         this.mBasePanel = param1;
         this.mDialog = param2;
      }
      
      public function hide() : void
      {
         if(this.mBasePanel.parent)
         {
            this.mBasePanel.parent.removeChild(this.mBasePanel);
         }
      }
      
      public function show() : void
      {
         this.mDialog.addChild(this.mBasePanel);
         this.mItemInfo = this.mBasePanel.getChildByName("shopiteminfo") as MovieClip;
         this.mItemInfo.visible = false;
         this.mInfoButton = new ArmyButton(this.mBasePanel,this.mBasePanel.getChildByName("iconinfo") as MovieClip,DCButton.BUTTON_TYPE_OK,null,null,this.infoPressed,null,null,this.infoUp);
      }
      
      public function setData(param1:ShopItem) : void
      {
         var _loc2_:TextField = null;
         var _loc3_:TextField = null;
         this.mItem = param1;
         this.mItemButton = Utils.createBasicButton(this.mBasePanel,"shopitem",this.buyPressed);
         this.mItemButton.setVisible(true);
         var _loc4_:MovieClip = this.mItemButton.getMovieClip() as MovieClip;
         var _loc5_:MovieClip = _loc4_.getChildByName("shopitem_container") as MovieClip;
         var _loc6_:MovieClip = _loc5_.getChildByName("Counter_Unlock") as MovieClip;
         this.mIconBaseDisable = _loc5_.getChildByName("Icon_disable") as MovieClip;
         this.mIconBaseEnable = _loc5_.getChildByName("Icon_enable") as MovieClip;
         if(param1.isUnlocked())
         {
            _loc6_.visible = false;
            this.mIconBaseDisable.visible = false;
            this.mIconBaseEnable.visible = true;
            if(param1 is MapItem && Boolean((param1 as MapItem).getShopIconGraphics()))
            {
               IconLoader.addIcon(this.mIconBaseEnable,new IconAdapter((param1 as MapItem).getShopIconGraphics(),(param1 as MapItem).getShopIconGraphicsFile()),this.iconLoaded);
            }
            else
            {
               IconLoader.addIcon(this.mIconBaseEnable,param1,this.iconLoaded);
            }
         }
         else
         {
            _loc6_.visible = true;
            this.mIconBaseDisable.visible = true;
            this.mIconBaseEnable.visible = false;
            if(param1 is MapItem && Boolean((param1 as MapItem).getShopIconGraphics()))
            {
               IconLoader.addIcon(this.mIconBaseDisable,new IconAdapter((param1 as MapItem).getShopIconGraphics(),(param1 as MapItem).getShopIconGraphicsFile()),this.iconLoaded);
            }
            else
            {
               IconLoader.addIcon(this.mIconBaseDisable,param1,this.iconLoaded);
            }
            _loc2_ = _loc6_.getChildByName("Text_Title") as TextField;
            _loc3_ = _loc6_.getChildByName("Text_Amount") as TextField;
            if(!param1.hasRequiredLevel())
            {
               _loc2_.text = GameState.getText("SHOP_REQUIRES_LEVEL");
               _loc3_.text = String(param1.mRequiredLevel);
            }
            else if(!param1.hasRequiredAllies())
            {
               _loc2_.text = GameState.getText("SHOP_REQUIRES_ALLIES");
               _loc3_.text = String(param1.mRequiredAllies);
            }
            else if(!param1.hasRequiredMission())
            {
               _loc2_.text = "";
               _loc3_.text = "X";
            }
            else if(!param1.hasRequiredBuilding())
            {
               _loc2_.text = "";
               _loc3_.text = "X";
            }
            else if(!param1.hasRequiredIntel())
            {
               _loc2_.text = "";
               _loc3_.text = "X";
            }
            else
            {
               _loc2_.text = "";
               _loc3_.text = "X";
            }
         }
         this.mName = _loc5_.getChildByName("Text_Title") as TextField;
         this.mName.text = param1.mName;
         this.mDesc = _loc5_.getChildByName("Text_Desc") as TextField;
         this.mDesc.visible = false;
         if(param1.mType == "BuyGold" || param1.mType == "BuyCash")
         {
            this.mDesc.visible = true;
            this.mDesc.text = param1.getDescription();
         }
         this.mValue = _loc5_.getChildByName("gold_text") as TextField;
         this.mValue.text = this.getTextForBuyButton(param1);
         this.mIconGold = _loc5_.getChildByName("gold") as MovieClip;
         this.mIconCash = _loc5_.getChildByName("cash") as MovieClip;
         this.mIconDollar = _loc5_.getChildByName("icon_dollor") as MovieClip;
         this.setResourceForBuyButton(param1);
         this.setItemInfoValues(param1);
      }
      
      public function iconLoaded(param1:Sprite) : void
      {
         Utils.scaleIcon(param1,90,90);
      }
      
      private function setItemInfoValues(param1:ShopItem) : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:ConstructionItem = null;
         var _loc5_:DecorationItem = null;
         var _loc6_:PlayerInstallationItem = null;
         var _loc7_:HFEPlotItem = null;
         this.mNameInfo = this.mItemInfo.getChildByName("Text_Title") as TextField;
         this.mNameInfo.text = param1.mName;
         this.mDescInfo = this.mItemInfo.getChildByName("Text_Description") as TextField;
         this.mDescInfo.autoSize = TextFieldAutoSize.CENTER;
         this.mDescInfo.wordWrap = true;
         if(param1.isUnlocked())
         {
            this.mDescInfo.text = param1.getDescription();
         }
         else
         {
            if(param1 is AreaItem)
            {
               this.mDescInfo.text = param1.getDescription();
            }
            if(param1.isAlreadyAdded())
            {
               this.mDescInfo.text = param1.getUnlockText();
            }
            else
            {
               this.mDescInfo.text = GameState.getText("SHOP_REQUIRES_PREFIX") + ": " + param1.getUnlockText() + "\n" + param1.getUnlockCostText();
            }
         }
         if(param1 is MapItem)
         {
            _loc2_ = int((param1 as MapItem).mCrafting.Time);
            if(_loc2_ > 0 && !(param1 is ConstructionItem))
            {
               this.mDescInfo.text = this.mDescInfo.text + "\n" + "\n" + GameState.getText("SHOP_PRODUCTION_TIME",[TimeUtils.secondsToString(_loc2_ * 60,2,true)]);
            }
         }
         else if(param1.mType == "Area" && !param1.mEarlyUnlockBought)
         {
            _loc3_ = (param1 as AreaItem).mCostIntel;
            this.mDescInfo.text = this.mDescInfo.text + "\n" + "\n" + GameState.getText("SHOP_REQUIRES_PREFIX") + " " + _loc3_ + " " + GameState.getText("SHOP_REQUIRES_INTEL");
         }
         var _loc8_:PlayerUnitItem = null;
         switch(param1.mType)
         {
            case "Infantry":
               _loc8_ = this.mItem as PlayerUnitItem;
               this.mDescInfo.text = this.mDescInfo.text + "\n" + "\n" + GameState.getText("SHOP_PANEL_ITEM_HEALTH") + ": " + _loc8_.mHealth + "\n" + GameState.getText("SHOP_PANEL_ITEM_DAMAGE") + ": " + _loc8_.mDamage + "\n" + GameState.getText("SHOP_PANEL_ITEM_RANGE") + ": " + _loc8_.mAttackRange;
               break;
            case "Armor":
               _loc8_ = this.mItem as PlayerUnitItem;
               this.mDescInfo.text = this.mDescInfo.text + "\n" + "\n" + GameState.getText("SHOP_PANEL_ITEM_HEALTH") + ": " + _loc8_.mHealth + "\n" + GameState.getText("SHOP_PANEL_ITEM_DAMAGE") + ": " + _loc8_.mDamage + "\n" + GameState.getText("SHOP_PANEL_ITEM_RANGE") + ": " + _loc8_.mAttackRange;
               break;
            case "Artillery":
               _loc8_ = this.mItem as PlayerUnitItem;
               this.mDescInfo.text = this.mDescInfo.text + "\n" + "\n" + GameState.getText("SHOP_PANEL_ITEM_HEALTH") + ": " + _loc8_.mHealth + "\n" + GameState.getText("SHOP_PANEL_ITEM_DAMAGE") + ": " + _loc8_.mDamage + "\n" + GameState.getText("SHOP_PANEL_ITEM_RANGE") + ": " + _loc8_.mAttackRange;
               break;
            case "Lab":
               _loc8_ = this.mItem as PlayerUnitItem;
               this.mDescInfo.text = this.mDescInfo.text + "\n" + "\n" + GameState.getText("SHOP_PANEL_ITEM_HEALTH") + ": " + _loc8_.mHealth + "\n" + GameState.getText("SHOP_PANEL_ITEM_DAMAGE") + ": " + _loc8_.mDamage + "\n" + GameState.getText("SHOP_PANEL_ITEM_RANGE") + ": " + _loc8_.mAttackRange;
               break;
            case "Building":
               _loc4_ = this.mItem as ConstructionItem;
               this.mDescInfo.text = this.mDescInfo.text + "\n" + "\n" + GameState.getText("SHOP_PANEL_ITEM_SIZE") + ": " + _loc4_.getItemSizeString();
               break;
            case "NonFunctionalDeco":
               _loc5_ = this.mItem as DecorationItem;
               this.mDescInfo.text = this.mDescInfo.text + "\n" + "\n" + GameState.getText("SHOP_PANEL_ITEM_SIZE") + ": " + _loc5_.getItemSizeString();
               break;
            case "CounterAttack":
               _loc6_ = this.mItem as PlayerInstallationItem;
               this.mDescInfo.text = this.mDescInfo.text + "\n" + "\n" + GameState.getText("SHOP_PANEL_ITEM_HEALTH") + ": " + _loc6_.mHealth + "\n" + GameState.getText("SHOP_PANEL_ITEM_DAMAGE") + ": " + _loc6_.mDamage + "\n" + GameState.getText("SHOP_PANEL_ITEM_RANGE") + ": " + _loc6_.mAttackRange + "\n" + GameState.getText("SHOP_PANEL_ITEM_SIZE") + ": " + _loc6_.getItemSizeString();
               break;
            case "EnergyRefill":
            case "BuyGold":
            case "BuyCash":
            case "SupplyPack":
            case "HomeFrontEffort":
            case "Signal":
            case "Area":
            case "Bundle":
               break;
            case "HFEPlot":
               _loc7_ = this.mItem as HFEPlotItem;
               this.mDescInfo.text = this.mDescInfo.text + "\n" + "\n" + GameState.getText("SHOP_PANEL_ITEM_SIZE") + ": " + _loc7_.getItemSizeString();
         }
      }
      
      private function setResourceForBuyButton(param1:ShopItem) : void
      {
         if(param1.mType == "BuyGold" || param1.mType == "BuyCash")
         {
            this.mIconGold.visible = false;
            this.mIconCash.visible = false;
            this.mIconDollar.visible = true;
         }
         else if(param1.getCostMoney() > 0)
         {
            this.mIconGold.visible = false;
            this.mIconCash.visible = true;
            this.mIconDollar.visible = false;
         }
         else if(param1.getCostPremium() > 0)
         {
            this.mIconGold.visible = true;
            this.mIconCash.visible = false;
            this.mIconDollar.visible = false;
         }
      }
      
      private function getResourceForBuyButton(param1:ShopItem) : Item
      {
         if(param1.mType == "BuyGold" || param1.mType == "BuyCash")
         {
            return ItemManager.getItem("Dollar","Resource");
         }
         if(param1.getCostMoney() > 0)
         {
            return ItemManager.getItem("Money","Resource");
         }
         if(param1.getCostSupplies() > 0)
         {
            return ItemManager.getItem("Supplies","Resource");
         }
         if(param1.getCostMaterial() > 0)
         {
            return ItemManager.getItem("Material","Resource");
         }
         if(param1.getCostPremium() > 0)
         {
            return ItemManager.getItem("Premium","Resource");
         }
         return null;
      }
      
      private function getTextForBuyButton(param1:ShopItem, param2:Boolean = false) : String
      {
         if(param1.getCostMoney() > 0)
         {
            return String(param1.getCostMoney(param2));
         }
         if(param1.getCostSupplies() > 0)
         {
            return String(param1.getCostSupplies(param2));
         }
         if(param1.getCostMaterial() > 0)
         {
            return String(param1.getCostMaterial(param2));
         }
         if(param1.getCostPremium() > 0)
         {
            return String(param1.getCostPremium(param2));
         }
         return "";
      }
      
      private function buyPressed(param1:MouseEvent) : void
      {
         var _loc2_:GamePlayerProfile = null;
         var _loc3_:GameHUD = null;
         if(!this.buyIsBeingPressed)
         {
            this.buyIsBeingPressed = true;
            _loc2_ = null;
            _loc3_ = GameState.mInstance.mHUD;
            if(this.mItem.isUnlocked())
            {
               if(this.mItem.canAffordItemWithResources() && this.mItem.capAvailable())
               {
                  if(this.mDialog is ShopDialog)
                  {
                     ShopDialog(this.mDialog).buyItem(this.mItem);
                  }
                  else if(this.mDialog is ProductionDialog)
                  {
                     ProductionDialog(this.mDialog).startProduction(this.mItem);
                  }
               }
               else
               {
                  _loc2_ = GameState.mInstance.mPlayerProfile;
                  if(!this.mItem.hasRequiredIntel())
                  {
                     _loc3_.openOutOfIntelTextBox([this.mItem]);
                  }
                  else if(!this.mItem.capAvailable())
                  {
                     if(GameState.mInstance.mCurrentMapId == "Snow")
                     {
                        GameState.mInstance.mHUD.openPolarCapTextBox();
                     }
                     else if(this.mItem.mType == "Infantry")
                     {
                        _loc3_.openInfantryCapTextBox();
                     }
                     else if(this.mItem.mType == "Armor")
                     {
                        _loc3_.openArmorCapTextBox();
                     }
                     else if(this.mItem.mType == "Artillery")
                     {
                        _loc3_.openArtilleryCapTextBox();
                     }
                     else if(this.mItem.mType == "Lab")
                     {
                        _loc3_.openLabCapTextBox();
                     }
                     else
                     {
                        _loc3_.openUnitCapTextBox(this.mItem);
                     }
                  }
                  else if(this.mItem.getCostSupplies() > _loc2_.mSupplies)
                  {
                     if(this.mDialog is ProductionDialog)
                     {
                        _loc3_.openOutOfSuppliesTextBox(null);
                     }
                  }
                  else if(this.mItem.getCostMoney() > _loc2_.mMoney)
                  {
                     _loc3_.openOutOfCashTextBox(null);
                  }
                  if(this.mDialog is ShopDialog)
                  {
                     ShopDialog(this.mDialog).closeDialog();
                  }
               }
            }
            else
            {
               if(!this.mItem.canBeBuiltOnThisMap())
               {
                  return;
               }
               if(!this.mItem.hasRequiredMission())
               {
                  _loc3_.openUnlockItemByMissionTextBox(this.mItem);
               }
               else if(!this.mItem.hasRequiredLevel())
               {
                  _loc3_.openUnlockItemByLevelTextBox(this.mItem);
               }
               else if(!this.mItem.hasRequiredBuilding())
               {
                  _loc3_.openUnlockItemByBuildingTextBox(this.mItem);
               }
               else if(!this.mItem.hasRequiredAllies())
               {
                  _loc3_.openUnlockItemByAlliesTextBox(this.mItem);
               }
               if(this.mDialog is ShopDialog)
               {
                  ShopDialog(this.mDialog).closeDialog();
               }
            }
         }
      }
      
      private function infoPressed(param1:MouseEvent) : void
      {
         this.mItemButton.setVisible(false);
         this.mItemInfo.visible = true;
      }
      
      private function infoUp(param1:MouseEvent) : void
      {
         this.mItemButton.setVisible(true);
         this.mItemInfo.visible = false;
      }
   }
}

