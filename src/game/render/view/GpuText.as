package game.render.view
{
   import flash.text.TextField;
   import game.render.timeline.TimelineClip;

   // Stand-in for a dynamic text field inside a GpuClip's part (see GpuPart):
   // its text is drawn by the GPU clip.
   public class GpuText extends TextField
   {
      private var mOwner:GpuClip;

      private var mPath:Array;

      private var mName:String;

      private var mValue:String;

      private var mSet:Boolean = false;

      public function GpuText(owner:GpuClip, path:Array, name:String, authored:String)
      {
         super();
         this.mOwner = owner;
         this.mPath = path;
         this.mName = name;
         this.mValue = authored;
         this.mouseEnabled = false;
      }

      override public function get text() : String
      {
         return this.mValue;
      }

      override public function set text(value:String) : void
      {
         this.mValue = value;
         this.mSet = true;
         this.apply();
      }

      internal function apply() : void
      {
         var clip:TimelineClip = this.mSet ? this.mOwner.resolve(this.mPath) as TimelineClip : null;
         if(clip)
         {
            clip.setText(this.mName,this.mValue);
         }
      }
   }
}
