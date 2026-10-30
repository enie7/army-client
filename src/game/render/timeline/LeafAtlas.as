package game.render.timeline
{
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.StageQuality;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;
   import flash.utils.getDefinitionByName;
   import starling.textures.SubTexture;
   import starling.textures.Texture;

   // Leaf graphics of the world art (shapes, text), rasterised once per scale
   // from the original vectors and packed into shared atlas pages, so a whole
   // animated object draws from one texture and batches.
   //
   // Leaves are not exported from the SWF; TimelineLibrary gives a path to a
   // live instance (an exported symbol, then frame / child-index steps), which
   // is walked on an offscreen copy of that symbol.
   public class LeafAtlas
   {
      private static const PAGE_SIZE:int = 2048;

      private static const PADDING:int = 2;

      private var mLibrary:TimelineLibrary;

      private var mScale:Number;

      private var mLeaves:Object = {};

      private var mPages:Vector.<Page> = new Vector.<Page>();

      private var mRoots:Object = {};

      private var mMatrix:Matrix = new Matrix();

      public var rasterised:int = 0;

      // scale: screen pixels per art unit (zoom x contentScaleFactor).
      public function LeafAtlas(library:TimelineLibrary, scale:Number)
      {
         super();
         this.mLibrary = library;
         this.mScale = scale;
      }

      public function get scale() : Number
      {
         return this.mScale;
      }

      // The leaf's texture, or null when it draws nothing / cannot be found.
      public function get(id:int) : Leaf
      {
         if(id in this.mLeaves)
         {
            return this.mLeaves[id];
         }
         var source:DisplayObject = this.find(id);
         var leaf:Leaf;
         leaf = source ? this.rasterise(source) : null;
         this.mLeaves[id] = leaf;
         return leaf;
      }

      private function find(id:int) : DisplayObject
      {
         var info:Object = this.mLibrary.leaf(id);
         if(info == null)
         {
            return null;
         }
         var path:Array = info.path;
         var root:MovieClip = this.mRoots[path[0]];
         if(root == null)
         {
            var cls:Class;
            try
            {
               cls = getDefinitionByName(path[0]) as Class;
            }
            catch(e:Error)
            {
               return null;
            }
            root = new cls() as MovieClip;
            if(root == null)
            {
               return null;
            }
            this.mRoots[path[0]] = root;
         }
         var node:DisplayObject = root;
         for(var i:int = 1; i < path.length; i++)
         {
            var mc:MovieClip = node as MovieClip;
            if(mc == null)
            {
               return null;
            }
            mc.gotoAndStop(path[i][0]);
            if(path[i][1] >= mc.numChildren)
            {
               return null;
            }
            node = mc.getChildAt(path[i][1]);
         }
         return node;
      }

      private function rasterise(source:DisplayObject) : Leaf
      {
         var bounds:Rectangle = source.getBounds(source);
         if(bounds.width <= 0 || bounds.height <= 0)
         {
            return null;
         }
         var x0:Number = Math.floor(bounds.x * this.mScale) - 1;
         var y0:Number = Math.floor(bounds.y * this.mScale) - 1;
         var w:int = Math.ceil(bounds.right * this.mScale) + 1 - x0;
         var h:int = Math.ceil(bounds.bottom * this.mScale) + 1 - y0;
         if(w > PAGE_SIZE - 2 * PADDING || h > PAGE_SIZE - 2 * PADDING)
         {
            return null;
         }
         var slot:Rectangle = this.allocate(w,h);
         var page:Page = this.mPages[int(slot.width)];
         this.mMatrix.setTo(this.mScale,0,0,this.mScale,slot.x - x0,slot.y - y0);
         page.bitmap.drawWithQuality(source,this.mMatrix,null,null,new Rectangle(slot.x,slot.y,w,h),true,StageQuality.HIGH_16X16);
         page.dirty = true;
         var leaf:Leaf = new Leaf();
         leaf.page = page;
         leaf.region = new Rectangle(slot.x,slot.y,w,h);
         // Offset of the texture's top-left from the leaf origin, in art units.
         leaf.offsetX = x0 / this.mScale;
         leaf.offsetY = y0 / this.mScale;
         ++this.rasterised;
         return leaf;
      }

      // Shelf packing: rows of the current page, a new page when full.
      // Returns the slot; slot.width carries the page index.
      private function allocate(w:int, h:int) : Rectangle
      {
         var page:Page = this.mPages.length ? this.mPages[this.mPages.length - 1] : null;
         if(page == null || !page.fit(w + PADDING,h + PADDING,PAGE_SIZE))
         {
            page = new Page(PAGE_SIZE,this.mScale);
            this.mPages.push(page);
            page.fit(w + PADDING,h + PADDING,PAGE_SIZE);
         }
         return new Rectangle(page.lastX,page.lastY,this.mPages.length - 1,0);
      }

      // Upload pages that got new leaves since the last frame.
      public function upload() : void
      {
         for each(var page:Page in this.mPages)
         {
            if(page.dirty)
            {
               page.upload();
            }
         }
      }

      public function textureOf(leaf:Leaf) : Texture
      {
         if(leaf.texture == null)
         {
            if(leaf.page.texture == null)
            {
               leaf.page.upload();
            }
            leaf.texture = new SubTexture(leaf.page.texture,new Rectangle(leaf.region.x / this.mScale,leaf.region.y / this.mScale,leaf.region.width / this.mScale,leaf.region.height / this.mScale));
         }
         return leaf.texture;
      }

      // Development aid: the atlas pages as they are now.
      public function get pageBitmaps() : Vector.<BitmapData>
      {
         var out:Vector.<BitmapData> = new Vector.<BitmapData>();
         for each(var page:Page in this.mPages)
         {
            out.push(page.bitmap);
         }
         return out;
      }

      public function dispose() : void
      {
         for each(var page:Page in this.mPages)
         {
            page.dispose();
         }
         this.mPages.length = 0;
         this.mLeaves = {};
         this.mRoots = {};
      }

   }
}

import flash.display.BitmapData;
import starling.textures.Texture;

class Page
{
   public var bitmap:BitmapData;

   public var texture:Texture;

   public var dirty:Boolean = false;

   public var lastX:int;

   public var lastY:int;

   private var mShelfX:int = 0;

   private var mShelfY:int = 0;

   private var mShelfH:int = 0;

   private var mScale:Number;

   // scale: pixels per point, so leaf regions can be given in points.
   public function Page(size:int, scale:Number)
   {
      super();
      this.mScale = scale;
      this.bitmap = new BitmapData(size,size,true,0);
   }

   public function fit(w:int, h:int, size:int) : Boolean
   {
      if(this.mShelfX + w > size)
      {
         this.mShelfY += this.mShelfH;
         this.mShelfX = 0;
         this.mShelfH = 0;
      }
      if(this.mShelfY + h > size)
      {
         return false;
      }
      this.lastX = this.mShelfX;
      this.lastY = this.mShelfY;
      this.mShelfX += w;
      this.mShelfH = Math.max(this.mShelfH,h);
      return true;
   }

   public function upload() : void
   {
      if(this.texture == null)
      {
         this.texture = Texture.fromBitmapData(this.bitmap,false,false,this.mScale);
      }
      else
      {
         this.texture.root.uploadBitmapData(this.bitmap);
      }
      this.dirty = false;
   }

   public function dispose() : void
   {
      if(this.texture)
      {
         this.texture.dispose();
      }
      this.bitmap.dispose();
   }
}
