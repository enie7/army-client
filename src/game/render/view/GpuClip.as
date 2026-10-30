package game.render.view
{
   import flash.display.Sprite;
   import game.render.timeline.TimelineClip;
   import starling.display.DisplayObject;

   // Stand-in on the Flash side for a clip the GPU timeline player draws, for
   // code that would put a plain MovieClip into the world (environment
   // effects). The world renderer draws its clip where this sprite is; its
   // frame can be read like the MovieClip's.
   public class GpuClip extends Sprite
   {
      private var mClip:TimelineClip;

      public function GpuClip(clip:TimelineClip)
      {
         super();
         this.mClip = clip;
         this.mouseEnabled = false;
         this.mouseChildren = false;
         GpuArt.registerClip(this);
      }

      // A stand-in playing `symbol`, or null when the GPU player cannot.
      public static function create(symbol:String) : GpuClip
      {
         if(!GpuArt.enabled || !GpuArt.library.hasSymbol(symbol))
         {
            return null;
         }
         return new GpuClip(TimelineClip.forSymbol(symbol,GpuArt.library,GpuArt.atlas));
      }

      public function get gpuNode() : starling.display.DisplayObject
      {
         return this.mClip;
      }

      public function get currentFrame() : int
      {
         return this.mClip ? this.mClip.currentFrame : 0;
      }

      public function get totalFrames() : int
      {
         return this.mClip ? this.mClip.totalFrames : 0;
      }

      public function gotoAndPlay(frame:Object) : void
      {
         if(this.mClip)
         {
            this.mClip.gotoAndPlay(frame);
         }
      }

      internal function tick() : void
      {
         if(this.mClip)
         {
            this.mClip.tick();
         }
      }

      public function dispose() : void
      {
         GpuArt.unregisterClip(this);
         if(this.mClip)
         {
            this.mClip.removeFromParent(true);
            this.mClip = null;
         }
      }
   }
}
