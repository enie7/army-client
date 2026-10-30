package game.render.timeline
{
   import starling.display.Mesh;
   import starling.rendering.MeshEffect;
   import starling.rendering.VertexDataFormat;
   import starling.styles.MeshStyle;

   // Flash colour transforms on leaf images: the vertex colour carries the
   // multipliers (as for any Starling mesh) and an extra vertex attribute the
   // additive offsets, so differently transformed leaves still batch.
   //
   // As in Flash, the transform applies to unpremultiplied colour:
   // rgb' = rgb * multiplier + offset, then the texel's coverage is applied.
   // Alpha offsets are not supported (none of the world art needs them).
   public class ColorTransformStyle extends MeshStyle
   {
      public static const VERTEX_FORMAT:VertexDataFormat = MeshStyle.VERTEX_FORMAT.extend("offset:float4");

      private var mOffsetR:Number = 0;

      private var mOffsetG:Number = 0;

      private var mOffsetB:Number = 0;

      public function ColorTransformStyle()
      {
         super();
      }

      // Offsets in colour units (0..1 = 0..255).
      public function setOffsets(r:Number, g:Number, b:Number) : void
      {
         if(r == this.mOffsetR && g == this.mOffsetG && b == this.mOffsetB)
         {
            return;
         }
         this.mOffsetR = r;
         this.mOffsetG = g;
         this.mOffsetB = b;
         this.writeOffsets();
      }

      private function writeOffsets() : void
      {
         if(vertexData == null)
         {
            return;
         }
         for(var i:int = vertexData.numVertices - 1; i >= 0; i--)
         {
            vertexData.setPoint4D(i,"offset",this.mOffsetR,this.mOffsetG,this.mOffsetB,0);
         }
         setVertexDataChanged();
      }

      override protected function onTargetAssigned(target:Mesh) : void
      {
         this.writeOffsets();
      }

      override public function copyFrom(meshStyle:MeshStyle) : void
      {
         var other:ColorTransformStyle = meshStyle as ColorTransformStyle;
         if(other)
         {
            this.mOffsetR = other.mOffsetR;
            this.mOffsetG = other.mOffsetG;
            this.mOffsetB = other.mOffsetB;
         }
         super.copyFrom(meshStyle);
      }

      override public function createEffect() : MeshEffect
      {
         return new ColorTransformEffect();
      }

      override public function get vertexFormat() : VertexDataFormat
      {
         return VERTEX_FORMAT;
      }
   }
}

import flash.display3D.Context3D;
import game.render.timeline.ColorTransformStyle;
import starling.rendering.MeshEffect;
import starling.rendering.Program;
import starling.rendering.VertexDataFormat;

class ColorTransformEffect extends MeshEffect
{
   public function ColorTransformEffect()
   {
      super();
   }

   override protected function createProgram() : Program
   {
      if(texture == null)
      {
         return super.createProgram();
      }
      var vertexShader:String = "m44 op, va0, vc0 \n" + // position to clip space
         "mov v0, va1 \n" + // texture coordinates
         "mul v1, va2, vc4 \n" + // premultiplied multipliers x alpha
         "mov v2, va3 \n"; // offsets
      var fragmentShader:String = tex("ft0","v0",0,texture) + //
         "mul ft1, ft0, v1 \n" + // rgb * multiplier (premultiplied), coverage * alpha
         "mul ft2, v2, ft1.wwww \n" + // offset, premultiplied by the result's alpha
         "add ft1.xyz, ft1.xyz, ft2.xyz \n" + //
         "sat ft1, ft1 \n" + //
         "min ft1.xyz, ft1.xyz, ft1.www \n" + // keep it a valid premultiplied colour
         "mov oc, ft1 \n";
      return Program.fromSource(vertexShader,fragmentShader);
   }

   override protected function beforeDraw(context:Context3D) : void
   {
      super.beforeDraw(context);
      // The shader always reads colours, even where MeshEffect would skip them.
      vertexFormat.setVertexBufferAt(2,vertexBuffer,"color");
      vertexFormat.setVertexBufferAt(3,vertexBuffer,"offset");
   }

   override protected function afterDraw(context:Context3D) : void
   {
      context.setVertexBufferAt(3,null);
      super.afterDraw(context);
   }

   override public function get vertexFormat() : VertexDataFormat
   {
      return ColorTransformStyle.VERTEX_FORMAT;
   }
}
