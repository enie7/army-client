package game.utils
{
   import flash.desktop.NativeApplication;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.Stage;
   import flash.events.Event;
   import flash.events.InvokeEvent;
   import flash.filesystem.File;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.profiler.showRedrawRegions;
   import flash.system.Capabilities;
   import flash.ui.Keyboard;
   import flash.utils.Dictionary;
   import flash.utils.getQualifiedClassName;
   import flash.utils.getTimer;
   import game.render.WorldRenderer;

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
         }
      }

      // Call at the end of the game's ENTER_FRAME handler.
      public static function enterFrameDone() : void
      {
         if(ENABLED)
         {
            sEnterDone = getTimer();
            sHandlers += sEnterDone - sLastFrame;
         }
      }

      private static function onInvoke(event:InvokeEvent) : void
      {
         NativeApplication.nativeApplication.removeEventListener(InvokeEvent.INVOKE,onInvoke);
         if(event.arguments.indexOf("--profile") >= 0)
         {
            ENABLED = true;
         }
         if(ENABLED)
         {
            var file:File = File.applicationStorageDirectory.resolvePath("profile.log");
            sLog = new FileStream();
            sLog.open(file,FileMode.WRITE);
            log("profiling to " + file.nativePath + " (debugger=" + Capabilities.isDebugger + ")");
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
            sTotals[name] = int(sTotals[name]) + getTimer() - sStarts[name];
            sCalls[name] = int(sCalls[name]) + 1;
            delete sStarts[name];
         }
      }

      public static function handleKey(keyCode:uint, shiftKey:Boolean, root:DisplayObjectContainer) : void
      {
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
      private static function census(root:DisplayObjectContainer) : void
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
               " | frame avg " + (sFrameTotal / sFrames).toFixed(1) + "ms max " + sFrameMax + "ms";
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
            sReportStart = now;
         }
      }
   }
}
