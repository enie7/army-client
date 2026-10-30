package
{
   import flash.display.MovieClip;
   import flash.text.TextField;
   import game.render.art.StopWhenDetached;

   // Replaces the art's class of this name (first definition wins): the
   // same symbol, plus StopWhenDetached.
   public dynamic class hint_health_enemy extends MovieClip
   {
      public var Hint_Health_Friendly:MovieClip;

      public var Text_Power_Value:TextField;

      public var Badge_Fire_Power:MovieClip;

      public var Hint_Health_Enemy:MovieClip;

      public function hint_health_enemy()
      {
         super();
         StopWhenDetached.watch(this);
      }
   }
}
