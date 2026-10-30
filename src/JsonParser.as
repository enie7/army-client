package
{
   public class JsonParser
   {
      
      private static const REFERENCE_TOKEN:String = "#";
      
      private static const REFERENCE_SEPARATOR:String = ".";
      
      private static const LIST_SEPARATOR:String = ",";
      
      public static const TEXTS_TABLE:String = "TID";
      
      public function JsonParser()
      {
         super();
      }
      
      public static function parseFile(param1:Object, param2:String) : void
      {
         var _loc3_:Object = null;
         var _loc4_:Object = null;
         var _loc5_:Object = null;
         var _loc6_:String = null;
         var _loc7_:Array = null;
         var _loc8_:Object = null;
         var _loc9_:RegExp = null;
         var _loc10_:Object = JSONWrapper.decode(param2);
         for(_loc3_ in _loc10_)
         {
            param1[_loc3_] = new Object();
            for(_loc4_ in _loc10_[_loc3_])
            {
               param1[_loc3_][_loc4_] = new Object();
               for(_loc5_ in _loc10_[_loc3_][_loc4_])
               {
                  _loc6_ = String(_loc10_[_loc3_][_loc4_][_loc5_]);
                  if(_loc6_ != null && _loc3_ != TEXTS_TABLE && _loc6_.search(LIST_SEPARATOR) != -1)
                  {
                     _loc7_ = _loc6_.split(LIST_SEPARATOR);
                     for(_loc8_ in _loc7_)
                     {
                        _loc7_[_loc8_] = trim(_loc7_[_loc8_]);
                     }
                     param1[_loc3_][_loc4_][_loc5_] = _loc7_;
                  }
                  else
                  {
                     if(_loc3_ == TEXTS_TABLE)
                     {
                        _loc9_ = /\\n/g;
                        _loc6_ = _loc6_.replace(_loc9_,"\n");
                     }
                     param1[_loc3_][_loc4_][_loc5_] = _loc6_;
                  }
               }
            }
         }
      }
      
      public static function link(param1:Object, param2:String) : void
      {
         var _loc3_:Object = null;
         var _loc4_:Object = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:Object = null;
         var _loc8_:Object = null;
         var _loc9_:Object = null;
         var _loc10_:Object = null;
         var _loc11_:Object = null;
         var _loc12_:Array = new Array();
         for(_loc3_ in param1)
         {
            for(_loc7_ in param1[_loc3_])
            {
               for(_loc8_ in param1[_loc3_][_loc7_])
               {
                  _loc9_ = param1[_loc3_][_loc7_][_loc8_];
                  if(_loc9_ is Array)
                  {
                     for(_loc10_ in _loc9_)
                     {
                        createLink(param1,param2,_loc12_,_loc9_[_loc10_] as String,_loc3_,_loc7_,_loc8_,_loc10_);
                     }
                  }
                  else
                  {
                     createLink(param1,param2,_loc12_,_loc9_ as String,_loc3_,_loc7_,_loc8_);
                  }
               }
            }
         }
         _loc5_ = int(_loc12_.length);
         _loc6_ = 0;
         while(_loc6_ < _loc5_)
         {
            _loc4_ = _loc12_[_loc6_] as Object;
            if(_loc4_.refFieldName)
            {
               _loc11_ = param1[_loc4_.refTableName][_loc4_.refRowName][_loc4_.refFieldName];
            }
            else if(_loc4_.refRowName)
            {
               _loc11_ = param1[_loc4_.refTableName][_loc4_.refRowName];
            }
            else
            {
               _loc11_ = param1[_loc4_.refTableName];
            }
            if(_loc4_.arrayIndex != null)
            {
               param1[_loc4_.tableName][_loc4_.rowName][_loc4_.fieldName][_loc4_.arrayIndex] = _loc11_;
            }
            else
            {
               param1[_loc4_.tableName][_loc4_.rowName][_loc4_.fieldName] = _loc11_;
            }
            _loc6_++;
         }
      }
      
      private static function createLink(param1:Object, param2:String, param3:Array, param4:String, param5:Object, param6:Object, param7:Object, param8:Object = null) : void
      {
         var _loc9_:Object = null;
         var _loc10_:Array = null;
         var _loc11_:String = null;
         var _loc12_:String = null;
         if(param4 != null)
         {
            param4 = trim(param4);
            _loc9_ = null;
            if(param4.charAt(0) == REFERENCE_TOKEN)
            {
               _loc10_ = param4.split(REFERENCE_SEPARATOR);
               if(_loc10_.length == 0 || _loc10_.length > 2)
               {
                  throw new Error("Invalid reference in " + param5 + " : " + param4);
               }
               _loc11_ = (_loc10_[0] as String).substring(1,(_loc10_[0] as String).length);
               if(param1[_loc11_] == null)
               {
                  throw new Error("Invalid reference in " + param5 + " : " + param4);
               }
               _loc9_ = new Object();
               _loc9_.refTableName = _loc11_;
               if(_loc10_.length == 2)
               {
                  _loc12_ = _loc10_[1] as String;
                  _loc9_.refRowName = _loc12_;
                  if(param1[_loc11_][_loc12_] == null)
                  {
                     throw new Error("Invalid reference in " + param5 + " : " + param4);
                  }
               }
               if(_loc11_ == TEXTS_TABLE)
               {
                  if(_loc10_.length != 2)
                  {
                     throw new Error("Invalid text reference in " + param5 + " : " + param4);
                  }
                  if(param1[TEXTS_TABLE][_loc12_][param2] == null || param1[TEXTS_TABLE][_loc12_][param2] == "")
                  {
                     throw new Error(_loc12_ + " is not defined in language " + param2);
                  }
                  _loc9_.refFieldName = param2;
               }
            }
            if(_loc9_)
            {
               _loc9_.tableName = param5;
               _loc9_.rowName = param6;
               _loc9_.fieldName = param7;
               _loc9_.arrayIndex = param8;
               param3.push(_loc9_);
            }
         }
      }
      
      public static function trim(param1:String) : String
      {
         var _loc2_:int = 0;
         while(param1.charCodeAt(_loc2_) < 33)
         {
            _loc2_++;
         }
         var _loc3_:* = int(param1.length - 1);
         while(param1.charCodeAt(_loc3_) < 33)
         {
            _loc3_--;
         }
         return param1.substring(_loc2_,_loc3_ + 1);
      }
   }
}

