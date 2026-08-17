with Ada.Strings.Unbounded;

--  Reading single values out of a TOML document, by scanning for a key.
--
--  Not a parser: these read one value at a time out of text a caller already
--  has, which is what a repository check wants when it is asking whether one
--  entry says what it should.
--
--  **A key may be given with or without its assignment.** `"version"`,
--  `"version ="` and `"version = "` all find the same value. That was not
--  always so, and the difference was silent: a caller that passed the bare key
--  got the `=` where a value was expected, every parser called that malformed,
--  and every convenience wrapper turned it into "" or zero. A check in Adash
--  compared the version in two files that way, read nothing out of either,
--  found the two nothings equal, and passed for years.
--
--  **The first occurrence that parses is the answer.** A key named in a
--  comment above its own entry is a normal thing to find, and a reader that
--  stopped at the first match would read the comment.
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
   --  @param Text TOML document to read.
   --  @param Key Key to look for, with or without its `=`.
   --  @param From Position to start looking at.
   --  @return The value and whether it was found and well formed.

   function Parse_String_After
     (Text : String;
      Key  : String;
      From : Positive)
      return String_Parse_Result;
   --  Parse a quoted string value after Key at or after From.
   --  @param Text TOML document to read.
   --  @param Key Key to look for, with or without its `=`.
   --  @param From Position to start looking at.
   --  @return The value and whether it was found and well formed.

   function Parse_Boolean_After
     (Text : String;
      Key  : String;
      From : Positive)
      return Boolean_Parse_Result;
   --  Parse a TOML boolean value after Key at or after From.
   --  @param Text TOML document to read.
   --  @param Key Key to look for, with or without its `=`.
   --  @param From Position to start looking at.
   --  @return The value and whether it was found and well formed.

   function Natural_Value_After
     (Text : String;
      Key  : String;
      From : Positive)
      return Natural;
   --  Return the parsed natural value, or 0 when missing or malformed.
   --  @param Text TOML document to read.
   --  @param Key Key to look for.
   --  @param From Position to start looking at.
   --  @return The value, or 0. A caller that must tell zero from absent
   --          wants Parse_Natural_After instead.

   function String_Value_After
     (Text : String;
      Key  : String;
      From : Positive)
      return String;
   --  Return the parsed quoted string value, or "" when missing or malformed.
   --  @param Text TOML document to read.
   --  @param Key Key to look for.
   --  @param From Position to start looking at.
   --  @return The value, or "".

   function Quoted_Value_After
     (Text : String;
      Key  : String;
      From : Positive)
      return String renames String_Value_After;
   --  Backward-compatible name for simple quoted value lookups.
   --  @param Text TOML document to read.
   --  @param Key Key to look for.
   --  @param From Position to start looking at.
   --  @return What String_Value_After returns.

   generic
      with procedure Process (Entry_Pos : Positive);
   procedure Iterate_Section
     (Text    : String;
      Section : String);
   --  Iterate every `[[Section]]` entry position in Text.
   --  @param Text TOML document to read.
   --  @param Section Section name, without the brackets.
   --  @param Entry_Pos Position of each entry, passed to Process.
end Project_Tools.TOML;
