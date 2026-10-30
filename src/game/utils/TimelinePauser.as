package game.utils
{
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.utils.Dictionary;

   // Pauses the timelines of a clip that cannot be seen, and resumes them
   // when it can be again.
   //
   // Flash keeps playing MovieClips that are hidden or off the display list,
   // and each time a looping timeline passes a keyframe it rebuilds that
   // frame's children. Every unit carries a clip per animation state plus
   // looping hint animations, so with a few hundred units this rebuilt
   // hundreds of MB of display objects per second that nobody could see,
   // and the garbage collector then dominated frame time.
   //
   // Only clips that were playing are paused, and exactly those are resumed,
   // so clips stopped on purpose (by frame scripts or game code) stay as they
   // were. stop()/play() keep the current frame, so nothing is rebuilt.
   public class TimelinePauser
   {
      // Same depth the game itself restarts unit animations to
      // (AnimationController.playCurrentAnimation).
      public static const LEVELS:int = 4;

      private static var sPaused:Dictionary = new Dictionary(true);

      public static function pause(root:MovieClip, levels:int = LEVELS) : void
      {
         if(root == null || sPaused[root] !== undefined)
         {
            return;
         }
         var clips:Array = [];
         collect(root,levels,clips);
         for each(var mc:MovieClip in clips)
         {
            mc.stop();
         }
         sPaused[root] = clips;
      }

      public static function resume(root:MovieClip) : void
      {
         if(root == null)
         {
            return;
         }
         var clips:Array = sPaused[root];
         if(clips == null)
         {
            return;
         }
         delete sPaused[root];
         for each(var mc:MovieClip in clips)
         {
            mc.play();
         }
      }

      private static function collect(mc:MovieClip, levels:int, out:Array) : void
      {
         if(mc.isPlaying)
         {
            out.push(mc);
         }
         if(levels <= 1)
         {
            return;
         }
         var n:int = mc.numChildren;
         for(var i:int = 0; i < n; i++)
         {
            var child:MovieClip = mc.getChildAt(i) as MovieClip;
            if(child != null)
            {
               collect(child,levels - 1,out);
            }
         }
      }
   }
}
