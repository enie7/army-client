package game.utils
{
   import flash.desktop.NativeApplication;
   import game.render.GpuTextures;
   import game.render.view.GpuArt;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.Stage;
   import flash.events.UncaughtErrorEvent;
   import flash.events.Event;
   import flash.events.InvokeEvent;
   import flash.filesystem.File;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.profiler.showRedrawRegions;
   import flash.sampler.NewObjectSample;
   import flash.sampler.clearSamples;
   import flash.sampler.getSamples;
   import flash.sampler.pauseSampling;
   import flash.sampler.startSampling;
   import flash.sampler.stopSampling;
   import flash.system.Capabilities;
   import flash.system.System;
   import flash.ui.Keyboard;
   import flash.utils.Dictionary;
   import flash.utils.getQualifiedClassName;
   import flash.utils.getTimer;
   import game.render.WorldRenderer;
   import game.utils.OfflineSave;
   import flash.events.TimerEvent;
   import flash.utils.Timer;
   import flash.text.TextFormat;
   import flash.text.TextField;
   import game.render.timeline.TimelineClip;
   import game.gui.PauseDialog;
   import game.isometric.GridCell;
   import game.isometric.characters.IsometricCharacter;
   import game.states.GameState;
   import game.gui.popups.PopUpManager;

   // Development aid: per-frame timing of named sections, summarised with
   // trace() and to <app storage>/profile.log every few seconds. Active in a
   // debugger runtime (adl), or in the packaged app when launched with
   // --profile (open "Army Attack.app" --args --profile); otherwise each call
   // is a single boolean check.
   //
   // Shift+L runs a layer test: each child of the root node (ground, world,
   // fog, effects, HUD...) is hidden in turn and the average frame time is
   // compared with a baseline, to see which layer the renderer spends time on.
   public class FrameProfiler
   {
      public static var ENABLED:Boolean = Capabilities.isDebugger;

      private static const REPORT_MS:int = 3000;

      private static const LAYER_PHASE_MS:int = 8000;

      private static var sLog:FileStream;

      private static var sShowRedraw:Boolean = false;

      private static var sExitTime:int = 0;

      private static var sConstructedTime:int = 0;

      private static var sEnterDone:int = 0;

      private static var sHandlers:int = 0;

      private static var sConstruct:int = 0;

      private static var sScripts:int = 0;

      private static var sAfterExit:int = 0;

      private static var sListening:Boolean = false;

      // Heap tracking: each drop in System.totalMemoryNumber is a collection.
      private static var sLastHeap:Number = 0;

      private static var sCollections:int = 0;

      private static var sAllocUntil:int = 0;

      private static var sAllocAt:int = 0;

      private static var sFreed:Number = 0;

      private static var sGrown:Number = 0;

      // Call once at startup.
      public static function init() : void
      {
         NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE,onInvoke);
      }

      // EXIT_FRAME fires after the frame's scripts and timeline updates, just
      // before the runtime renders; from then to the next frame is render+idle.
      private static function onExitFrame(event:Event) : void
      {
         sExitTime = getTimer();
         if(sConstructedTime > 0)
         {
            sScripts += sExitTime - sConstructedTime;
            sFrameScripts = sExitTime - sConstructedTime;
         }
      }

      // FRAME_CONSTRUCTED fires once every timeline has advanced and new
      // children were constructed, before frame scripts run.
      private static function onFrameConstructed(event:Event) : void
      {
         sConstructedTime = getTimer();
         if(sEnterDone > 0)
         {
            sConstruct += sConstructedTime - sEnterDone;
            sFrameConstruct = sConstructedTime - sEnterDone;
         }
      }

      // Call at the end of the game's ENTER_FRAME handler.
      public static function enterFrameDone() : void
      {
         if(ENABLED)
         {
            sEnterDone = getTimer();
            sHandlers += sEnterDone - sLastFrame;
            sFrameHandlers = sEnterDone - sLastFrame;
         }
      }

      private static function onInvoke(event:InvokeEvent) : void
      {
         NativeApplication.nativeApplication.removeEventListener(InvokeEvent.INVOKE,onInvoke);
         if(event.arguments.indexOf("--profile") >= 0)
         {
            ENABLED = true;
         }
         // --alloc-sample=N: sample allocations for 2s, N seconds after launch
         // (debugger runtime only; same as Shift+A, for when keys don't reach adl).
         for each(var arg:String in event.arguments)
         {
            // --fps: show the frame rate overlay (F3) from the start.
            if(arg == "--fps")
            {
               FpsCounter.showAtStart = true;
            }
            if(arg.indexOf("--alloc-sample=") == 0)
            {
               sAllocAt = getTimer() + int(arg.substr(15)) * 1000;
            }
            // --gallery=N: open the timeline gallery on page N at startup.
            if(arg.indexOf("--gallery=") == 0)
            {
               WorldRenderer.galleryAtStart = int(arg.substr(10));
            }
            // --gallery-shots=K: save K gallery pages as PNGs, then quit.
            if(arg.indexOf("--gallery-shots=") == 0)
            {
               WorldRenderer.galleryShots = int(arg.substr(16));
            }
            if(arg.indexOf("--autoload=") == 0)
            {
               PauseDialog.autoloadPath = arg.substr(11);
            }
            if(arg.indexOf("--freeze-stage=") == 0)
            {
               PauseDialog.freezeSeconds = int(arg.substr(15));
            }
            if(arg.indexOf("--autoquit=") == 0)
            {
               PauseDialog.autoquitSeconds = int(arg.substr(11));
            }
            if(arg == "--show-masks")
            {
               TimelineClip.showMasks = true;
            }
            if(arg == "--no-masks")
            {
               TimelineClip.masksOff = true;
            }
            if(arg.indexOf("--autoshot=") == 0)
            {
               PauseDialog.autoshotSeconds = int(arg.substr(11));
            }
            if(arg == "--autoplay")
            {
               PauseDialog.autoplay = true;
            }
            if(arg.indexOf("--autohover=") == 0)
            {
               PauseDialog.autohoverSeconds = int(arg.substr(12));
            }
            if(arg.indexOf("--autoclick=") == 0)
            {
               PauseDialog.autoclickSeconds = int(arg.substr(12));
            }
            if(arg.indexOf("--autobug=") == 0)
            {
               PauseDialog.autobugSeconds = int(arg.substr(10));
            }
            if(arg == "--autopan")
            {
               PauseDialog.autopan = true;
            }
            if(arg == "--autokey")
            {
               PauseDialog.autokey = true;
            }
            if(arg.indexOf("--leak-textures=") == 0)
            {
               PauseDialog.leakTexturesSeconds = int(arg.substr(16));
            }
            if(arg.indexOf("--compare-scale=") == 0)
            {
               PauseDialog.compareScale = Number(arg.substr(16));
            }
            else if(arg.indexOf("--compare=") == 0)
            {
               PauseDialog.compareSymbol = arg.substr(10);
            }
            if(arg == "--hide-hud")
            {
               PauseDialog.hideHud = true;
            }
            if(arg == "--texture-probe")
            {
               PauseDialog.textureProbe = true;
            }
            if(arg == "--no-texture-guards")
            {
               GpuTextures.guards = false;
            }
            if(arg == "--autoloot")
            {
               PauseDialog.autoloot = true;
            }
            if(arg == "--autowork")
            {
               PauseDialog.autowork = true;
            }
            if(arg.indexOf("--autoplace=") == 0)
            {
               PauseDialog.autoplace = arg.substr(12);
            }
            if(arg == "--gallery-hold")
            {
               WorldRenderer.galleryHold = true;
            }
         }
         if(ENABLED)
         {
            var file:File = File.applicationStorageDirectory.resolvePath("profile.log");
            sLog = new FileStream();
            sLog.open(file,FileMode.WRITE);
            log("profiling to " + file.nativePath + " (debugger=" + Capabilities.isDebugger + ")");
            // Errors nothing catches would otherwise vanish in the release
            // runtime: log them (with the stack, in the debugger).
            var main:DisplayObject = NativeApplication.nativeApplication.openedWindows.length ? NativeApplication.nativeApplication.openedWindows[0].stage.getChildAt(0) : null;
            if(main && main.loaderInfo)
            {
               main.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR,onUncaughtError);
            }
         }
      }

      private static var sBugReports:int = 0;

      // Everything needed to look at a moment the player says is broken, in
      // Documents/ArmyAttack/bug-reports/: a screenshot, the game saved as it
      // is (loadable with the load picker or --autoload), and in the profile
      // log a marker with the world census and the playing clips, to line up
      // with the frame timings around it.
      // What gates arrow-key and mouse scrolling right now.
      private static function describeInput() : String
      {
         var game:GameState = GameState.mInstance;
         if(game == null || game.mScene == null)
         {
            return "input: no scene";
         }
         var sc:Object = game.mScene;
         return "input: keys up " + sc.mUpPressed + " down " + sc.mDownPressed + " left " + sc.mLeftPressed + " right " + sc.mRightPressed + " anyKey " + sc.mAnyScrollKeyPressed + " | state " + game.mState + " modal " + PopUpManager.isModalPopupActive() + " current " + game.mCurrentAction + " queue " + game.mMainActionQueue.mActions.length + " | " + game.mScene.describeScrollState();
      }

      private static var sArrowsDown:Object = {};

      // Logs arrow presses and releases (not key repeats) with what gates
      // scrolling, to follow a scroll that does not happen.
      public static function arrowKey(keyCode:int, down:Boolean) : void
      {
         if(!ENABLED || keyCode < 37 || keyCode > 40 || Boolean(sArrowsDown[keyCode]) == down)
         {
            return;
         }
         sArrowsDown[keyCode] = down;
         mark("arrow " + keyCode + (down ? " down " : " up ") + describeInput());
      }

      public static function bugReport(stage:Stage) : void
      {
         var n:int = ++sBugReports;
         var stamp:String = new Date().getTime().toString();
         var dir:File = File.documentsDirectory.resolvePath("ArmyAttack/bug-reports");
         dir.createDirectory();
         var base:String = "bug-" + stamp + "-" + n;
         mark("BUG REPORT " + n + ": " + dir.nativePath + "/" + base);
         try
         {
            WorldRenderer.saveScreenshotTo(dir.resolvePath(base + ".png"));
         }
         catch(e:Error)
         {
            log("  screenshot failed: " + e);
         }
         try
         {
            var save:FileStream = new FileStream();
            save.open(dir.resolvePath(base + ".sav"),FileMode.WRITE);
            save.writeUTFBytes(JSON.stringify(OfflineSave.generateSaveJson()));
            save.close();
         }
         catch(e:Error)
         {
            log("  save failed: " + e);
         }
         try
         {
            mark(WorldRenderer.describeWorld());
            mark(GpuArt.atlas ? GpuArt.atlas.describeRoots() : "no atlas");
            mark(describeInput());
            if(stage)
            {
               listPlaying(stage);
            }
         }
         catch(e:Error)
         {
            log("  census failed: " + e);
         }
         if(stage)
         {
            var note:TextField = new TextField();
            note.defaultTextFormat = new TextFormat("_sans",14,0xffffff,true);
            note.background = true;
            note.backgroundColor = 0xaa0000;
            note.autoSize = "left";
            note.mouseEnabled = false;
            note.text = " Bug report " + n + " saved ";
            note.x = 10;
            note.y = stage.stageHeight - 40;
            stage.addChild(note);
            var hide:Timer = new Timer(2000,1);
            hide.addEventListener(TimerEvent.TIMER,function(event:TimerEvent):void
            {
               if(note.parent)
               {
                  note.parent.removeChild(note);
               }
            });
            hide.start();
         }
      }

      // A marker line in the profile log (e.g. when an automated run starts
      // playing), so runs can be cut into phases.
      public static function mark(text:String) : void
      {
         log("== " + text + " at " + getTimer() + "ms");
      }

      private static var sUncaught:int = 0;

      private static function onUncaughtError(event:UncaughtErrorEvent) : void
      {
         // The first few in full, then a count: they tend to repeat per frame.
         if(++sUncaught <= 5 || sUncaught % 200 == 0)
         {
            var error:Error = event.error as Error;
            log("UNCAUGHT ERROR #" + sUncaught + ": " + (error ? error + (error.getStackTrace() ? "\n" + error.getStackTrace() : "") : event.error));
         }
      }

      private static function log(line:String) : void
      {
         trace("[profile] " + line);
         if(sLog)
         {
            sLog.writeUTFBytes(line + "\n");
         }
      }

      private static var sStarts:Object = {};
      private static var sTotals:Object = {};
      private static var sCalls:Object = {};
      private static var sFrames:int = 0;
      private static var sLastFrame:int = 0;
      private static var sFrameTotal:int = 0;
      private static var sFrameMax:int = 0;

      // Frames over budget (40 fps = 25ms), and per frame what it spent:
      // logged as "hitch" lines so long frames can be told apart.
      private static const BUDGET_MS:int = 27;

      private static var sOver25:int = 0;

      private static var sOver33:int = 0;

      private static var sOver50:int = 0;

      private static var sFrameNamed:Object = {};

      private static var sFrameHandlers:int = 0;

      private static var sFrameConstruct:int = 0;

      private static var sFrameScripts:int = 0;

      private static var sHitchLines:int = 0;
      private static var sReportStart:int = 0;

      private static var sLayerRoot:DisplayObjectContainer;
      private static var sLayerPhase:int = -2;
      private static var sLayerPhaseStart:int = 0;
      private static var sLayerFrames:int = 0;
      private static var sLayerTime:int = 0;
      private static var sLayerResults:Array;

      public static function begin(name:String) : void
      {
         if(ENABLED)
         {
            sStarts[name] = getTimer();
         }
      }

      public static function end(name:String) : void
      {
         if(ENABLED && sStarts[name] != undefined)
         {
            var spent:int = getTimer() - sStarts[name];
            sTotals[name] = int(sTotals[name]) + spent;
            sFrameNamed[name] = int(sFrameNamed[name]) + spent;
            sCalls[name] = int(sCalls[name]) + 1;
            delete sStarts[name];
         }
      }

      public static function handleKey(keyCode:uint, shiftKey:Boolean, root:DisplayObjectContainer) : void
      {
         // Shift+B: bug report (screenshot, save, census) for "this looks broken".
         if(ENABLED && shiftKey && keyCode == Keyboard.B)
         {
            bugReport(root ? root.stage : null);
            return;
         }
         // Shift+R outlines what the renderer repaints each frame (debugger only).
         if(ENABLED && shiftKey && keyCode == Keyboard.R && Capabilities.isDebugger)
         {
            sShowRedraw = !sShowRedraw;
            showRedrawRegions(sShowRedraw,0xFF0000);
            log("redraw regions " + (sShowRedraw ? "on" : "off"));
            return;
         }
         if(ENABLED && shiftKey && keyCode == Keyboard.D && root != null && root.stage != null && sDirtyFramesLeft == 0)
         {
            sDirtyStage = root.stage;
            sDirtyState = new Dictionary(true);
            sDirtyCounts = new Dictionary(true);
            sDirtyFramesLeft = DIRTY_FRAMES;
            log("dirty-object scan started (" + DIRTY_FRAMES + " frames)");
            return;
         }
         if(ENABLED && shiftKey && keyCode == Keyboard.O)
         {
            WorldRenderer.offstage = !WorldRenderer.offstage;
            log("off-stage world " + (WorldRenderer.offstage ? "on" : "off"));
            return;
         }
         if(ENABLED && shiftKey && keyCode == Keyboard.A && Capabilities.isDebugger && sAllocUntil == 0)
         {
            // flash.sampler only works in a debugger runtime (adl).
            clearSamples();
            startSampling();
            sAllocUntil = getTimer() + 500;
            log("allocation sampling for 0.5s");
            return;
         }
         if(ENABLED && shiftKey && keyCode == Keyboard.G)
         {
            WorldRenderer.toggleGallery();
            return;
         }
         if(ENABLED && shiftKey && (keyCode == Keyboard.RIGHTBRACKET || keyCode == Keyboard.LEFTBRACKET))
         {
            WorldRenderer.pageGallery(keyCode == Keyboard.RIGHTBRACKET ? 1 : -1);
            return;
         }
         if(ENABLED && shiftKey && keyCode == Keyboard.I)
         {
            inspectUnderMouse();
            return;
         }
         if(ENABLED && shiftKey && keyCode == Keyboard.C && root != null)
         {
            census(root);
            return;
         }
         if(!ENABLED || root == null || keyCode != Keyboard.L || !shiftKey || sLayerPhase != -2)
         {
            return;
         }
         sLayerRoot = root;
         sLayerResults = [];
         sLayerPhase = -1;
         sLayerPhaseStart = getTimer();
         sLayerFrames = 0;
         sLayerTime = 0;
         log("layer test started: keep the camera still for " + (root.numChildren + 2) * LAYER_PHASE_MS / 1000 + "s");
      }

      // Count display objects and MovieClips (animated / currently playing)
      // under each root layer, hidden ones included: the runtime advances
      // every playing timeline each frame whether it is drawn or not.
      // The playing MovieClips under `root`: path, class, frames, children.
      public static function listPlaying(root:DisplayObjectContainer) : void
      {
         var out:Array = [];
         var walk:Function = function(o:DisplayObject, path:String):void
         {
            var mc:MovieClip = o as MovieClip;
            if(mc && mc.isPlaying)
            {
               out.push(path + " [" + getQualifiedClassName(mc) + "] frame " + mc.currentFrame + "/" + mc.totalFrames + ", " + mc.numChildren + " children");
            }
            var c:DisplayObjectContainer = o as DisplayObjectContainer;
            for(var i:int = 0; c && i < c.numChildren; i++)
            {
               var child:DisplayObject = c.getChildAt(i);
               walk(child,path + "/" + (child ? child.name : "?"));
            }
         };
         walk(root,root.name);
         log("playing clips under " + root.name + ": " + out.length);
         for each(var line:String in out.slice(0,25))
         {
            log("  " + line);
         }
      }

      public static function census(root:DisplayObjectContainer) : void
      {
         log("census of " + root.numChildren + " root layers (objects / MovieClips / multi-frame / playing):");
         for(var i:int = 0; i < root.numChildren; i++)
         {
            var c:Array = [0,0,0,0];
            countTree(root.getChildAt(i),c);
            var layer:DisplayObject = root.getChildAt(i);
            log("  " + i + " " + getQualifiedClassName(layer) + (layer.visible ? "" : " (hidden)") + ": " + c.join(" / "));
         }
      }

      private static function countTree(o:DisplayObject, c:Array) : void
      {
         if(o == null)
         {
            return;
         }
         c[0]++;
         var mc:MovieClip = o as MovieClip;
         if(mc != null)
         {
            c[1]++;
            if(mc.totalFrames > 1)
            {
               c[2]++;
            }
            if(mc.isPlaying)
            {
               c[3]++;
            }
         }
         var container:DisplayObjectContainer = o as DisplayObjectContainer;
         if(container != null)
         {
            for(var i:int = 0; i < container.numChildren; i++)
            {
               try
               {
                  countTree(container.getChildAt(i),c);
               }
               catch(e:Error)
               {
               }
            }
         }
      }

      // Summarise allocation samples (Shift+A): bytes by type, and by the
      // innermost game function on the allocating stack.
      private static function reportAllocations() : void
      {
         // Pause, not stop: stopSampling() discards what was collected.
         pauseSampling();
         var byType:Object = {};
         var bySite:Object = {};
         // Where new display objects live: the root of their tree (off the
         // display list, a clip that keeps playing builds children unseen).
         var byRoot:Object = {};
         var rootObjects:Object = {};
         // Where instances of exported art classes (not plain MovieClips)
         // are made, with a deeper stack.
         var bySymbolSite:Object = {};
         // CPU: periodic stack samples (plain Samples), by innermost frame and
         // by every frame on the stack (inclusive).
         var cpuSelf:Object = {};
         var cpuIncl:Object = {};
         var cpuCount:int = 0;
         var cpuStacks:Object = {};
         var total:Number = 0;
         var count:int = 0;
         for each(var sample:Object in getSamples())
         {
            var alloc:NewObjectSample = sample as NewObjectSample;
            if(alloc == null)
            {
               if(getQualifiedClassName(sample) == "flash.sampler::Sample" && sample.stack)
               {
                  ++cpuCount;
                  var seen:Object = {};
                  var chain:Array = [];
                  for(var g:int = 0; g < sample.stack.length && chain.length < 7; g++)
                  {
                     chain.push(String(sample.stack[g].name).replace("flash.display::",""));
                  }
                  var stackKey:String = chain.join(" < ");
                  cpuStacks[stackKey] = Number(cpuStacks[stackKey] || 0) + 1;
                  for(var f:int = 0; f < sample.stack.length; f++)
                  {
                     var fn:String = String(sample.stack[f].name);
                     if(f == 0)
                     {
                        cpuSelf[fn] = Number(cpuSelf[fn] || 0) + 1;
                     }
                     if(!seen[fn])
                     {
                        seen[fn] = true;
                        cpuIncl[fn] = Number(cpuIncl[fn] || 0) + 1;
                     }
                  }
               }
               continue;
            }
            var size:Number = alloc.size;
            total += size;
            ++count;
            var type:String = alloc.type ? getQualifiedClassName(alloc.type) : "?";
            byType[type] = Number(byType[type] || 0) + size;
            var site:String = "(no stack)";
            if(alloc.stack)
            {
               var frames:Array = [];
               for(var i:int = 0; i < alloc.stack.length && frames.length < 3; i++)
               {
                  var name:String = String(alloc.stack[i].name);
                  if(name.indexOf("flash.") != 0 && name.indexOf("FrameProfiler") < 0)
                  {
                     frames.push(name);
                  }
               }
               site = frames.join(" < ") || String(alloc.stack[0].name);
            }
            bySite[site] = Number(bySite[site] || 0) + size;
            if(type.indexOf("::") < 0 && type != "Object" && type != "Function" && type != "String" && type != "Array")
            {
               var deep:Array = [];
               for(var d:int = 0; alloc.stack && d < alloc.stack.length && deep.length < 8; d++)
               {
                  deep.push(String(alloc.stack[d].name).replace("flash.display::",""));
               }
               var symKey:String = type + " @ " + (deep.join(" < ") || "(no stack)");
               bySymbolSite[symKey] = Number(bySymbolSite[symKey] || 0) + 1;
            }
            var shown:DisplayObject = alloc.object as DisplayObject;
            if(shown)
            {
               var top:DisplayObject = shown;
               var below:DisplayObject = null;
               while(top.parent)
               {
                  below = top;
                  top = top.parent;
               }
               var key:String = (top.stage ? "on stage " : "off list ") + getQualifiedClassName(top) + " \"" + top.name + "\"" + (below ? " > " + getQualifiedClassName(below) + " \"" + below.name + "\"" : "");
               byRoot[key] = Number(byRoot[key] || 0) + size;
               var distinct:Dictionary = rootObjects[key] || (rootObjects[key] = new Dictionary(true));
               distinct[top] = true;
            }
         }
         stopSampling();
         clearSamples();
         log("allocations in 0.5s: " + count + " objects, " + (total / 1048576).toFixed(1) + "MB");
         logTop("  by type", byType, total);
         logTop("  by site", bySite, total);
         for(var rk:String in byRoot)
         {
            var n:int = 0;
            for(var ro:Object in rootObjects[rk])
            {
               ++n;
            }
            byRoot[rk + " x" + n + " roots"] = byRoot[rk];
            delete byRoot[rk];
         }
         logTop("  new display objects by tree root", byRoot, total);
         var symCount:Number = 0;
         for(var sk:String in bySymbolSite)
         {
            symCount += bySymbolSite[sk];
         }
         logTop("  art class instances by site (count)", bySymbolSite, symCount);
         log("cpu: " + cpuCount + " stack samples");
         logTop("  cpu by innermost frame", cpuSelf, cpuCount);
         logTop("  cpu inclusive", cpuIncl, cpuCount);
         logTop("  cpu stacks", cpuStacks, cpuCount);
      }

      private static function logTop(title:String, table:Object, total:Number) : void
      {
         var rows:Array = [];
         for(var key:String in table)
         {
            rows.push({"key":key,"bytes":table[key]});
         }
         rows.sortOn("bytes",Array.NUMERIC | Array.DESCENDING);
         log(title + ":");
         for(var i:int = 0; i < Math.min(15,rows.length); i++)
         {
            log("    " + (rows[i].bytes / 1048576).toFixed(2) + "MB (" + (100 * rows[i].bytes / total).toFixed(0) + "%) " + rows[i].key);
         }
      }

      // Log the unit on the cell under the mouse (Shift+I).
      private static function inspectUnderMouse() : void
      {
         var game:GameState = GameState.mInstance;
         if(game && game.mScene)
         {
            log("inspect " + game.mScene.describeScrollState());
         }
         var cell:GridCell = game && game.mScene ? game.mScene.getTileUnderMouse() : null;
         if(cell == null)
         {
            log("inspect: no cell under the mouse");
            return;
         }
         var unit:IsometricCharacter = cell.mCharacter as IsometricCharacter;
         log("inspect cell " + cell.mPosI + "," + cell.mPosJ + ": " + (unit ? unit.describeForDebug() : "no unit"));
      }

      private static function layerName(index:int) : String
      {
         var layer:DisplayObject = sLayerRoot.getChildAt(index);
         return index + " " + getQualifiedClassName(layer) + (layer.name ? " \"" + layer.name + "\"" : "");
      }

      private static function updateLayerTest(now:int, interval:int) : void
      {
         // Skip the first frame of each phase; it still renders the old state.
         if(now - sLayerPhaseStart > interval)
         {
            sLayerFrames++;
            sLayerTime += interval;
         }
         if(now - sLayerPhaseStart < LAYER_PHASE_MS)
         {
            return;
         }
         var avg:Number = sLayerFrames > 0 ? sLayerTime / sLayerFrames : 0;
         if(sLayerPhase >= 0 && sLayerPhase < sLayerRoot.numChildren)
         {
            sLayerRoot.getChildAt(sLayerPhase).visible = true;
         }
         sLayerResults.push(avg);
         sLayerPhase++;
         if(sLayerPhase > sLayerRoot.numChildren)
         {
            var n:int = sLayerRoot.numChildren;
            var base:Number = (sLayerResults[0] + sLayerResults[n + 1]) / 2;
            log("layer test: baseline " + sLayerResults[0].toFixed(1) + "ms/frame at start, " + sLayerResults[n + 1].toFixed(1) + "ms/frame at end");
            for(var i:int = 0; i < n; i++)
            {
               var hidden:Number = sLayerResults[i + 1];
               log("  hide " + layerName(i) + ": " + hidden.toFixed(1) + "ms/frame (saves " + (base - hidden).toFixed(1) + "ms, " + (100 * (base - hidden) / base).toFixed(0) + "%)");
            }
            sLayerPhase = -2;
            sLayerRoot = null;
            return;
         }
         if(sLayerPhase < sLayerRoot.numChildren)
         {
            sLayerRoot.getChildAt(sLayerPhase).visible = false;
         }
         sLayerPhaseStart = now;
         sLayerFrames = 0;
         sLayerTime = 0;
      }

      private static const DIRTY_FRAMES:int = 100;

      private static var sDirtyStage:Stage;
      private static var sDirtyState:Dictionary;
      private static var sDirtyCounts:Dictionary;
      private static var sDirtyFramesLeft:int = 0;

      // Record which display objects change from frame to frame; Flash
      // repaints their bounds, so large ones that change every frame force
      // big redraws.
      private static function scanDirty(node:DisplayObject) : void
      {
         if(node == null || !node.visible)
         {
            return;
         }
         // transform.matrix is null for objects positioned in 3D.
         var m:Matrix = node.transform.matrix;
         var sig:String = (m ? m.a + "," + m.b + "," + m.c + "," + m.d + "," + m.tx + "," + m.ty : "3d:" + node.x + "," + node.y + "," + node.z + "," + node.rotationX + "," + node.rotationY + "," + node.rotationZ) + "," + node.alpha;
         var mc:MovieClip = node as MovieClip;
         if(mc != null)
         {
            sig += "," + mc.currentFrame;
         }
         var bmp:Bitmap = node as Bitmap;
         if(bmp != null && bmp.bitmapData != null)
         {
            // Cheap content check: a few sampled pixels.
            var bd:BitmapData = bmp.bitmapData;
            sig += "," + bd.getPixel32(bd.width >> 1,bd.height >> 1) + "," + bd.getPixel32(bd.width >> 2,bd.height >> 2) + "," + bd.getPixel32(bd.width * 3 >> 2,bd.height * 3 >> 2);
         }
         if(sDirtyState[node] !== undefined && sDirtyState[node] != sig)
         {
            sDirtyCounts[node] = int(sDirtyCounts[node]) + 1;
         }
         sDirtyState[node] = sig;
         var container:DisplayObjectContainer = node as DisplayObjectContainer;
         if(container != null)
         {
            for(var i:int = 0; i < container.numChildren; i++)
            {
               try
               {
                  scanDirty(container.getChildAt(i));
               }
               catch(e:Error)
               {
                  // e.g. content from another security domain
               }
            }
         }
      }

      private static function pathOf(node:DisplayObject) : String
      {
         var parts:Array = [];
         for(var n:DisplayObject = node; n != null && n != sDirtyStage; n = n.parent)
         {
            parts.unshift(getQualifiedClassName(n).replace(/^.*::/,"") + (n.name && n.name.indexOf("instance") != 0 ? "(" + n.name + ")" : ""));
         }
         return parts.join(" > ");
      }

      private static function reportDirty() : void
      {
         var screenArea:Number = sDirtyStage.stageWidth * sDirtyStage.stageHeight;
         var rows:Array = [];
         for(var key:Object in sDirtyCounts)
         {
            var node:DisplayObject = key as DisplayObject;
            if(node.stage == null)
            {
               continue;
            }
            var r:Rectangle = node.getBounds(sDirtyStage).intersection(new Rectangle(0,0,sDirtyStage.stageWidth,sDirtyStage.stageHeight));
            var cover:Number = r.width * r.height / screenArea;
            rows.push({"node":node,"changes":sDirtyCounts[key],"cover":cover,"score":cover * sDirtyCounts[key]});
         }
         rows.sortOn("score",Array.NUMERIC | Array.DESCENDING);
         log("dirty-object scan: " + rows.length + " objects changed; largest by screen area x changes:");
         for(var i:int = 0; i < Math.min(15,rows.length); i++)
         {
            log("  " + rows[i].changes + "/" + DIRTY_FRAMES + " frames, covers " + (100 * rows[i].cover).toFixed(0) + "% of window: " + pathOf(rows[i].node));
         }
         sDirtyState = null;
         sDirtyCounts = null;
         sDirtyStage = null;
      }

      // Call once at the start of every frame.
      public static function frame(stage:Stage) : void
      {
         if(!ENABLED)
         {
            return;
         }
         var now:int = getTimer();
         var interval:int = 0;
         if(sLastFrame > 0)
         {
            interval = now - sLastFrame;
            sFrameTotal += interval;
            sFrameMax = Math.max(sFrameMax, interval);
            sFrames++;
         }
         sLastFrame = now;
         var heap:Number = System.totalMemoryNumber;
         var collected:Boolean = sLastHeap > 0 && heap < sLastHeap;
         if(interval > 25)
         {
            ++sOver25;
         }
         if(interval > 33)
         {
            ++sOver33;
         }
         if(interval > 50)
         {
            ++sOver50;
         }
         if(interval > BUDGET_MS && sHitchLines < 20)
         {
            ++sHitchLines;
            var hitch:String = "hitch " + interval + "ms: our ENTER_FRAME " + sFrameHandlers + " | timelines " + sFrameConstruct + " | scripts " + sFrameScripts + " | render+idle " + (sExitTime > 0 ? now - sExitTime : 0) + (collected ? " | GC" : "");
            for(var n:String in sFrameNamed)
            {
               if(sFrameNamed[n] > 0)
               {
                  hitch += " | " + n + " " + sFrameNamed[n];
               }
            }
            log(hitch);
         }
         sFrameNamed = {};
         sFrameHandlers = sFrameConstruct = sFrameScripts = 0;
         if(sLastHeap > 0)
         {
            if(heap < sLastHeap)
            {
               ++sCollections;
               sFreed += sLastHeap - heap;
            }
            else
            {
               sGrown += heap - sLastHeap;
            }
         }
         sLastHeap = heap;
         if(sAllocAt > 0 && now >= sAllocAt && Capabilities.isDebugger)
         {
            sAllocAt = 0;
            clearSamples();
            startSampling();
            sAllocUntil = now + 500;
            log("allocation sampling for 0.5s");
         }
         if(sAllocUntil > 0 && now >= sAllocUntil)
         {
            sAllocUntil = 0;
            reportAllocations();
         }
         if(!sListening && stage != null)
         {
            stage.addEventListener(Event.EXIT_FRAME,onExitFrame);
            stage.addEventListener(Event.FRAME_CONSTRUCTED,onFrameConstructed);
            sListening = true;
         }
         if(sExitTime > 0)
         {
            sAfterExit += now - sExitTime;
            sExitTime = 0;
         }
         if(sLayerPhase != -2)
         {
            updateLayerTest(now, interval);
         }
         if(sDirtyFramesLeft > 0)
         {
            scanDirty(sDirtyStage);
            if(--sDirtyFramesLeft == 0)
            {
               reportDirty();
            }
         }
         if(sReportStart == 0)
         {
            sReportStart = now;
         }
         if(now - sReportStart >= REPORT_MS && sFrames > 0)
         {
            var line:String = "fps " + (1000 * sFrames / (now - sReportStart)).toFixed(1) +
               " | frame avg " + (sFrameTotal / sFrames).toFixed(1) + "ms max " + sFrameMax + "ms" +
               " over 25/33/50ms " + sOver25 + "/" + sOver33 + "/" + sOver50;
            var script:Number = 0;
            for(var name:String in sTotals)
            {
               line += " | " + name + " " + (sTotals[name] / sFrames).toFixed(2) + "ms/f (" + sCalls[name] + "x)";
               if(name == "logic")
               {
                  script = sTotals[name] / sFrames;
               }
            }
            line += " || our ENTER_FRAME " + (sHandlers / sFrames).toFixed(1) + "ms | timelines " + (sConstruct / sFrames).toFixed(1) + "ms | frame scripts " + (sScripts / sFrames).toFixed(1) + "ms | render+idle " + (sAfterExit / sFrames).toFixed(1) + "ms || " + WorldRenderer.takeStats();
            log("  heap " + (heap / 1048576).toFixed(0) + "MB, allocated " + (sGrown / 1048576 / ((now - sReportStart) / 1000)).toFixed(1) + "MB/s, " + sCollections + " collections freeing " + (sFreed / 1048576).toFixed(0) + "MB, process " + (System.privateMemory / 1048576).toFixed(0) + "MB");
            sCollections = 0;
            sFreed = 0;
            sGrown = 0;
            sAfterExit = 0;
            sHandlers = 0;
            sConstruct = 0;
            sScripts = 0;
            log(line);
            sTotals = {};
            sCalls = {};
            sFrames = 0;
            sFrameTotal = 0;
            sFrameMax = 0;
            sOver25 = sOver33 = sOver50 = 0;
            sHitchLines = 0;
            sReportStart = now;
         }
      }
   }
}
