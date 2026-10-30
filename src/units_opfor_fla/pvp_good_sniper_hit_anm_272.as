package units_opfor_fla
{
   import flash.display.MovieClip;
   
   // The FLA's PvP sniper sprites are linked to pvp_good_sniper_*_anm_N, but the
   // published code only defines the good_sniper_*_anm_N originals, so the
   // player logged #1065 and fire/hit looped instead of stopping on the last frame.
   public dynamic class pvp_good_sniper_hit_anm_272 extends MovieClip
   {
      
      public function pvp_good_sniper_hit_anm_272()
      {
         super();
         addFrameScript(34,this.frame35);
      }
      
      internal function frame35() : *
      {
         stop();
      }
   }
}
