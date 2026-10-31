package game.gui
{
   import com.dchoc.GUI.DCButton;
   import com.dchoc.graphics.DCResourceManager;
   import flash.display.MovieClip;
   import flash.events.*;
   import flash.filesystem.File;
   import flash.net.FileFilter;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.permissions.PermissionStatus;
   import game.gui.button.ArmyButton;
   import game.gui.popups.PopUpWindow;
   import game.gui.popups.PopUpManager;
   import game.missions.MissionManager;
   import game.sound.ArmySoundManager;
   import game.states.GameState;
   import game.utils.OfflineSave;
   import game.utils.FrameProfiler;
   import game.render.view.GpuClip;
   import game.items.ItemManager;
   import game.gameElements.ConstructionObject;
   import game.gameElements.LootReward;
   import game.items.MapItem;
   import game.isometric.elements.Renderable;
   import game.render.art.StopWhenDetached;
   import game.utils.TimelinePauser;
   import game.render.WorldRenderer;
   import flash.desktop.NativeApplication;
   import flash.utils.Timer;
   import starling.textures.Texture;
   
   public class PauseDialog extends PopUpWindow
   {
      
      public static var mPauseScreenState:int;
      
      public static var mPauseScreenPreviousState:int;
      
      public static const STATE_IN_GAME:int = 0;
      
      public static const STATE_UNDEFINED:int = 1;
      
      public static const STATE_CONTINUE:int = 2;
      
      public static const STATE_HELP_CLICK:int = 3;
      
      public static const STATE_SETTINGS_CLICK:int = 4;
      
      private var mButtonPlay:ArmyButton;
      
      private var mButtonResume:ArmyButton;
      
      private var mButtonSettings:ArmyButton;
      
      private var mButtonHelp:ArmyButton;
      
      private var mButtonLoad:ArmyButton;
      
      public function PauseDialog()
      {
         var _loc1_:Class = DCResourceManager.getInstance().getSWFClass(Config.SWF_MAIN_MENU_NAME,"MainMenu");
         super(new _loc1_(),false);
         if(mPauseScreenState == STATE_CONTINUE)
         {
            this.mButtonPlay = this.addButton(mClip,"Button_play",this.tabPressed);
            this.mButtonPlay.resizeNeeded = false;
            this.mButtonResume = this.addButton(mClip,"Button_resume",this.tabPressed);
            this.mButtonResume.resizeNeeded = false;
            this.mButtonSettings = this.addButton(mClip,"Button_settings",this.tabPressed);
            this.mButtonSettings.resizeNeeded = false;
            this.mButtonHelp = this.addButton(mClip,"Button_how_to_play",this.tabPressed);
            this.mButtonHelp.resizeNeeded = false;
            this.mButtonLoad = this.addButton(mClip,"Button_loadsave",this.tabPressed);
            this.mButtonLoad.resizeNeeded = false;
            this.mButtonPlay.setText(GameState.getText("PLAY_BUTTON_TEXT"),"Text_Title");
            this.mButtonResume.setText(GameState.getText("RESUME_BUTTON_TEXT"),"Text_Title");
            this.mButtonSettings.setText(GameState.getText("SETTINGS_BUTTON_TEXT"),"Text_Title");
            this.mButtonHelp.setText(GameState.getText("HELP_BUTTON_TEXT"),"Text_Title");
            this.mButtonLoad.setText(GameState.getText("LOAD_BUTTON_TEXT"),"Text_Title");
            this.updatePlayResumeButton();
         }
      }
      
      // --autoload=<file>: load that save and press Play once the menu first
      // opens (for unattended performance runs); --autoquit=N quits N seconds
      // after that.
      public static var autoloadPath:String;

      public static var autoquitSeconds:int = 0;

      // --autoplay: press Play without loading a save (the state the game
      // starts with), with the same timers as --autoload.
      public static var autoplay:Boolean = false;

      // --freeze-stage=N: N seconds after Play, stop every playing clip on the
      // stage (experiment: is per-frame construction from on-stage clips?).
      public static var freezeSeconds:int = 0;

      // --autokey: after Play, hold the left arrow for 2s (a synthetic key on
      // the stage) and log the camera before and after.
      public static var autokey:Boolean = false;

      // --autoplace=Type_ID: 6s after Play, start placing that shop item (as
      // buying it does), e.g. --autoplace=Building_HQ.
      public static var autoplace:String = null;

      // --autowork: 6s after Play, click the first construction site five
      // times (queueing build steps).
      public static var autowork:Boolean = false;

      // --autoloot: from 6s after Play, every 2s until quit, drop money and
      // energy at the first construction site and click every other piece a
      // second later; log how many pieces of loot are left each second.
      public static var autoloot:Boolean = false;

      // --leak-textures=N: N seconds after Play, take GPU textures until no
      // more can be made, and keep them (the state a texture leak ends in);
      // log what follows, with screenshots 3s and 6s later.
      public static var leakTexturesSeconds:int = 0;

      // --texture-probe: every 20s, log how many more GPU textures could be
      // made (made and freed again), to see a leak as falling headroom.
      public static var textureProbe:Boolean = false;

      // --hide-hud: hide the HUD 1s after Play (measuring what it costs).
      public static var hideHud:Boolean = false;

      // --compare=SYMBOL: 6s after Play, show the symbol drawn by Flash (left)
      // and by the GPU player (right), and save compare.png 2s later.
      public static var compareSymbol:String = null;

      // --compare-scale=N: the size --compare shows them at (default 1).
      public static var compareScale:Number = 1;

      private static var sLeaked:Array;

      // --autopan: after Play, keep panning (left, down, right, up, 2s each)
      // with synthetic arrow keys, to measure frame times while scrolling.
      public static var autopan:Boolean = false;

      // --autoshot=N: N seconds after Play, save a screenshot (GPU world plus
      // the Flash display list) as autoshot.png in the app storage directory.
      public static var autoshotSeconds:int = 0;

      // --autobug=N: N seconds after Play, file a bug report (as Shift+B does).
      public static var autobugSeconds:int = 0;

      // --autoclick=N: N seconds after Play, click the first enemy
      // installation that has player units in range (debugging clicks).
      public static var autoclickSeconds:int = 0;

      // --autohover=N: N seconds after Play, hold the mouse over the first
      // enemy installation with player units in range for 3s.
      public static var autohoverSeconds:int = 0;

      public function Activate(param1:Function) : void
      {
         mDoneCallback = param1;
         doOpeningTransition();
         if((autoloadPath || autoplay) && mPauseScreenState == STATE_CONTINUE)
         {
            var path:String = autoloadPath;
            autoloadPath = null;
            autoplay = false;
            var timer:Timer = new Timer(1000,1);
            timer.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
            {
               autoload(path);
            });
            timer.start();
         }
      }

      private function autoload(path:String) : void
      {
         if(path)
         {
            var file:File = new File(path);
            var stream:FileStream = new FileStream();
            stream.open(file,FileMode.READ);
            var data:* = JSON.parse(stream.readUTFBytes(stream.bytesAvailable));
            stream.close();
            FrameProfiler.mark("autoload " + path);
            this.loadProgress(data);
         }
         this.play();
         FrameProfiler.mark("autoload: playing");
         if(autohoverSeconds > 0)
         {
            var hoverTimer:Timer = new Timer(autohoverSeconds * 1000,1);
            hoverTimer.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
            {
               var game:GameState = GameState.mInstance;
               var hovered:Object = null;
               for each(var inst:Object in game.mScene.getEnemyInstallations())
               {
                  var attackers:Array = game.searchAttackablePlayerUnits(inst as Renderable);
                  if(attackers && attackers.length > 0)
                  {
                     hovered = inst;
                     break;
                  }
               }
               if(hovered == null)
               {
                  FrameProfiler.mark("autohover: no installation with units in range");
                  return;
               }
               game.mScene.mCamera.moveTo(hovered.getContainer().x,hovered.getContainer().y);
               var moves:int = 0;
               var mover:Timer = new Timer(100,30);
               mover.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
               {
                  var b:Object = hovered.getContainer().getBounds(game.getMainClip().stage);
                  WorldRenderer.moveMouseTo(b.x + b.width / 2 + (moves++ % 2),b.y + b.height / 2);
                  if(moves == 1)
                  {
                     FrameProfiler.mark("autohover: over " + hovered + " at " + (b.x + b.width / 2) + "," + (b.y + b.height / 2));
                  }
               });
               mover.addEventListener(TimerEvent.TIMER_COMPLETE,function(event:TimerEvent):void
               {
                  FrameProfiler.mark("autohover: done");
               });
               mover.start();
            });
            hoverTimer.start();
         }
         if(autoclickSeconds > 0)
         {
            var target:Object = null;
            var clickTimer:Timer = new Timer(autoclickSeconds * 1000,1);
            clickTimer.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
            {
               var game:GameState = GameState.mInstance;
               for each(var inst:Object in game.mScene.getEnemyInstallations())
               {
                  var attackers:Array = game.searchAttackablePlayerUnits(inst as Renderable);
                  if(attackers && attackers.length > 0)
                  {
                     target = inst;
                     FrameProfiler.mark("autoclick: target " + inst + " cell " + inst.getCell().mPosI + "," + inst.getCell().mPosJ + " tiles " + inst.getTileSize() + " attackers " + attackers.length + " visible " + inst.getContainer().visible);
                     game.mScene.mCamera.moveTo(inst.getContainer().x,inst.getContainer().y);
                     break;
                  }
               }
               if(target == null)
               {
                  FrameProfiler.mark("autoclick: no installation with units in range");
                  return;
               }
               var go:Timer = new Timer(800,1);
               go.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
               {
                  var b:Object = target.getContainer().getBounds(game.getMainClip().stage);
                  var x:Number = b.x + b.width / 2;
                  var y:Number = b.y + b.height / 2;
                  FrameProfiler.mark("autoclick: clicking " + x + "," + y + " (bounds " + b + "), queue " + game.mMainActionQueue.mActions.length + " current " + game.mCurrentAction);
                  WorldRenderer.clickAt(x,y);
                  var after:Timer = new Timer(500,1);
                  after.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
                  {
                     FrameProfiler.mark("autoclick: after: queue " + game.mMainActionQueue.mActions.length + " current " + game.mCurrentAction);
                  });
                  after.start();
               });
               go.start();
            });
            clickTimer.start();
         }
         if(autobugSeconds > 0)
         {
            var bugTimer:Timer = new Timer(autobugSeconds * 1000,1);
            bugTimer.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
            {
               FrameProfiler.bugReport(GameState.mInstance.getMainClip().stage);
            });
            bugTimer.start();
         }
         if(autoshotSeconds > 0)
         {
            var shotTimer:Timer = new Timer(autoshotSeconds * 1000,1);
            shotTimer.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
            {
               WorldRenderer.saveScreenshot("autoshot.png");
               FrameProfiler.mark("autoshot saved");
            });
            shotTimer.start();
         }
         if(autopan)
         {
            var keys:Array = [37,40,39,38];
            var step:int = 0;
            var pan:Timer = new Timer(2000);
            pan.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
            {
               var st:Object = GameState.mInstance.getMainClip().stage;
               if(step > 0)
               {
                  st.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP,true,false,0,keys[(step - 1) % 4]));
               }
               st.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN,true,false,0,keys[step % 4]));
               ++step;
            });
            pan.start();
         }
         if(compareSymbol)
         {
            var cmpTimer:Timer = new Timer(6000,1);
            cmpTimer.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
            {
               var game:GameState = GameState.mInstance;
               var cls:Class = DCResourceManager.getInstance().getSWFClass(Config.SWF_INTERFACE_NAME,compareSymbol);
               var flashArt:MovieClip = cls ? new cls() as MovieClip : null;
               var stage:Object = game.getMainClip().stage;
               if(flashArt)
               {
                  flashArt.x = 400;
                  flashArt.y = 360;
                  flashArt.scaleX = flashArt.scaleY = compareScale;
                  stage.addChild(flashArt);
               }
               var gpu:MovieClip = GpuClip.create(compareSymbol);
               var hud:Object = game.mScene.mSceneHud;
               var sc:Number = game.mScene.mContainer.scaleX;
               if(gpu)
               {
                  gpu.x = (880 - game.mScene.mContainer.x) / sc;
                  gpu.y = (360 - game.mScene.mContainer.y) / sc;
                  gpu.scaleX = gpu.scaleY = compareScale / sc;
                  hud.addChild(gpu);
               }
               FrameProfiler.mark("compare: " + compareSymbol + " flash " + flashArt + " gpu " + gpu);
               var shot:Timer = new Timer(2000,1);
               shot.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
               {
                  WorldRenderer.saveScreenshot("compare.png");
               });
               shot.start();
            });
            cmpTimer.start();
         }
         if(hideHud)
         {
            var hudTimer:Timer = new Timer(1000,1);
            hudTimer.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
            {
               GameState.mInstance.mHUD.visible = false;
               FrameProfiler.mark("hide-hud: HUD hidden");
            });
            hudTimer.start();
         }
         if(textureProbe)
         {
            var probeTimer:Timer = new Timer(20000);
            probeTimer.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
            {
               var made:Array = [];
               try
               {
                  while(made.length < 6000)
                  {
                     made.push(starling.textures.Texture.empty(4,4));
                  }
               }
               catch(e:Error)
               {
               }
               for each(var t:starling.textures.Texture in made)
               {
                  t.dispose();
               }
               FrameProfiler.mark("texture-probe: room for " + made.length + " more textures");
            });
            probeTimer.start();
         }
         if(leakTexturesSeconds > 0)
         {
            var leakTimer:Timer = new Timer(leakTexturesSeconds * 1000,1);
            leakTimer.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
            {
               var leaked:Array = [];
               try
               {
                  while(leaked.length < 10000)
                  {
                     leaked.push(starling.textures.Texture.empty(4,4));
                  }
               }
               catch(e:Error)
               {
                  FrameProfiler.mark("leak-textures: took " + leaked.length + " textures, then " + e);
               }
               sLeaked = leaked;
               for each(var at:int in [3,6])
               {
                  var shot:Timer = new Timer(at * 1000,1);
                  shot.addEventListener(TimerEvent.TIMER,function(name:String):Function
                  {
                     return function(event:TimerEvent):void
                     {
                        WorldRenderer.saveScreenshot(name);
                        FrameProfiler.mark("leak-textures: saved " + name + ", camera " + GameState.mInstance.mScene.mCamera.getCameraX() + "," + GameState.mInstance.mScene.mCamera.getCameraY());
                     };
                  }("leak-" + at + "s.png"));
                  shot.start();
               }
            });
            leakTimer.start();
         }
         if(autoloot)
         {
            var lootTimer:Timer = new Timer(1000);
            lootTimer.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
            {
               var scene:Object = GameState.mInstance.mScene;
               var hud:Object = scene.mSceneHud;
               var loot:Array = [];
               for(var i:int = 0; i < hud.numChildren; i++)
               {
                  if(hud.getChildAt(i) is LootReward)
                  {
                     loot.push(hud.getChildAt(i));
                  }
               }
               var tick:int = lootTimer.currentCount;
               if(tick >= 6 && tick % 2 == 0)
               {
                  for each(var el:Object in scene.mAllElements)
                  {
                     if(el is ConstructionObject)
                     {
                        if(tick == 6)
                        {
                           scene.mCamera.moveTo(el.getContainer().x,el.getContainer().y);
                        }
                        scene.addLootReward(ItemManager.getItem("Money","Resource"),150,el.getContainer());
                        scene.addLootReward(ItemManager.getItem("Energy","Resource"),10,el.getContainer());
                        break;
                     }
                  }
               }
               else if(tick >= 7 && tick % 2 == 1)
               {
                  for(var j:int = 0; j < loot.length; j += 2)
                  {
                     var r:Object = loot[j].getBounds(hud.stage);
                     FrameProfiler.mark("autoloot: click " + j + " at " + int(r.x + r.width / 2) + "," + int(r.y + r.height / 2));
                     WorldRenderer.clickAt(r.x + r.width / 2,r.y + r.height / 2);
                  }
               }
               FrameProfiler.mark("autoloot: " + loot.length + " loot in the scene hud");
            });
            lootTimer.start();
         }
         if(autowork)
         {
            var workTimer:Timer = new Timer(6000,1);
            workTimer.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
            {
               for each(var el:Object in GameState.mInstance.mScene.mAllElements)
               {
                  if(el is ConstructionObject)
                  {
                     FrameProfiler.mark("autowork: " + el.mItem.mId);
                     for(var c:int = 0; c < 5; c++)
                     {
                        (el as ConstructionObject).MousePressed(new MouseEvent(MouseEvent.MOUSE_DOWN));
                     }
                     break;
                  }
               }
            });
            workTimer.start();
         }
         if(autoplace)
         {
            var placeTimer:Timer = new Timer(6000,1);
            placeTimer.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
            {
               var item:Object = ItemManager.getItemList()[autoplace];
               FrameProfiler.mark("autoplace: " + autoplace + " " + item);
               if(item)
               {
                  GameState.mInstance.addToWorld(item as MapItem);
               }
            });
            placeTimer.start();
         }
         if(autokey)
         {
            var keyTimer:Timer = new Timer(10000,1);
            keyTimer.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
            {
               var stage:Object = GameState.mInstance.getMainClip().stage;
               var cam:Object = GameState.mInstance.mScene.mCamera;
               FrameProfiler.mark("autokey: left down, camera " + cam.getCameraX() + "," + cam.getCameraY() + " focus " + stage.focus);
               WorldRenderer.saveScreenshot("autokey-before.png");
               stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN,true,false,0,37));
               var up:Timer = new Timer(2000,1);
               up.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
               {
                  var sc:Object = GameState.mInstance.mScene;
                  FrameProfiler.mark("autokey: held: left " + sc.mLeftPressed + " mouseScrolling " + sc.mMouseScrolling + " anyKey " + sc.mAnyScrollKeyPressed + " state " + GameState.mInstance.mState + " modal " + PopUpManager.isModalPopupActive() + " target " + cam.getTargetX() + "," + cam.getTargetY() + " bounds " + cam.getBounds());
                  WorldRenderer.saveScreenshot("autokey-held.png");
                  stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP,true,false,0,37));
                  FrameProfiler.mark("autokey: left up, camera " + cam.getCameraX() + "," + cam.getCameraY() + " " + sc.describeScrollState());
                  var later:Timer = new Timer(3000,1);
                  later.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
                  {
                     FrameProfiler.mark("autokey: 3s later, camera " + cam.getCameraX() + "," + cam.getCameraY());
                  });
                  later.start();
               });
               up.start();
            });
            keyTimer.start();
         }
         if(freezeSeconds > 0)
         {
            var freeze:Timer = new Timer(freezeSeconds * 1000,1);
            freeze.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
            {
               var stopped:int = 0;
               var stopAll:Function = function(o:flash.display.DisplayObject):void
               {
                  var mc:MovieClip = o as MovieClip;
                  if(mc && mc.isPlaying)
                  {
                     mc.stop();
                     ++stopped;
                  }
                  var c:flash.display.DisplayObjectContainer = o as flash.display.DisplayObjectContainer;
                  for(var i:int = 0; c && i < c.numChildren; i++)
                  {
                     stopAll(c.getChildAt(i));
                  }
               };
               stopAll(GameState.mInstance.getMainClip().stage);
               var world:flash.display.DisplayObject = GameState.mInstance.mScene.mContainer.parent;
               if(world && !world.stage)
               {
                  stopAll(world);
               }
               FrameProfiler.mark("froze " + stopped + " playing clips");
            });
            freeze.start();
         }
         if(autoquitSeconds > 5)
         {
            var census:Timer = new Timer((autoquitSeconds - 5) * 1000,1);
            census.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
            {
               FrameProfiler.mark(WorldRenderer.describeWorld());
               FrameProfiler.census(GameState.mInstance.getMainClip().stage);
               FrameProfiler.listPlaying(GameState.mInstance.getMainClip().stage);
               FrameProfiler.mark(StopWhenDetached.describe());
               var scene:Object = GameState.mInstance.mScene;
               if(scene && scene.mContainer.parent)
               {
                  FrameProfiler.mark("world root " + scene.mContainer.parent + (scene.mContainer.stage ? " (on stage)" : " (off stage)"));
                  FrameProfiler.census(scene.mContainer.parent);
               }
            });
            census.start();
         }
         if(autoquitSeconds > 0)
         {
            var quit:Timer = new Timer(autoquitSeconds * 1000,1);
            quit.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
            {
               FrameProfiler.mark("autoquit");
               NativeApplication.nativeApplication.exit();
            });
            quit.start();
         }
      }

      private function play() : void
      {
         if(MissionManager.isTutorialCompleted())
         {
            GameState.mInstance.changeState(GameState.STATE_PLAY);
         }
         else
         {
            ArmySoundManager.getInstance().stopSound(ArmySoundManager.MUSIC_HOME);
            GameState.mInstance.mHUD.openIntroTextBox();
         }
         mDoneCallback((this as Object).constructor);
      }
      
      public function startSelectingFile() : void
      {
         var _loc1_:File = null;
         // Open in Documents, where the save picker starts.
         _loc1_ = File.documentsDirectory;
         _loc1_.addEventListener(PermissionEvent.PERMISSION_STATUS,this.onPermission);
         _loc1_.requestPermission();
      }
      
      public function onFileSelected(param1:Event) : void
      {
         var _loc2_:File = null;
         var _loc3_:FileStream = null;
         var _loc4_:* = undefined;
         _loc2_ = param1.target as File;
         _loc3_ = new FileStream();
         _loc3_.open(_loc2_,FileMode.READ);
         _loc4_ = JSON.parse(_loc3_.readUTFBytes(_loc3_.bytesAvailable));
         _loc3_.close();
         this.loadProgress(_loc4_);
      }
      
      public function fixOldSave(param1:*, param2:int) : *
      {
         if(param2 < 3)
         {
            param1["isFogOfWarOff"] = true;
         }
         return param1;
      }
      
      public function loadProgress(param1:*) : void
      {
         OfflineSave.loadProgress(param1);
      }
      
      private function tabPressed(param1:MouseEvent) : void
      {
         var _loc2_:* = undefined;
         if(ArmySoundManager.getInstance().isSfxOn())
         {
            ArmySoundManager.getInstance().playSound(ArmySoundManager.SFX_UI_CLICK);
         }
         switch(param1.target)
         {
            case this.mButtonPlay.getMovieClip():
            case this.mButtonResume.getMovieClip():
               GameHUD.isPauseButtonClicked = false;
               if(param1.target == this.mButtonPlay.getMovieClip())
               {
                  if(FeatureTuner.USE_RATEAPP_POPUP)
                  {
                     GameState.mInstance.checkRateApp();
                  }
               }
               this.play();
               break;
            case this.mButtonHelp.getMovieClip():
               GameState.mInstance.mHUD.openHelpScreen();
               break;
            case this.mButtonSettings.getMovieClip():
               GameState.mInstance.mHUD.openSettingsScreen();
               break;
            case this.mButtonLoad.getMovieClip():
               this.startSelectingFile();
         }
      }
      
      private function updatePlayResumeButton() : void
      {
         if(GameHUD.isPauseButtonClicked)
         {
            this.mButtonPlay.setVisible(false);
            this.mButtonResume.setVisible(true);
         }
         else
         {
            this.mButtonPlay.setVisible(true);
            this.mButtonResume.setVisible(false);
         }
      }
      
      private function addButton(param1:MovieClip, param2:String, param3:Function) : ArmyButton
      {
         var _loc4_:MovieClip = null;
         _loc4_ = param1.getChildByName(param2) as MovieClip;
         if(_loc4_ != null)
         {
            _loc4_.mouseEnabled = true;
            return new ArmyButton(param1,_loc4_,DCButton.BUTTON_TYPE_ICON,null,null,null,null,null,param3);
         }
         param3 = null;
         return null;
      }
      
      public function closePauseMenuAuto() : void
      {
         GameHUD.isPauseButtonClicked = false;
         if(MissionManager.isTutorialCompleted())
         {
            GameState.mInstance.changeState(GameState.STATE_PLAY);
         }
         else
         {
            ArmySoundManager.getInstance().stopSound(ArmySoundManager.MUSIC_HOME);
            GameState.mInstance.mHUD.openIntroTextBox();
         }
         mDoneCallback((this as Object).constructor);
      }
      
      public function onPermission(param1:PermissionEvent) : void
      {
         var _loc2_:File = param1.target as File;
         _loc2_.removeEventListener(PermissionEvent.PERMISSION_STATUS,this.onPermission);
         if(param1.status == PermissionStatus.GRANTED)
         {
            _loc2_.addEventListener(Event.SELECT,this.onFileSelected);
            // Only save files (.sav, as the save picker names them).
            _loc2_.browseForOpen("Select a save file",[new FileFilter("Army Attack saves (*.sav)","*.sav")]);
         }
      }
   }
}

