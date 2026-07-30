
package Project_Tools.JSON is
   --  Reading a value out of JSON without parsing it into a tree. These are
   --  for check programs reading a known field out of a known shape -- a
   --  manifest, an API response -- not a general JSON reader. Anything not
   --  found is "" rather than an error, because a check has somewhere better
   --  to report that than an exception.

   function Field_Value (Text : String; Field : String) return String;
   --  @param Text JSON document.
   --  @param Field Field name to read.
   --  @return The field's value as written, or "" when it is not there.

   function Object_Field_Value (Text : String; Field : String) return String;
   --  @param Text JSON object.
   --  @param Field Field name to read.
   --  @return The field's value, or "" when the object does not carry it.

   function Array_First_Value (Text : String; Field : String) return String;
   --  @param Text JSON document holding an array.
   --  @param Field Field name to read from the array's first element.
   --  @return That value, or "" when the array is empty or lacks the field.

   function Find_Object_Field
     (Text        : String;
      Match_Field : String;
      Match_Value : String;
      Value_Field : String) return String;
   --  Find the object whose Match_Field equals Match_Value, and read
   --  Value_Field out of it.
   --  @param Text JSON document holding an array of objects.
   --  @param Match_Field Field to match on.
   --  @param Match_Value Value that field must have.
   --  @param Value_Field Field to read from the matching object.
   --  @return That value, or "" when no object matches.

   --  Call Process with the value of Field in each object of a top-level JSON
   --  array -- for example every "name" in a GitHub directory listing. Objects
   --  without Field, and non-object array items, are skipped; malformed input
   --  yields no calls.
   procedure For_Each_Array_Object_Field
     (Text    : String;
      Field   : String;
      Process : not null access procedure (Value : String));
   --  @param Text JSON document holding a top-level array.
   --  @param Field Field to read from each object in it.
   --  @param Process Called once per object that carries the field.
   --  @param Value The field's value for that object.
end Project_Tools.JSON;
