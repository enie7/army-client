package game.render.timeline
{
   import flash.filesystem.File;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;

   // Timelines of the world art, extracted from the release SWF at build time
   // (macos/tools/timelines.py -> timelines.json in the app). Sprites are keyed
   // by SWF character id; exported symbols map their class name to theirs.
   public class TimelineLibrary
   {
      private static var sInstance:TimelineLibrary;

      private var mSymbols:Object;

      private var mSprites:Object = {};

      private var mRawSprites:Object;

      private var mLeaves:Object;

      public function TimelineLibrary(data:Object)
      {
         super();
         this.mSymbols = data.symbols;
         this.mRawSprites = data.sprites;
         this.mLeaves = data.leaves;
      }

      // The library bundled with the app, or null when there is none.
      public static function get instance() : TimelineLibrary
      {
         if(sInstance == null)
         {
            var file:File = File.applicationDirectory.resolvePath("timelines.json");
            if(!file.exists)
            {
               return null;
            }
            var stream:FileStream = new FileStream();
            stream.open(file,FileMode.READ);
            var text:String = stream.readUTFBytes(stream.bytesAvailable);
            stream.close();
            sInstance = new TimelineLibrary(JSON.parse(text));
         }
         return sInstance;
      }

      // name -> id of every exported world symbol.
      public function get symbolNames() : Object
      {
         return this.mSymbols;
      }

      public function hasSymbol(name:String) : Boolean
      {
         return this.mSymbols[name] !== undefined;
      }

      public function symbolId(name:String) : int
      {
         var id:* = this.mSymbols[name];
         return id === undefined ? -1 : int(id);
      }

      // Parsed lazily: most sprites are never needed in a session.
      public function sprite(id:int) : SpriteDef
      {
         var def:SpriteDef = this.mSprites[id];
         if(def == null)
         {
            var raw:Object = this.mRawSprites[String(id)];
            if(raw == null)
            {
               return null;
            }
            def = new SpriteDef(id,raw);
            this.mSprites[id] = def;
         }
         return def;
      }

      public function isSprite(id:int) : Boolean
      {
         return this.mRawSprites[String(id)] !== undefined;
      }

      // {kind, path}: path[0] is an exported symbol name, then [frame, childIndex] steps.
      public function leaf(id:int) : Object
      {
         return this.mLeaves[String(id)];
      }
   }
}
