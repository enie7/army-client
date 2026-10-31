package game.render
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.StageQuality;
   import flash.geom.ColorTransform;
   import flash.geom.Matrix;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.text.TextField;
   import flash.utils.Dictionary;
   import starling.textures.Texture;

   // Rasterised looks of Flash display objects, as GPU textures.
   //
   // An object's look is identified by a signature of its whole subtree
   // (classes, timeline frames, child transforms, alpha, colour, text,
   // visibility), so every instance in the same state shares one texture and
   // an animation costs one rasterisation per distinct frame. Objects are
   // drawn with the highest quality the runtime offers.
   public class SnapshotCache
   {
      private static const MAX_SIDE:int = 4096;

      // Stage3D allows 4096 textures in all; past that every new one fails
      // and the frame with it. Many small looks fit the pixel budget long
      // before that, so their number is capped too.
      private static const MAX_ENTRIES:int = 1200;

      private var mEntryCount:int = 0;

      private var mBudgetPixels:Number;

      private var mUsedPixels:Number = 0;

      private var mEntries:Object = {};

      // Animating objects -> their live buffer; and the frame each object
      // last missed the cache, to spot animation. Held strongly, so a buffer
      // is disposed by sweepLive rather than lost with its object.
      private var mLive:Dictionary = new Dictionary();

      private var mLastMiss:Dictionary = new Dictionary(true);

      private var mClassIds:Dictionary = new Dictionary(true);

      private var mBitmapIds:Dictionary = new Dictionary(true);

      private var mNextId:int = 1;

      private var mFrame:int = 0;

      private var mH1:int;

      private var mH2:int;

      public var misses:int = 0;

      public var hits:int = 0;

      private var mMatrix:Matrix = new Matrix();

      private var mPoint:Point = new Point();

      public function SnapshotCache(budgetMegabytes:int)
      {
         super();
         this.mBudgetPixels = budgetMegabytes * 1024 * 1024 / 4;
      }

      public function nextFrame() : void
      {
         ++this.mFrame;
         if(this.mFrame % 60 == 0)
         {
            this.sweepLive();
         }
      }

      public function get usedMegabytes() : Number
      {
         return this.mUsedPixels * 4 / (1024 * 1024);
      }

      // Look of `obj` at `scale`, or null when it draws nothing. The object's
      // own translation and rotation are left out (the GPU applies them), so
      // a moving, spinning projectile is still a single texture.
      public function get(obj:DisplayObject, scale:Number) : Snapshot
      {
         var sx:Number = obj.scaleX * scale;
         var sy:Number = obj.scaleY * scale;
         var ct:ColorTransform = obj.transform.colorTransform;
         this.mH1 = 0x811c9dc5;
         this.mH2 = 17;
         this.signature(obj);
         var key:String = sx + "," + sy + "," + this.mH1 + "," + this.mH2 + (isIdentity(ct) ? "" : "," + ct.toString());
         // Objects whose look changes every frame (animated overlays: missile
         // trails, loot pop-ups, explosions) draw into one buffer of their own,
         // reused, instead of a new bitmap and texture per look: those made
         // tens of MB of garbage a second in combat, and long collections.
         var live:Snapshot = this.mLive[obj];
         if(live != null)
         {
            live.lastUsed = this.mFrame;
            if(live.key != key)
            {
               ++this.misses;
               live.key = key;
               this.redrawLive(live,obj,sx,sy,ct);
            }
            else
            {
               ++this.hits;
            }
            return live.texture ? live : null;
         }
         var entry:Snapshot = this.mEntries[key];
         if(entry != null)
         {
            entry.lastUsed = this.mFrame;
            ++this.hits;
            return entry.texture ? entry : null;
         }
         ++this.misses;
         // A miss on consecutive frames: it is animating, give it a buffer.
         if(this.mLastMiss[obj] === this.mFrame - 1)
         {
            delete this.mLastMiss[obj];
            live = new Snapshot();
            live.key = key;
            live.lastUsed = this.mFrame;
            this.mLive[obj] = live;
            this.redrawLive(live,obj,sx,sy,ct);
            return live.texture ? live : null;
         }
         this.mLastMiss[obj] = this.mFrame;
         entry = this.rasterise(obj,sx,sy,ct);
         entry.key = key;
         entry.lastUsed = this.mFrame;
         this.mEntries[key] = entry;
         ++this.mEntryCount;
         this.mUsedPixels += entry.pixels;
         if(this.mUsedPixels > this.mBudgetPixels || this.mEntryCount > MAX_ENTRIES)
         {
            this.evict();
         }
         return entry.texture ? entry : null;
      }

      public function clear() : void
      {
         for each(var entry:Snapshot in this.mEntries)
         {
            entry.dispose();
         }
         for(var obj:Object in this.mLive)
         {
            Snapshot(this.mLive[obj]).dispose();
         }
         this.mLive = new Dictionary();
         this.mLastMiss = new Dictionary(true);
         this.mEntries = {};
         this.mEntryCount = 0;
         this.mUsedPixels = 0;
      }

      // Two independent 32-bit hashes, in exact int arithmetic: FNV-1a
      // (multiplying by the FNV prime via shifts) and a Java-style *31 hash.
      private function mix(v:int) : void
      {
         var h:int = this.mH1 ^ v;
         this.mH1 = h + (h << 1) + (h << 4) + (h << 7) + (h << 8) + (h << 24) | 0;
         this.mH2 = (this.mH2 << 5) - this.mH2 + v | 0;
      }

      // Hash everything that decides how a subtree looks. Child transforms set
      // by the timeline are implied by the parent's frame; ones set from code
      // (e.g. flipping a unit to face left) show up in x/y/scale/rotation.
      // Only allocation-free getters are used: this runs for every visible
      // object, every frame.
      private function signature(o:DisplayObject) : void
      {
         this.mix(this.idOf(this.mClassIds,Object(o).constructor));
         var mc:MovieClip = o as MovieClip;
         if(mc != null)
         {
            this.mix(mc.currentFrame);
         }
         else
         {
            var tf:TextField = o as TextField;
            if(tf != null)
            {
               var text:String = tf.text;
               for(var j:int = 0; j < text.length; j++)
               {
                  this.mix(text.charCodeAt(j));
               }
            }
            else
            {
               var bmp:Bitmap = o as Bitmap;
               if(bmp != null)
               {
                  this.mix(this.idOf(this.mBitmapIds,bmp.bitmapData));
               }
            }
         }
         var c:DisplayObjectContainer = o as DisplayObjectContainer;
         if(c != null)
         {
            var n:int = c.numChildren;
            this.mix(n);
            for(var i:int = 0; i < n; i++)
            {
               var child:DisplayObject = c.getChildAt(i);
               if(child == null || !child.visible)
               {
                  this.mix(-1);
                  continue;
               }
               this.mix(child.x * 20);
               this.mix(child.y * 20);
               this.mix(child.scaleX * 1000);
               this.mix(child.scaleY * 1000);
               this.mix(child.rotation * 100);
               this.mix(child.alpha * 255);
               this.signature(child);
            }
         }
      }

      private function idOf(table:Dictionary, thing:Object) : int
      {
         if(thing == null)
         {
            return 0;
         }
         var id:* = table[thing];
         if(id === undefined)
         {
            id = this.mNextId++;
            table[thing] = id;
         }
         return id;
      }

      private function rasterise(obj:DisplayObject, sx:Number, sy:Number, ct:ColorTransform) : Snapshot
      {
         var entry:Snapshot = new Snapshot();
         var local:Rectangle = obj.getBounds(obj);
         if(local.width <= 0 || local.height <= 0)
         {
            return entry;
         }
         this.mMatrix.setTo(sx,0,0,sy,0,0);
         var r:Rectangle = transformedBounds(local,this.mMatrix,this.mPoint);
         // One pixel of padding keeps anti-aliased edges intact.
         var x0:int = Math.floor(r.x) - 1;
         var y0:int = Math.floor(r.y) - 1;
         var w:int = Math.min(MAX_SIDE,Math.ceil(r.right) + 1 - x0);
         var h:int = Math.min(MAX_SIDE,Math.ceil(r.bottom) + 1 - y0);
         if(w <= 0 || h <= 0)
         {
            return entry;
         }
         var bd:BitmapData = new BitmapData(w,h,true,0);
         this.mMatrix.translate(-x0,-y0);
         bd.drawWithQuality(obj,this.mMatrix,isIdentity(ct) ? null : ct,null,null,true,StageQuality.HIGH_16X16);
         entry.texture = upload(bd);
         entry.offsetX = x0;
         entry.offsetY = y0;
         entry.pixels = w * h;
         return entry;
      }

      // Draw `obj` into its live buffer, growing the buffer (with slack) only
      // when the look no longer fits.
      private function redrawLive(live:Snapshot, obj:DisplayObject, sx:Number, sy:Number, ct:ColorTransform) : void
      {
         var local:Rectangle = obj.getBounds(obj);
         if(local.width <= 0 || local.height <= 0)
         {
            live.offsetX = live.offsetY = 0;
            if(live.bitmap && live.texture)
            {
               live.bitmap.fillRect(live.bitmap.rect,0);
               live.texture.root.uploadBitmapData(live.bitmap);
            }
            return;
         }
         this.mMatrix.setTo(sx,0,0,sy,0,0);
         var r:Rectangle = transformedBounds(local,this.mMatrix,this.mPoint);
         var x0:int = Math.floor(r.x) - 1;
         var y0:int = Math.floor(r.y) - 1;
         var w:int = Math.min(MAX_SIDE,Math.ceil(r.right) + 1 - x0);
         var h:int = Math.min(MAX_SIDE,Math.ceil(r.bottom) + 1 - y0);
         if(w <= 0 || h <= 0)
         {
            return;
         }
         if(live.bitmap == null || w > live.bitmap.width || h > live.bitmap.height)
         {
            var bw:int = Math.min(MAX_SIDE,Math.max(w + (w >> 2),live.bitmap ? live.bitmap.width : 0));
            var bh:int = Math.min(MAX_SIDE,Math.max(h + (h >> 2),live.bitmap ? live.bitmap.height : 0));
            if(live.bitmap)
            {
               this.mUsedPixels -= live.pixels;
            }
            live.dispose();
            live.bitmap = new BitmapData(bw,bh,true,0);
            live.texture = upload(live.bitmap);
            if(live.texture == null)
            {
               live.bitmap.dispose();
               live.bitmap = null;
               return;
            }
            live.pixels = bw * bh;
            this.mUsedPixels += live.pixels;
         }
         else
         {
            live.bitmap.fillRect(live.bitmap.rect,0);
         }
         this.mMatrix.translate(-x0,-y0);
         live.bitmap.drawWithQuality(obj,this.mMatrix,isIdentity(ct) ? null : ct,null,null,true,StageQuality.HIGH_16X16);
         live.texture.root.uploadBitmapData(live.bitmap);
         live.offsetX = x0;
         live.offsetY = y0;
      }

      // Free the live buffers of objects not drawn for a while.
      private function sweepLive() : void
      {
         for(var obj:Object in this.mLive)
         {
            var live:Snapshot = this.mLive[obj];
            if(this.mFrame - live.lastUsed > 80)
            {
               this.mUsedPixels -= live.pixels;
               live.dispose();
               delete this.mLive[obj];
            }
         }
      }

      private function evict() : void
      {
         // Drop least recently used looks until we are back under 80% of budget.
         var all:Array = [];
         for each(var entry:Snapshot in this.mEntries)
         {
            if(entry.lastUsed < this.mFrame)
            {
               all.push(entry);
            }
         }
         all.sortOn("lastUsed",Array.NUMERIC);
         var target:Number = this.mBudgetPixels * 0.8;
         var targetCount:int = MAX_ENTRIES * 0.8;
         for(var i:int = 0; i < all.length && (this.mUsedPixels > target || this.mEntryCount > targetCount); i++)
         {
            entry = all[i];
            delete this.mEntries[entry.key];
            --this.mEntryCount;
            this.mUsedPixels -= entry.pixels;
            entry.dispose();
         }
      }

      // A texture of `bd`, or null when the GPU has no room for one; the
      // look is then simply not drawn this time, instead of the frame failing.
      private static function upload(bd:BitmapData) : Texture
      {
         return GpuTextures.fromBitmapData(bd);
      }

      // The GPU is out of textures: free every look and live buffer not drawn
      // this frame (they are drawn again when next needed).
      public function reclaim() : void
      {
         for each(var entry:Snapshot in this.mEntries)
         {
            if(entry.lastUsed < this.mFrame)
            {
               delete this.mEntries[entry.key];
               --this.mEntryCount;
               this.mUsedPixels -= entry.pixels;
               entry.dispose();
            }
         }
         for(var obj:Object in this.mLive)
         {
            var live:Snapshot = this.mLive[obj];
            if(live.lastUsed < this.mFrame)
            {
               this.mUsedPixels -= live.pixels;
               live.dispose();
               delete this.mLive[obj];
            }
         }
      }

      public function get entryCount() : int
      {
         return this.mEntryCount;
      }

      public function get liveCount() : int
      {
         var n:int = 0;
         for(var obj:Object in this.mLive)
         {
            ++n;
         }
         return n;
      }

      private static function isIdentity(ct:ColorTransform) : Boolean
      {
         return ct.redMultiplier == 1 && ct.greenMultiplier == 1 && ct.blueMultiplier == 1 && ct.alphaMultiplier == 1 && ct.redOffset == 0 && ct.greenOffset == 0 && ct.blueOffset == 0 && ct.alphaOffset == 0;
      }

      private static function transformedBounds(r:Rectangle, m:Matrix, p:Point) : Rectangle
      {
         var minX:Number = Number.MAX_VALUE;
         var minY:Number = Number.MAX_VALUE;
         var maxX:Number = -Number.MAX_VALUE;
         var maxY:Number = -Number.MAX_VALUE;
         for(var i:int = 0; i < 4; i++)
         {
            p.x = i & 1 ? r.right : r.left;
            p.y = i & 2 ? r.bottom : r.top;
            var q:Point = m.transformPoint(p);
            minX = Math.min(minX,q.x);
            minY = Math.min(minY,q.y);
            maxX = Math.max(maxX,q.x);
            maxY = Math.max(maxY,q.y);
         }
         return new Rectangle(minX,minY,maxX - minX,maxY - minY);
      }
   }
}
