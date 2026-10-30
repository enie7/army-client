package game.isometric.elements
{
   import game.isometric.IsometricScene;
   import game.isometric.boundingElements.BoundingElement;
   import game.items.MapItem;
   import game.render.view.ObjectView;
   import game.render.view.StarlingView;
   
   public class WorldObject extends Renderable
   {
      // World objects' art is drawn by the GPU timeline player; StarlingView
      // falls back to Flash for art it cannot draw.
      override protected function createView() : ObjectView
      {
         return new StarlingView(this,mContainer);
      }

       
      
      public var mBoundingElement:BoundingElement;
      
      public function WorldObject(param1:int, param2:IsometricScene, param3:MapItem, param4:String = null)
      {
         super(param1,param2,param3,param4);
      }
   }
}
