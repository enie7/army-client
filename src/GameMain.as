package
{
   import com.dchoc.graphics.DCResourceManager;
   import fi.joniaromaa.adobeair.discordrpc.DiscordRpc;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.FullScreenEvent;
   import flash.events.KeyboardEvent;
   import flash.utils.getTimer;
   import game.gui.popups.PopUpManager;
   import game.isometric.elements.Element;
   import game.net.ErrorObject;
   import game.utils.FrameProfiler;
   import game.render.WorldRenderer;
   import game.render.view.GpuArt;
   import flash.desktop.NativeApplication;
   import flash.events.InvokeEvent;
   import game.net.MyServer;
   import game.states.FSMState;
   import game.states.GameLoadingFirst;
   import game.states.GameLoadingSecond;
   import game.states.GameState;
   import game.states.StateMachine;
   
   public class GameMain extends Sprite
   {
      
      private var mGameTime:Number;
      
      private var mStateMachine:StateMachine;
      
      private var gameState:GameState;
      
      private var mLogicError:ErrorObject;
      
      private var secondLoading:FSMState;
      
      private var initialLoading:FSMState;
      
      private var RPC:* = {};
      
      private var messages:Array = [];
      
      private var messages_big:Array = [];
      
      private var discordRpc:DiscordRpc;
      
      public function GameMain()
      {
         this.RPC = {};
         this.messages = [];
         this.messages_big = [];
         super();
         FrameProfiler.init();
         NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE,this.onInvoke);
         this.runUnitTests();
         this.mStateMachine = new StateMachine(this);
         this.gameState = new GameState(this.mStateMachine);
         this.resetGame();
         addEventListener(Event.ENTER_FRAME,this.onEnterFrame,false,0,true);
         stage.addEventListener(KeyboardEvent.KEY_DOWN,this.keyDown,false,0,true);
         stage.addEventListener(KeyboardEvent.KEY_UP,this.keyUp,false,0,true);
         stage.addEventListener(Event.RESIZE,this.windowResized);
         stage.addEventListener(FullScreenEvent.FULL_SCREEN,this.windowResized);
         this.discordRpc = new DiscordRpc();
         this.setDiscordStatus({});
      }
      
      private function keyDown(param1:KeyboardEvent) : void
      {
         FrameProfiler.handleKey(param1.keyCode,param1.shiftKey,GameState.mInstance ? GameState.mInstance.mRootNode : null);
         this.gameState.keyDown(param1);
      }
      
      private function keyUp(param1:KeyboardEvent) : void
      {
         this.gameState.keyUp(param1);
      }
      
      private function windowResized(param1:Event) : void
      {
         this.gameState.reactToFullscreen();
      }
      
      // By default game logic runs once per frame with the measured delta, as
      // the game always did: much of it polls timeline frames (e.g. popups
      // close when their outro reaches its last frame), so it must see every
      // frame. --fixed-logic instead runs fixed 1/40 s steps, with time not yet
      // simulated carried over; frames that get no step miss those checks (a
      // tutorial prompt then never closes), so it is opt-in until the world no
      // longer depends on Flash timelines. After a long stall the rest is
      // simulated in one step, as the game always did.
      private static const LOGIC_STEP_MS:int = 25;

      private static const MAX_STEPS_PER_FRAME:int = 4;

      private static var sVariableLogic:Boolean = true;

      private function onEnterFrame(param1:Event) : void
      {
         FrameProfiler.frame(stage);
         var behind:int = getTimer() - this.mGameTime;
         var steps:int = 0;
         FrameProfiler.begin("logic");
         if(sVariableLogic)
         {
            if(behind > 0)
            {
               this.logicUpdate(behind);
               steps = 1;
            }
            behind = 0;
         }
         while(behind >= LOGIC_STEP_MS && steps < MAX_STEPS_PER_FRAME)
         {
            this.logicUpdate(LOGIC_STEP_MS);
            behind -= LOGIC_STEP_MS;
            ++steps;
         }
         if(behind >= LOGIC_STEP_MS)
         {
            this.logicUpdate(behind - behind % LOGIC_STEP_MS);
         }
         FrameProfiler.end("logic");
         WorldRenderer.init(stage);
         FrameProfiler.begin("gpu");
         WorldRenderer.update(this.mGameTime,steps > 0);
         FrameProfiler.end("gpu");
         FrameProfiler.enterFrameDone();
      }
      
      // --cpu-render keeps the whole game on the Flash renderer (for comparison).
      private function onInvoke(param1:InvokeEvent) : void
      {
         NativeApplication.nativeApplication.removeEventListener(InvokeEvent.INVOKE,this.onInvoke);
         if(param1.arguments.indexOf("--cpu-render") >= 0)
         {
            WorldRenderer.disabled = true;
         }
         // --flash-art keeps every world object on Flash art (static objects
         // are otherwise drawn by the GPU timeline player).
         if(param1.arguments.indexOf("--flash-art") >= 0)
         {
            GpuArt.flashOnly = true;
         }
         if(param1.arguments.indexOf("--fixed-logic") >= 0)
         {
            sVariableLogic = false;
         }
         // --render-hz=N: presentation rate of the GPU world (40 = once per Flash frame, no interpolation).
         for each(var arg:String in param1.arguments)
         {
            if(arg.indexOf("--render-hz=") == 0)
            {
               WorldRenderer.presentHz = int(arg.substr(12));
            }
         }
      }
      
      public function resetGame() : void
      {
         if(Config.RESTART_STATUS == 0)
         {
            Config.RESTART_STATUS = -1;
            PopUpManager.resetAllPopup();
            DCResourceManager.getInstance().unsetResources();
            this.gameState.removeNative();
         }
         this.mStateMachine = null;
         this.gameState = null;
         this.secondLoading = null;
         this.initialLoading = null;
         Element.counter = 0;
         GameState.needToUpdatePermanentHFE = false;
         GameState.mObjectCounter = 0;
         GameState.updateUserDataFlag = false;
         this.mStateMachine = new StateMachine(this);
         this.gameState = new GameState(this.mStateMachine);
         this.secondLoading = new GameLoadingSecond(this.mStateMachine,stage,this.gameState);
         this.initialLoading = new GameLoadingFirst(this.mStateMachine,stage,this.secondLoading,this.gameState);
         this.mStateMachine.changeState(this.initialLoading);
         this.mGameTime = getTimer();
      }
      
      private function logicUpdate(param1:int) : void
      {
         var server:MyServer = null;
         var errorType:String = null;
         var currentState:FSMState = null;
         var errorMessage:String = null;
         var codeStartIndex:int = 0;
         var errorService:String = null;
         var matchPattern:RegExp = null;
         var result:Array = null;
         var i:int = 0;
         var serviceIndex:int = 0;
         errorType = null;
         currentState = null;
         errorMessage = null;
         var errorCode:String = null;
         codeStartIndex = 0;
         errorService = null;
         matchPattern = null;
         result = null;
         i = 0;
         serviceIndex = 0;
         var deltaTime:int = param1;
         this.mGameTime += deltaTime;
         server = this.gameState.mServer;
         if(server)
         {
            server.update();
         }
         if(Config.USE_LOGIC_UPDATE_TRY_CATCH && !this.mLogicError)
         {
            try
            {
               this.mStateMachine.logicUpdate(deltaTime);
            }
            catch(e:Error)
            {
               try
               {
                  errorType = null;
                  currentState = mStateMachine.getCurrentState();
                  if(currentState is GameLoadingFirst)
                  {
                     errorType = "First Loading " + GameLoadingFirst(currentState).getLoadingPercent() + "%";
                  }
                  else if(currentState is GameLoadingSecond)
                  {
                     errorType = "Second Loading " + GameLoadingSecond(currentState).getLoadingPercent() + "%";
                  }
                  else if(currentState is GameState)
                  {
                     if(GameState.mInstance.mScene == null)
                     {
                        errorType = "CreatingScene";
                     }
                     else
                     {
                        errorType = "InGame";
                     }
                  }
                  errorMessage = null;
                  if(e.getStackTrace())
                  {
                     errorMessage = "Update exception:" + e + " \nST:" + e.getStackTrace() + " \nErrorType:" + errorType;
                  }
                  else
                  {
                     errorMessage = "Update exception:" + e + " \nST:null" + " \nName:" + e.name + " \nMessage:" + e.message + " \nErrorType:" + errorType;
                  }
                  if(errorType != "InGame")
                  {
                     errorMessage += "\n" + GameState.mInstance.getUserStateSummary();
                  }
                  errorCode = null;
                  codeStartIndex = -1;
                  if(e.getStackTrace() != null)
                  {
                     codeStartIndex = int(e.getStackTrace().indexOf("#"));
                  }
                  if(e.getStackTrace() != null && codeStartIndex > -1)
                  {
                     errorCode = String(e.getStackTrace().substr(codeStartIndex + 1,4));
                  }
                  errorService = null;
                  if(e.getStackTrace() != null)
                  {
                     matchPattern = /at(.*)\(\)/gi;
                     result = matchPattern.exec(e.getStackTrace());
                     i = 0;
                     while(result != null)
                     {
                        i++;
                        errorService = String(result[i]);
                        if(errorService.substr(0,5) != "flash")
                        {
                           result = null;
                        }
                        else
                        {
                           result = matchPattern.exec(e.getStackTrace());
                        }
                     }
                  }
                  if(errorService)
                  {
                     serviceIndex = int(errorService.indexOf("::"));
                     if(serviceIndex > -1)
                     {
                        errorService = errorService.substr(serviceIndex + 2);
                     }
                  }
               }
               catch(e:Error)
               {
               }
            }
         }
         else
         {
            this.mStateMachine.logicUpdate(deltaTime);
         }
      }
      
      public function runUnitTests() : void
      {
      }
      
      public function getRandomElementOf(param1:Array) : String
      {
         var _loc2_:int = Math.floor(Math.random() * param1.length);
         return param1[_loc2_];
      }
      
      private function setDiscordStatus(param1:Object) : void
      {
         var _loc2_:Date = null;
         var _loc3_:Number = NaN;
         var _loc4_:* = undefined;
         _loc2_ = null;
         _loc3_ = NaN;
         _loc4_ = undefined;
         _loc2_ = new Date();
         _loc3_ = Math.round(_loc2_.valueOf() / 1000);
         this.messages.push("Chilling on ");
         this.messages.push("Sleeping on ");
         this.messages.push("Fighting on ");
         this.messages.push("Attacking on ");
         this.messages.push("Killing tanks on ");
         this.messages.push("Shooting rockets on ");
         this.messages.push("Bullying Tubman on ");
         this.messages.push("Oops I hit my own ");
         this.messages.push("Stalking a Scout on ");
         this.messages.push("Cleaning Debris on ");
         this.messages_big.push("Destroying the Crimson Empire");
         this.messages_big.push("AYO THEY ADDED DESERT (hype)");
         this.messages_big.push("Bought 10.000.000 Gold");
         this.messages_big.push("\'Where did my water pack go????\'");
         this.messages_big.push("Playing the game in portrait mode");
         this.messages_big.push("NOOOO I forgot to save the game :(");
         this.messages_big.push("Playing a silly Facebook game");
         this.messages_big.push("Almost out of energy :(");
         this.messages_big.push("wait do they have a new version???");
         this.messages_big.push("OMG ARMY ATTACK I LOVED THIS GAME");
         this.messages_big.push("AAAAAAATTTTTTAAAAAAACK!!!!!!!!!");
         this.messages_big.push("Digital Chocolate = noobs");
         this.messages_big.push("Going crazy on Army Attack music");
         this.messages_big.push("rip i ran out of energy :(");
         this.messages_big.push("ayo does this game still exist???");
         this.messages_big.push("ABSOLUTELY NOT playing AA Reborn.");
         this.discordRpc.init("1232767781611634760");
         this.RPC.StartTime = _loc3_;
         this.RPC.State = this.getRandomElementOf(this.messages) + "Homeland";
         this.RPC.Details = this.getRandomElementOf(this.messages_big);
         this.RPC.LargeImage = "big_logo";
         this.RPC.LargeImageDescription = "Army Attack";
         this.RPC.SmallImage = null;
         this.RPC.SmallImageDescription = null;
         this.RPC.PartyId = null;
         this.RPC.PartySize = 0;
         this.RPC.PartyCape = 0;
         this.RPC.JoinSecret = null;
         this.RPC.SpectatorSecret = null;
         this.discordRpc.updatePresence(this.RPC.State,this.RPC.Details,this.RPC.StartTime,this.RPC.EndTime,this.RPC.LargeImage,this.RPC.LargeImageDescription,this.RPC.SmallImage,this.RPC.SmallImageDescription,this.RPC.PartyId,this.RPC.PartySize,this.RPC.PartyCape,this.RPC.JoinSecret,this.RPC.SpectatorSecret);
      }
      
      public function changeDiscordMap(param1:String) : void
      {
         this.RPC.State = this.getRandomElementOf(this.messages) + param1;
         this.RPC.Details = this.getRandomElementOf(this.messages_big);
         this.discordRpc.updatePresence(this.RPC.State,this.RPC.Details,this.RPC.StartTime,this.RPC.EndTime,this.RPC.LargeImage,this.RPC.LargeImageDescription,this.RPC.SmallImage,this.RPC.SmallImageDescription,this.RPC.PartyId,this.RPC.PartySize,this.RPC.PartyCape,this.RPC.JoinSecret,this.RPC.SpectatorSecret);
      }
   }
}

