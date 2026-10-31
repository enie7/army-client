package game.render.view
{
   import flash.utils.Dictionary;
   import game.render.GpuTextures;
   import game.render.WorldRenderer;
   import game.render.timeline.LeafAtlas;
   import game.render.timeline.TimelineLibrary;
   import game.render.timeline.TimelineClip;
   import starling.textures.RenderTexture;
   import starling.core.Starling;
   import starling.display.DisplayObject;
   import starling.display.DisplayObjectContainer;
   import game.utils.FrameProfiler;
   import game.render.timeline.PlaceOp;
   import game.render.timeline.SpriteDef;
   import flash.utils.getTimer;

   // Shared state of the art drawn by the GPU timeline player (StarlingView):
   // the timeline library, the leaf atlas for the current zoom, and the views
   // that are live, so they can be ticked and rebuilt together.
   public class GpuArt
   {
      // --flash-art: keep every object on Flash art (for comparison).
      public static var flashOnly:Boolean = false;

      private static var sAtlas:LeafAtlas;

      private static var sScale:Number = 0;

      private static var sViews:Dictionary = new Dictionary(true);

      private static var sRebuilds:int = 0;

      // Stand-ins for clips drawn on the GPU (GpuClip).
      private static var sClips:Dictionary = new Dictionary(true);

      public function GpuArt()
      {
         super();
      }

      // Whether new art may go to the GPU player: the GPU world renderer is
      // in use and the timelines are bundled.
      public static function get enabled() : Boolean
      {
         return !flashOnly && !WorldRenderer.disabled && library != null;
      }

      public static function get library() : TimelineLibrary
      {
         return TimelineLibrary.instance;
      }

      // The atlas leaves are rasterised into, at the current zoom.
      public static function get atlas() : LeafAtlas
      {
         if(sAtlas == null)
         {
            sAtlas = new LeafAtlas(library,sScale > 0 ? sScale : 1);
         }
         return sAtlas;
      }

      // New zoom: leaves are rasterised again at the new size, and every
      // view rebuilds its clips from the new atlas.
      public static function setScale(scale:Number) : void
      {
         if(scale == sScale)
         {
            return;
         }
         sScale = scale;
         ++sRebuilds;
         var old:LeafAtlas = sAtlas;
         sAtlas = null;
         for(var view:Object in sViews)
         {
            StarlingView(view).rebuild();
         }
         for(var clip:Object in sClips)
         {
            GpuClip(clip).rebuild();
         }
         if(old)
         {
            old.dispose();
         }
         prewarm();
      }

      private static function countNodes(o:starling.display.DisplayObject) : int
      {
         var n:int = o ? 1 : 0;
         var c:starling.display.DisplayObjectContainer = o as starling.display.DisplayObjectContainer;
         for(var i:int = 0; c && i < c.numChildren; i++)
         {
            n += countNodes(c.getChildAt(i));
         }
         return n;
      }

      // Development aid: views drawing GPU art, and leaves rasterised.
      public static function describe() : String
      {
         var n:int = 0;
         for(var view:Object in sViews)
         {
            ++n;
         }
         var clips:int = 0;
         var nodes:int = 0;
         var biggest:String = "";
         var most:int = 0;
         for(var c:Object in sClips)
         {
            ++clips;
            var count:int = countNodes(GpuClip(c).gpuNode);
            nodes += count;
            if(count > most)
            {
               most = count;
               biggest = GpuClip(c).symbol;
            }
         }
         var out:String = "gpu clips " + clips + " (" + nodes + " nodes, most " + most + " in " + biggest + "), gpu art " + n + " objects, " + (sAtlas ? sAtlas.rasterised : 0) + " leaves, scale " + sScale + ", atlas rebuilds " + sRebuilds + ", finds " + LeafAtlas.finds + ", text draws " + LeafAtlas.textDraws;
         sRebuilds = 0;
         LeafAtlas.finds = 0;
         LeafAtlas.textDraws = 0;
         return out;
      }

      // Art that code makes as GpuClip stand-ins while playing (effects),
      // prewarmed with the views' art.
      private static const EFFECT_SYMBOLS:Array = ["bullet_hitting","effect_explosion","electric_bubble","electric_hitting","explosion_small_sequence","redeploy_pickup","Water_CoastTile","Bg_RiverTile_Shine_01","Bg_RiverTile_Shine_02","Bg_RiverTile_Shine_03","Bg_RiverTile_Shine_05","Bg_BadRiverTile_Bubbles_05","icon_status_finished","icon_status_finished1","icon_status_low_health","rocket","Smoke3","Smoke4","feedback_gain","feedback_loss","explosion_friend_artillery","debris_animation","medevac","City_Liberated_01"];

      // Rasterise, now, every leaf the art in play can show, in any state or
      // frame: otherwise each first appearance (scrolling to new art, a unit
      // starting to fire) rasterised leaves and uploaded an atlas page in the
      // middle of play, a visible hitch.
      public static function prewarm() : void
      {
         var lib:TimelineLibrary = library;
         if(lib == null)
         {
            return;
         }
         var start:int = getTimer();
         var before:int = atlas.rasterised;
         var names:Object = {};
         for(var view:Object in sViews)
         {
            for each(var name:String in StarlingView(view).symbols)
            {
               names[name] = true;
            }
         }
         for each(name in EFFECT_SYMBOLS)
         {
            names[name] = true;
         }
         var seen:Object = {};
         var visit:Function = function(id:int, mask:Boolean):void
         {
            var key:String = (mask ? "m" : "") + id;
            if(seen[key])
            {
               return;
            }
            seen[key] = true;
            if(lib.isSprite(id))
            {
               var def:SpriteDef = lib.sprite(id);
               for each(var ops:Vector.<PlaceOp> in def.ops)
               {
                  for each(var op:PlaceOp in ops)
                  {
                     if(op.character >= 0)
                     {
                        visit(op.character,mask || op.clipDepth > 0);
                     }
                  }
               }
            }
            else if(!mask)
            {
               // Masks are geometry; everything else is rasterised.
               atlas.get(id);
            }
         };
         for(name in names)
         {
            var id:int = lib.symbolId(name);
            if(id >= 0)
            {
               visit(id,false);
            }
         }
         upload();
         var rasterised:int = atlas.rasterised - before;
         var drawn:int = warmGpu();
         if(FrameProfiler.ENABLED)
         {
            FrameProfiler.mark("prewarm: " + rasterised + " leaves, " + drawn + " effect frames drawn, in " + (getTimer() - start) + "ms");
         }
      }

      // Draw the effects through their frames once, offscreen, so what the
      // GPU sets up on first use (shader variants, the textures glow and blur
      // filters render into, batch buffers) is done now and not on the first
      // explosion in combat. Returns the frames drawn.
      private static function warmGpu() : int
      {
         if(Starling.current == null || Starling.current.context == null)
         {
            return 0;
         }
         var target:RenderTexture = GpuTextures.make(function():RenderTexture
         {
            return new RenderTexture(256,256,false);
         });
         if(target == null)
         {
            return 0;
         }
         var drawn:int = 0;
         for each(var name:String in EFFECT_SYMBOLS)
         {
            var clip:TimelineClip = TimelineClip.forSymbol(name,library,atlas);
            if(clip == null)
            {
               continue;
            }
            clip.x = clip.y = 128;
            var frames:int = clip.totalFrames;
            for(var f:int = 1; f <= frames; f += Math.max(1,int(frames / 12)))
            {
               clip.gotoAndStop(f);
               upload();
               target.draw(clip);
               ++drawn;
            }
            clip.dispose();
         }
         target.dispose();
         return drawn;
      }

      public static function registerClip(clip:GpuClip) : void
      {
         sClips[clip] = true;
      }

      public static function unregisterClip(clip:GpuClip) : void
      {
         delete sClips[clip];
      }

      public static function register(view:StarlingView) : void
      {
         sViews[view] = true;
      }

      public static function unregister(view:StarlingView) : void
      {
         delete sViews[view];
      }

      // One Flash frame: advance every view's timelines, as Flash does for
      // its clips.
      public static function tick() : void
      {
         for(var view:Object in sViews)
         {
            StarlingView(view).tick();
         }
         for(var clip:Object in sClips)
         {
            GpuClip(clip).tick();
         }
      }

      // Before drawing: upload the leaves rasterised since the last frame.
      public static function upload() : void
      {
         if(sAtlas)
         {
            sAtlas.upload();
         }
      }
   }
}
