package game.gui.popups
{
   import com.dchoc.GUI.DCButton;
   import com.dchoc.graphics.DCResourceManager;
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import game.gui.StylizedHeaderClip;
   import game.gui.button.ResizingButton;
   import game.states.GameState;
   
   public class BuyMoneyWindow extends PopUpWindow
   {
      
      private var mButtonContinue:ResizingButton;
      
      private var mButtonCancel:DCButton;
      
      private var mPricePoints:*;
      
      private var mSelectedPricePoint:int;
      
      private var mPricePointPanels:Array;
      
      public function BuyMoneyWindow()
      {
         var _loc1_:Class = DCResourceManager.getInstance().getSWFClass(Config.SWF_POPUPS_START_NAME,"popup_exchange_cash");
         super(new _loc1_() as MovieClip,true);
         this.mButtonCancel = Utils.createBasicButton(mClip,"Button_Cancel",this.closeClicked);
         this.mButtonContinue = Utils.createFBIconResizingButton(mClip,"Button_Share",this.continueClicked);
         this.mButtonContinue.setText(GameState.getText("BUTTON_CONTINUE"));
         this.mPricePoints = GameState.mConfig["FBCreditPriceVariations"];
      }
      
      public function Activate(param1:Function, param2:Array) : void
      {
         var _loc3_:StylizedHeaderClip = null;
         var _loc4_:TextField = null;
         var _loc5_:MovieClip = null;
         var _loc6_:MoneyPricePointPanel = null;
         mDoneCallback = param1;
         _loc3_ = new StylizedHeaderClip(mClip.getChildByName("Header") as MovieClip,GameState.getText("MENU_HEADER_BUY_MONEY"));
         _loc4_ = mClip.getChildByName("Text_Description") as TextField;
         _loc4_.text = GameState.getText("MENU_DESC_BUY_MONEY");
         _loc4_ = mClip.getChildByName("Text_Disclaimer") as TextField;
         _loc4_.text = GameState.getText("MONEY_DISCLAIMER");
         this.mSelectedPricePoint = 0;
         var _loc7_:Array = new Array();
         this.mPricePointPanels = new Array();
         var _loc8_:* = null;
         for(_loc8_ in this.mPricePoints)
         {
            _loc5_ = mClip.getChildByName("Frame_Option_" + (int(_loc8_) + 1)) as MovieClip;
            _loc6_ = new MoneyPricePointPanel(_loc5_,this.mPricePoints[_loc8_],int(_loc8_),_loc7_,this.selectClicked);
            this.mPricePointPanels.push(_loc6_);
         }
         doOpeningTransition();
      }
      
      private function closeClicked(param1:MouseEvent) : void
      {
         mDoneCallback((this as Object).constructor);
      }
      
      private function continueClicked(param1:MouseEvent) : void
      {
         mDoneCallback((this as Object).constructor);
         GameState.mInstance.externalCallBuyMoney(this.mPricePoints[String(this.mSelectedPricePoint)]);
      }
      
      private function selectClicked(param1:int) : void
      {
         this.mSelectedPricePoint = param1;
      }
   }
}

