with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Project_Tools.TOML is
   function Parse_Natural_After
     (Text : String;
      Key  : String;
      From : Positive)
      return Natural_Parse_Result
   is
      Key_Pos : constant Natural :=
        Ada.Strings.Fixed.Index (Text, Key, From => From);
   begin
      if Key_Pos = 0 then
         return (Status => Missing_Natural, Value => 0);
      end if;

      declare
         First : Natural := Key_Pos + Key'Length;
         Last  : Natural := First;
      begin
         while First <= Text'Last and then Text (First) = ' ' loop
            First := First + 1;
         end loop;

         Last := First;
         while Last <= Text'Last and then Text (Last) in '0' .. '9' loop
            Last := Last + 1;
         end loop;

         if Last = First then
            return (Status => Malformed_Natural, Value => 0);
         else
            return
              (Status => Parsed_Natural,
               Value  => Natural'Value (Text (First .. Last - 1)));
         end if;
      end;
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
      Key_Pos : constant Natural :=
        Ada.Strings.Fixed.Index (Text, Key, From => From);
   begin
      if Key_Pos = 0 then
         return (Status => Missing_String, Value => Null_Unbounded_String);
      end if;

      declare
         First : Natural := Key_Pos + Key'Length;
      begin
         while First <= Text'Last and then Text (First) = ' ' loop
            First := First + 1;
         end loop;

         if First > Text'Last
           or else (Text (First) /= '"' and then Text (First) /= ''')
         then
            return (Status => Malformed_String, Value => Null_Unbounded_String);
         end if;

         declare
            Quote : constant Character := Text (First);
            Last  : constant Natural :=
              Ada.Strings.Fixed.Index
                (Text, String'(1 => Quote), From => First + 1);
         begin
            if Last = 0 or else Last = First + 1 then
               return
                 (Status => Malformed_String, Value => Null_Unbounded_String);
            end if;

            return
              (Status => Parsed_String,
               Value  => To_Unbounded_String (Text (First + 1 .. Last - 1)));
         end;
      end;
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
      Key_Pos : constant Natural :=
        Ada.Strings.Fixed.Index (Text, Key, From => From);
   begin
      if Key_Pos = 0 then
         return (Status => Missing_Boolean, Value => False);
      end if;

      declare
         First : Natural := Key_Pos + Key'Length;
      begin
         while First <= Text'Last and then Text (First) = ' ' loop
            First := First + 1;
         end loop;

         if First + 3 <= Text'Last
           and then Text (First .. First + 3) = "true"
         then
            return (Status => Parsed_Boolean, Value => True);
         elsif First + 4 <= Text'Last
           and then Text (First .. First + 4) = "false"
         then
            return (Status => Parsed_Boolean, Value => False);
         else
            return (Status => Malformed_Boolean, Value => False);
         end if;
      end;
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
