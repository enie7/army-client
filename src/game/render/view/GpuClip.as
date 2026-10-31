package game.render.view
{
   import flash.display.MovieClip;
   import flash.display.DisplayObject;
   import flash.utils.getQualifiedClassName;
   import game.render.timeline.TimelineClip;
   import starling.display.DisplayObject;
   import starling.display.DisplayObjectContainer;

   // Stand-in on the Flash side for a clip the GPU timeline player draws, for
   // code that would put an art MovieClip into the world (effects, icons,
   // environment). It is an empty MovieClip, so Flash builds nothing for it;
   // the world renderer draws its GPU clip where it is, and its frame API
   // (frames, labels, play / stop) is the GPU clip's. Dynamic like MovieClip,
   // since game code sets ad-hoc properties on clips (and misspelt ones, like
   // LootReward's old "mouseChildre").
   public dynamic class GpuClip extends MovieClip
   {
      private var mClip:TimelineClip;

      private var mSymbol:String;

      public function GpuClip(symbol:String)
      {
         super();
         this.mSymbol = symbol;
         this.mClip = TimelineClip.forSymbol(symbol,GpuArt.library,GpuArt.atlas);
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
         return new GpuClip(symbol);
      }

      // `new cls()`, as a stand-in when the GPU player can draw that symbol.
      public static function make(cls:Class) : MovieClip
      {
         return create(getQualifiedClassName(cls).replace("::",".")) || new cls() as MovieClip;
      }

      public function get symbol() : String
      {
         return this.mSymbol;
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

      // The atlas changed (new zoom, or the first frame setting the real
      // scale): play the symbol again from the new atlas, on the same frame.
      internal function rebuild() : void
      {
         if(this.mClip == null)
         {
            return;
         }
         var old:TimelineClip = this.mClip;
         var parent:starling.display.DisplayObjectContainer = old.parent;
         var index:int = parent ? parent.getChildIndex(old) : -1;
         this.mClip = TimelineClip.forSymbol(this.mSymbol,GpuArt.library,GpuArt.atlas);
         if(old.isPlaying)
         {
            this.mClip.gotoAndPlay(old.currentFrame);
         }
         else
         {
            this.mClip.gotoAndStop(old.currentFrame);
         }
         this.mClip.transformationMatrix = old.transformationMatrix;
         this.mClip.alpha = old.alpha;
         if(parent)
         {
            parent.addChildAt(this.mClip,index);
         }
         old.removeFromParent(true);
         this.applyParts();
      }

      // Set the text of the dynamic text field `field` in the named part
      // (like part.getChildByName(field).text = text), drawn with `autoSize`.
      public function setPartText(part:String, field:String, text:String, autoSize:String = null) : void
      {
         var clip:TimelineClip = this.mClip ? this.mClip.getPartByName(part) as TimelineClip : null;
         if(clip)
         {
            clip.setText(field,text,autoSize);
         }
      }

      internal function tick() : void
      {
         if(this.mClip)
         {
            this.mClip.tick();
            this.applyParts();
         }
      }

      // Stand-ins for named parts (see GpuPart), made on first use.
      private var mParts:Object = null;

      override public function getChildByName(name:String) : flash.display.DisplayObject
      {
         var part:GpuPart = this.mParts ? this.mParts[name] : null;
         if(part == null && this.mClip && this.mClip.getPartByName(name))
         {
            this.mParts ||= {};
            part = this.mParts[name] = new GpuPart(this,[name]);
         }
         return part;
      }

      // The GPU clip's part at `path` (instance names, outermost first).
      internal function resolve(path:Array) : starling.display.DisplayObject
      {
         var node:starling.display.DisplayObject = this.mClip;
         for each(var name:String in path)
         {
            var clip:TimelineClip = node as TimelineClip;
            node = clip ? clip.getPartByName(name) : null;
            if(node == null)
            {
               return null;
            }
         }
         return node;
      }

      private function applyParts() : void
      {
         for each(var part:GpuPart in this.mParts)
         {
            part.apply();
         }
      }

      // Measured from the GPU art, as Flash measures the art.
      override public function get width() : Number
      {
         return this.mClip ? this.mClip.getBounds(this.mClip).width * Math.abs(scaleX) : 0;
      }

      override public function get height() : Number
      {
         return this.mClip ? this.mClip.getBounds(this.mClip).height * Math.abs(scaleY) : 0;
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
