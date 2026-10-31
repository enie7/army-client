package game.render.view
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.Shape;
   import flash.geom.Rectangle;
   import flash.text.TextField;
   import flash.utils.getQualifiedClassName;
   import game.characters.AnimationController;
   import game.isometric.elements.Renderable;
   import game.render.WorldRenderer;
   import game.render.timeline.TimelineClip;
   import game.render.timeline.TimelineLibrary;
   import game.utils.TimelinePauser;
   import starling.display.DisplayObject;
   import starling.display.Sprite;

   // ObjectView whose art is drawn by the GPU timeline player instead of
   // Flash.
   //
   // The Flash art the game makes is kept off the display list, stopped, as a
   // model: the symbols to draw (by class name), their frames and transforms,
   // and the state game code sets on it (frames, visibility, text of named
   // parts, which the view copies to the GPU clips every frame). The Flash
   // container keeps an invisible shape with the art's bounds in the art's
   // place, because the scene sorts objects by their container's size
   // (IsometricScene.getTileRectSize).
   //
   // Static art (setArt) and animations (loadAnimations) both work this way.
   // Art that is not made of known symbols stays on Flash (FlashView).
   public class StarlingView extends FlashView
   {
      private static const HINT:String = "Hint_Health_Friendly";

      private static const HINT_ATTENTION:String = "Hint_Health_Friendly_Attention";

      // Static art: the Flash model, or null when showing Flash art.
      private var mSource:flash.display.DisplayObject;

      // Animations drawn on the GPU (else they go through FlashView).
      private var mGpuAnimations:Boolean;

      private var mPlaceholder:Shape;

      // The art's bounds in the container's coordinates (from the placeholder),
      // for the world renderer to skip art that is off screen.
      private var mBounds:Rectangle;

      // Positioned by the world renderer like the Flash container; holds the
      // converted art. Built on first use (the GPU may not be up when art
      // arrives).
      private var mNode:starling.display.Sprite;

      // Static art: the clip of the model's root symbol, and every clip made.
      private var mRoot:TimelineClip;

      private var mClips:Vector.<TimelineClip> = new Vector.<TimelineClip>();

      // Static art: names of parts game code got (artPart), synced each frame.
      private var mParts:Object = {};

      // Animations: per state, the converted wrapper, its art clips, and the
      // model's child count it was built from (art arrives late).
      private var mAnimNodes:Array = [];

      private var mAnimClips:Array = [];

      private var mAnimBuiltFrom:Array = [];

      private var mShown:int = -1;

      // Facing (AnimationController.setDirection, done here: there is no
      // Flash art to flip). mFlipped toggles on every change of direction
      // to left or right, as the controller's flips did.
      private var mDirection:int = AnimationController.DIR_RIGHT;

      private var mFlipped:Boolean = false;

      // The placeholder still has to be sized from the state's GPU art.
      private var mPlaceholderDirty:Boolean = false;


      public function StarlingView(renderable:Renderable, container:DisplayObjectContainer)
      {
         super(renderable,container);
      }

      // Development aid: "gpu-anim", "gpu-static" or "flash".
      public function get mode() : String
      {
         return this.mGpuAnimations ? "gpu-anim" : (this.mSource ? "gpu-static" : "flash");
      }

      // Development aid: the Flash models this view keeps (for counting what
      // still plays in them).
      public function get models() : Array
      {
         var out:Array = [];
         if(this.mSource)
         {
            out.push(this.mSource);
         }
         if(this.mGpuAnimations)
         {
            for(var i:int = 0; i < mAnimations.animationCount; i++)
            {
               out.push(mAnimations.getAnimationAt(i));
            }
         }
         return out;
      }

      // The symbols this view can show: its static art's, or every
      // animation state's (for GpuArt.prewarm).
      public function get symbols() : Array
      {
         var out:Array = [];
         if(this.mGpuAnimations)
         {
            for(var i:int = 0; i < mAnimations.animationCount; i++)
            {
               out.push(mAnimations.symbolAt(i));
            }
         }
         else if(this.mSource)
         {
            var walk:Function = function(d:flash.display.DisplayObject):void
            {
               var name:String = symbolName(d);
               if(GpuArt.library.hasSymbol(name))
               {
                  out.push(name);
                  return;
               }
               var c:DisplayObjectContainer = d as DisplayObjectContainer;
               for(var j:int = 0; c && j < c.numChildren; j++)
               {
                  walk(c.getChildAt(j));
               }
            };
            walk(this.mSource);
         }
         return out;
      }

      private function get onGpu() : Boolean
      {
         return this.mSource != null || this.mGpuAnimations;
      }

      // The GPU art for the world renderer, or null when this object shows
      // Flash art.
      public function get gpuNode() : starling.display.DisplayObject
      {
         if(!this.onGpu)
         {
            return null;
         }
         if(this.mNode == null)
         {
            this.mNode = new starling.display.Sprite();
            this.mNode.touchable = false;
            if(this.mSource)
            {
               this.buildStatic();
            }
         }
         if(this.mGpuAnimations)
         {
            this.attachAnimation();
         }
         return this.mNode;
      }

      public function get bounds() : Rectangle
      {
         return this.mBounds;
      }

      // Static art -----------------------------------------------------------

      override public function setArt(art:flash.display.DisplayObject) : void
      {
         this.clearArt();
         if(!GpuArt.enabled || this.mGpuAnimations || !convertible(art,GpuArt.library))
         {
            super.setArt(art);
            return;
         }
         this.mSource = art;
         stopAll(art as MovieClip);
         this.setPlaceholder(art);
         GpuArt.register(this);
      }

      override public function clearArt() : void
      {
         if(this.mSource == null)
         {
            if(this.mGpuAnimations)
            {
               // Animated objects swap static art in only on Flash.
               return;
            }
            super.clearArt();
            return;
         }
         GpuArt.unregister(this);
         this.removePlaceholder();
         this.disposeNode();
         this.mSource = null;
         this.mParts = {};
      }

      // The placeholder stands in the art's place for code that positions
      // things by the art.
      override public function get art() : flash.display.DisplayObject
      {
         return this.onGpu ? this.mPlaceholder : super.art;
      }

      override public function gotoArtFrame(frame:int) : void
      {
         if(this.mSource == null)
         {
            super.gotoArtFrame(frame);
            return;
         }
         var mc:MovieClip = this.mSource as MovieClip;
         if(mc)
         {
            mc.gotoAndStop(frame);
            this.setPlaceholder(mc);
         }
         if(this.mRoot)
         {
            this.mRoot.gotoAndStop(frame);
         }
      }

      override public function get artFrame() : int
      {
         if(this.mSource == null)
         {
            return super.artFrame;
         }
         var mc:MovieClip = this.mSource as MovieClip;
         return mc ? mc.currentFrame : 0;
      }

      // The part of the model; what code does to it (frame, play, visible,
      // text fields in it) is copied to the GPU part every frame.
      override public function artPart(name:String) : MovieClip
      {
         if(this.mSource == null)
         {
            return super.artPart(name);
         }
         this.mParts[name] = true;
         var mc:MovieClip = this.mSource as MovieClip;
         return mc ? mc.getChildByName(name) as MovieClip : null;
      }

      // Animations -----------------------------------------------------------

      override public function loadAnimations(files:Array) : void
      {
         if(!GpuArt.enabled || !knownSymbols(files,GpuArt.library))
         {
            super.loadAnimations(files);
            return;
         }
         // The controller's clips are only a model here: inert, so they
         // never play (see AnimationController.inert).
         mAnimations = new AnimationController(mRenderable);
         mAnimations.inert = true;
         mAnimations.loadAnimations(files);
         this.mGpuAnimations = true;
         GpuArt.register(this);
      }

      override public function showAnimation(stop:Boolean, play:Boolean) : void
      {
         if(!this.mGpuAnimations)
         {
            super.showAnimation(stop,play);
            return;
         }
         var index:int = mAnimations.getCurrentAnimationIndex();
         this.mShown = index;
         this.mPlaceholderDirty = true;
         if(WorldRenderer.active)
         {
            this.updateAnimationPlaceholder();
         }
         if(this.mNode)
         {
            this.attachAnimation();
         }
         if(stop)
         {
            this.restart(false);
         }
         else if(play)
         {
            this.restart(true);
         }
      }

      override public function playAnimation() : void
      {
         if(!this.mGpuAnimations)
         {
            super.playAnimation();
            return;
         }
         this.restart(true);
      }

      override public function stopAnimation() : void
      {
         if(!this.mGpuAnimations)
         {
            super.stopAnimation();
            return;
         }
         this.restart(false);
      }

      // As AnimationController.getCurrentAnimationFrameLabel: the label of the
      // art's frame, else the first one found among the clips below it, two
      // levels deep.
      override public function get frameLabel() : String
      {
         if(!this.mGpuAnimations)
         {
            return super.frameLabel;
         }
         for each(var art:TimelineClip in this.currentClips())
         {
            var label:String = art.currentFrameLabel;
            if(label)
            {
               return label;
            }
            for each(var c1:TimelineClip in art.childClips)
            {
               label = c1.currentFrameLabel;
               if(label)
               {
                  return label;
               }
               for each(var c2:TimelineClip in c1.childClips)
               {
                  label = c2.currentFrameLabel;
                  if(label)
                  {
                     return label;
                  }
               }
            }
         }
         return "";
      }

      // Like AnimationController.play/stopCurrentAnimation: back to frame 1,
      // playing or stopped, the art and two levels of clips in it.
      private function restart(play:Boolean) : void
      {
         for each(var art:TimelineClip in this.currentClips())
         {
            goFirst(art,play);
            for each(var c1:TimelineClip in art.childClips)
            {
               goFirst(c1,play);
               for each(var c2:TimelineClip in c1.childClips)
               {
                  goFirst(c2,play);
               }
            }
         }
      }

      private static function goFirst(clip:TimelineClip, play:Boolean) : void
      {
         if(play)
         {
            clip.gotoAndPlay(1);
         }
         else
         {
            clip.gotoAndStop(1);
         }
      }

      private function get shownIndex() : int
      {
         return this.mShown >= 0 ? this.mShown : mAnimations.getCurrentAnimationIndex();
      }

      // The art clips of the state being shown (built if needed).
      private function currentClips() : Vector.<TimelineClip>
      {
         var index:int = this.shownIndex;
         this.buildAnimation(index);
         return this.mAnimClips[index] || new Vector.<TimelineClip>();
      }

      // Build the GPU art of a state from its symbol: a wrapper (positioned
      // like the controller's wrapper clip) holding the art's clip.
      private function buildAnimation(index:int) : void
      {
         if(this.mAnimNodes[index] != null || index < 0 || index >= mAnimations.animationCount)
         {
            return;
         }
         var wrapper:starling.display.Sprite = new starling.display.Sprite();
         var clips:Vector.<TimelineClip> = new Vector.<TimelineClip>();
         var clip:TimelineClip = TimelineClip.forSymbol(mAnimations.symbolAt(index),GpuArt.library,GpuArt.atlas);
         if(clip)
         {
            wrapper.addChild(clip);
            clips.push(clip);
         }
         this.mAnimNodes[index] = wrapper;
         this.mAnimClips[index] = clips;
         if(this.mFlipped)
         {
            this.flip(index);
         }
      }

      // As AnimationController.setDirection flipped a state: its
      // "Unit_Container" part when the art has one, else the whole art. The
      // dying state is left as it is.
      private function flip(index:int) : void
      {
         if(index == AnimationController.CHARACTER_ANIMATION_DYING)
         {
            return;
         }
         for each(var clip:TimelineClip in this.mAnimClips[index])
         {
            if(!clip.flipPartX("Unit_Container"))
            {
               clip.scaleX = -clip.scaleX;
            }
         }
      }

      override public function setDirection(direction:int) : void
      {
         if(!this.mGpuAnimations)
         {
            super.setDirection(direction);
            return;
         }
         if(direction == this.mDirection)
         {
            return;
         }
         if(direction == AnimationController.DIR_LEFT || direction == AnimationController.DIR_RIGHT)
         {
            this.mFlipped = !this.mFlipped;
            for(var i:int = 0; i < this.mAnimNodes.length; i++)
            {
               if(this.mAnimNodes[i] != null)
               {
                  this.flip(i);
               }
            }
         }
         this.mDirection = direction;
      }

      // The shown state's bounds, from its GPU art, for the placeholder.
      private function updateAnimationPlaceholder() : void
      {
         var index:int = this.shownIndex;
         this.buildAnimation(index);
         var node:starling.display.DisplayObject = this.mAnimNodes[index];
         if(node == null)
         {
            return;
         }
         this.mPlaceholderDirty = false;
         var bounds:Rectangle = node.getBounds(node);
         var wrapper:MovieClip = mAnimations.getAnimationAt(index);
         if(this.mPlaceholder == null)
         {
            this.mPlaceholder = new Shape();
         }
         this.mPlaceholder.transform.matrix = wrapper.transform.matrix;
         this.mPlaceholder.graphics.clear();
         if(bounds.width > 0 && bounds.height > 0)
         {
            this.mPlaceholder.graphics.beginFill(0,0);
            this.mPlaceholder.graphics.drawRect(bounds.x,bounds.y,bounds.width,bounds.height);
            this.mPlaceholder.graphics.endFill();
         }
         if(this.mPlaceholder.parent != mContainer)
         {
            mContainer.addChildAt(this.mPlaceholder,0);
         }
         this.mBounds = this.mPlaceholder.getBounds(mContainer);
      }

      // Show the current state's GPU copy in the node.
      private function attachAnimation() : void
      {
         var index:int = this.shownIndex;
         this.buildAnimation(index);
         var shown:starling.display.DisplayObject = this.mAnimNodes[index];
         if(shown && shown.parent != this.mNode)
         {
            this.mNode.removeChildren();
            this.mNode.addChild(shown);
         }
      }

      // Hints, on the GPU clips (FlashView does the same on Flash art) --------

      private function forEachHintPart(callback:Function) : void
      {
         for each(var p:TimelineClip in this.currentClips())
         {
            callback(p);
         }
      }

      private static function part(clip:TimelineClip, name:String) : TimelineClip
      {
         return clip ? clip.getPartByName(name) as TimelineClip : null;
      }

      private static function innerHint(attention:TimelineClip) : TimelineClip
      {
         return part(attention,"Hint_Friendly") || part(attention,"Hint_Enemy");
      }

      // Hint timelines are cheap on the GPU; nothing to pause.
      override public function setHintsRunning(running:Boolean) : void
      {
         if(!this.mGpuAnimations)
         {
            super.setHintsRunning(running);
         }
      }

      override public function setHealthHint(text:String) : Boolean
      {
         if(!this.mGpuAnimations)
         {
            return super.setHealthHint(text);
         }
         var found:Boolean = false;
         this.forEachHintPart(function(p:TimelineClip):void
         {
            var hint:TimelineClip = part(p,HINT);
            if(hint)
            {
               found = true;
               var badge:TimelineClip = part(hint,HINT);
               if(badge)
               {
                  badge.setText("Text_Value",text);
               }
            }
            var attention:TimelineClip = part(p,HINT_ATTENTION);
            if(attention)
            {
               found = true;
               var innerBadge:TimelineClip = part(innerHint(attention),HINT);
               if(innerBadge)
               {
                  innerBadge.setText("Text_Value",text);
               }
            }
         });
         return found;
      }

      override public function setPowerHint(power:int) : Boolean
      {
         if(!this.mGpuAnimations)
         {
            return super.setPowerHint(power);
         }
         var found:Boolean = false;
         this.forEachHintPart(function(p:TimelineClip):void
         {
            var hint:TimelineClip = part(p,HINT);
            if(hint)
            {
               found = true;
               setBadge(part(hint,"Badge_Fire_Power"),power);
               hint.setText("Text_Power_Value","x" + String(power));
            }
            var attention:TimelineClip = part(p,HINT_ATTENTION);
            if(attention)
            {
               found = true;
               var inner:TimelineClip = innerHint(attention);
               if(inner)
               {
                  setBadge(part(inner,"Badge_Fire_Power"),power);
                  inner.setText("Text_Power_Value","x" + String(power));
               }
            }
         });
         return found;
      }

      private static function setBadge(badge:TimelineClip, power:int) : void
      {
         if(badge && (badge.currentFrame != power || badge.isPlaying))
         {
            badge.gotoAndStop(power);
         }
      }

      override public function showHint(attention:Boolean, shown:Boolean) : int
      {
         if(!this.mGpuAnimations)
         {
            return super.showHint(attention,shown);
         }
         var result:int = -1;
         this.forEachHintPart(function(p:TimelineClip):void
         {
            var hint:TimelineClip = part(p,attention ? HINT_ATTENTION : HINT);
            if(hint == null)
            {
               return;
            }
            if(result < 0)
            {
               result = 0;
            }
            if(hint.visible != shown)
            {
               hint.visible = shown;
               result = 1;
            }
         });
         return result;
      }

      override public function get attentionShown() : Boolean
      {
         if(!this.mGpuAnimations)
         {
            return super.attentionShown;
         }
         var shown:Boolean = false;
         this.forEachHintPart(function(p:TimelineClip):void
         {
            var hint:TimelineClip = part(p,HINT_ATTENTION);
            shown = shown || hint != null && hint.visible;
         });
         return shown;
      }

      override public function describe() : String
      {
         if(!this.mGpuAnimations)
         {
            return super.describe();
         }
         var out:String = " gpu anim=" + this.shownIndex;
         this.forEachHintPart(function(p:TimelineClip):void
         {
            for each(var name:String in [HINT,HINT_ATTENTION])
            {
               var hint:TimelineClip = part(p,name);
               if(hint)
               {
                  var badge:TimelineClip = name == HINT ? part(hint,HINT) : part(innerHint(hint),HINT);
                  out += "\n      " + name + (hint.visible ? "" : " (hidden)") + " health=" + (badge ? badge.getText("Text_Value") : "?");
               }
            }
         });
         return out;
      }

      // Every frame ------------------------------------------------------------

      // Called by GpuArt each Flash frame: copy what code set on the model,
      // then advance the timelines being shown.
      internal function tick() : void
      {
         if(this.mNode == null)
         {
            return;
         }
         var clip:TimelineClip;
         if(this.mGpuAnimations)
         {
            if(this.mPlaceholderDirty)
            {
               this.updateAnimationPlaceholder();
            }
            this.syncAnimation();
            for each(clip in this.currentClips())
            {
               clip.tick();
            }
            return;
         }
         this.syncParts();
         for each(clip in this.mClips)
         {
            clip.tick();
         }
      }

      // What game code sets on the controller's wrapper clip (offsets,
      // visibility, and the alpha EffectController fades) on the GPU art.
      private function syncAnimation() : void
      {
         var index:int = this.shownIndex;
         var wrapper:MovieClip = mAnimations.getAnimationAt(index);
         var node:starling.display.DisplayObject = this.mAnimNodes[index];
         if(wrapper == null || node == null)
         {
            return;
         }
         node.transformationMatrix = wrapper.transform.matrix;
         node.visible = wrapper.visible;
         node.alpha = wrapper.alpha;
      }

      // Parts game code got from static art: frame / play state, visibility
      // and the text of fields in them.
      private function syncParts() : void
      {
         if(this.mRoot == null)
         {
            return;
         }
         var mc:MovieClip = this.mSource as MovieClip;
         for(var name:String in this.mParts)
         {
            var model:MovieClip = mc.getChildByName(name) as MovieClip;
            var gpu:TimelineClip = this.mRoot.getPartByName(name) as TimelineClip;
            if(model == null || gpu == null)
            {
               continue;
            }
            gpu.visible = model.visible;
            if(model.isPlaying)
            {
               if(!gpu.isPlaying)
               {
                  gpu.play();
               }
            }
            else if(gpu.currentFrame != model.currentFrame || gpu.isPlaying)
            {
               gpu.gotoAndStop(model.currentFrame);
            }
            for(var i:int = 0; i < model.numChildren; i++)
            {
               var tf:TextField = model.getChildAt(i) as TextField;
               if(tf && tf.name)
               {
                  gpu.setText(tf.name,tf.text);
               }
            }
         }
      }

      // Rebuilding -------------------------------------------------------------

      // The atlas changed (new zoom): build the art again, keeping the frames
      // the clips being shown were on.
      internal function rebuild() : void
      {
         if(this.mNode == null)
         {
            // Not on screen yet, but states may already have been built (hint
            // text is set while the map loads): drop them, they are built
            // again from the new atlas when needed. Otherwise they kept the
            // old atlas's disposed textures and drew nothing.
            if(this.mGpuAnimations)
            {
               for each(var built:starling.display.DisplayObject in this.mAnimNodes)
               {
                  if(built)
                  {
                     built.dispose();
                  }
               }
               this.mAnimNodes = [];
               this.mAnimClips = [];
               this.mAnimBuiltFrom = [];
               this.mPlaceholderDirty = true;
            }
            return;
         }
         var clips:Vector.<TimelineClip> = this.mGpuAnimations ? this.currentClips() : this.mClips;
         var frames:Vector.<int> = new Vector.<int>();
         var playing:Vector.<Boolean> = new Vector.<Boolean>();
         for each(var clip:TimelineClip in clips)
         {
            frames.push(clip.currentFrame);
            playing.push(clip.isPlaying);
         }
         if(this.mGpuAnimations)
         {
            this.mNode.removeChildren();
            for each(var node:starling.display.DisplayObject in this.mAnimNodes)
            {
               if(node)
               {
                  node.dispose();
               }
            }
            this.mAnimNodes = [];
            this.mAnimClips = [];
            this.mAnimBuiltFrom = [];
            clips = this.currentClips();
            this.attachAnimation();
         }
         else
         {
            this.mNode.removeChildren(0,-1,true);
            this.buildStatic();
            clips = this.mClips;
         }
         // Same art, same order: the clips line up.
         for(var i:int = 0; i < clips.length && i < frames.length; i++)
         {
            if(playing[i])
            {
               clips[i].gotoAndPlay(frames[i]);
            }
            else
            {
               clips[i].gotoAndStop(frames[i]);
            }
         }
      }

      private function buildStatic() : void
      {
         this.mClips = new Vector.<TimelineClip>();
         this.mRoot = null;
         var art:starling.display.DisplayObject = this.convert(this.mSource,GpuArt.library);
         if(art)
         {
            this.mNode.addChild(art);
         }
         if(GpuArt.library.hasSymbol(symbolName(this.mSource)))
         {
            this.mRoot = art as TimelineClip;
         }
      }

      private function disposeNode() : void
      {
         if(this.mNode)
         {
            this.mNode.removeChildren();
            this.mNode.removeFromParent(true);
            this.mNode = null;
         }
         for each(var node:starling.display.DisplayObject in this.mAnimNodes)
         {
            if(node)
            {
               node.dispose();
            }
         }
         this.mClips = new Vector.<TimelineClip>();
         this.mRoot = null;
         this.mAnimNodes = [];
         this.mAnimClips = [];
         this.mAnimBuiltFrom = [];
      }

      override public function destroy() : void
      {
         this.clearArt();
         if(this.mGpuAnimations)
         {
            GpuArt.unregister(this);
            this.removePlaceholder();
            this.disposeNode();
            this.mGpuAnimations = false;
         }
         super.destroy();
      }

      // The placeholder ----------------------------------------------------------

      // The art's bounds, in the container's coordinates, as an invisible
      // filled shape (which counts towards the container's width / height,
      // as the art did).
      private function setPlaceholder(art:flash.display.DisplayObject) : void
      {
         if(this.mPlaceholder == null)
         {
            this.mPlaceholder = new Shape();
         }
         this.mPlaceholder.graphics.clear();
         if(art)
         {
            var bounds:Rectangle = art.getBounds(art);
            this.mPlaceholder.transform.matrix = art.transform.matrix;
            if(bounds.width > 0 && bounds.height > 0)
            {
               this.mPlaceholder.graphics.beginFill(0,0);
               this.mPlaceholder.graphics.drawRect(bounds.x,bounds.y,bounds.width,bounds.height);
               this.mPlaceholder.graphics.endFill();
            }
         }
         if(this.mPlaceholder.parent != mContainer)
         {
            mContainer.addChildAt(this.mPlaceholder,0);
         }
         this.mBounds = this.mPlaceholder.getBounds(mContainer);
      }

      private function removePlaceholder() : void
      {
         this.mBounds = null;
         if(this.mPlaceholder && this.mPlaceholder.parent)
         {
            this.mPlaceholder.parent.removeChild(this.mPlaceholder);
         }
         this.mPlaceholder = null;
      }

      // Converting ---------------------------------------------------------------

      // Flash art -> Starling: known symbols become timeline clips on the
      // frame (and play state) the Flash clip was in; plain containers become
      // sprites of their converted children. Clips made go to mClips.
      private function convert(d:flash.display.DisplayObject, library:TimelineLibrary) : starling.display.DisplayObject
      {
         var out:starling.display.DisplayObject;
         var name:String = symbolName(d);
         if(library.hasSymbol(name))
         {
            var clip:TimelineClip = TimelineClip.forSymbol(name,library,GpuArt.atlas);
            var mc:MovieClip = d as MovieClip;
            if(mc)
            {
               if(TimelinePauser.wasPlaying(mc,this.modelRootOf(mc)))
               {
                  clip.gotoAndPlay(mc.currentFrame);
               }
               else
               {
                  clip.gotoAndStop(mc.currentFrame);
               }
            }
            this.mClips.push(clip);
            out = clip;
         }
         else
         {
            var c:DisplayObjectContainer = d as DisplayObjectContainer;
            var sprite:starling.display.Sprite = new starling.display.Sprite();
            for(var i:int = 0; c && i < c.numChildren; i++)
            {
               var child:starling.display.DisplayObject = this.convert(c.getChildAt(i),library);
               if(child)
               {
                  sprite.addChild(child);
               }
            }
            out = sprite;
         }
         // The art's own transform within its parent, as in Flash.
         out.transformationMatrix = d.transform.matrix;
         out.alpha = d.alpha;
         out.visible = d.visible;
         return out;
      }

      // The model root a clip was paused under (see stopAll).
      private function modelRootOf(mc:MovieClip) : MovieClip
      {
         var root:flash.display.DisplayObject = mc;
         while(root.parent && root.parent != mContainer)
         {
            root = root.parent;
         }
         return root as MovieClip;
      }

      // Stop a model and everything in it: off the display list Flash would
      // keep playing it unseen. Records what was playing (TimelinePauser), so
      // the GPU copy can start the same way.
      private static function stopAll(mc:MovieClip) : void
      {
         if(mc)
         {
            TimelinePauser.forget(mc);
            TimelinePauser.pause(mc,99);
         }
      }

      private static function symbolName(d:flash.display.DisplayObject) : String
      {
         return getQualifiedClassName(d).replace("::",".");
      }

      // Animation files ("swf/pack/Class"): all of them known symbols.
      private static function knownSymbols(files:Array, library:TimelineLibrary) : Boolean
      {
         if(library == null || files == null || files.length == 0)
         {
            return false;
         }
         for each(var file:String in files)
         {
            if(!library.hasSymbol(file.slice(file.lastIndexOf("/") + 1)))
            {
               return false;
            }
         }
         return true;
      }

      // Art the player can draw: a known symbol, or a plain container of such.
      private static function convertible(d:flash.display.DisplayObject, library:TimelineLibrary) : Boolean
      {
         if(d == null || library == null)
         {
            return false;
         }
         if(library.hasSymbol(symbolName(d)))
         {
            return true;
         }
         var name:String = getQualifiedClassName(d);
         if(name != "flash.display::MovieClip" && name != "flash.display::Sprite")
         {
            return false;
         }
         var c:DisplayObjectContainer = d as DisplayObjectContainer;
         if(c.numChildren == 0)
         {
            return false;
         }
         for(var i:int = 0; i < c.numChildren; i++)
         {
            if(!convertible(c.getChildAt(i),library))
            {
               return false;
            }
         }
         return true;
      }
   }
}
