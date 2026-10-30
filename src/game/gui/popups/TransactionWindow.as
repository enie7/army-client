package game.gui.popups
{
   import com.dchoc.graphics.DCResourceManager;
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import game.gui.StylizedHeaderClip;
   import game.gui.button.ResizingButton;
   
   public class TransactionWindow extends PopUpWindow
   {
      
      private var mButtonExit:ResizingButton;
      
      public function TransactionWindow()
      {
         var _loc1_:Class = DCResourceManager.getInstance().getSWFClass(Config.SWF_POPUPS_WARNINGS_NAME,"popup_error_msg");
         super(new _loc1_() as MovieClip);
      }
      
      public function Activate(param1:Function, param2:String, param3:String) : void
      {
         var _loc6_:TextField = null;
         var _loc8_:TextFormat = null;
         var _loc4_:StylizedHeaderClip = null;
         var _loc5_:TextFormat = null;
         this.mButtonExit = Utils.createResizingButton(mClip,"Button_Skip",this.okClicked);
         this.mButtonExit.setText("OK");
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
         _loc8_ = _loc6_.getTextFormat();
         _loc8_.size = 17;
         _loc6_.defaultTextFormat = _loc8_;
         _loc6_.setTextFormat(_loc8_);
         _loc6_.selectable = true;
      }
      
      private function okClicked(param1:MouseEvent) : void
      {
         mDoneCallback((this as Object).constructor);
      }
   }
}

