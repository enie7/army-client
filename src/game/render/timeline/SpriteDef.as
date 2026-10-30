package game.render.timeline
{
   // One sprite's timeline: per frame, the placement operations that frame
   // applies to the display list (as in the SWF), and the frame labels.
   public class SpriteDef
   {
      public var id:int;

      public var totalFrames:int;

      // ops[frame - 1]: the PlaceOps of that frame, in SWF order.
      public var ops:Vector.<Vector.<PlaceOp>>;

      // label -> frame, and frame -> label (first label on a frame).
      public var labels:Object = {};

      public var frameLabels:Vector.<String>;

      // stops[frame]: that frame's script calls stop() (the only frame
      // script the world art uses).
      public var stops:Vector.<Boolean>;

      public function SpriteDef(id:int, raw:Object)
      {
         super();
         this.id = id;
         var frames:Array = raw.frames;
         // An empty sprite still has one (empty) frame in Flash.
         if(frames.length == 0)
         {
            frames = [[]];
         }
         this.totalFrames = frames.length;
         this.ops = new Vector.<Vector.<PlaceOp>>(this.totalFrames,true);
         this.frameLabels = new Vector.<String>(this.totalFrames + 1,true);
         for(var f:int = 0; f < this.totalFrames; f++)
         {
            var list:Array = frames[f];
            var ops:Vector.<PlaceOp> = new Vector.<PlaceOp>(list.length,true);
            for(var i:int = 0; i < list.length; i++)
            {
               ops[i] = new PlaceOp(list[i]);
            }
            this.ops[f] = ops;
         }
         this.stops = new Vector.<Boolean>(this.totalFrames + 1,true);
         for each(var stop:int in raw.stops)
         {
            if(stop >= 1 && stop <= this.totalFrames)
            {
               this.stops[stop] = true;
            }
         }
         for(var label:String in raw.labels)
         {
            var frame:int = raw.labels[label];
            this.labels[label] = frame;
            if(frame <= this.totalFrames && this.frameLabels[frame] == null)
            {
               this.frameLabels[frame] = label;
            }
         }
      }
   }
}
