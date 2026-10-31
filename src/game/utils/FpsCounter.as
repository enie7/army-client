package game.utils
{
   import flash.display.Stage;
   import flash.events.Event;
   import flash.system.System;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.utils.getTimer;

   // Debug overlay (F3, or --fps at launch): frames per second, average and
   // longest frame, and memory in use, over the last half second.
   public class FpsCounter
   {
      private static var sField:TextField;

      private static var sStage:Stage;

      private static var sFrames:int;

      private static var sStart:int;

      private static var sLast:int;

      private static var sMax:int;

      public static var showAtStart:Boolean = false;

      public function FpsCounter()
      {
         super();
      }

      public static function toggle(stage:Stage) : void
      {
         if(sField)
         {
            hide();
         }
         else
         {
            show(stage);
         }
      }

      public static function show(stage:Stage) : void
      {
         if(sField || stage == null)
         {
            return;
         }
         sStage = stage;
         sField = new TextField();
         sField.defaultTextFormat = new TextFormat("_typewriter",13,0xffffff,true);
         sField.background = true;
         sField.backgroundColor = 0x000000;
         sField.alpha = 0.75;
         sField.autoSize = TextFieldAutoSize.LEFT;
         sField.selectable = false;
         sField.mouseEnabled = false;
         sField.text = " -- fps ";
         stage.addChild(sField);
         sStart = sLast = getTimer();
         sFrames = sMax = 0;
         stage.addEventListener(Event.ENTER_FRAME,onFrame,false,-1000);
      }

      public static function hide() : void
      {
         if(sField == null)
         {
            return;
         }
         sStage.removeEventListener(Event.ENTER_FRAME,onFrame);
         if(sField.parent)
         {
            sField.parent.removeChild(sField);
         }
         sField = null;
      }

      private static function onFrame(event:Event) : void
      {
         var now:int = getTimer();
         sMax = Math.max(sMax,now - sLast);
         sLast = now;
         ++sFrames;
         // Kept above anything added later (dialogs, the HUD).
         if(sStage.getChildIndex(sField) != sStage.numChildren - 1)
         {
            sStage.setChildIndex(sField,sStage.numChildren - 1);
         }
         var span:int = now - sStart;
         if(span < 500)
         {
            return;
         }
         var fps:Number = sFrames * 1000 / span;
         sField.text = " " + fps.toFixed(1) + " fps | " + (span / sFrames).toFixed(1) + " ms avg | " + sMax + " ms max | " + int(System.totalMemory / (1024 * 1024)) + " MB ";
         sField.textColor = fps >= 38 ? 0x66ff66 : (fps >= 30 ? 0xffdd44 : 0xff5555);
         sField.x = sStage.stageWidth - sField.width - 8;
         sField.y = 64;
         sStart = now;
         sFrames = 0;
         sMax = 0;
      }
   }
}
