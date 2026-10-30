package game.render
{
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

      public function dispose() : void
      {
         if(this.texture)
         {
            this.texture.dispose();
            this.texture = null;
         }
      }
   }
}
