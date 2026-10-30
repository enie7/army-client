package game.render
{
   import flash.display.BitmapData;
   import flash.geom.Point;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.textures.Texture;

   // The ground and fog drawn in world space, as GPU textures in square
   // chunks. The game normally repaints two screen-sized bitmaps on every
   // camera move; here a chunk is only drawn again when the map, fog or zoom
   // actually changes, so panning just moves the layers.
   public class GroundChunks
   {
      public static const SIZE:int = 512;

      // Chunks kept per layer before the farthest ones are freed.
      private static const MAX_CHUNKS:int = 64;

      // Off-screen chunks drawn per frame when they scroll into the margin.
      private static const MARGIN_BUDGET:int = 2;

      private var mGround:Sprite;

      private var mFog:Sprite;

      private var mChunks:Object = {};

      private var mCount:int = 0;

      // Opaque, like the game's own field bitmap: tiles are layered with
      // copyPixels, which on a transparent target would let each overlay's
      // transparent pixels punch holes through the tile below.
      private var mFieldScratch:BitmapData = new BitmapData(SIZE,SIZE,false,0);

      private var mFogScratch:BitmapData = new BitmapData(SIZE,SIZE,true,0);

      private var mVersion:int = -1;

      private var mScale:Number = NaN;

      public var drawn:int = 0;

      public function GroundChunks(ground:Sprite, fog:Sprite)
      {
         super();
         this.mGround = ground;
         this.mFog = fog;
      }

      // tiles: the scene's TileMapGraphic. (originX, originY): screen
      // position of the world origin. The visible area is the stage.
      public function update(tiles:Object, originX:Number, originY:Number, shakeX:Number, shakeY:Number, stageW:Number, stageH:Number, scale:Number) : void
      {
         if(scale != this.mScale)
         {
            this.clear();
            this.mScale = scale;
         }
         var version:int = tiles.mContentVersion;
         var stale:Boolean = version != this.mVersion;
         this.mVersion = version;
         this.mGround.x = originX + shakeX;
         this.mGround.y = originY + shakeY;
         this.mFog.x = originX;
         this.mFog.y = originY;
         var world:Point = tiles.getWorldPixelSize();
         var maxCx:int = Math.ceil(world.x / SIZE) - 1;
         var maxCy:int = Math.ceil(world.y / SIZE) - 1;
         var x0:int = Math.max(0,Math.floor(-originX / SIZE));
         var y0:int = Math.max(0,Math.floor(-originY / SIZE));
         var x1:int = Math.min(maxCx,Math.floor((stageW - originX) / SIZE));
         var y1:int = Math.min(maxCy,Math.floor((stageH - originY) / SIZE));
         var budget:int = MARGIN_BUDGET;
         this.drawn = 0;
         // Visible chunks are always current; the one-chunk margin around
         // them is filled in a little at a time.
         for(var cy:int = Math.max(0,y0 - 1); cy <= Math.min(maxCy,y1 + 1); cy++)
         {
            for(var cx:int = Math.max(0,x0 - 1); cx <= Math.min(maxCx,x1 + 1); cx++)
            {
               var visible:Boolean = cx >= x0 && cx <= x1 && cy >= y0 && cy <= y1;
               var chunk:Chunk = this.mChunks[cx + "," + cy];
               if(chunk != null && chunk.version == version)
               {
                  continue;
               }
               if(!visible && budget-- <= 0)
               {
                  continue;
               }
               this.draw(tiles,cx,cy,version);
            }
         }
         if(this.mCount > MAX_CHUNKS)
         {
            this.evict((x0 + x1) / 2,(y0 + y1) / 2);
         }
      }

      private function draw(tiles:Object, cx:int, cy:int, version:int) : void
      {
         var key:String = cx + "," + cy;
         var chunk:Chunk = this.mChunks[key];
         tiles.drawWorldChunk(this.mFieldScratch,this.mFogScratch,cx * SIZE,cy * SIZE);
         if(chunk == null)
         {
            chunk = new Chunk();
            chunk.cx = cx;
            chunk.cy = cy;
            chunk.ground = new Image(Texture.empty(SIZE,SIZE,true,false,false,1));
            chunk.fog = new Image(Texture.empty(SIZE,SIZE,true,false,false,1));
            chunk.ground.x = chunk.fog.x = cx * SIZE;
            chunk.ground.y = chunk.fog.y = cy * SIZE;
            this.mGround.addChild(chunk.ground);
            this.mFog.addChild(chunk.fog);
            this.mChunks[key] = chunk;
            ++this.mCount;
         }
         chunk.ground.texture.root.uploadBitmapData(this.mFieldScratch);
         chunk.fog.texture.root.uploadBitmapData(this.mFogScratch);
         chunk.version = version;
         ++this.drawn;
      }

      private function evict(centerX:Number, centerY:Number) : void
      {
         var all:Array = [];
         for each(var chunk:Chunk in this.mChunks)
         {
            chunk.distance = Math.abs(chunk.cx - centerX) + Math.abs(chunk.cy - centerY);
            all.push(chunk);
         }
         all.sortOn("distance",Array.NUMERIC | Array.DESCENDING);
         for(var i:int = 0; this.mCount > MAX_CHUNKS * 3 / 4 && i < all.length; i++)
         {
            this.remove(all[i]);
         }
      }

      private function remove(chunk:Chunk) : void
      {
         delete this.mChunks[chunk.cx + "," + chunk.cy];
         --this.mCount;
         chunk.ground.removeFromParent();
         chunk.fog.removeFromParent();
         chunk.ground.texture.dispose();
         chunk.fog.texture.dispose();
      }

      public function clear() : void
      {
         for each(var chunk:Chunk in this.mChunks)
         {
            this.remove(chunk);
         }
         this.mVersion = -1;
      }
   }
}

import starling.display.Image;

class Chunk
{
   public var cx:int;

   public var cy:int;

   public var version:int = -1;

   public var distance:Number = 0;

   public var ground:Image;

   public var fog:Image;

   public function Chunk()
   {
      super();
   }
}
