package game.gui.popups
{
   import com.dchoc.GUI.DCButton;
   import com.dchoc.graphics.DCResourceManager;
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import game.gui.StylizedHeaderClip;
   import game.gui.button.ResizingButton;
   import game.states.GameState;
   
   public class HiddenErrorWindow extends PopUpWindow
   {
      
      private var mButtonSkip:ResizingButton;
      
      private var mButtonCancel:DCButton;
      
      public function HiddenErrorWindow()
      {
         var _loc1_:Class = DCResourceManager.getInstance().getSWFClass(Config.SWF_POPUPS_WARNINGS_NAME,"popup_error");
         super(new _loc1_() as MovieClip);
      }
      
      public function Activate(param1:Function, param2:String, param3:String) : void
      {
         var _loc6_:TextField = null;
         var _loc4_:StylizedHeaderClip = null;
         var _loc5_:TextFormat = null;
         this.mButtonCancel = Utils.createBasicButton(mClip,"Button_Cancel",this.okClicked);
         this.mButtonCancel.setVisible(false);
         this.mButtonSkip = Utils.createResizingButton(mClip,"Button_Skip",this.okClicked);
         this.mButtonSkip.setText(GameState.getText("BUTTON_OK"));
         mDoneCallback = param1;
         _loc4_ = new StylizedHeaderClip(mClip.getChildByName("Header") as MovieClip);
         _loc4_.setText(param2);
         _loc6_ = mClip.getChildByName("Text_Description") as TextField;
         var _loc7_:int = _loc6_.height;
         _loc6_.autoSize = TextFieldAutoSize.CENTER;
         _loc6_.text = param3;
         _loc6_.defaultTextFormat = _loc6_.getTextFormat();
         while(_loc6_.height > _loc7_ && _loc6_.defaultTextFormat.size > 6)
         {
            _loc5_ = _loc6_.defaultTextFormat;
            _loc5_.size = int(_loc5_.size) - 1;
            _loc6_.defaultTextFormat = _loc5_;
            _loc6_.text = param3;
         }
      }
      
      private function okClicked(param1:MouseEvent) : void
      {
         close();
      }
   }
}

