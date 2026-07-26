
package Project_Tools.JSON is
   function Field_Value (Text : String; Field : String) return String;
   function Object_Field_Value (Text : String; Field : String) return String;
   function Array_First_Value (Text : String; Field : String) return String;

   function Find_Object_Field
     (Text        : String;
      Match_Field : String;
      Match_Value : String;
      Value_Field : String) return String;

   --  Call Process with the value of Field in each object of a top-level JSON
   --  array -- for example every "name" in a GitHub directory listing. Objects
   --  without Field, and non-object array items, are skipped; malformed input
   --  yields no calls.
   procedure For_Each_Array_Object_Field
     (Text    : String;
      Field   : String;
      Process : not null access procedure (Value : String));
end Project_Tools.JSON;
