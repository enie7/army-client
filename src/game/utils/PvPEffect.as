package game.utils
{
   import com.dchoc.graphics.DCResourceManager;
   import flash.display.MovieClip;
   
   public class PvPEffect extends Effect
   {
      
      public var mEffectClipName:String;
      
      public function PvPEffect()
      {
         super();
      }
      
      override public function start(param1:MovieClip, param2:int, param3:String = "") : void
      {
         this.mTimer = 0;
         this.mMC = param1;
         this.mType = param2;
         this.mEffectClipName = param3;
         this.setEffectSpecificValues();
      }
      
      override public function update(param1:int) : Boolean
      {
         if(!mMC)
         {
            return true;
         }
         var _loc2_:String = mMC.currentFrameLabel;
         if(_loc2_ == "end")
         {
            mMC.gotoAndStop(1);
            mMC.visible = false;
            if(mMC.parent)
            {
               mMC.parent.removeChild(mMC);
            }
            mMC = null;
            return true;
         }
         return false;
      }
      
      override public function setEffectSpecificValues() : void
      {
         var _loc1_:Class = null;
         var _loc2_:DCResourceManager = DCResourceManager.getInstance();
         if(this.mEffectClipName != "")
         {
            _loc1_ = _loc2_.getSWFClass("swf/pvp_effects",this.mEffectClipName);
            if(_loc1_ != null)
            {
               mMC = new _loc1_();
               mMC.gotoAndPlay(1);
            }
         }
      }
   }
}

