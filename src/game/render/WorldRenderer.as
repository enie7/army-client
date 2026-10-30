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
   import flash.events.TimerEvent;
   import flash.utils.Dictionary;
   import flash.utils.Timer;
   import flash.utils.getTimer;
   import flash.utils.getQualifiedClassName;
   import flash.display.MovieClip;
   import game.isometric.IsometricScene;
   import game.isometric.elements.DisplayContainer;
   import game.isometric.elements.Renderable;
   import game.render.view.GpuArt;
   import game.render.view.GpuClip;
   import game.render.view.StarlingView;
   import game.states.GameState;
   import game.utils.FrameProfiler;
   import flash.display.PNGEncoderOptions;
   import flash.utils.ByteArray;
   import flash.filesystem.File;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.desktop.NativeApplication;
   import game.render.timeline.TimelineGallery;
   import game.render.timeline.TimelineLibrary;
   import starling.core.Starling;
   import starling.display.DisplayObject;
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

      // What each layer shows, in order: snapshot images, and the GPU art of
      // objects drawn by the timeline player (StarlingView).
      private var mWorldOrder:Vector.<starling.display.DisplayObject> = new Vector.<starling.display.DisplayObject>();

      private var mEffectOrder:Vector.<starling.display.DisplayObject> = new Vector.<starling.display.DisplayObject>();

      // Screen area in layer coordinates (pixels, camera removed), with a
      // margin for interpolated motion: art outside it is not drawn.
      private static const CULL_MARGIN:Number = 96;

      private var mViewLeft:Number = 0;

      private var mViewTop:Number = 0;

      private var mViewRight:Number = 0;

      private var mViewBottom:Number = 0;

      // Development aid: objects left out as off screen, since the last stats.
      private var mCulled:int = 0;

      // Development aid: what had to be rasterised again, by kind.
      private var mMisses:Object = {};

      private var mInput:flash.display.Sprite = new flash.display.Sprite();

      private var mScene:IsometricScene;

      private var mGround:GroundChunks;

      private var mGroundDrawn:int = 0;

      private var mScale:Number = NaN;

      private var mFailed:Boolean = false;

      private var mPoint:Point = new Point();

      private var mGallery:TimelineGallery;

      // Presentation rate. Above 40 (the game's frame and logic rate), extra
      // frames are presented between Flash frames from a pacing timer, with
      // positions interpolated between the last two logic states; animation
      // frames keep the 40 fps rhythm they were drawn for. Set by --render-hz.
      public static var presentHz:int = 60;

      // Interpolation runs this far behind the newest logic state, so there is
      // always a pair of states to blend between: one logic step.
      private static const INTERP_DELAY_MS:int = 25;

      private var mPacer:Timer;

      private var mLastPresent:int = 0;

      private var mPresents:int = 0;

      private var mPrevTime:Number = 0;

      private var mCurTime:Number = 0;

      private var mCaptures:int = 0;

      // Per mirrored Flash object: its previous and current position.
      private var mMotion:Dictionary = new Dictionary(true);

      private var mWorldMotion:Vector.<Motion> = new Vector.<Motion>();

      private var mEffectMotion:Vector.<Motion> = new Vector.<Motion>();

      private var mCamera:Motion = new Motion();

      private var mGroundOrigin:Motion = new Motion();

      private var mHasWorld:Boolean = false;

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

      // Call once per frame, after the game logic has run. simTime: game
      // time of the state now in the Flash display list; stepped: whether
      // logic advanced this frame.
      public static function update(simTime:Number, stepped:Boolean) : void
      {
         if(sInstance != null)
         {
            sInstance.render(simTime,stepped);
         }
      }

      public static function get active() : Boolean
      {
         return sInstance != null && sInstance.mRoot != null && !sInstance.mFailed;
      }

      // Page to open the timeline gallery on once Starling is up (-1: don't).
      public static var galleryAtStart:int = -1;

      // Gallery pages still to save as PNGs (--gallery-shots), and when next.
      public static var galleryShots:int = 0;

      // Keep shooting the same page (--gallery-hold), to compare over time.
      public static var galleryHold:Boolean = false;

      private var mShotCount:int = 0;

      private var mNextShot:int = 0;

      // Development aid: open / close / page the timeline gallery.
      public static function toggleGallery() : void
      {
         if(sInstance == null || sInstance.mRoot == null)
         {
            return;
         }
         if(sInstance.mGallery)
         {
            sInstance.mGallery.dispose();
            sInstance.mGallery = null;
         }
         else if(TimelineLibrary.instance)
         {
            sInstance.mGallery = new TimelineGallery(sInstance.mStage,sInstance.mRoot,TimelineLibrary.instance);
         }
      }

      // Save what the gallery shows (GPU stage with the Flash layer over it),
      // three seconds after each page opens, then page on; quit when done.
      private function galleryShot() : void
      {
         var now:int = getTimer();
         if(this.mNextShot == 0)
         {
            this.mNextShot = now + 3000;
         }
         if(now < this.mNextShot)
         {
            return;
         }
         var shot:BitmapData = new BitmapData(this.mStage.stageWidth,this.mStage.stageHeight,false,0);
         this.mStarling.stage.drawToBitmapData(shot);
         shot.draw(this.mStage);
         var bytes:ByteArray = shot.encode(shot.rect,new PNGEncoderOptions());
         shot.dispose();
         var file:File = File.applicationStorageDirectory.resolvePath("gallery-" + this.mGallery.pageIndex + (galleryHold ? "-t" + this.mShotCount++ : "") + ".png");
         var out:FileStream = new FileStream();
         out.open(file,FileMode.WRITE);
         out.writeBytes(bytes);
         out.close();
         trace("[gallery] saved " + file.nativePath);
         // The frame log, then paging / quitting, happen at EXIT_FRAME.
         this.mNextShot = int.MAX_VALUE;
         var header:String = "page " + this.mGallery.pageIndex + " shot " + this.mShotCount + "\n";
         this.mGallery.describeAtExitFrame(function(text:String):void
         {
            var log:FileStream = new FileStream();
            log.open(File.applicationStorageDirectory.resolvePath("gallery-frames.txt"),FileMode.APPEND);
            log.writeUTFBytes(header + text);
            try
            {
               afterGalleryShot();
            }
            catch(e:Error)
            {
               log.writeUTFBytes("ERROR " + e.getStackTrace() + "\n" + e + "\n");
            }
            log.close();
         });
      }

      private function afterGalleryShot() : void
      {
         if(--galleryShots <= 0)
         {
            var out:FileStream = new FileStream();
            var pages:Vector.<BitmapData> = this.mGallery.atlas.pageBitmaps;
            for(var i:int = 0; i < pages.length; i++)
            {
               var bytes:ByteArray = pages[i].encode(pages[i].rect,new PNGEncoderOptions());
               out.open(File.applicationStorageDirectory.resolvePath("gallery-atlas-" + i + ".png"),FileMode.WRITE);
               out.writeBytes(bytes);
               out.close();
            }
            NativeApplication.nativeApplication.exit();
            return;
         }
         if(!galleryHold)
         {
            this.mGallery.page(1);
         }
         this.mNextShot = getTimer() + (galleryHold ? 700 : 3000);
      }

      public static function pageGallery(delta:int) : void
      {
         if(sInstance && sInstance.mGallery)
         {
            sInstance.mGallery.page(delta);
         }
      }

      // Development aid: per world object class and view mode, how many
      // objects, Flash display objects still under their containers, and
      // MovieClips playing there and in the hidden models.
      public static function describeWorld() : String
      {
         var scene:IsometricScene = GameState.mInstance ? GameState.mInstance.mScene : null;
         if(scene == null)
         {
            return "no scene";
         }
         var rows:Object = {};
         var container:flash.display.Sprite = scene.mContainer;
         for(var i:int = 0; i < container.numChildren; i++)
         {
            var child:flash.display.DisplayObject = container.getChildAt(i);
            var dc:DisplayContainer = child as DisplayContainer;
            var renderable:Renderable = dc ? dc.getRenderableObject() : null;
            var view:StarlingView = renderable ? renderable.getView() as StarlingView : null;
            var key:String = (renderable ? getQualifiedClassName(renderable).split("::").pop() : getQualifiedClassName(child).split("::").pop()) + " [" + (view ? view.mode : (renderable ? "flashview" : "other")) + "]";
            var row:Array = rows[key] || (rows[key] = [0,0,0,0]);
            row[0]++;
            var c:Array = [0,0];
            countFlash(child,c);
            row[1] += c[0];
            row[2] += c[1];
            if(view)
            {
               for each(var model:flash.display.DisplayObject in view.models)
               {
                  var m:Array = [0,0];
                  countFlash(model,m);
                  row[3] += m[1];
               }
            }
         }
         var out:String = "world census (objects / flash objects / playing / playing in models):";
         for(key in rows)
         {
            out += "\n  " + key + ": " + rows[key].join(" / ");
         }
         var fx:Array = [0,0];
         countFlash(scene.mSceneHud,fx);
         out += "\n  scene hud (effects): " + fx.join(" / ");
         var hud:Object = {};
         for(i = 0; i < scene.mSceneHud.numChildren; i++)
         {
            var item:flash.display.DisplayObject = scene.mSceneHud.getChildAt(i);
            var k:String = getQualifiedClassName(item) + (item.visible ? "" : " (hidden)");
            var r:Array = hud[k] || (hud[k] = [0,0,0]);
            r[0]++;
            var cc:Array = [0,0];
            countFlash(item,cc);
            r[1] += cc[0];
            r[2] += cc[1];
         }
         for(k in hud)
         {
            out += "\n    hud " + k + ": " + hud[k].join(" / ");
         }
         return out;
      }

      private static function countFlash(o:flash.display.DisplayObject, c:Array) : void
      {
         if(o == null)
         {
            return;
         }
         c[0]++;
         var mc:flash.display.MovieClip = o as flash.display.MovieClip;
         if(mc && mc.isPlaying)
         {
            c[1]++;
         }
         var container:DisplayObjectContainer = o as DisplayObjectContainer;
         if(container)
         {
            for(var i:int = 0; i < container.numChildren; i++)
            {
               countFlash(container.getChildAt(i),c);
            }
         }
      }

      // Cache activity since the last call, for the profiler.
      public static function takeStats() : String
      {
         if(!active)
         {
            return "gpu off";
         }
         var c:SnapshotCache = sInstance.mCache;
         var line:String = "presents " + sInstance.mPresents + " | gpu " + c.hits + " cached / " + c.misses + " rasterised, " + c.usedMegabytes.toFixed(0) + "MB, ground chunks drawn " + sInstance.mGroundDrawn + " | " + GpuArt.describe() + ", culled " + sInstance.mCulled;
         sInstance.mCulled = 0;
         var rows:Array = [];
         for(var k:String in sInstance.mMisses)
         {
            rows.push({"k":k,"n":sInstance.mMisses[k]});
         }
         rows.sortOn("n",Array.NUMERIC | Array.DESCENDING);
         if(rows.length)
         {
            line += " | rasterised:";
            for(var r:int = 0; r < Math.min(4,rows.length); r++)
            {
               line += " " + rows[r].k + " x" + rows[r].n;
            }
         }
         sInstance.mMisses = {};
         sInstance.mGroundDrawn = 0;
         sInstance.mPresents = 0;
         c.hits = 0;
         c.misses = 0;
         return line;
      }

      private function onRootCreated(event:starling.events.Event) : void
      {
         this.mRoot = this.mStarling.root as StarlingRoot;
         // Stage3D sits under the Flash display list and is cleared every
         // present: clear to the Flash stage's background colour, so whatever
         // Flash content does not cover (e.g. beside a loading screen laid out
         // narrower than the window) looks as it did without the GPU renderer,
         // not black.
         this.mStarling.stage.color = this.mStage.color;
         this.mRoot.touchable = false;
         this.mGround = new GroundChunks(this.mRoot.ground,this.mRoot.fog);
         if(presentHz > 40)
         {
            // Timers fire between Flash frames; a short one lets presents
            // land on a steady presentHz grid.
            this.mPacer = new Timer(4);
            this.mPacer.addEventListener(TimerEvent.TIMER,this.onPacer);
            this.mPacer.start();
         }
         if(galleryAtStart >= 0)
         {
            toggleGallery();
            pageGallery(galleryAtStart);
         }
      }

      private function onPacer(event:TimerEvent) : void
      {
         if(getTimer() - this.mLastPresent >= 1000 / presentHz - 1)
         {
            this.present();
         }
      }

      // Place everything at its interpolated position and draw a frame.
      private function present() : void
      {
         if(this.mRoot == null || this.mFailed)
         {
            return;
         }
         this.mLastPresent = getTimer();
         ++this.mPresents;
         if(this.mGallery)
         {
            this.mGallery.tick();
            if(galleryShots > 0)
            {
               this.galleryShot();
            }
         }
         if(this.mHasWorld)
         {
            var span:Number = this.mCurTime - this.mPrevTime;
            var t:Number = span > 0 ? (this.mLastPresent - INTERP_DELAY_MS - this.mPrevTime) / span : 1;
            t = t < 0 ? 0 : (t > 1 ? 1 : t);
            if(this.mPacer == null)
            {
               t = 1;
            }
            this.placeLayer(this.mRoot.world,this.mWorldMotion,t);
            this.placeLayer(this.mRoot.effects,this.mEffectMotion,t);
            var camX:Number = this.mCamera.x(t);
            var camY:Number = this.mCamera.y(t);
            this.mRoot.world.x = this.mRoot.effects.x = this.mRoot.fog.x = camX;
            this.mRoot.world.y = this.mRoot.effects.y = this.mRoot.fog.y = camY;
            this.mRoot.ground.x = camX + this.mGroundOrigin.x(t);
            this.mRoot.ground.y = camY + this.mGroundOrigin.y(t);
         }
         GpuArt.upload();
         FrameProfiler.begin("gpu.present");
         this.mStarling.nextFrame();
         FrameProfiler.end("gpu.present");
      }

      private function placeLayer(layer:starling.display.Sprite, motion:Vector.<Motion>, t:Number) : void
      {
         var n:int = motion.length;
         for(var i:int = 0; i < n && i < layer.numChildren; i++)
         {
            var m:Motion = motion[i];
            if(m != null)
            {
               var shown:starling.display.DisplayObject = layer.getChildAt(i);
               shown.x = m.x(t);
               shown.y = m.y(t);
            }
         }
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

      private function render(simTime:Number, stepped:Boolean) : void
      {
         if(this.mRoot == null || this.mFailed)
         {
            return;
         }
         if(stepped)
         {
            this.mPrevTime = this.mCurTime;
            this.mCurTime = simTime;
            ++this.mCaptures;
         }
         var game:GameState = GameState.mInstance;
         var scene:IsometricScene = game ? game.mScene : null;
         if(scene != this.mScene)
         {
            // Switch first: loading a save destroys the old scene (its
            // containers are nulled), and if releasing it failed the renderer
            // must not stay attached to it, or input would keep going to the
            // dead scene and the map could no longer be scrolled.
            var old:IsometricScene = this.mScene;
            this.mScene = scene;
            this.release(old);
         }
         if(scene == null || scene.mContainer.parent == null && !this.mOffstage)
         {
            this.hideWorld();
            this.mHasWorld = false;
            this.present();
            return;
         }
         this.mCache.nextFrame();
         this.attach(game,scene);
         FrameProfiler.begin("gpu.world");
         this.mirrorWorld(scene);
         FrameProfiler.end("gpu.world");
         FrameProfiler.begin("gpu.ground");
         var tiles:Object = scene.mTilemapGraphic;
         var shakeX:Number = tiles.mFieldBmp ? tiles.mFieldBmp.x : 0;
         var shakeY:Number = tiles.mFieldBmp ? tiles.mFieldBmp.y : 0;
         this.mGround.update(tiles,scene.mContainer.x,scene.mContainer.y,shakeX,shakeY,this.mStage.stageWidth,this.mStage.stageHeight,scene.mContainer.scaleX);
         this.mGroundDrawn += this.mGround.drawn;
         FrameProfiler.end("gpu.ground");
         this.mCamera.capture(scene.mContainer.x,scene.mContainer.y,this.mCaptures);
         this.mGroundOrigin.capture(shakeX,shakeY,this.mCaptures);
         this.mHasWorld = true;
         if(this.mPacer == null)
         {
            this.present();
         }
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
            var field:flash.display.DisplayObject = tiles.mFieldBmp;
            var fog:flash.display.DisplayObject = tiles.mFogBmp;
            root.addChildAt(scene.mContainer,field && field.parent == root ? root.getChildIndex(field) + 1 : 0);
            root.addChildAt(scene.mSceneHud,fog && fog.parent == root ? root.getChildIndex(fog) + 1 : root.getChildIndex(scene.mContainer) + 1);
         }
         this.mOffstage = on;
         trace("[profile] world containers " + (on ? "off" : "on") + " stage");
      }

      // Return the current scene's world to the Flash renderer.
      private function detach() : void
      {
         this.release(this.mScene);
      }

      // Drop the GPU copy of `scene` and give its layers back to Flash; a
      // scene that was destroyed meanwhile has nothing left to give back.
      private function release(scene:IsometricScene) : void
      {
         var alive:Boolean = scene != null && scene.mContainer != null && scene.mSceneHud != null;
         if(alive && this.mOffstage && GameState.mInstance)
         {
            this.setOffstage(GameState.mInstance.mRootNode,scene,false);
         }
         this.mOffstage = false;
         if(alive)
         {
            scene.mContainer.visible = true;
            scene.mSceneHud.visible = true;
            var tiles:Object = scene.mTilemapGraphic;
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
         GpuArt.setScale(scale * Starling.contentScaleFactor);
         GpuArt.tick();
         // Both layers sit at the camera: what lies off screen is left out,
         // so Starling neither batches nor uploads it.
         this.mViewLeft = -CULL_MARGIN - scene.mContainer.x;
         this.mViewTop = -CULL_MARGIN - scene.mContainer.y;
         this.mViewRight = this.mStage.stageWidth + CULL_MARGIN - scene.mContainer.x;
         this.mViewBottom = this.mStage.stageHeight + CULL_MARGIN - scene.mContainer.y;
         this.mirrorLayer(scene.mContainer,scene.getFloorContainer(),this.mRoot.world,this.mWorldImages,this.mWorldMotion,this.mWorldOrder,scale);
         this.mirrorLayer(scene.mSceneHud,null,this.mRoot.effects,this.mEffectImages,this.mEffectMotion,this.mEffectOrder,scale);
      }

      // Mirror the children of a world-space Flash layer into `layer`, in order:
      // a snapshot image per child, or for objects whose art the timeline
      // player draws, that art (plus a snapshot of whatever else is still in
      // their Flash container, e.g. text effects).
      private function mirrorLayer(container:flash.display.Sprite, skip:flash.display.DisplayObject, layer:starling.display.Sprite, images:Vector.<Image>, motions:Vector.<Motion>, order:Vector.<starling.display.DisplayObject>, scale:Number) : void
      {
         var used:int = 0;
         var usedImages:int = 0;
         var n:int = container.numChildren;
         for(var i:int = 0; i < n; i++)
         {
            var child:flash.display.DisplayObject = container.getChildAt(i);
            if(child == null || child == skip || !child.visible || child.alpha <= 0)
            {
               continue;
            }
            var motion:Motion = this.mMotion[child];
            if(motion == null)
            {
               motion = new Motion();
               this.mMotion[child] = motion;
            }
            motion.capture(child.x * scale,child.y * scale,this.mCaptures);
            var gpu:starling.display.DisplayObject = gpuArtOf(child);
            if(gpu != null && this.offscreen(child,boundsOf(child),scale))
            {
               ++this.mCulled;
               gpu = null;
               if((child as DisplayObjectContainer).numChildren <= 1)
               {
                  continue;
               }
            }
            if(gpu != null)
            {
               gpu.scaleX = child.scaleX * scale;
               gpu.scaleY = child.scaleY * scale;
               gpu.rotation = child.rotation * DEG_TO_RAD;
               gpu.alpha = child.alpha;
               gpu.visible = true;
               order[used] = gpu;
               motions[used] = motion;
               ++used;
               // Only the art's placeholder left in the container (or only
               // stand-ins, for a group): done.
               if((child as DisplayObjectContainer).numChildren <= 1 || gpu is starling.display.Sprite && sGroups[child] == gpu)
               {
                  continue;
               }
            }
            var missesBefore:int = this.mCache.misses;
            var look:Snapshot = this.mCache.get(child,scale);
            if(this.mCache.misses != missesBefore)
            {
               var missKey:String = describeChild(child);
               this.mMisses[missKey] = int(this.mMisses[missKey]) + 1;
            }
            if(look == null)
            {
               continue;
            }
            var px:Number = child.x * scale;
            var py:Number = child.y * scale;
            if(child.rotation == 0 && (px + look.offsetX > this.mViewRight || py + look.offsetY > this.mViewBottom || px + look.offsetX + look.texture.width < this.mViewLeft || py + look.offsetY + look.texture.height < this.mViewTop))
            {
               ++this.mCulled;
               continue;
            }
            var image:Image;
            if(usedImages < images.length)
            {
               image = images[usedImages];
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
            }
            ++usedImages;
            // The look is drawn unrotated around the object's origin; rotate
            // about that origin on the GPU.
            image.pivotX = -look.offsetX;
            image.pivotY = -look.offsetY;
            image.rotation = child.rotation * DEG_TO_RAD;
            image.alpha = child.alpha;
            image.visible = true;
            order[used] = image;
            motions[used] = motion;
            ++used;
         }
         for(i = usedImages; i < images.length; i++)
         {
            images[i].visible = false;
         }
         order.length = used;
         motions.length = used;
         // Put the layer's children in that order; when nothing changed this
         // is only a comparison per child.
         for(i = 0; i < used; i++)
         {
            if(i >= layer.numChildren || layer.getChildAt(i) != order[i])
            {
               layer.addChildAt(order[i],i);
            }
         }
         // Past the end: pooled images (hidden) and the art of objects that
         // went away or are hidden, which their views own and dispose.
         for(i = layer.numChildren - 1; i >= used; i--)
         {
            var rest:starling.display.DisplayObject = layer.getChildAt(i);
            if(rest is Image)
            {
               rest.visible = false;
            }
            else
            {
               layer.removeChildAt(i);
            }
         }
      }

      // Development aid: a world layer child, as its object's class or its own
      // class, and what else its container holds.
      private static function describeChild(child:flash.display.DisplayObject) : String
      {
         var dc:DisplayContainer = child as DisplayContainer;
         var renderable:Renderable = dc ? dc.getRenderableObject() : null;
         var name:String = getQualifiedClassName(renderable || child).split("::").pop();
         if(renderable == null)
         {
            var c:DisplayObjectContainer = child as DisplayObjectContainer;
            name += " \"" + child.name + "\" in " + (child.parent ? child.parent.name : "?") + (c && c.numChildren ? " > " + getQualifiedClassName(c.getChildAt(0)).split("::").pop() : "") + " s" + child.scaleX.toFixed(2);
         }
         if(dc && dc.numChildren > 1)
         {
            name += "[" + getQualifiedClassName(dc.getChildAt(dc.numChildren - 1)).split("::").pop() + "]";
         }
         return name;
      }

      // GPU groups: plain Flash containers holding only stand-ins (GpuClip),
      // e.g. the sea wave strip. Drawn as their clips, laid out like the
      // stand-ins; null for other containers.
      private static var sGroups:Dictionary = new Dictionary(true);

      private static function gpuGroupOf(child:flash.display.DisplayObject) : starling.display.Sprite
      {
         var c:DisplayObjectContainer = child as DisplayObjectContainer;
         if(c == null || c is DisplayContainer || c is GpuClip || c.numChildren == 0)
         {
            return null;
         }
         for(var i:int = 0; i < c.numChildren; i++)
         {
            if(!(c.getChildAt(i) is GpuClip))
            {
               return null;
            }
         }
         var group:starling.display.Sprite = sGroups[c];
         if(group == null)
         {
            group = new starling.display.Sprite();
            group.touchable = false;
            sGroups[c] = group;
         }
         group.removeChildren();
         for(i = 0; i < c.numChildren; i++)
         {
            var stand:GpuClip = GpuClip(c.getChildAt(i));
            var node:starling.display.DisplayObject = stand.gpuNode;
            if(node && stand.visible)
            {
               node.x = stand.x;
               node.y = stand.y;
               node.scaleX = stand.scaleX;
               node.scaleY = stand.scaleY;
               node.rotation = stand.rotation * DEG_TO_RAD;
               node.alpha = stand.alpha;
               group.addChild(node);
            }
         }
         return group;
      }

      // Whether art with `bounds` (in the container's coordinates; null when
      // unknown) lies entirely off screen.
      private function offscreen(child:flash.display.DisplayObject, bounds:Rectangle, scale:Number) : Boolean
      {
         if(bounds == null || child.rotation != 0)
         {
            return false;
         }
         var sx:Number = child.scaleX * scale;
         var sy:Number = child.scaleY * scale;
         var x0:Number = child.x * scale + Math.min(bounds.left * sx,bounds.right * sx);
         var x1:Number = child.x * scale + Math.max(bounds.left * sx,bounds.right * sx);
         var y0:Number = child.y * scale + Math.min(bounds.top * sy,bounds.bottom * sy);
         var y1:Number = child.y * scale + Math.max(bounds.top * sy,bounds.bottom * sy);
         return x1 < this.mViewLeft || x0 > this.mViewRight || y1 < this.mViewTop || y0 > this.mViewBottom;
      }

      private static function boundsOf(child:flash.display.DisplayObject) : Rectangle
      {
         var dc:DisplayContainer = child as DisplayContainer;
         var renderable:Renderable = dc ? dc.getRenderableObject() : null;
         var view:StarlingView = renderable ? renderable.getView() as StarlingView : null;
         return view ? view.bounds : null;
      }

      // The GPU art of a world object's container, or null if it shows Flash art.
      private static function gpuArtOf(child:flash.display.DisplayObject) : starling.display.DisplayObject
      {
         var group:starling.display.Sprite = gpuGroupOf(child);
         if(group)
         {
            return group;
         }
         var stand:GpuClip = child as GpuClip;
         if(stand)
         {
            return stand.gpuNode;
         }
         var dc:DisplayContainer = child as DisplayContainer;
         if(dc == null)
         {
            return null;
         }
         var renderable:Renderable = dc.getRenderableObject();
         var view:StarlingView = renderable ? renderable.getView() as StarlingView : null;
         return view ? view.gpuNode : null;
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
         if(target == null)
         {
            // The scene is being torn down (loading a save).
            return;
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
            var child:flash.display.DisplayObject = container.getChildAt(i);
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

      private static function hits(o:flash.display.DisplayObject, x:Number, y:Number) : Boolean
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

// Previous and current position of one mirrored thing (an object, the camera),
// as of the last two logic states, for interpolated presents.
class Motion
{
   private static const SNAP_DISTANCE:Number = 300;

   private var mPrevX:Number = 0;

   private var mPrevY:Number = 0;

   private var mCurX:Number = 0;

   private var mCurY:Number = 0;

   private var mCapture:int = -2;

   public function Motion()
   {
      super();
   }

   // capture: id of the logic state being recorded. Recording the same state
   // again (a Flash frame without a logic step) only refreshes it; skipping
   // one (the object was hidden) starts it afresh, without sliding.
   public function capture(x:Number, y:Number, capture:int) : void
   {
      if(capture == this.mCapture + 1)
      {
         this.mPrevX = this.mCurX;
         this.mPrevY = this.mCurY;
      }
      else if(capture != this.mCapture)
      {
         this.mPrevX = x;
         this.mPrevY = y;
      }
      this.mCurX = x;
      this.mCurY = y;
      this.mCapture = capture;
      var dx:Number = this.mCurX - this.mPrevX;
      var dy:Number = this.mCurY - this.mPrevY;
      if(dx * dx + dy * dy > SNAP_DISTANCE * SNAP_DISTANCE)
      {
         this.mPrevX = x;
         this.mPrevY = y;
      }
   }

   public function x(t:Number) : Number
   {
      return this.mPrevX + (this.mCurX - this.mPrevX) * t;
   }

   public function y(t:Number) : Number
   {
      return this.mPrevY + (this.mCurY - this.mPrevY) * t;
   }
}
