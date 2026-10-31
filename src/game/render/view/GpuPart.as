package game.render.view
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import game.render.timeline.TimelineClip;
   import starling.display.DisplayObject;

   // Stand-in for a named child of a GpuClip (as getChildByName gives it), for
   // code that shows, hides or retexts parts of art: `visible` and child text
   // go to the GPU clip's part of that name. The timeline may place a part
   // anew (e.g. when it loops), so the state is applied again every frame.
   public dynamic class GpuPart extends MovieClip
   {
      private var mOwner:GpuClip;

      private var mPath:Array;

      private var mShown:Boolean = true;

      private var mShownSet:Boolean = false;

      private var mChildren:Object = {};

      public function GpuPart(owner:GpuClip, path:Array)
      {
         super();
         this.mOwner = owner;
         this.mPath = path;
         this.mouseEnabled = false;
         this.mouseChildren = false;
      }

      override public function get visible() : Boolean
      {
         return this.mShown;
      }

      override public function set visible(value:Boolean) : void
      {
         this.mShown = value;
         this.mShownSet = true;
         this.apply();
      }

      // A stand-in for the part's child: text for a dynamic text field, a
      // part otherwise; null if the part has no child of that name now.
      override public function getChildByName(name:String) : flash.display.DisplayObject
      {
         var child:flash.display.DisplayObject = this.mChildren[name];
         if(child)
         {
            return child;
         }
         var clip:TimelineClip = this.mOwner.resolve(this.mPath) as TimelineClip;
         if(clip == null)
         {
            return null;
         }
         if(clip.getText(name) != null)
         {
            child = new GpuText(this.mOwner,this.mPath,name,clip.getText(name));
         }
         else if(clip.getPartByName(name))
         {
            child = new GpuPart(this.mOwner,this.mPath.concat(name));
         }
         if(child)
         {
            this.mChildren[name] = child;
         }
         return child;
      }

      internal function apply() : void
      {
         var node:starling.display.DisplayObject = this.mOwner.resolve(this.mPath);
         if(node && this.mShownSet)
         {
            node.visible = this.mShown;
         }
         for each(var child:Object in this.mChildren)
         {
            if(child is GpuPart)
            {
               GpuPart(child).apply();
            }
            else
            {
               GpuText(child).apply();
            }
         }
      }
   }
}
