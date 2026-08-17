with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Project_Tools.TOML is

   --  Where the value after one occurrence of Key begins.
   --
   --  Two things every parser below needs and none of them used to do.
   --
   --  **The assignment is skipped.** A caller who passed `"version"` rather
   --  than `"version = "` got the character `=` where a value was expected,
   --  which each parser reported as malformed and each convenience wrapper
   --  turned into "" or zero. In Adash that made a check compare the version
   --  recorded in two files, read nothing out of either, find the two
   --  nothings equal and pass -- for years, including on runs made to prove
   --  it worked. The key is what a caller thinks of as the key; the `=`
   --  between it and its value is this package's business.
   --
   --  **An occurrence that does not parse is not the answer.** The word a
   --  caller is looking for appears in a comment above the entry in more than
   --  one file here, and the first match is that comment. Each parser walks
   --  occurrences until one yields a value, so a mention in prose costs
   --  nothing and a malformed entry is still reported when nothing else in
   --  the document answers.
   --
   --  @param Text The document.
   --  @param Key The key, with or without its assignment.
   --  @param From Where to start looking.
   --  @param Value Where the value starts, when this returns True.
   --  @param Next Where to resume looking afterwards.
   --  @return True when an occurrence was found with something after it.
   function Value_After
     (Text  : String;
      Key   : String;
      From  : Positive;
      Value : out Positive;
      Next  : out Positive) return Boolean;

   function Value_After
     (Text  : String;
      Key   : String;
      From  : Positive;
      Value : out Positive;
      Next  : out Positive) return Boolean
   is
      Key_Pos : constant Natural :=
        Ada.Strings.Fixed.Index (Text, Key, From => From);

      Tab : constant Character := Character'Val (9);
   begin
      Value := Text'First;
      Next  := Text'Last;

      if Key_Pos = 0 then
         return False;
      end if;

      Next := Positive'Min (Key_Pos + 1, Text'Last);

      declare
         First : Natural := Key_Pos + Key'Length;
      begin
         while First <= Text'Last
           and then (Text (First) = ' ' or else Text (First) = Tab)
         loop
            First := First + 1;
         end loop;

         --  At most one, because `==` is not TOML and a caller whose key
         --  already carried its `=` has none left here.
         if First <= Text'Last and then Text (First) = '=' then
            First := First + 1;

            while First <= Text'Last
              and then (Text (First) = ' ' or else Text (First) = Tab)
            loop
               First := First + 1;
            end loop;
         end if;

         if First > Text'Last then
            return False;
         end if;

         Value := First;
         return True;
      end;
   end Value_After;

   function Parse_Natural_After
     (Text : String;
      Key  : String;
      From : Positive)
      return Natural_Parse_Result
   is
      Cursor : Positive := From;
      First  : Positive;
      Next   : Positive;

      Found_One : Boolean := False;
   begin
      while Value_After (Text, Key, Cursor, First, Next) loop
         Found_One := True;
         Cursor := Next;

         declare
            Last : Natural := First;
         begin
            while Last <= Text'Last and then Text (Last) in '0' .. '9' loop
               Last := Last + 1;
            end loop;

            if Last > First then
               return
                 (Status => Parsed_Natural,
                  Value  => Natural'Value (Text (First .. Last - 1)));
            end if;
         end;
      end loop;

      if Found_One then
         return (Status => Malformed_Natural, Value => 0);
      end if;

      return (Status => Missing_Natural, Value => 0);
   exception
      when Constraint_Error =>
         return (Status => Malformed_Natural, Value => 0);
   end Parse_Natural_After;

   function Parse_String_After
     (Text : String;
      Key  : String;
      From : Positive)
      return String_Parse_Result
   is
      Cursor : Positive := From;
      First  : Positive;
      Next   : Positive;

      Found_One : Boolean := False;
   begin
      while Value_After (Text, Key, Cursor, First, Next) loop
         Found_One := True;
         Cursor := Next;

         if Text (First) = '"' or else Text (First) = ''' then
            declare
               Quote : constant Character := Text (First);
               Last  : constant Natural :=
                 Ada.Strings.Fixed.Index
                   (Text, String'(1 => Quote), From => First + 1);
            begin
               if Last > First + 1 then
                  return
                    (Status => Parsed_String,
                     Value  =>
                       To_Unbounded_String (Text (First + 1 .. Last - 1)));
               end if;
            end;
         end if;
      end loop;

      if Found_One then
         return (Status => Malformed_String, Value => Null_Unbounded_String);
      end if;

      return (Status => Missing_String, Value => Null_Unbounded_String);
   exception
      when Constraint_Error =>
         return (Status => Malformed_String, Value => Null_Unbounded_String);
   end Parse_String_After;

   function Parse_Boolean_After
     (Text : String;
      Key  : String;
      From : Positive)
      return Boolean_Parse_Result
   is
      Cursor : Positive := From;
      First  : Positive;
      Next   : Positive;

      Found_One : Boolean := False;
   begin
      while Value_After (Text, Key, Cursor, First, Next) loop
         Found_One := True;
         Cursor := Next;

         if First + 3 <= Text'Last
           and then Text (First .. First + 3) = "true"
         then
            return (Status => Parsed_Boolean, Value => True);

         elsif First + 4 <= Text'Last
           and then Text (First .. First + 4) = "false"
         then
            return (Status => Parsed_Boolean, Value => False);
         end if;
      end loop;

      if Found_One then
         return (Status => Malformed_Boolean, Value => False);
      end if;

      return (Status => Missing_Boolean, Value => False);
   exception
      when Constraint_Error =>
         return (Status => Malformed_Boolean, Value => False);
   end Parse_Boolean_After;

   function Natural_Value_After
     (Text : String;
      Key  : String;
      From : Positive)
      return Natural
   is
      Parsed : constant Natural_Parse_Result :=
        Parse_Natural_After (Text, Key, From);
   begin
      if Parsed.Status = Parsed_Natural then
         return Parsed.Value;
      else
         return 0;
      end if;
   end Natural_Value_After;

   function String_Value_After
     (Text : String;
      Key  : String;
      From : Positive)
      return String
   is
      Parsed : constant String_Parse_Result :=
        Parse_String_After (Text, Key, From);
   begin
      if Parsed.Status = Parsed_String then
         return To_String (Parsed.Value);
      else
         return "";
      end if;
   end String_Value_After;

   procedure Iterate_Section
     (Text    : String;
      Section : String)
   is
      Marker   : constant String := "[[" & Section & "]]";
      Position : Positive := Text'First;
   begin
      if Text = "" or else Section = "" then
         return;
      end if;

      loop
         declare
            Entry_Pos : constant Natural :=
              Ada.Strings.Fixed.Index (Text, Marker, From => Position);
         begin
            exit when Entry_Pos = 0;
            Process (Entry_Pos);

            exit when Entry_Pos = Text'Last;
            Position := Entry_Pos + 1;
         end;
      end loop;
   end Iterate_Section;
end Project_Tools.TOML;
