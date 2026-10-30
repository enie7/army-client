package game.render.timeline
{
   import flash.geom.Matrix;

   // One PlaceObject / RemoveObject from a sprite's timeline. Fields mirror the
   // SWF: only those present in the tag are set (has* flags).
   public class PlaceOp
   {
      public var depth:int;

      public var remove:Boolean;

      // PlaceObject "move" flag: modify the object already at this depth
      // (and replace its character if character is set too).
      public var move:Boolean;

      public var character:int = -1;

      public var matrix:Matrix;

      // [rm, gm, bm, am, ro, go, bo, ao]: multipliers as fractions, offsets 0-255.
      public var color:Array;

      public var ratio:int = -1;

      public var name:String;

      public var clipDepth:int = 0;

      public var filters:Array;

      public var blendMode:String;

      public var hasVisible:Boolean;

      public var visible:Boolean = true;

      public function PlaceOp(raw:Object)
      {
         super();
         this.depth = raw.d;
         this.remove = raw.rm == 1;
         this.move = raw.move == 1;
         if(raw.c !== undefined)
         {
            this.character = raw.c;
         }
         if(raw.m !== undefined)
         {
            var m:Array = raw.m;
            this.matrix = new Matrix(m[0],m[1],m[2],m[3],m[4],m[5]);
         }
         if(raw.ct !== undefined)
         {
            this.color = raw.ct;
         }
         if(raw.r !== undefined)
         {
            this.ratio = raw.r;
         }
         if(raw.n !== undefined)
         {
            this.name = raw.n;
         }
         if(raw.clip !== undefined)
         {
            this.clipDepth = raw.clip;
         }
         if(raw.f !== undefined)
         {
            this.filters = raw.f;
         }
         if(raw.b !== undefined)
         {
            this.blendMode = raw.b;
         }
         if(raw.v !== undefined)
         {
            this.hasVisible = true;
            this.visible = raw.v != 0;
         }
      }
   }
}
