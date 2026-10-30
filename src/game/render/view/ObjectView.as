package game.render.view
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;

   // The art of one world object (Renderable): what the game shows for it
   // and the calls the game makes on that art. Overlays added by code (text
   // effects, loading bars, icons) and input stay on the object's container;
   // this is only the art in it.
   //
   // An object has either static art (setArt: buildings, decorations, whose
   // states are frames of one clip) or a set of animations (loadAnimations:
   // units and installations, one clip per state, flipped for direction).
   //
   // FlashView keeps today's Flash display objects; the GPU timeline player
   // will be the other implementation (see macos/RENDER_REBUILD.md).
   public interface ObjectView
   {
      // Static art -------------------------------------------------------

      // Show `art` as the object's art, replacing what was shown.
      function setArt(art:DisplayObject) : void;

      function clearArt() : void;

      // What is shown now (static art or the current animation), or null.
      // For code that only needs a display object to position things by
      // (loot rewards, effects).
      function get art() : DisplayObject;

      // State frames of static art.
      function gotoArtFrame(frame:int) : void;

      function get artFrame() : int;

      // A named clip inside the static art (e.g. a building's "Animation").
      function artPart(name:String) : MovieClip;

      // Animations ---------------------------------------------------------

      // One animation per state, from "swf/Class" names; art not loaded yet
      // appears when its file has loaded.
      function loadAnimations(files:Array) : void;

      function get hasAnimations() : Boolean;

      // Select the state to show; false if it already is, or does not exist.
      function setAnimation(index:int) : Boolean;

      function get animationIndex() : int;

      // AnimationController.DIR_*: flips the art to face left or right.
      function setDirection(direction:int) : void;

      // Put the selected animation on screen, from its first frame: stopped,
      // or else playing if `play`.
      function showAnimation(stop:Boolean, play:Boolean) : void;

      function playAnimation() : void;

      function stopAnimation() : void;

      // Label of the frame the current animation (or a clip in it) is on.
      function get frameLabel() : String;

      // Move / hide the current animation within the object (installations
      // offset their wreck art; see EnemyInstallationObject).
      function moveAnimationBy(dx:Number, dy:Number) : void;

      function set animationVisible(value:Boolean) : void;

      function setAnimationSize(width:int, height:int) : void;

      // The current animation's Flash clip, for the effects that animate the
      // art itself (EffectController fade / hit). Flash-only: to be replaced
      // by view-side effects when installations move off Flash (M4).
      function get animationClip() : MovieClip;

      // Hints (badges in unit art: health, power, attention) -----------------

      // Pause hint timelines while the object cannot be seen.
      function setHintsRunning(running:Boolean) : void;

      // Health text on every hint; false if the art has no hint yet.
      function setHealthHint(text:String) : Boolean;

      // Power badge and text on every hint; false if there is none yet.
      function setPowerHint(power:int) : Boolean;

      // Show / hide the attention hint (attention) or the normal one: -1 if
      // the art has none, 1 if that changed its visibility, 0 if not.
      function showHint(attention:Boolean, shown:Boolean) : int;

      // Whether an attention hint is showing.
      function get attentionShown() : Boolean;

      // Development aid: the art's state for the unit inspector (hint text
      // fields and power badges, with their visibility).
      function describe() : String;

      function destroy() : void;
   }
}
