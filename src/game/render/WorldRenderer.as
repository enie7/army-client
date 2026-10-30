package game.render
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.InteractiveObject;
   import flash.display.Sprite;
   import flash.display.Stage;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import game.isometric.IsometricScene;
   import game.states.GameState;
   import game.utils.FrameProfiler;
   import starling.core.Starling;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.textures.Texture;

   // Draws the game world on the GPU (Stage3D, via Starling).
   //
   // The Flash display list stays the source of truth: the game keeps
   // creating, animating, sorting and positioning its world MovieClips
   // exactly as before. The world layers (ground bitmap, scene container,
   // fog bitmap, world-space effects layer) are hidden from the Flash
   // renderer and mirrored each frame into Starling, where each object's
   // current look is a cached texture. Flash used to repaint the whole window
   // every frame because ~130 small animations were spread across it; now it
   // only draws the HUD, on top of the GPU-drawn world.
   //
   // Hidden objects get no mouse events, so a transparent input layer in the
   // world's place picks the object Flash would have targeted (the topmost,
   // deepest mouse-enabled one under the cursor, effects layer first) and
   // dispatches the event there. The floor covers the whole map, so clicks on
   // nothing in particular reach its FloorClicked handler as before.
   public class WorldRenderer
   {
      // Set from the --cpu-render launch argument to compare against, or as a fallback.
      public static var disabled:Boolean = false;

      // Experimental: take the hidden world containers off the display list
      // altogether, so the runtime's per-frame walk over every display object
      // skips them (timelines and ENTER_FRAME keep running off-stage).
      public static var offstage:Boolean = false;

      private var mOffstage:Boolean = false;

      private static const DEG_TO_RAD:Number = Math.PI / 180;

      private static var sInstance:WorldRenderer;

      private var mStage:Stage;

      private var mStarling:Starling;

      private var mRoot:StarlingRoot;

      private var mCache:SnapshotCache;

      private var mWorldImages:Vector.<Image> = new Vector.<Image>();

      private var mEffectImages:Vector.<Image> = new Vector.<Image>();

      private var mInput:flash.display.Sprite = new flash.display.Sprite();

      private var mScene:IsometricScene;

      private var mGround:GroundChunks;

      private var mGroundDrawn:int = 0;

      private var mScale:Number = NaN;

      private var mFailed:Boolean = false;

      private var mPoint:Point = new Point();

      public function WorldRenderer(stage:Stage)
      {
         super();
         this.mStage = stage;
         this.mCache = new SnapshotCache(512);
         this.mStarling = new Starling(StarlingRoot,stage,new Rectangle(0,0,stage.stageWidth,stage.stageHeight),null,"auto","auto");
         this.mStarling.addEventListener(starling.events.Event.ROOT_CREATED,this.onRootCreated);
         this.mStarling.addEventListener(starling.events.Event.FATAL_ERROR,this.onFatalError);
         this.mStarling.antiAliasing = 0;
         stage.addEventListener(flash.events.Event.RESIZE,this.onResize);
         this.mInput.name = "WorldInput";
         this.mInput.addEventListener(MouseEvent.MOUSE_DOWN,this.forwardMouse);
         this.mInput.addEventListener(MouseEvent.MOUSE_MOVE,this.forwardMouse);
         this.mInput.addEventListener(MouseEvent.MOUSE_UP,this.forwardMouse);
         this.mInput.addEventListener(MouseEvent.CLICK,this.forwardMouse);
         this.drawInputArea();
      }

      public static function init(stage:Stage) : void
      {
         if(!disabled && sInstance == null && stage != null)
         {
            sInstance = new WorldRenderer(stage);
         }
      }

      // Call once per frame, after the game logic has run.
      public static function update() : void
      {
         if(sInstance != null)
         {
            sInstance.render();
         }
      }

      public static function get active() : Boolean
      {
         return sInstance != null && sInstance.mRoot != null && !sInstance.mFailed;
      }

      // Cache activity since the last call, for the profiler.
      public static function takeStats() : String
      {
         if(!active)
         {
            return "gpu off";
         }
         var c:SnapshotCache = sInstance.mCache;
         var line:String = "gpu " + c.hits + " cached / " + c.misses + " rasterised, " + c.usedMegabytes.toFixed(0) + "MB, ground chunks drawn " + sInstance.mGroundDrawn;
         sInstance.mGroundDrawn = 0;
         c.hits = 0;
         c.misses = 0;
         return line;
      }

      private function onRootCreated(event:starling.events.Event) : void
      {
         this.mRoot = this.mStarling.root as StarlingRoot;
         this.mRoot.touchable = false;
         this.mGround = new GroundChunks(this.mRoot.ground,this.mRoot.fog);
      }

      private function onFatalError(event:starling.events.Event) : void
      {
         // No usable Stage3D: give the world back to the Flash renderer.
         this.mFailed = true;
         this.detach();
      }

      private function onResize(event:flash.events.Event) : void
      {
         var r:Rectangle = new Rectangle(0,0,this.mStage.stageWidth,this.mStage.stageHeight);
         this.mStarling.viewPort = r;
         this.mStarling.stage.stageWidth = r.width;
         this.mStarling.stage.stageHeight = r.height;
         this.drawInputArea();
      }

      private function drawInputArea() : void
      {
         this.mInput.graphics.clear();
         this.mInput.graphics.beginFill(0,0);
         this.mInput.graphics.drawRect(0,0,this.mStage.stageWidth,this.mStage.stageHeight);
         this.mInput.graphics.endFill();
      }

      private function render() : void
      {
         if(this.mRoot == null || this.mFailed)
         {
            return;
         }
         var game:GameState = GameState.mInstance;
         var scene:IsometricScene = game ? game.mScene : null;
         if(scene != this.mScene)
         {
            this.detach();
            this.mScene = scene;
         }
         if(scene == null || scene.mContainer.parent == null && !this.mOffstage)
         {
            this.hideWorld();
            this.mStarling.nextFrame();
            return;
         }
         this.mCache.nextFrame();
         this.attach(game,scene);
         FrameProfiler.begin("gpu.world");
         this.mirrorWorld(scene);
         FrameProfiler.end("gpu.world");
         FrameProfiler.begin("gpu.ground");
         var tiles:Object = scene.mTilemapGraphic;
         this.mGround.update(tiles,scene.mContainer.x,scene.mContainer.y,tiles.mFieldBmp ? tiles.mFieldBmp.x : 0,tiles.mFieldBmp ? tiles.mFieldBmp.y : 0,this.mStage.stageWidth,this.mStage.stageHeight,scene.mContainer.scaleX);
         this.mGroundDrawn += this.mGround.drawn;
         FrameProfiler.end("gpu.ground");
         FrameProfiler.begin("gpu.present");
         this.mStarling.nextFrame();
         FrameProfiler.end("gpu.present");
      }

      // Hide the Flash world layers and put the input layer where they were.
      private function attach(game:GameState, scene:IsometricScene) : void
      {
         scene.mContainer.visible = false;
         scene.mSceneHud.visible = false;
         var tiles:Object = scene.mTilemapGraphic;
         tiles.mGpuGround = true;
         if(tiles.mFieldBmp)
         {
            tiles.mFieldBmp.visible = false;
         }
         if(tiles.mFogBmp)
         {
            tiles.mFogBmp.visible = false;
         }
         var root:flash.display.Sprite = game.mRootNode;
         if(offstage != this.mOffstage)
         {
            this.setOffstage(root,scene,offstage);
         }
         if(this.mOffstage)
         {
            if(this.mInput.parent != root || root.getChildIndex(this.mInput) != 0)
            {
               root.addChildAt(this.mInput,0);
            }
            return;
         }
         // Keep the input layer directly above the world container (the game
         // re-adds its layers at times), below the HUD.
         if(this.mInput.parent != root)
         {
            root.addChildAt(this.mInput,root.getChildIndex(scene.mContainer) + 1);
         }
         else if(root.getChildIndex(this.mInput) != root.getChildIndex(scene.mContainer) + 1)
         {
            root.removeChild(this.mInput);
            root.addChildAt(this.mInput,root.getChildIndex(scene.mContainer) + 1);
         }
      }

      private function setOffstage(root:flash.display.Sprite, scene:IsometricScene, on:Boolean) : void
      {
         if(on)
         {
            if(scene.mContainer.parent == root)
            {
               root.removeChild(scene.mContainer);
            }
            if(scene.mSceneHud.parent == root)
            {
               root.removeChild(scene.mSceneHud);
            }
         }
         else
         {
            // Back in the game's order: field bitmap, world, fog bitmap, effects.
            var tiles:Object = scene.mTilemapGraphic;
            var field:DisplayObject = tiles.mFieldBmp;
            var fog:DisplayObject = tiles.mFogBmp;
            root.addChildAt(scene.mContainer,field && field.parent == root ? root.getChildIndex(field) + 1 : 0);
            root.addChildAt(scene.mSceneHud,fog && fog.parent == root ? root.getChildIndex(fog) + 1 : root.getChildIndex(scene.mContainer) + 1);
         }
         this.mOffstage = on;
         trace("[profile] world containers " + (on ? "off" : "on") + " stage");
      }

      // Return the world to the Flash renderer.
      private function detach() : void
      {
         if(this.mScene != null && this.mOffstage && GameState.mInstance)
         {
            this.setOffstage(GameState.mInstance.mRootNode,this.mScene,false);
         }
         if(this.mScene != null)
         {
            this.mScene.mContainer.visible = true;
            this.mScene.mSceneHud.visible = true;
            var tiles:Object = this.mScene.mTilemapGraphic;
            if(tiles)
            {
               tiles.mGpuGround = false;
               if(tiles.mFieldBmp)
               {
                  tiles.mFieldBmp.visible = true;
               }
               if(tiles.mFogBmp)
               {
                  tiles.mFogBmp.visible = true;
               }
               // The screen bitmaps were not kept up to date meanwhile.
               tiles.updateTilemap();
            }
         }
         if(this.mInput.parent)
         {
            this.mInput.parent.removeChild(this.mInput);
         }
         this.hideWorld();
         this.mCache.clear();
         if(this.mGround)
         {
            this.mGround.clear();
         }
         this.mScale = NaN;
      }

      private function hideWorld() : void
      {
         if(this.mRoot)
         {
            this.mRoot.visible = false;
         }
      }

      private function mirrorWorld(scene:IsometricScene) : void
      {
         var scale:Number = scene.mContainer.scaleX;
         if(scale != this.mScale)
         {
            // New zoom level: every look has to be rasterised again at the new size.
            this.mCache.clear();
            this.mScale = scale;
         }
         this.mRoot.visible = true;
         this.mirrorLayer(scene.mContainer,scene.getFloorContainer(),this.mRoot.world,this.mWorldImages,scale);
         this.mirrorLayer(scene.mSceneHud,null,this.mRoot.effects,this.mEffectImages,scale);
      }

      // Mirror the children of a world-space Flash layer into `layer`, in order.
      private function mirrorLayer(container:flash.display.Sprite, skip:DisplayObject, layer:starling.display.Sprite, images:Vector.<Image>, scale:Number) : void
      {
         layer.x = container.x;
         layer.y = container.y;
         var used:int = 0;
         var n:int = container.numChildren;
         for(var i:int = 0; i < n; i++)
         {
            var child:DisplayObject = container.getChildAt(i);
            if(child == null || child == skip || !child.visible || child.alpha <= 0)
            {
               continue;
            }
            var look:Snapshot = this.mCache.get(child,scale);
            if(look == null)
            {
               continue;
            }
            var image:Image;
            if(used < images.length)
            {
               image = images[used];
               if(image.texture != look.texture)
               {
                  image.texture = look.texture;
                  image.readjustSize();
               }
            }
            else
            {
               image = new Image(look.texture);
               images.push(image);
               layer.addChild(image);
            }
            // The look is drawn unrotated around the object's origin; rotate
            // about that origin on the GPU.
            image.pivotX = -look.offsetX;
            image.pivotY = -look.offsetY;
            image.x = child.x * scale;
            image.y = child.y * scale;
            image.rotation = child.rotation * DEG_TO_RAD;
            image.alpha = child.alpha;
            image.visible = true;
            ++used;
         }
         for(i = used; i < images.length; i++)
         {
            images[i].visible = false;
         }
      }

      private function forwardMouse(event:MouseEvent) : void
      {
         if(this.mScene == null)
         {
            return;
         }
         this.mPoint.x = event.stageX;
         this.mPoint.y = event.stageY;
         var target:InteractiveObject = null;
         if(event.type != MouseEvent.MOUSE_MOVE)
         {
            // Effects layer first (it is above the world), then the map
            // overlays (e.g. move-target cells). Every other world object
            // sends its clicks to FloorClicked, same as the floor, so it does
            // not need hit-testing.
            target = pick(this.mScene.mSceneHud,this.mPoint.x,this.mPoint.y);
            var overlays:Object = this.mScene.mMapGUIEffectsLayer;
            if(target == null && overlays)
            {
               target = pickIn(overlays.mTopLayer,this.mPoint.x,this.mPoint.y) || pickIn(overlays.mGroundLayer,this.mPoint.x,this.mPoint.y);
            }
         }
         if(target == null)
         {
            // Moves only drive scrolling and hover, which use stage coordinates.
            target = this.mScene.getFloorContainer() || this.mScene.mContainer;
         }
         var local:Point = target.globalToLocal(this.mPoint);
         target.dispatchEvent(new MouseEvent(event.type,true,false,local.x,local.y,null,event.ctrlKey,event.altKey,event.shiftKey,event.buttonDown,event.delta));
         // On stage, the copy bubbles on up to the game's root listeners (which
         // track the mouse position for hover highlights), so stop the
         // original. Off stage the copy ends at the detached world container,
         // so the original has to carry on instead.
         if(!this.mOffstage)
         {
            event.stopPropagation();
         }
      }

      // The object Flash would make the target of a mouse event at (x, y):
      // the topmost, deepest mouse-enabled InteractiveObject whose shape (or
      // hitArea) contains the point. Shapes and bitmaps are not interactive
      // themselves; hits on them go to their enclosing container.
      private static function pick(container:DisplayObjectContainer, x:Number, y:Number) : InteractiveObject
      {
         for(var i:int = container.numChildren - 1; i >= 0; i--)
         {
            var child:DisplayObject = container.getChildAt(i);
            if(child == null || !child.visible)
            {
               continue;
            }
            var io:InteractiveObject = child as InteractiveObject;
            if(io == null)
            {
               continue;
            }
            var c:DisplayObjectContainer = child as DisplayObjectContainer;
            if(c != null && c.mouseChildren)
            {
               var inner:InteractiveObject = pick(c,x,y);
               if(inner != null)
               {
                  return inner;
               }
            }
            if(io.mouseEnabled && hits(child,x,y))
            {
               return io;
            }
         }
         return null;
      }

      private static function pickIn(layer:DisplayObjectContainer, x:Number, y:Number) : InteractiveObject
      {
         return layer && layer.parent && layer.visible ? pick(layer,x,y) : null;
      }

      private static function hits(o:DisplayObject, x:Number, y:Number) : Boolean
      {
         var s:flash.display.Sprite = o as flash.display.Sprite;
         if(s != null && s.hitArea != null)
         {
            return s.hitArea.hitTestPoint(x,y,true);
         }
         return o.hitTestPoint(x,y,true);
      }
   }
}
