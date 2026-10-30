package game.render.timeline
{
   import starling.rendering.MeshEffect;
   import starling.styles.MeshStyle;

   // Style for leaf images used as masks (SWF clip depths). Stage3D stencil
   // masks take a mesh's geometry, so a textured quad would mask its whole
   // rectangle; this style discards the texels the shape doesn't cover, so
   // only the shape itself writes the stencil.
   public class MaskStyle extends MeshStyle
   {
      public function MaskStyle()
      {
         super();
      }

      override public function createEffect() : MeshEffect
      {
         return new MaskEffect();
      }
   }
}

import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import starling.rendering.MeshEffect;
import starling.rendering.Program;

class MaskEffect extends MeshEffect
{
   private static const THRESHOLD:Vector.<Number> = new <Number>[0.004,0,0,0];

   public function MaskEffect()
   {
      super();
   }

   override protected function createProgram() : Program
   {
      if(texture == null)
      {
         return super.createProgram();
      }
      var vertexShader:String = "m44 op, va0, vc0 \n" + "mov v0, va1      \n" + "mul v1, va2, vc4 \n";
      var fragmentShader:String = tex("ft0","v0",0,texture) + "sub ft1, ft0.wwww, fc0.xxxx \n" + "kil ft1.x \n" + "mul oc, ft0, v1 \n";
      return Program.fromSource(vertexShader,fragmentShader);
   }

   override protected function beforeDraw(context:Context3D) : void
   {
      super.beforeDraw(context);
      if(texture)
      {
         context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,0,THRESHOLD);
      }
   }
}
