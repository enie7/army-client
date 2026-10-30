package game.render.timeline
{
   import flash.geom.Matrix;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.display.Mesh;
   import starling.display.Sprite;
   import starling.filters.BlurFilter;
   import starling.filters.FilterChain;
   import starling.filters.FragmentFilter;
   import starling.filters.GlowFilter;

   // A Starling replay of one SWF sprite's timeline, behaving like a Flash
   // MovieClip: it applies the sprite's placement stream frame by frame
   // (place / move / replace / remove at depths), nested clips run on their
   // own clocks, and it can be driven with gotoAndStop / gotoAndPlay, frame
   // labels and named children.
   //
   // Coordinates are art units, as in the SWF; leaves come from a LeafAtlas
   // rasterised at the scale the clip is displayed at.
   //
   // Not yet supported: masks (clip depth), additive colour offsets, morph
   // shapes at other ratios than their first use, frame scripts.
   public class TimelineClip extends Sprite
   {
      private var mDef:SpriteDef;

      private var mLibrary:TimelineLibrary;

      private var mAtlas:LeafAtlas;

      private var mFrame:int = 0;

      private var mPlaying:Boolean = true;

      // depth -> Node, plus the nodes sorted by depth for ordering.
      private var mNodes:Object = {};

      private var mDepths:Vector.<int> = new Vector.<int>();

      // Accumulated RGB tint from ancestors, applied to leaf images.
      private var mTintR:Number = 1;

      private var mTintG:Number = 1;

      private var mTintB:Number = 1;

      // Accumulated additive offsets from ancestors, in colour units (0..1).
      private var mOffsetR:Number = 0;

      private var mOffsetG:Number = 0;

      private var mOffsetB:Number = 0;

      // Drawn only into the stencil, as (part of) a mask.
      private var mAsMask:Boolean;

      private var mMasksDirty:Boolean = false;

      // Created by code (not by a parent's timeline): like a MovieClip made
      // with `new`, it stays on frame 1 through the first frame after.
      private var mFresh:Boolean = false;

      public function TimelineClip(def:SpriteDef, library:TimelineLibrary, atlas:LeafAtlas, asMask:Boolean = false)
      {
         super();
         this.mDef = def;
         this.mLibrary = library;
         this.mAtlas = atlas;
         this.mAsMask = asMask;
         this.seek(1);
      }

      public static function forSymbol(name:String, library:TimelineLibrary, atlas:LeafAtlas) : TimelineClip
      {
         var id:int = library.symbolId(name);
         var def:SpriteDef = id >= 0 ? library.sprite(id) : null;
         var clip:TimelineClip = def ? new TimelineClip(def,library,atlas) : null;
         if(clip)
         {
            clip.mFresh = true;
         }
         return clip;
      }

      public function get currentFrame() : int
      {
         return this.mFrame;
      }

      public function get totalFrames() : int
      {
         return this.mDef.totalFrames;
      }

      public function get isPlaying() : Boolean
      {
         return this.mPlaying;
      }

      // Like MovieClip.currentFrameLabel: only on the labelled frame itself.
      public function get currentFrameLabel() : String
      {
         return this.mDef.frameLabels[this.mFrame];
      }

      // Like MovieClip.currentLabel: the last label at or before this frame.
      public function get currentLabel() : String
      {
         for(var f:int = this.mFrame; f > 0; f--)
         {
            if(this.mDef.frameLabels[f] != null)
            {
               return this.mDef.frameLabels[f];
            }
         }
         return null;
      }

      public function play() : void
      {
         this.mPlaying = true;
      }

      public function stop() : void
      {
         this.mPlaying = false;
      }

      public function gotoAndStop(frame:Object) : void
      {
         this.seek(this.resolve(frame));
         this.mPlaying = false;
      }

      public function gotoAndPlay(frame:Object) : void
      {
         this.mPlaying = true;
         this.seek(this.resolve(frame));
      }

      public function nextFrame() : void
      {
         if(this.mFrame < this.mDef.totalFrames)
         {
            this.seek(this.mFrame + 1);
         }
         this.mPlaying = false;
      }

      // The child placed under this instance name, as a TimelineClip (for
      // sprites) or a display object (for leaves); null if none.
      public function getPartByName(name:String) : DisplayObject
      {
         for each(var node:Node in this.mNodes)
         {
            if(node.name == name)
            {
               return node.display;
            }
         }
         return null;
      }

      // Development aid: this clip's frame and its nested clips', like
      // "3(1 6)", children in display order.
      public function describeFrames() : String
      {
         var inner:String = "";
         for(var i:int = 0; i < numChildren; i++)
         {
            var clip:TimelineClip = getChildAt(i) as TimelineClip;
            if(clip)
            {
               inner += (inner ? " " : "") + clip.describeFrames();
            }
         }
         return inner ? this.mFrame + "(" + inner + ")" : String(this.mFrame);
      }

      // Nested clips, in display order.
      public function get childClips() : Vector.<TimelineClip>
      {
         var out:Vector.<TimelineClip> = new Vector.<TimelineClip>();
         for(var i:int = 0; i < numChildren; i++)
         {
            var clip:TimelineClip = getChildAt(i) as TimelineClip;
            if(clip)
            {
               out.push(clip);
            }
         }
         return out;
      }

      // Set the text of the dynamic text field placed under `name` (like
      // setting TextField.text); false if there is none. The field is drawn
      // again from the original TextField with the new text.
      public function setText(name:String, text:String) : Boolean
      {
         for each(var node:Node in this.mNodes)
         {
            if(node.name == name && node.text != null)
            {
               if(node.text != text)
               {
                  node.text = text;
                  var drawn:Object = this.mAtlas.drawText(node.character,text);
                  if(node.textTexture)
                  {
                     node.textTexture.dispose();
                  }
                  node.textTexture = drawn ? drawn.texture : null;
                  node.image.visible = drawn != null;
                  if(drawn)
                  {
                     node.image.texture = drawn.texture;
                     node.image.readjustSize();
                     node.image.x = drawn.offsetX;
                     node.image.y = drawn.offsetY;
                  }
               }
               return true;
            }
         }
         return false;
      }

      public function getText(name:String) : String
      {
         for each(var node:Node in this.mNodes)
         {
            if(node.name == name && node.text != null)
            {
               return node.text;
            }
         }
         return null;
      }

      // Like `child.scaleX = -child.scaleX` in Flash on a timeline child: the
      // child is flipped, and from then on the timeline no longer moves it.
      public function flipPartX(name:String) : Boolean
      {
         for each(var node:Node in this.mNodes)
         {
            if(node.name == name)
            {
               var m:Matrix = node.matrix.clone();
               m.a = -m.a;
               m.b = -m.b;
               node.matrix = m;
               node.scripted = true;
               this.place(node);
               return true;
            }
         }
         return false;
      }

      // One tick of the 40 fps clock: advance every nested clip, then this
      // timeline if it is playing (looping at the end, as Flash does).
      // Children this frame creates start on their frame 1 and first advance
      // on the next tick, as in Flash.
      public function tick() : void
      {
         if(this.mFresh)
         {
            this.mFresh = false;
            return;
         }
         for each(var node:Node in this.mNodes)
         {
            var clip:TimelineClip = node.display as TimelineClip;
            if(clip != null)
            {
               clip.tick();
            }
         }
         if(this.mPlaying && this.mDef.totalFrames > 1)
         {
            this.seek(this.mFrame >= this.mDef.totalFrames ? 1 : this.mFrame + 1);
         }
      }

      private function resolve(frame:Object) : int
      {
         if(frame is String)
         {
            var labelled:* = this.mDef.labels[frame];
            return labelled === undefined ? this.mFrame : int(labelled);
         }
         return Math.max(1,Math.min(this.mDef.totalFrames,int(frame)));
      }

      // Move the playhead to `frame`: forward by applying the frames in
      // between; backward by rebuilding from frame 1, keeping the children
      // that are the same placement in both states (as Flash does).
      // Frame scripts run when the playhead lands on a frame (also via goto
      // and on construction); all of them are stop().
      private function seek(frame:int) : void
      {
         if(frame == this.mFrame)
         {
            return;
         }
         if(frame < this.mFrame)
         {
            this.rewindTo(frame);
         }
         else
         {
            this.forwardTo(frame);
         }
         if(this.mDef.stops[frame])
         {
            this.mPlaying = false;
         }
      }

      private function forwardTo(frame:int) : void
      {
         for(var f:int = this.mFrame + 1; f <= frame; f++)
         {
            this.applyFrame(f);
         }
         this.mFrame = frame;
         this.updateMasks();
      }

      private function rewindTo(frame:int) : void
      {
         // Placements that make up the target frame's display list.
         var target:Object = {};
         for(var f:int = 1; f <= frame; f++)
         {
            for each(var op:PlaceOp in this.mDef.ops[f - 1])
            {
               if(op.remove)
               {
                  delete target[op.depth];
               }
               else if(op.character >= 0)
               {
                  target[op.depth] = op.character;
               }
            }
         }
         for each(var depth:int in this.mDepths.concat())
         {
            var node:Node = this.mNodes[depth];
            if(target[depth] !== node.character)
            {
               this.removeDepth(depth);
            }
         }
         this.mFrame = 0;
         for(f = 1; f <= frame; f++)
         {
            this.applyFrame(f,true);
         }
         this.mFrame = frame;
         this.updateMasks();
      }

      // A placement with a clip depth masks the depths above it, up to and
      // including the clip depth (SWF semantics).
      // Development aid (--no-masks): draw masked content unmasked.
      public static var masksOff:Boolean = false;


      // Development aid (--show-masks, with --no-masks): draw mask shapes as
      // content, to see what they rasterised to.
      public static var showMasks:Boolean = false;

      private function updateMasks() : void
      {
         if(masksOff)
         {
            return;
         }
         if(!this.mMasksDirty)
         {
            return;
         }
         this.mMasksDirty = false;
         var mask:Node = null;
         for each(var depth:int in this.mDepths)
         {
            var node:Node = this.mNodes[depth];
            if(node.clipDepth > 0)
            {
               mask = node;
               continue;
            }
            if(mask != null && depth > mask.clipDepth)
            {
               mask = null;
            }
            var want:DisplayObject = mask ? mask.display : null;
            if(node.display.mask != want)
            {
               node.display.mask = want;
            }
         }
      }

      private function applyFrame(frame:int, rebuilding:Boolean = false) : void
      {
         for each(var op:PlaceOp in this.mDef.ops[frame - 1])
         {
            if(op.remove)
            {
               this.removeDepth(op.depth);
               continue;
            }
            var node:Node = this.mNodes[op.depth];
            if(op.character >= 0 && (node == null || node.character != op.character))
            {
               var keep:Matrix = node && op.move ? node.matrix : null;
               if(node != null)
               {
                  this.removeDepth(op.depth);
               }
               node = this.createNode(op.depth,op.character,op.clipDepth > 0);
               if(node == null)
               {
                  continue;
               }
               if(keep)
               {
                  node.matrix = keep;
               }
            }
            else if(node == null)
            {
               continue;
            }
            else if(rebuilding && op.character >= 0 && !op.move)
            {
               // Same placement kept across a rewind: reset what the frame sets.
               node.matrix = new Matrix();
            }
            // Once code has transformed a child, the timeline leaves its
            // transform alone (as in Flash).
            if(op.matrix && !node.scripted)
            {
               node.matrix = op.matrix;
            }
            if(op.name)
            {
               node.name = op.name;
            }
            if(op.color)
            {
               node.color = op.color;
            }
            if(op.filters)
            {
               node.display.filter = makeFilter(op.filters);
            }
            if(op.blendMode)
            {
               node.display.blendMode = op.blendMode == "add" ? "add" : (op.blendMode == "multiply" ? "multiply" : (op.blendMode == "screen" ? "screen" : "normal"));
            }
            if(op.clipDepth > 0 && node.clipDepth != op.clipDepth)
            {
               node.clipDepth = op.clipDepth;
               this.mMasksDirty = true;
            }
            if(op.hasVisible)
            {
               node.display.visible = op.visible;
            }
            this.place(node);
         }
      }

      private function createNode(depth:int, character:int, mask:Boolean) : Node
      {
         var node:Node = new Node();
         node.depth = depth;
         node.character = character;
         if(this.mLibrary.isSprite(character))
         {
            var clip:TimelineClip = new TimelineClip(this.mLibrary.sprite(character),this.mLibrary,this.mAtlas,mask || this.mAsMask);
            node.display = clip;
         }
         else
         {
            // Leaves sit in a holder so the timeline matrix can be set on the
            // holder while the image keeps its offset from the leaf origin.
            var holder:Sprite = new Sprite();
            if(mask || this.mAsMask)
            {
               // Masks are geometry (see LeafAtlas.maskMesh).
               var shape:Mesh = this.mAtlas.maskMesh(character);
               if(shape == null)
               {
                  return null;
               }
               holder.addChild(shape);
            }
            else
            {
               var leaf:Leaf = this.mAtlas.get(character);
               if(leaf == null)
               {
                  return null;
               }
               var image:Image = new Image(this.mAtlas.textureOf(leaf));
               image.x = leaf.offsetX;
               image.y = leaf.offsetY;
               image.style = new ColorTransformStyle();
               holder.addChild(image);
               node.image = image;
            }
            node.display = holder;
            if(this.mLibrary.leaf(character).kind == "edittext")
            {
               node.text = this.mAtlas.authoredText(character);
            }
         }
         this.mNodes[depth] = node;
         var at:int = 0;
         while(at < this.mDepths.length && this.mDepths[at] < depth)
         {
            at++;
         }
         this.mDepths.splice(at,0,depth);
         addChildAt(node.display,at);
         this.mMasksDirty = true;
         return node;
      }

      private function removeDepth(depth:int) : void
      {
         var node:Node = this.mNodes[depth];
         if(node == null)
         {
            return;
         }
         delete this.mNodes[depth];
         this.mMasksDirty = true;
         node.display.mask = null;
         this.mDepths.splice(this.mDepths.indexOf(depth),1);
         node.display.removeFromParent(true);
         if(node.textTexture)
         {
            node.textTexture.dispose();
         }
      }

      // Push the node's matrix and colour to its display object.
      private function place(node:Node) : void
      {
         node.display.transformationMatrix = node.matrix;
         var c:Array = node.color;
         // Masks are never drawn as content, only into the stencil.
         node.display.alpha = node.clipDepth > 0 && !showMasks ? 0 : (c ? Math.max(0,Math.min(1,c[3])) : 1);
         // Flash composes colour transforms child first: for a child (Mc, Oc)
         // under (Mp, Op), x * Mc + Oc then * Mp + Op, so M = Mc * Mp and
         // O = Oc * Mp + Op.
         var r:Number = this.mTintR * (c ? c[0] : 1);
         var g:Number = this.mTintG * (c ? c[1] : 1);
         var b:Number = this.mTintB * (c ? c[2] : 1);
         var or:Number = this.mOffsetR + (c ? c[4] / 255 * this.mTintR : 0);
         var og:Number = this.mOffsetG + (c ? c[5] / 255 * this.mTintG : 0);
         var ob:Number = this.mOffsetB + (c ? c[6] / 255 * this.mTintB : 0);
         if(node.image)
         {
            node.image.color = clamp(r) << 16 | clamp(g) << 8 | clamp(b);
            var style:ColorTransformStyle = node.image.style as ColorTransformStyle;
            if(style)
            {
               style.setOffsets(or,og,ob);
            }
         }
         else if(node.display is TimelineClip)
         {
            TimelineClip(node.display).setTint(r,g,b,or,og,ob);
         }
      }

      internal function setTint(r:Number, g:Number, b:Number, or:Number, og:Number, ob:Number) : void
      {
         if(r == this.mTintR && g == this.mTintG && b == this.mTintB && or == this.mOffsetR && og == this.mOffsetG && ob == this.mOffsetB)
         {
            return;
         }
         this.mTintR = r;
         this.mTintG = g;
         this.mTintB = b;
         this.mOffsetR = or;
         this.mOffsetG = og;
         this.mOffsetB = ob;
         for each(var node:Node in this.mNodes)
         {
            this.place(node);
         }
      }

      private static function clamp(v:Number) : int
      {
         return Math.max(0,Math.min(255,Math.round(v * 255)));
      }

      private static function makeFilter(list:Array) : FragmentFilter
      {
         var made:Array = [];
         for each(var f:Object in list)
         {
            if(f.type == "glow")
            {
               made.push(new GlowFilter(f.color,f.alpha * Math.min(1,f.strength),(f.blurX + f.blurY) / 8));
            }
            else if(f.type == "blur")
            {
               made.push(new BlurFilter(f.blurX / 4,f.blurY / 4));
            }
         }
         if(made.length == 0)
         {
            return null;
         }
         if(made.length == 1)
         {
            return made[0];
         }
         var chain:FilterChain = new FilterChain();
         for each(var one:FragmentFilter in made)
         {
            chain.addFilter(one);
         }
         return chain;
      }
   }
}

import flash.geom.Matrix;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.textures.Texture;

class Node
{
   // Dynamic text: the field's current text (null for other leaves), and
   // the texture drawn for it once code changed it.
   public var text:String;

   public var textTexture:Texture;

   // Transformed by code: the timeline no longer sets its matrix.
   public var scripted:Boolean;

   public var clipDepth:int;

   public var depth:int;

   public var character:int;

   public var name:String;

   public var display:DisplayObject;

   public var image:Image;

   public var matrix:Matrix = new Matrix();

   public var color:Array;
}
