package game.render.timeline
{
   import flash.display.BitmapData;
   import game.render.GpuTextures;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.Shape;
   import flash.display.StageQuality;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;
   import flash.geom.Point;
   import flash.geom.ColorTransform;
   import flash.filters.BitmapFilter;
   import flash.filters.GlowFilter;
   import flash.filters.BlurFilter;
   import flash.text.TextField;
   import flash.utils.getDefinitionByName;
   import game.utils.TimelinePauser;
   import starling.display.Mesh;
   import starling.rendering.IndexData;
   import starling.rendering.VertexData;
   import starling.styles.MeshStyle;
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

      private var mAuthored:Object = {};

      // Mask shape id -> {vertices, indices}, or null if it has no geometry.
      private var mMaskMeshes:Object = {};

      // Text leaves: the TextField found for each, kept so drawing new text
      // needs no further walks over the art.
      private var mTextFields:Object = {};

      private var mMatrix:Matrix = new Matrix();

      public var rasterised:int = 0;

      // Development aid: path walks over Flash instances (find), text draws.
      public static var finds:int = 0;

      public static var textDraws:int = 0;

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

      // A mask shape, as geometry: Stage3D stencil masks take geometry, and
      // the runtime draws a shape the timeline uses as a mask as nothing, so
      // the shape comes from the SWF as rectangles in art units
      // (macos/tools/maskshapes.py). Null if the shape has none.
      public function maskMesh(id:int) : Mesh
      {
         if(!(id in this.mMaskMeshes))
         {
            var info:Object = this.mLibrary.leaf(id);
            var rects:Array = info ? info.mask : null;
            var mesh:Object = null;
            if(rects && rects.length)
            {
               var vertices:VertexData = new VertexData(MeshStyle.VERTEX_FORMAT,rects.length * 4);
               var indices:IndexData = new IndexData(rects.length * 6);
               for(var i:int = 0; i < rects.length; i++)
               {
                  var r:Array = rects[i];
                  var v:int = i * 4;
                  vertices.setPoint(v,"position",r[0],r[1]);
                  vertices.setPoint(v + 1,"position",r[0] + r[2],r[1]);
                  vertices.setPoint(v + 2,"position",r[0],r[1] + r[3]);
                  vertices.setPoint(v + 3,"position",r[0] + r[2],r[1] + r[3]);
                  indices.addQuad(v,v + 1,v + 2,v + 3);
               }
               vertices.colorize("color",0xffffff,1);
               mesh = {"vertices":vertices,"indices":indices};
            }
            this.mMaskMeshes[id] = mesh;
         }
         var m:Object = this.mMaskMeshes[id];
         return m ? new Mesh(VertexData(m.vertices).clone(),IndexData(m.indices).clone()) : null;
      }

      private function find(id:int) : DisplayObject
      {
         ++finds;
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
            // Off the display list it would keep playing; only its frames
            // are wanted.
            stopTree(root);
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
            // That built the frame's children, playing; stop them before the
            // next step can take them off the display list (where they would
            // go on playing, and building frames, until collected).
            stopTree(mc);
            if(path[i][1] >= mc.numChildren)
            {
               return null;
            }
            node = mc.getChildAt(path[i][1]);
         }
         return node;
      }

      // Development aid: the cached art roots, and clips playing inside them.
      public function describeRoots() : String
      {
         var roots:int = 0;
         var playing:Array = [];
         for(var name:String in this.mRoots)
         {
            ++roots;
            collectPlaying(this.mRoots[name],name,playing);
         }
         return "atlas roots: " + roots + ", playing inside: " + playing.length + (playing.length ? " e.g. " + playing.slice(0,6).join(", ") : "");
      }

      private static function collectPlaying(o:DisplayObject, path:String, out:Array) : void
      {
         if(o == null)
         {
            return;
         }
         var mc:MovieClip = o as MovieClip;
         if(mc && mc.isPlaying && mc.totalFrames > 1)
         {
            out.push(path + " (" + mc.currentFrame + "/" + mc.totalFrames + ")");
         }
         var c:DisplayObjectContainer = o as DisplayObjectContainer;
         for(var i:int = 0; c && i < c.numChildren; i++)
         {
            var child:DisplayObject = c.getChildAt(i);
            collectPlaying(child,path + "/" + (child ? child.name : "null"),out);
         }
      }

      private static function stopTree(o:DisplayObject) : void
      {
         var mc:MovieClip = o as MovieClip;
         if(mc && mc.isPlaying)
         {
            mc.stop();
         }
         var c:DisplayObjectContainer = o as DisplayObjectContainer;
         for(var i:int = 0; c && i < c.numChildren; i++)
         {
            stopTree(c.getChildAt(i));
         }
      }

      private var mFiltered:Object = {};

      // The leaf drawn with Flash filters applied (as the timeline placing
      // it filters it), keyed by `key` (the filter settings): Flash's own
      // glow, e.g. a strong one as a hard outline, which Starling's glow
      // (no strength) cannot draw. Null if it cannot be drawn so.
      public function getFiltered(id:int, filters:Array, key:String) : Leaf
      {
         var cacheKey:String = id + "|" + key;
         if(cacheKey in this.mFiltered)
         {
            return this.mFiltered[cacheKey];
         }
         var made:Array = [];
         var pad:int = 2;
         for each(var f:Object in filters)
         {
            if(f.type == "glow")
            {
               made.push(new flash.filters.GlowFilter(f.color,f.alpha,f.blurX,f.blurY,f.strength,f.quality || 1,f.inner,f.knockout));
            }
            else if(f.type == "blur")
            {
               made.push(new flash.filters.BlurFilter(f.blurX,f.blurY,f.quality || 1));
            }
            else
            {
               made = null;
               break;
            }
            pad += Math.ceil(Math.max(f.blurX,f.blurY));
         }
         var leaf:Leaf = null;
         var source:DisplayObject = made && made.length ? this.find(id) : null;
         if(source)
         {
            leaf = this.rasterise(source,made,pad);
         }
         this.mFiltered[cacheKey] = leaf;
         return leaf;
      }

      // A static sprite (one frame of shapes, no text or masks) drawn as one
      // leaf with Flash filters applied, keyed like getFiltered: composited
      // from its shapes' rasters, then filtered. Null if it is not static.
      public function getFilteredSprite(id:int, filters:Array, key:String) : Leaf
      {
         var cacheKey:String = "s" + id + "|" + key;
         if(cacheKey in this.mFiltered)
         {
            return this.mFiltered[cacheKey];
         }
         this.mFiltered[cacheKey] = null;
         var pad:int = 2;
         var made:Array = flashFilters(filters);
         for each(var f:Object in filters)
         {
            pad += Math.ceil(Math.max(f.blurX,f.blurY));
         }
         var parts:Array = [];
         if(made == null || !this.collectStatic(id,new Matrix(),null,parts,0) || parts.length == 0)
         {
            return null;
         }
         var minX:Number = Number.MAX_VALUE;
         var minY:Number = Number.MAX_VALUE;
         var maxX:Number = -Number.MAX_VALUE;
         var maxY:Number = -Number.MAX_VALUE;
         for each(var part:Object in parts)
         {
            var leaf:Leaf = part.leaf;
            var r:Rectangle = new Rectangle(leaf.offsetX,leaf.offsetY,leaf.region.width / this.mScale,leaf.region.height / this.mScale);
            var m:Matrix = part.m;
            for each(var corner:Point in [r.topLeft,new Point(r.right,r.top),new Point(r.left,r.bottom),r.bottomRight])
            {
               var p:Point = m.transformPoint(corner);
               minX = Math.min(minX,p.x);
               minY = Math.min(minY,p.y);
               maxX = Math.max(maxX,p.x);
               maxY = Math.max(maxY,p.y);
            }
         }
         var x0:Number = Math.floor(minX * this.mScale) - 1 - pad;
         var y0:Number = Math.floor(minY * this.mScale) - 1 - pad;
         var w:int = Math.ceil(maxX * this.mScale) + 1 + pad - x0;
         var h:int = Math.ceil(maxY * this.mScale) + 1 + pad - y0;
         if(w > PAGE_SIZE - 2 * PADDING || h > PAGE_SIZE - 2 * PADDING)
         {
            return null;
         }
         var tmp:BitmapData = new BitmapData(w,h,true,0);
         for each(part in parts)
         {
            leaf = part.leaf;
            var src:BitmapData = new BitmapData(leaf.region.width,leaf.region.height,true,0);
            src.copyPixels(leaf.page.bitmap,leaf.region,new Point(0,0));
            // Raster pixels -> art units -> through the placements -> pixels.
            var dm:Matrix = new Matrix(1 / this.mScale,0,0,1 / this.mScale,leaf.offsetX,leaf.offsetY);
            dm.concat(part.m);
            dm.concat(new Matrix(this.mScale,0,0,this.mScale,-x0,-y0));
            tmp.draw(src,dm,part.ct,null,null,true);
            src.dispose();
         }
         for each(var filter:flash.filters.BitmapFilter in made)
         {
            tmp.applyFilter(tmp,tmp.rect,new Point(0,0),filter);
         }
         var slot:Rectangle = this.allocate(w,h);
         var page:Page = this.mPages[int(slot.width)];
         page.bitmap.copyPixels(tmp,tmp.rect,new Point(slot.x,slot.y));
         tmp.dispose();
         page.dirty = true;
         var baked:Leaf = new Leaf();
         baked.page = page;
         baked.region = new Rectangle(slot.x,slot.y,w,h);
         baked.offsetX = x0 / this.mScale;
         baked.offsetY = y0 / this.mScale;
         ++this.rasterised;
         this.mFiltered[cacheKey] = baked;
         return baked;
      }

      // The shapes of sprite `id`'s only frame, in drawing order, with their
      // matrix and colour transform to the sprite; false if it is not static.
      private function collectStatic(id:int, m:Matrix, ct:ColorTransform, out:Array, depth:int) : Boolean
      {
         var def:SpriteDef = depth < 8 ? this.mLibrary.sprite(id) : null;
         if(def == null || def.totalFrames != 1)
         {
            return false;
         }
         var ops:Array = [];
         for each(var op:PlaceOp in def.ops[0])
         {
            if(!op.remove && op.character >= 0)
            {
               ops.push(op);
            }
         }
         ops.sortOn("depth",Array.NUMERIC);
         for each(op in ops)
         {
            if(op.clipDepth > 0 || op.filters || op.blendMode && op.blendMode != "normal" || op.hasVisible && !op.visible)
            {
               return false;
            }
            var cm:Matrix = op.matrix ? op.matrix.clone() : new Matrix();
            cm.concat(m);
            var cct:ColorTransform = null;
            if(op.color)
            {
               var c:Array = op.color;
               cct = new ColorTransform(c[0],c[1],c[2],c[3],c[4],c[5],c[6],c[7]);
            }
            if(ct)
            {
               if(cct == null)
               {
                  cct = new ColorTransform();
               }
               cct.concat(ct);
            }
            if(this.mLibrary.isSprite(op.character))
            {
               if(!this.collectStatic(op.character,cm,cct,out,depth + 1))
               {
                  return false;
               }
               continue;
            }
            var info:Object = this.mLibrary.leaf(op.character);
            if(info == null || info.kind == "edittext")
            {
               return false;
            }
            var leaf:Leaf = this.get(op.character);
            if(leaf)
            {
               out.push({"leaf":leaf,"m":cm,"ct":cct});
            }
         }
         return true;
      }

      private static function flashFilters(filters:Array) : Array
      {
         var made:Array = [];
         for each(var f:Object in filters)
         {
            if(f.type == "glow")
            {
               made.push(new flash.filters.GlowFilter(f.color,f.alpha,f.blurX,f.blurY,f.strength,f.quality || 1,f.inner,f.knockout));
            }
            else if(f.type == "blur")
            {
               made.push(new flash.filters.BlurFilter(f.blurX,f.blurY,f.quality || 1));
            }
            else
            {
               return null;
            }
         }
         return made.length ? made : null;
      }

      private function rasterise(source:DisplayObject, filters:Array = null, pad:int = 0) : Leaf
      {
         var bounds:Rectangle = source.getBounds(source);
         if(bounds.width <= 0 || bounds.height <= 0)
         {
            return null;
         }
         // Filters are in screen pixels in Flash (not scaled with the art).
         var x0:Number = Math.floor(bounds.x * this.mScale) - 1 - pad;
         var y0:Number = Math.floor(bounds.y * this.mScale) - 1 - pad;
         var w:int = Math.ceil(bounds.right * this.mScale) + 1 + pad - x0;
         var h:int = Math.ceil(bounds.bottom * this.mScale) + 1 + pad - y0;
         if(w > PAGE_SIZE - 2 * PADDING || h > PAGE_SIZE - 2 * PADDING)
         {
            return null;
         }
         var slot:Rectangle = this.allocate(w,h);
         var page:Page = this.mPages[int(slot.width)];
         if(filters)
         {
            var tmp:BitmapData = new BitmapData(w,h,true,0);
            this.mMatrix.setTo(this.mScale,0,0,this.mScale,-x0,-y0);
            tmp.drawWithQuality(source,this.mMatrix,null,null,null,true,StageQuality.HIGH_16X16);
            for each(var filter:flash.filters.BitmapFilter in filters)
            {
               tmp.applyFilter(tmp,tmp.rect,new Point(0,0),filter);
            }
            page.bitmap.copyPixels(tmp,tmp.rect,new Point(slot.x,slot.y));
            tmp.dispose();
         }
         else
         {
            this.mMatrix.setTo(this.mScale,0,0,this.mScale,slot.x - x0,slot.y - y0);
            page.bitmap.drawWithQuality(source,this.mMatrix,null,null,new Rectangle(slot.x,slot.y,w,h),true,StageQuality.HIGH_16X16);
         }
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

      // Dynamic text: the text a text leaf was authored with.
      public function authoredText(id:int) : String
      {
         if(!(id in this.mAuthored))
         {
            var tf:TextField = this.textField(id);
            this.mAuthored[id] = tf ? tf.text : "";
         }
         return this.mAuthored[id];
      }

      private function textField(id:int) : TextField
      {
         if(!(id in this.mTextFields))
         {
            var tf:TextField = this.find(id) as TextField;
            // Kept on its own (it is drawn with other text later), so it does
            // not keep the art it was found in alive.
            if(tf && tf.parent)
            {
               tf.parent.removeChild(tf);
            }
            this.mTextFields[id] = tf;
         }
         return this.mTextFields[id];
      }

      // Dynamic text: the text leaf drawn with other text, as its own
      // texture {texture, offsetX, offsetY} (art units), or null if empty.
      public function drawText(id:int, text:String, autoSize:String = null) : Object
      {
         ++textDraws;
         var tf:TextField = this.textField(id);
         if(tf == null)
         {
            return null;
         }
         this.authoredText(id);
         var old:String = tf.text;
         var oldAutoSize:String = tf.autoSize;
         var oldX:Number = tf.x;
         var oldWidth:Number = tf.width;
         if(autoSize)
         {
            tf.autoSize = autoSize;
         }
         tf.text = text;
         var bounds:Rectangle = tf.getBounds(tf);
         var out:Object = null;
         if(bounds.width > 0 && bounds.height > 0 && text.length > 0)
         {
            var x0:Number = Math.floor(bounds.x * this.mScale) - 1;
            var y0:Number = Math.floor(bounds.y * this.mScale) - 1;
            var w:int = Math.ceil(bounds.right * this.mScale) + 1 - x0;
            var h:int = Math.ceil(bounds.bottom * this.mScale) + 1 - y0;
            var bmp:BitmapData = new BitmapData(w,h,true,0);
            this.mMatrix.setTo(this.mScale,0,0,this.mScale,-x0,-y0);
            bmp.drawWithQuality(tf,this.mMatrix,null,null,null,true,StageQuality.HIGH_16X16);
            // Auto-sizing moves the field to keep it centred (or right
            // aligned); that move is in the parent's coordinates, so it goes
            // onto the offset too.
            // No room left on the GPU: the text is not drawn, rather than
            // the frame failing.
            var texture:Texture = GpuTextures.fromBitmapData(bmp,this.mScale);
            out = texture ? {
               "texture":texture,
               "offsetX":x0 / this.mScale + (autoSize ? tf.x - oldX : 0),
               "offsetY":y0 / this.mScale
            } : null;
            bmp.dispose();
         }
         tf.text = old;
         if(autoSize)
         {
            tf.autoSize = oldAutoSize;
            tf.width = oldWidth;
            tf.x = oldX;
         }
         return out;
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
         this.releaseRoots();
      }

      // Let go of the art built to find leaves once a frame's finds are done.
      // Off the display list and stopped, a clip left on some frames (a unit's
      // health hint on its 2nd or 51st) still has the runtime build that
      // frame's children anew every frame: kept, the roots made ~80 badge
      // clips a second for good, and much of the garbage. Each goes back to
      // its first frame (which stays put) and is dropped; a later find makes
      // the root again.
      private function releaseRoots() : void
      {
         var any:Boolean = false;
         for each(var root:MovieClip in this.mRoots)
         {
            rewindTree(root);
            emptyTree(root);
            any = true;
         }
         if(any)
         {
            this.mRoots = {};
         }
      }

      // Take everything out of the art, deepest first.
      private static function emptyTree(o:DisplayObject) : void
      {
         var c:DisplayObjectContainer = o as DisplayObjectContainer;
         if(c == null)
         {
            return;
         }
         while(c.numChildren > 0)
         {
            var child:DisplayObject = c.getChildAt(c.numChildren - 1);
            emptyTree(child);
            c.removeChildAt(c.numChildren - 1);
         }
      }

      private static function rewindTree(o:DisplayObject) : void
      {
         var mc:MovieClip = o as MovieClip;
         if(mc && mc.totalFrames > 1 && mc.currentFrame != 1)
         {
            mc.gotoAndStop(1);
         }
         stopTree(o);
         var c:DisplayObjectContainer = o as DisplayObjectContainer;
         for(var i:int = 0; c && i < c.numChildren; i++)
         {
            rewindTree(c.getChildAt(i));
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
         this.mFiltered = {};
         this.releaseRoots();
         this.mTextFields = {};
      }

   }
}

import flash.display.BitmapData;
import starling.textures.Texture;
import game.render.GpuTextures;

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
         // Without room for it, the page stays dirty and is tried again.
         this.texture = GpuTextures.fromBitmapData(this.bitmap,this.mScale);
         if(this.texture == null)
         {
            return;
         }
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
