package
{
   import flash.display.MovieClip;
   import game.render.art.StopWhenDetached;

   // Replaces the art's class of this name (first definition wins): the
   // same symbol, plus StopWhenDetached.
   public dynamic class hint_health_enemy_attention extends MovieClip
   {
      public var Hint_Friendly:hint_health_enemy;

      public var Hint_Enemy:hint_health_enemy;

      public function hint_health_enemy_attention()
      {
         super();
         StopWhenDetached.watch(this);
      }
   }
}
