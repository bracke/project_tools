with Ada.Strings.Unbounded;

package Project_Tools.JSON is
   function Field_Value (Text : String; Field : String) return String;
   function Object_Field_Value (Text : String; Field : String) return String;
   function Array_First_Value (Text : String; Field : String) return String;

   function Find_Object_Field
     (Text        : String;
      Match_Field : String;
      Match_Value : String;
      Value_Field : String) return String;
end Project_Tools.JSON;
