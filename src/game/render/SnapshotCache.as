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

      private var mBudgetPixels:Number;

      private var mUsedPixels:Number = 0;

      private var mEntries:Object = {};

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
         var entry:Snapshot = this.mEntries[key];
         if(entry != null)
         {
            entry.lastUsed = this.mFrame;
            ++this.hits;
            return entry.texture ? entry : null;
         }
         ++this.misses;
         entry = this.rasterise(obj,sx,sy,ct);
         entry.key = key;
         entry.lastUsed = this.mFrame;
         this.mEntries[key] = entry;
         this.mUsedPixels += entry.pixels;
         if(this.mUsedPixels > this.mBudgetPixels)
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
         this.mEntries = {};
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
         entry.texture = Texture.fromBitmapData(bd,false,false,1);
         entry.offsetX = x0;
         entry.offsetY = y0;
         entry.pixels = w * h;
         return entry;
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
         for(var i:int = 0; i < all.length && this.mUsedPixels > target; i++)
         {
            entry = all[i];
            delete this.mEntries[entry.key];
            this.mUsedPixels -= entry.pixels;
            entry.dispose();
         }
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
