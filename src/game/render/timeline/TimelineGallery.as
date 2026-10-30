package game.render.timeline
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.display.Stage;
   import flash.events.Event;
   import flash.geom.Rectangle;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.utils.getDefinitionByName;
   import flash.utils.getQualifiedClassName;
   import starling.display.Quad;
   import starling.display.Sprite;

   // Development aid (profiling builds, Shift+G): pages of world art symbols,
   // the original Flash MovieClip on the left half of the screen and the GPU
   // TimelineClip replay on the right, both animating, to check the replay
   // matches frame for frame. Shift+] / Shift+[ page through the symbols.
   public class TimelineGallery
   {
      private static const COLUMNS:int = 4;

      private static const ROWS:int = 3;

      private var mStage:Stage;

      private var mLibrary:TimelineLibrary;

      private var mAtlas:LeafAtlas;

      private var mFlashLayer:flash.display.Sprite = new flash.display.Sprite();

      private var mGpuLayer:starling.display.Sprite = new starling.display.Sprite();

      private var mNames:Array = [];

      private var mPage:int = 0;

      private var mClips:Vector.<TimelineClip> = new Vector.<TimelineClip>();

      private var mOriginals:Array = [];

      // Called with describeFrames() at the next EXIT_FRAME, when Flash's
      // display list for the frame is complete.
      private var mOnDescribe:Function;


      // The game's own stage children, hidden while the gallery is open.
      private var mHidden:Array = [];

      public function TimelineGallery(stage:Stage, gpuParent:starling.display.Sprite, library:TimelineLibrary)
      {
         super();
         this.mStage = stage;
         this.mLibrary = library;
         this.mAtlas = new LeafAtlas(library,1);
         for(var name:String in library.symbolNames)
         {
            this.mNames.push(name);
         }
         this.mNames.sort();
         for(var i:int = 0; i < stage.numChildren; i++)
         {
            var child:DisplayObject = stage.getChildAt(i);
            if(child.visible)
            {
               child.visible = false;
               this.mHidden.push(child);
            }
         }
         stage.addChild(this.mFlashLayer);
         // Step the GPU clips on Flash's own frames, so both sides stay in phase.
         this.mFlashLayer.addEventListener(Event.ENTER_FRAME,this.onEnterFrame);
         this.mFlashLayer.addEventListener(Event.EXIT_FRAME,this.onExitFrame);
         gpuParent.addChild(this.mGpuLayer);
         this.show();
      }

      public function get atlas() : LeafAtlas
      {
         return this.mAtlas;
      }

      public function get pageIndex() : int
      {
         return this.mPage;
      }

      public function get pageCount() : int
      {
         return Math.ceil(this.mNames.length / (COLUMNS * ROWS));
      }

      public function page(delta:int) : void
      {
         this.mPage = (this.mPage + delta + this.pageCount) % this.pageCount;
         this.show();
      }

      // Called once per present: upload leaves rasterised since the last one.
      // The clips themselves advance in onEnterFrame.
      public function tick() : void
      {
         this.mAtlas.upload();
      }

      private function onEnterFrame(event:Event) : void
      {
         for each(var clip:TimelineClip in this.mClips)
         {
            clip.tick();
         }
      }

      // Development aid: per cell, the frames of the nested clips, depth
      // first, on both sides ("name: flash | gpu").
      public function describeFrames() : String
      {
         var out:String = "";
         for each(var clip:TimelineClip in this.mClips)
         {
            var i:int = int(clip.name);
            out += this.mNames[this.mPage * COLUMNS * ROWS + i] + ": " + flashFrames(this.mOriginals[i]) + " | " + clip.describeFrames() + "\n";
         }
         return out;
      }

      private static function flashFrames(d:DisplayObject) : String
      {
         var mc:DisplayObjectContainer = d as DisplayObjectContainer;
         if(mc == null)
         {
            return "";
         }
         var out:String = mc is MovieClip ? String(MovieClip(mc).currentFrame) : "S:" + getQualifiedClassName(mc);
         var inner:String = "";
         for(var i:int = 0; i < mc.numChildren; i++)
         {
            var sub:String = flashFrames(mc.getChildAt(i));
            if(sub)
            {
               inner += (inner ? " " : "") + sub;
            }
         }
         return inner ? out + "(" + inner + ")" : out;
      }

      public function describeAtExitFrame(callback:Function) : void
      {
         this.mOnDescribe = callback;
      }

      private function onExitFrame(event:Event) : void
      {
         if(this.mOnDescribe != null)
         {
            var callback:Function = this.mOnDescribe;
            this.mOnDescribe = null;
            var text:String;
            try
            {
               text = this.describeFrames();
            }
            catch(e:Error)
            {
               text = "ERROR describing " + e + "\n" + e.getStackTrace() + "\n";
            }
            callback(text);
         }
      }

      public function dispose() : void
      {
         this.mFlashLayer.removeEventListener(Event.ENTER_FRAME,this.onEnterFrame);
         this.mFlashLayer.removeEventListener(Event.EXIT_FRAME,this.onExitFrame);
         this.clear();
         this.mFlashLayer.parent && this.mFlashLayer.parent.removeChild(this.mFlashLayer);
         this.mGpuLayer.removeFromParent(true);
         this.mAtlas.dispose();
         for each(var child:DisplayObject in this.mHidden)
         {
            child.visible = true;
         }
         this.mHidden.length = 0;
      }

      private function clear() : void
      {
         while(this.mFlashLayer.numChildren)
         {
            var mc:MovieClip = this.mFlashLayer.removeChildAt(0) as MovieClip;
            if(mc)
            {
               mc.stop();
            }
         }
         this.mGpuLayer.removeChildren(0,-1,true);
         this.mClips.length = 0;
         this.mOriginals = [];
      }

      private function show() : void
      {
         this.clear();
         var half:Number = this.mStage.stageWidth / 2;
         var cellW:Number = half / COLUMNS;
         var cellH:Number = (this.mStage.stageHeight - 40) / ROWS;
         this.mFlashLayer.graphics.clear();
         this.mFlashLayer.graphics.beginFill(0x404040);
         this.mFlashLayer.graphics.drawRect(0,0,half,this.mStage.stageHeight);
         this.mFlashLayer.graphics.endFill();
         var backdrop:Quad = new Quad(half,this.mStage.stageHeight,0x404040);
         backdrop.x = half;
         this.mGpuLayer.addChild(backdrop);
         var first:int = this.mPage * COLUMNS * ROWS;
         for(var i:int = 0; i < COLUMNS * ROWS && first + i < this.mNames.length; i++)
         {
            var name:String = this.mNames[first + i];
            var cx:Number = (i % COLUMNS + 0.5) * cellW;
            var cy:Number = 40 + (int(i / COLUMNS) + 0.6) * cellH;
            // Both copies get the same fit-to-cell transform, taken from the
            // original's first-frame bounds.
            var original:DisplayObject = instantiate(name);
            var fit:Number = 1;
            var ox:Number = cx;
            var oy:Number = cy;
            if(original)
            {
               var b:Rectangle = original.getBounds(original);
               if(b.width > 0 && b.height > 0)
               {
                  fit = Math.min(1,(cellW - 8) / b.width,(cellH - 24) / b.height);
                  ox = cx - (b.x + b.width / 2) * fit;
                  oy = 40 + (int(i / COLUMNS) + 0.5) * cellH + 8 - (b.y + b.height / 2) * fit;
               }
               original.scaleX = original.scaleY = fit;
               original.x = ox;
               original.y = oy;
               this.mFlashLayer.addChild(original);
               this.mOriginals[i] = original;
            }
            var clip:TimelineClip = TimelineClip.forSymbol(name,this.mLibrary,this.mAtlas);
            if(clip)
            {
               clip.scale = fit;
               clip.x = half + ox;
               clip.y = oy;
               this.mGpuLayer.addChild(clip);
               this.mClips.push(clip);
               clip.name = String(i);
            }
            this.label(name,cx - cellW / 2,40 + int(i / COLUMNS) * cellH);
         }
         this.label("timeline gallery page " + (this.mPage + 1) + "/" + this.pageCount + "  (left: Flash, right: GPU replay; Shift+] / Shift+[ to page, Shift+G to close)",8,8);
         this.mAtlas.upload();
      }

      private function label(text:String, x:Number, y:Number) : void
      {
         var tf:TextField = new TextField();
         tf.defaultTextFormat = new TextFormat("_sans",10,0xffffff);
         tf.text = text;
         tf.width = text.length > 40 ? 900 : 160;
         tf.height = 16;
         tf.x = x;
         tf.y = y;
         tf.mouseEnabled = false;
         this.mFlashLayer.addChild(tf);
      }

      private static function instantiate(name:String) : DisplayObject
      {
         try
         {
            var cls:Class = getDefinitionByName(name) as Class;
            return new cls() as DisplayObject;
         }
         catch(e:Error)
         {
         }
         return null;
      }
   }
}
