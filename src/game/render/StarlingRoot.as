package game.render
{
   import starling.display.Sprite;

   // Root of the Starling (Stage3D) scene: the ground, the world objects,
   // fog, then the world-space effects layer (clouds, projectiles, icons), in
   // the same order as the Flash layers they mirror. The Flash HUD is
   // composited on top of all of it.
   public class StarlingRoot extends Sprite
   {
      public var ground:Sprite = new Sprite();

      public var world:Sprite = new Sprite();

      public var fog:Sprite = new Sprite();

      public var effects:Sprite = new Sprite();

      public function StarlingRoot()
      {
         super();
         addChild(this.ground);
         addChild(this.world);
         addChild(this.fog);
         addChild(this.effects);
      }
   }
}
