package game.render.view
{
   import flash.utils.Dictionary;
   import game.render.WorldRenderer;
   import game.render.timeline.LeafAtlas;
   import game.render.timeline.TimelineLibrary;

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
         if(old)
         {
            old.dispose();
         }
      }

      // Development aid: views drawing GPU art, and leaves rasterised.
      public static function describe() : String
      {
         var n:int = 0;
         for(var view:Object in sViews)
         {
            ++n;
         }
         var out:String = "gpu art " + n + " objects, " + (sAtlas ? sAtlas.rasterised : 0) + " leaves, scale " + sScale + ", atlas rebuilds " + sRebuilds + ", finds " + LeafAtlas.finds + ", text draws " + LeafAtlas.textDraws;
         sRebuilds = 0;
         LeafAtlas.finds = 0;
         LeafAtlas.textDraws = 0;
         return out;
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
