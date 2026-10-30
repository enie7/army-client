package
{
   import flash.display.StageAlign;
   import flash.display.StageDisplayState;
   import flash.display.StageScaleMode;
   import flash.system.Capabilities;

   public class iArmyAir extends GameMain
   {


      public function iArmyAir()
      {
         super();
         stage.scaleMode = StageScaleMode.NO_SCALE;
         stage.align = StageAlign.TOP_LEFT;
		 // macOS opens in a normal window; fullscreen is still available from the HUD toggle.
		 if (Capabilities.os.indexOf("Mac") != 0) {
			 stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
		 }
      }
   }
}
