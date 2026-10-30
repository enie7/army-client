package
{
   import flash.display.MovieClip;
   import game.render.art.StopWhenDetached;

   // Replaces the art's class of this name (first definition wins): the
   // same symbol, plus StopWhenDetached.
   public dynamic class hint_health_friendly_attention extends MovieClip
   {
      public var Hint_Friendly:hint_health_friendly;

      public function hint_health_friendly_attention()
      {
         super();
         StopWhenDetached.watch(this);
      }
   }
}
