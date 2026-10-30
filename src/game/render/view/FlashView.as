package game.render.view
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.text.TextField;
   import flash.utils.getQualifiedClassName;
   import game.characters.AnimationController;
   import game.isometric.elements.Renderable;
   import game.utils.TimelinePauser;

   // ObjectView on the original Flash art: the art is child 0 of the
   // object's container, and animations come from an AnimationController.
   // The code here is what Renderable and its subclasses did on their art
   // directly before ObjectView existed.
   public class FlashView implements ObjectView
   {
      private static const HINT:String = "Hint_Health_Friendly";

      private static const HINT_ATTENTION:String = "Hint_Health_Friendly_Attention";

      private var mRenderable:Renderable;

      private var mContainer:DisplayObjectContainer;

      private var mAnimations:AnimationController;

      public function FlashView(renderable:Renderable, container:DisplayObjectContainer)
      {
         super();
         this.mRenderable = renderable;
         this.mContainer = container;
      }

      // Static art ---------------------------------------------------------

      public function setArt(art:DisplayObject) : void
      {
         this.clearArt();
         this.mContainer.addChildAt(art,0);
      }

      public function clearArt() : void
      {
         if(this.mContainer.numChildren > 0)
         {
            this.mContainer.removeChildAt(0);
         }
      }

      public function get art() : DisplayObject
      {
         return this.mContainer.numChildren > 0 ? this.mContainer.getChildAt(0) : null;
      }

      public function gotoArtFrame(frame:int) : void
      {
         var mc:MovieClip = this.art as MovieClip;
         if(mc)
         {
            mc.gotoAndStop(frame);
         }
      }

      public function get artFrame() : int
      {
         var mc:MovieClip = this.art as MovieClip;
         return mc ? mc.currentFrame : 0;
      }

      public function artPart(name:String) : MovieClip
      {
         var mc:MovieClip = this.art as MovieClip;
         return mc ? mc.getChildByName(name) as MovieClip : null;
      }

      // Animations -----------------------------------------------------------

      public function loadAnimations(files:Array) : void
      {
         this.mAnimations = new AnimationController(this.mRenderable);
         this.mAnimations.loadAnimations(files);
      }

      public function get hasAnimations() : Boolean
      {
         return this.mAnimations != null;
      }

      public function setAnimation(index:int) : Boolean
      {
         return this.mAnimations.setAnimation(index);
      }

      public function get animationIndex() : int
      {
         return this.mAnimations.getCurrentAnimationIndex();
      }

      public function setDirection(direction:int) : void
      {
         this.mAnimations.setDirection(direction);
      }

      public function showAnimation(stop:Boolean, play:Boolean) : void
      {
         var next:MovieClip = this.mAnimations.getAnimation();
         if(this.mContainer.numChildren > 0)
         {
            // The outgoing state clip leaves the display list but would keep
            // playing (and rebuilding its looping hints) unseen; pause it.
            var previous:MovieClip = this.mContainer.removeChildAt(0) as MovieClip;
            if(previous != null && previous != next)
            {
               TimelinePauser.pause(previous);
            }
         }
         TimelinePauser.resume(next);
         this.mContainer.addChildAt(next,0);
         if(stop)
         {
            this.mAnimations.stopCurrentAnimation();
         }
         else if(play)
         {
            this.mAnimations.playCurrentAnimation();
         }
      }

      public function playAnimation() : void
      {
         this.mAnimations.playCurrentAnimation();
      }

      public function stopAnimation() : void
      {
         this.mAnimations.stopCurrentAnimation();
      }

      public function get frameLabel() : String
      {
         return this.mAnimations.getCurrentAnimationFrameLabel();
      }

      public function moveAnimationBy(dx:Number, dy:Number) : void
      {
         var clip:MovieClip = this.mAnimations.getCurrentAnimation();
         clip.x += dx;
         clip.y += dy;
      }

      public function set animationVisible(value:Boolean) : void
      {
         this.mAnimations.getAnimation().visible = value;
      }

      public function setAnimationSize(width:int, height:int) : void
      {
         this.mAnimations.setSize(width,height);
      }

      public function get animationClip() : MovieClip
      {
         return this.mAnimations.getAnimation();
      }

      // Hints ------------------------------------------------------------------
      //
      // A unit's state clip holds parts; a part may hold the normal hint and
      // the attention hint. The attention hint holds the badge again, in an
      // inner clip that friendly art names "Hint_Friendly" and enemy art
      // "Hint_Enemy".

      // The parts of the current animation, in display order.
      private function forEachPart(callback:Function) : void
      {
         if(this.mAnimations == null)
         {
            return;
         }
         var clip:MovieClip = this.mAnimations.getCurrentAnimation();
         for(var i:int = 0; i < clip.numChildren; i++)
         {
            var part:MovieClip = clip.getChildAt(i) as MovieClip;
            if(part != null)
            {
               callback(part);
            }
         }
      }

      private static function innerHint(attention:MovieClip) : MovieClip
      {
         return (attention.getChildByName("Hint_Friendly") || attention.getChildByName("Hint_Enemy")) as MovieClip;
      }

      public function setHintsRunning(running:Boolean) : void
      {
         this.forEachPart(function(part:MovieClip):void
         {
            for each(var name:String in [HINT,HINT_ATTENTION])
            {
               var hint:MovieClip = part.getChildByName(name) as MovieClip;
               if(hint)
               {
                  if(running)
                  {
                     TimelinePauser.resume(hint);
                  }
                  else
                  {
                     TimelinePauser.pause(hint);
                  }
               }
            }
         });
      }

      // Hidden hints are set too: showHint swaps which one is visible later.
      public function setHealthHint(text:String) : Boolean
      {
         var found:Boolean = false;
         this.forEachPart(function(part:MovieClip):void
         {
            var hint:MovieClip = part.getChildByName(HINT) as MovieClip;
            if(hint)
            {
               found = true;
               var badge:MovieClip = hint.getChildByName(HINT) as MovieClip;
               setText(badge.getChildByName("Text_Value") as TextField,text);
            }
            var attention:MovieClip = part.getChildByName(HINT_ATTENTION) as MovieClip;
            if(attention)
            {
               found = true;
               var inner:MovieClip = innerHint(attention);
               if(inner)
               {
                  var innerBadge:MovieClip = inner.getChildByName(HINT) as MovieClip;
                  if(innerBadge)
                  {
                     setText(innerBadge.getChildByName("Text_Value") as TextField,text);
                  }
               }
            }
         });
         return found;
      }

      public function setPowerHint(power:int) : Boolean
      {
         var found:Boolean = false;
         this.forEachPart(function(part:MovieClip):void
         {
            var hint:MovieClip = part.getChildByName(HINT) as MovieClip;
            if(hint)
            {
               found = true;
               setBadge(hint.getChildByName("Badge_Fire_Power") as MovieClip,power);
               setText(hint.getChildByName("Text_Power_Value") as TextField,"x" + String(power));
            }
            var attention:MovieClip = part.getChildByName(HINT_ATTENTION) as MovieClip;
            if(attention)
            {
               found = true;
               var inner:MovieClip = innerHint(attention);
               if(inner)
               {
                  setBadge(inner.getChildByName("Badge_Fire_Power") as MovieClip,power);
                  setText(inner.getChildByName("Text_Power_Value") as TextField,"x" + String(power));
               }
            }
         });
         return found;
      }

      // A hidden attention hint would keep looping (and rebuilding its
      // children) unseen, so it is paused while hidden.
      public function showHint(attention:Boolean, shown:Boolean) : int
      {
         var result:int = -1;
         this.forEachPart(function(part:MovieClip):void
         {
            var hint:MovieClip = part.getChildByName(attention ? HINT_ATTENTION : HINT) as MovieClip;
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
               if(attention)
               {
                  if(shown)
                  {
                     TimelinePauser.resume(hint);
                  }
                  else
                  {
                     TimelinePauser.pause(hint);
                  }
               }
            }
         });
         return result;
      }

      public function get attentionShown() : Boolean
      {
         var shown:Boolean = false;
         this.forEachPart(function(part:MovieClip):void
         {
            var hint:MovieClip = part.getChildByName(HINT_ATTENTION) as MovieClip;
            shown = shown || hint != null && hint.visible;
         });
         return shown;
      }

      // Writes only when the value differs: hints are set every update while
      // a warning is shown, and unchanged fields should stay untouched.
      private static function setText(field:TextField, value:String) : void
      {
         if(field && field.text != value)
         {
            field.text = value;
         }
      }

      private static function setBadge(badge:MovieClip, power:int) : void
      {
         if(badge && (badge.currentFrame != power || badge.isPlaying))
         {
            badge.gotoAndStop(power);
         }
      }

      public function describe() : String
      {
         if(this.mAnimations == null)
         {
            return " (no animations)";
         }
         var clip:MovieClip = this.mAnimations.getCurrentAnimation();
         var out:String = " anim=" + getQualifiedClassName(clip) + " children=" + clip.numChildren;
         var isShown:Function = function(o:DisplayObject):Boolean
         {
            for(var n:DisplayObject = o; n && n != clip; n = n.parent)
            {
               if(!n.visible)
               {
                  return false;
               }
            }
            return true;
         };
         var walk:Function = function(o:DisplayObject, path:String):void
         {
            var tf:TextField = o as TextField;
            if(tf && (tf.name == "Text_Value" || tf.name == "Text_Power_Value"))
            {
               out += "\n      " + path + " = \"" + tf.text + "\"" + (isShown(tf) ? "" : " (hidden)");
            }
            var mc:MovieClip = o as MovieClip;
            if(mc && mc.name == "Badge_Fire_Power")
            {
               out += "\n      " + path + " frame " + mc.currentFrame + "/" + mc.totalFrames + (isShown(mc) ? "" : " (hidden)");
            }
            var c:DisplayObjectContainer = o as DisplayObjectContainer;
            if(c)
            {
               for(var i:int = 0; i < c.numChildren; i++)
               {
                  var child:DisplayObject = c.getChildAt(i);
                  if(child)
                  {
                     walk(child,path + "/" + child.name);
                  }
               }
            }
         };
         walk(clip,"");
         return out;
      }

      public function destroy() : void
      {
         if(this.mAnimations)
         {
            this.mAnimations.destroy();
            this.mAnimations = null;
         }
      }
   }
}
