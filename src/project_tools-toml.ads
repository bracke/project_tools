with Ada.Strings.Unbounded;

package Project_Tools.TOML is
   subtype Unbounded_String is Ada.Strings.Unbounded.Unbounded_String;

   type Natural_Parse_Status is
     (Parsed_Natural,
      Missing_Natural,
      Malformed_Natural);

   type Natural_Parse_Result is record
      Status : Natural_Parse_Status := Missing_Natural;
      Value  : Natural := 0;
   end record;

   type String_Parse_Status is
     (Parsed_String,
      Missing_String,
      Malformed_String);

   type String_Parse_Result is record
      Status : String_Parse_Status := Missing_String;
      Value  : Unbounded_String;
   end record;

   type Boolean_Parse_Status is
     (Parsed_Boolean,
      Missing_Boolean,
      Malformed_Boolean);

   type Boolean_Parse_Result is record
      Status : Boolean_Parse_Status := Missing_Boolean;
      Value  : Boolean := False;
   end record;

   function Parse_Natural_After
     (Text : String;
      Key  : String;
      From : Positive)
      return Natural_Parse_Result;
   --  Parse a natural value after Key at or after From.

   function Parse_String_After
     (Text : String;
      Key  : String;
      From : Positive)
      return String_Parse_Result;
   --  Parse a quoted string value after Key at or after From.

   function Parse_Boolean_After
     (Text : String;
      Key  : String;
      From : Positive)
      return Boolean_Parse_Result;
   --  Parse a TOML boolean value after Key at or after From.

   function Natural_Value_After
     (Text : String;
      Key  : String;
      From : Positive)
      return Natural;
   --  Return the parsed natural value, or 0 when missing or malformed.

   function String_Value_After
     (Text : String;
      Key  : String;
      From : Positive)
      return String;
   --  Return the parsed quoted string value, or "" when missing or malformed.

   function Quoted_Value_After
     (Text : String;
      Key  : String;
      From : Positive)
      return String renames String_Value_After;
   --  Backward-compatible name for simple quoted value lookups.

   generic
      with procedure Process (Entry_Pos : Positive);
   procedure Iterate_Section
     (Text    : String;
      Section : String);
   --  Iterate every `[[Section]]` entry position in Text.
end Project_Tools.TOML;
