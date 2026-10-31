package game.render
{
   import flash.display.BitmapData;
   import starling.textures.Texture;

   // One rasterised look in SnapshotCache: a texture plus the offset of its
   // top-left corner from the object's origin, in screen pixels.
   public class Snapshot
   {
      public var key:String;

      public var texture:Texture;

      public var offsetX:int;

      public var offsetY:int;

      public var pixels:int;

      public var lastUsed:int;

      // Live snapshots (SnapshotCache): the buffer drawn into, kept for reuse.
      public var bitmap:BitmapData;

      public function dispose() : void
      {
         if(this.texture)
         {
            this.texture.dispose();
            this.texture = null;
         }
         if(this.bitmap)
         {
            this.bitmap.dispose();
            this.bitmap = null;
         }
      }
   }
}
