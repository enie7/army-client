package game.gui
{
   import com.dchoc.GUI.DCButton;
   import com.dchoc.graphics.DCResourceManager;
   import flash.display.MovieClip;
   import flash.events.*;
   import flash.filesystem.File;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.permissions.PermissionStatus;
   import game.gui.button.ArmyButton;
   import game.gui.popups.PopUpWindow;
   import game.missions.MissionManager;
   import game.sound.ArmySoundManager;
   import game.states.GameState;
   import game.utils.OfflineSave;
   import game.utils.FrameProfiler;
   import game.render.art.StopWhenDetached;
   import game.utils.TimelinePauser;
   import game.render.WorldRenderer;
   import flash.desktop.NativeApplication;
   import flash.utils.Timer;
   
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

      // --freeze-stage=N: N seconds after Play, stop every playing clip on the
      // stage (experiment: is per-frame construction from on-stage clips?).
      public static var freezeSeconds:int = 0;

      // --autokey: after Play, hold the left arrow for 2s (a synthetic key on
      // the stage) and log the camera before and after.
      public static var autokey:Boolean = false;

      public function Activate(param1:Function) : void
      {
         mDoneCallback = param1;
         doOpeningTransition();
         if(autoloadPath && mPauseScreenState == STATE_CONTINUE)
         {
            var path:String = autoloadPath;
            autoloadPath = null;
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
         var file:File = new File(path);
         var stream:FileStream = new FileStream();
         stream.open(file,FileMode.READ);
         var data:* = JSON.parse(stream.readUTFBytes(stream.bytesAvailable));
         stream.close();
         FrameProfiler.mark("autoload " + path);
         this.loadProgress(data);
         this.play();
         FrameProfiler.mark("autoload: playing");
         if(autokey)
         {
            var keyTimer:Timer = new Timer(10000,1);
            keyTimer.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
            {
               var stage:Object = GameState.mInstance.getMainClip().stage;
               var cam:Object = GameState.mInstance.mScene.mCamera;
               FrameProfiler.mark("autokey: left down, camera " + cam.getCameraX() + "," + cam.getCameraY() + " focus " + stage.focus);
               stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN,true,false,0,37));
               var up:Timer = new Timer(2000,1);
               up.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
               {
                  var sc:Object = GameState.mInstance.mScene;
                  FrameProfiler.mark("autokey: held: left " + sc.mLeftPressed + " mouseScrolling " + sc.mMouseScrolling + " anyKey " + sc.mAnyScrollKeyPressed + " target " + cam.getTargetX() + "," + cam.getTargetY() + " bounds " + cam.getBounds());
                  stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP,true,false,0,37));
                  FrameProfiler.mark("autokey: left up, camera " + cam.getCameraX() + "," + cam.getCameraY());
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
         _loc1_ = new File();
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
            _loc2_.browseForOpen("Select a file");
         }
      }
   }
}

