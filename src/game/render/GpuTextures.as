package game.render
{
   import starling.textures.Texture;

   // Making GPU textures when Stage3D may be out of them. It allows about 4096
   // textures in all; past that every new one fails (#3691), and a failure in
   // the middle of a frame stopped the world drawing for good: the view froze
   // while the camera moved on. Here a failure first frees textures that can
   // be made again (the least recently used snapshots), then tries once more;
   // if that fails too, the caller gets null and leaves the look out.
   public class GpuTextures
   {
      // Frees what it can; set by the world renderer.
      public static var reclaim:Function;

      public static var failures:int = 0;

      // Off with --no-texture-guards (testing): a failure throws, as it did
      // before.
      public static var guards:Boolean = true;

      // `create()`'s texture (or other GPU resource), or null if there is no
      // room even after reclaiming.
      public static function make(create:Function) : *
      {
         try
         {
            return create();
         }
         catch(e:Error)
         {
            if(!guards)
            {
               throw e;
            }
         }
         if(reclaim != null)
         {
            reclaim();
            try
            {
               return create();
            }
            catch(e:Error)
            {
            }
         }
         ++failures;
         return null;
      }

      public static function fromBitmapData(data:*, scale:Number = 1) : Texture
      {
         return make(function():Texture
         {
            return Texture.fromBitmapData(data,false,false,scale);
         });
      }
   }
}
