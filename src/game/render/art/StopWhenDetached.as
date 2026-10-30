package game.render.art
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.utils.Dictionary;

   // For art classes that timelines place and replace (unit hint badges):
   // when one is taken off its parent, stop it and everything in it. Flash
   // keeps playing a removed clip until it is collected, and these badges
   // build a new frame of their contents every frame, so replaced ones went
   // on doing that unseen, out of reach of any code.
   public class StopWhenDetached
   {
      public function StopWhenDetached()
      {
         super();
      }

      // Development aid: every watched clip (weakly), and how many were made.
      private static var sLive:Dictionary = new Dictionary(true);

      public static var made:int = 0;

      public static function watch(clip:MovieClip) : void
      {
         clip.addEventListener(Event.REMOVED,onRemoved,false,0,true);
         sLive[clip] = true;
         ++made;
      }

      // Development aid: watched clips alive, without a parent, and of
      // those, with something playing inside.
      public static function describe() : String
      {
         var live:int = 0;
         var orphans:int = 0;
         var playing:int = 0;
         for(var o:Object in sLive)
         {
            ++live;
            var clip:MovieClip = o as MovieClip;
            if(clip.parent == null)
            {
               ++orphans;
               if(anyPlaying(clip))
               {
                  ++playing;
               }
            }
         }
         return "hint badges: " + made + " made, " + live + " alive, " + orphans + " without parent, " + playing + " of those playing";
      }

      private static function anyPlaying(o:DisplayObject) : Boolean
      {
         var mc:MovieClip = o as MovieClip;
         if(mc && mc.isPlaying)
         {
            return true;
         }
         var c:DisplayObjectContainer = o as DisplayObjectContainer;
         for(var i:int = 0; c && i < c.numChildren; i++)
         {
            if(anyPlaying(c.getChildAt(i)))
            {
               return true;
            }
         }
         return false;
      }

      private static function onRemoved(event:Event) : void
      {
         // REMOVED bubbles up from removed children too; only this clip's own
         // removal matters.
         if(event.target == event.currentTarget)
         {
            stopTree(event.target as DisplayObject);
         }
      }

      public static function stopTree(o:DisplayObject) : void
      {
         var mc:MovieClip = o as MovieClip;
         if(mc && mc.isPlaying)
         {
            mc.stop();
         }
         var c:DisplayObjectContainer = o as DisplayObjectContainer;
         for(var i:int = 0; c && i < c.numChildren; i++)
         {
            stopTree(c.getChildAt(i));
         }
      }
   }
}
