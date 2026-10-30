package game.render.view
{
   import flash.display.MovieClip;
   import flash.utils.getQualifiedClassName;
   import game.render.timeline.TimelineClip;
   import starling.display.DisplayObject;

   // Stand-in on the Flash side for a clip the GPU timeline player draws, for
   // code that would put an art MovieClip into the world (effects, icons,
   // environment). It is an empty MovieClip, so Flash builds nothing for it;
   // the world renderer draws its GPU clip where it is, and its frame API
   // (frames, labels, play / stop) is the GPU clip's.
   public class GpuClip extends MovieClip
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

      // `new cls()`, as a stand-in when the GPU player can draw that symbol.
      public static function make(cls:Class) : MovieClip
      {
         return create(getQualifiedClassName(cls).replace("::",".")) || new cls() as MovieClip;
      }

      public function get gpuNode() : starling.display.DisplayObject
      {
         return this.mClip;
      }

      override public function get currentFrame() : int
      {
         return this.mClip ? this.mClip.currentFrame : 0;
      }

      override public function get totalFrames() : int
      {
         return this.mClip ? this.mClip.totalFrames : 0;
      }

      override public function get currentFrameLabel() : String
      {
         return this.mClip ? this.mClip.currentFrameLabel : null;
      }

      override public function get currentLabel() : String
      {
         return this.mClip ? this.mClip.currentLabel : null;
      }

      override public function get isPlaying() : Boolean
      {
         return this.mClip ? this.mClip.isPlaying : false;
      }

      override public function play() : void
      {
         if(this.mClip)
         {
            this.mClip.play();
         }
      }

      override public function stop() : void
      {
         if(this.mClip)
         {
            this.mClip.stop();
         }
      }

      override public function gotoAndPlay(frame:Object, scene:String = null) : void
      {
         if(this.mClip)
         {
            this.mClip.gotoAndPlay(frame);
         }
      }

      override public function gotoAndStop(frame:Object, scene:String = null) : void
      {
         if(this.mClip)
         {
            this.mClip.gotoAndStop(frame);
         }
      }

      override public function nextFrame() : void
      {
         if(this.mClip)
         {
            this.mClip.nextFrame();
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
