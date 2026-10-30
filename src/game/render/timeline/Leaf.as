package game.render.timeline
{
   import flash.geom.Rectangle;
   import starling.textures.Texture;

   // One rasterised leaf graphic: where it sits in an atlas page, and the
   // offset of its top-left corner from the leaf's origin, in art units.
   public class Leaf
   {
      internal var page:*;

      public var region:Rectangle;

      public var offsetX:Number;

      public var offsetY:Number;

      internal var texture:Texture;
   }
}
