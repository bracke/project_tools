with Ada.Strings.Unbounded;
with Ada.Characters.Latin_1;

package body Project_Tools.JSON is
   use Ada.Strings.Unbounded;

   type Value_Kind is
     (Missing, String_Value, Number_Value, Boolean_Value, Null_Value,
      Object_Value, Array_Value, Other_Value);

   procedure Skip_WS (Text : String; Pos : in out Natural) is
   begin
      while Pos <= Text'Last
        and then Text (Pos) in ' ' | Ada.Characters.Latin_1.HT |
          Ada.Characters.Latin_1.CR | Ada.Characters.Latin_1.LF
      loop
         Pos := Pos + 1;
      end loop;
   end Skip_WS;

   function Parse_String (Text : String; Pos : in out Natural) return String is
      Result : Unbounded_String;
      Hex_Code : Natural;
   begin
      if Pos > Text'Last or else Text (Pos) /= '"' then
         return "";
      end if;
      Pos := Pos + 1;
      while Pos <= Text'Last loop
         if Text (Pos) = '"' then
            Pos := Pos + 1;
            return To_String (Result);
         elsif Text (Pos) = '\' then
            Pos := Pos + 1;
            exit when Pos > Text'Last;
            case Text (Pos) is
               when '"' | '\' | '/' =>
                  Append (Result, Text (Pos));
               when 'b' =>
                  Append (Result, Ada.Characters.Latin_1.BS);
               when 't' =>
                  Append (Result, Ada.Characters.Latin_1.HT);
               when 'n' =>
                  Append (Result, Ada.Characters.Latin_1.LF);
               when 'f' =>
                  Append (Result, Ada.Characters.Latin_1.FF);
               when 'r' =>
                  Append (Result, Ada.Characters.Latin_1.CR);
               when 'u' =>
                  Hex_Code := 0;
                  for Offset in 1 .. 4 loop
                     exit when Pos + Offset > Text'Last;
                     declare
                        Ch : constant Character := Text (Pos + Offset);
                     begin
                        Hex_Code := Hex_Code * 16 +
                          (if Ch in '0' .. '9' then Character'Pos (Ch) - Character'Pos ('0')
                           elsif Ch in 'A' .. 'F' then 10 + Character'Pos (Ch) - Character'Pos ('A')
                           elsif Ch in 'a' .. 'f' then 10 + Character'Pos (Ch) - Character'Pos ('a')
                           else 0);
                     end;
                  end loop;
                  if Hex_Code <= 255 then
                     Append (Result, Character'Val (Hex_Code));
                  end if;
                  Pos := Natural'Min (Text'Last, Pos + 4);
               when others =>
                  Append (Result, Text (Pos));
            end case;
         else
            Append (Result, Text (Pos));
         end if;
         Pos := Pos + 1;
      end loop;
      return To_String (Result);
   exception
      when others =>
         return To_String (Result);
   end Parse_String;

   procedure Value_Slice
     (Text  : String;
      Pos   : in out Natural;
      First : out Natural;
      Last  : out Natural;
      Kind  : out Value_Kind)
   is
      Depth : Natural := 0;
   begin
      First := 0;
      Last := 0;
      Kind := Missing;
      Skip_WS (Text, Pos);
      if Pos > Text'Last then
         return;
      end if;
      First := Pos;
      case Text (Pos) is
         when '"' =>
            Kind := String_Value;
            declare
               Ignored : constant String := Parse_String (Text, Pos);
            begin
               null;
            end;
            Last := Pos - 1;
         when '{' =>
            Kind := Object_Value;
            while Pos <= Text'Last loop
               if Text (Pos) = '"' then
                  declare
                     Ignored : constant String := Parse_String (Text, Pos);
                  begin
                     null;
                  end;
               elsif Text (Pos) = '{' then
                  Depth := Depth + 1;
                  Pos := Pos + 1;
               elsif Text (Pos) = '}' then
                  Depth := Depth - 1;
                  Pos := Pos + 1;
                  if Depth = 0 then
                     Last := Pos - 1;
                     return;
                  end if;
               else
                  Pos := Pos + 1;
               end if;
            end loop;
            Last := Text'Last;
            Pos := Text'Last + 1;
         when '[' =>
            Kind := Array_Value;
            while Pos <= Text'Last loop
               if Text (Pos) = '"' then
                  declare
                     Ignored : constant String := Parse_String (Text, Pos);
                  begin
                     null;
                  end;
               elsif Text (Pos) = '[' then
                  Depth := Depth + 1;
                  Pos := Pos + 1;
               elsif Text (Pos) = ']' then
                  Depth := Depth - 1;
                  Pos := Pos + 1;
                  if Depth = 0 then
                     Last := Pos - 1;
                     return;
                  end if;
               else
                  Pos := Pos + 1;
               end if;
            end loop;
            Last := Text'Last;
            Pos := Text'Last + 1;
         when '0' .. '9' | '-' =>
            Kind := Number_Value;
            Pos := Pos + 1;
            while Pos <= Text'Last
              and then Text (Pos) in '0' .. '9' | '.' | 'e' | 'E' | '+' | '-'
            loop
               Pos := Pos + 1;
            end loop;
            Last := Pos - 1;
         when 't' | 'f' =>
            Kind := Boolean_Value;
            Pos := Pos + 1;
            while Pos <= Text'Last and then Text (Pos) in 'a' .. 'z' loop
               Pos := Pos + 1;
            end loop;
            Last := Pos - 1;
         when 'n' =>
            Kind := Null_Value;
            Pos := Pos + 1;
            while Pos <= Text'Last and then Text (Pos) in 'a' .. 'z' loop
               Pos := Pos + 1;
            end loop;
            Last := Pos - 1;
         when others =>
            Kind := Other_Value;
            Pos := Pos + 1;
            while Pos <= Text'Last and then Text (Pos) not in ',' | '}' | ']' loop
               Pos := Pos + 1;
            end loop;
            Last := Pos - 1;
      end case;
   exception
      when others =>
         First := 0;
         Last := 0;
         Kind := Missing;
   end Value_Slice;

   procedure Field_Slice
     (Text  : String;
      Field : String;
      First : out Natural;
      Last  : out Natural;
      Kind  : out Value_Kind)
   is
      Pos : Natural := Text'First;
      Key : Unbounded_String;
      Value_First : Natural;
      Value_Last  : Natural;
      Parsed_Kind  : Value_Kind;
   begin
      First := 0;
      Last := 0;
      Kind := Missing;
      Skip_WS (Text, Pos);
      if Pos > Text'Last or else Text (Pos) /= '{' then
         return;
      end if;
      Pos := Pos + 1;
      loop
         Skip_WS (Text, Pos);
         exit when Pos > Text'Last or else Text (Pos) = '}';
         if Text (Pos) /= '"' then
            return;
         end if;
         Key := To_Unbounded_String (Parse_String (Text, Pos));
         Skip_WS (Text, Pos);
         if Pos > Text'Last or else Text (Pos) /= ':' then
            return;
         end if;
         Pos := Pos + 1;
         Value_Slice (Text, Pos, Value_First, Value_Last, Parsed_Kind);
         if To_String (Key) = Field then
            First := Value_First;
            Last := Value_Last;
            Kind := Parsed_Kind;
            return;
         end if;
         Skip_WS (Text, Pos);
         exit when Pos > Text'Last or else Text (Pos) /= ',';
         Pos := Pos + 1;
      end loop;
   exception
      when others =>
         First := 0;
         Last := 0;
         Kind := Missing;
   end Field_Slice;

   function Value_Text
     (Text  : String;
      First : Natural;
      Last  : Natural;
      Kind  : Value_Kind) return String
   is
      Pos : Natural := First;
   begin
      if First = 0 or else Last < First or else Last > Text'Last then
         return "";
      elsif Kind = String_Value then
         return Parse_String (Text, Pos);
      else
         return Text (First .. Last);
      end if;
   exception
      when others =>
         return "";
   end Value_Text;

   function Object_Field_Value (Text : String; Field : String) return String is
      First : Natural;
      Last  : Natural;
      Kind  : Value_Kind;
   begin
      Field_Slice (Text, Field, First, Last, Kind);
      return Value_Text (Text, First, Last, Kind);
   end Object_Field_Value;

   function Field_Value (Text : String; Field : String) return String is
      function Scan_Value (Fragment : String; First : Natural; Last : Natural) return String;

      function Scan_Object (Fragment : String) return String is
         Pos : Natural := Fragment'First;
         Value_First : Natural;
         Value_Last  : Natural;
         Parsed_Kind  : Value_Kind;
         Direct      : constant String := Object_Field_Value (Fragment, Field);
      begin
         if Direct'Length > 0 then
            return Direct;
         end if;
         Skip_WS (Fragment, Pos);
         if Pos > Fragment'Last or else Fragment (Pos) /= '{' then
            return "";
         end if;
         Pos := Pos + 1;
         loop
            Skip_WS (Fragment, Pos);
            exit when Pos > Fragment'Last or else Fragment (Pos) = '}';
            if Fragment (Pos) /= '"' then
               return "";
            end if;
            declare
               Ignored_Key : constant String := Parse_String (Fragment, Pos);
            begin
               null;
            end;
            Skip_WS (Fragment, Pos);
            exit when Pos > Fragment'Last or else Fragment (Pos) /= ':';
            Pos := Pos + 1;
            Value_Slice (Fragment, Pos, Value_First, Value_Last, Parsed_Kind);
            declare
               Found : constant String := Scan_Value (Fragment, Value_First, Value_Last);
            begin
               if Found'Length > 0 then
                  return Found;
               end if;
            end;
            Skip_WS (Fragment, Pos);
            exit when Pos > Fragment'Last or else Fragment (Pos) /= ',';
            Pos := Pos + 1;
         end loop;
         return "";
      end Scan_Object;

      function Scan_Array (Fragment : String) return String is
         Pos : Natural := Fragment'First + 1;
         Item_First : Natural;
         Item_Last  : Natural;
         Item_Kind  : Value_Kind;
      begin
         while Pos <= Fragment'Last loop
            Skip_WS (Fragment, Pos);
            exit when Pos > Fragment'Last or else Fragment (Pos) = ']';
            Value_Slice (Fragment, Pos, Item_First, Item_Last, Item_Kind);
            declare
               Found : constant String := Scan_Value (Fragment, Item_First, Item_Last);
            begin
               if Found'Length > 0 then
                  return Found;
               end if;
            end;
            Skip_WS (Fragment, Pos);
            exit when Pos > Fragment'Last or else Fragment (Pos) /= ',';
            Pos := Pos + 1;
         end loop;
         return "";
      end Scan_Array;

      function Scan_Value (Fragment : String; First : Natural; Last : Natural) return String is
      begin
         if First = 0 or else Last < First or else Last > Fragment'Last then
            return "";
         elsif Fragment (First) = '{' then
            return Scan_Object (Fragment (First .. Last));
         elsif Fragment (First) = '[' then
            return Scan_Array (Fragment (First .. Last));
         end if;
         return "";
      end Scan_Value;
   begin
      return Scan_Value (Text, Text'First, Text'Last);
   exception
      when others =>
         return "";
   end Field_Value;

   function Array_First_Value (Text : String; Field : String) return String is
      First : Natural;
      Last  : Natural;
      Kind  : Value_Kind;
      Pos   : Natural;
      Value_First : Natural;
      Value_Last  : Natural;
      Parsed_Kind  : Value_Kind;
   begin
      Field_Slice (Text, Field, First, Last, Kind);
      if Kind /= Array_Value or else First + 1 > Last then
         return "";
      end if;
      Pos := First + 1;
      Value_Slice (Text, Pos, Value_First, Value_Last, Parsed_Kind);
      if Parsed_Kind in String_Value | Number_Value | Boolean_Value then
         return Value_Text (Text, Value_First, Value_Last, Parsed_Kind);
      end if;
      return "";
   exception
      when others =>
         return "";
   end Array_First_Value;

   function Find_Object_Field
     (Text        : String;
      Match_Field : String;
      Match_Value : String;
      Value_Field : String) return String
   is
      function Scan_Value (Fragment : String; First : Natural; Last : Natural) return String;

      function Scan_Object (Fragment : String) return String is
         Pos : Natural := Fragment'First;
         Field_First : Natural;
         Field_Last  : Natural;
         Field_Kind  : Value_Kind;
         Candidate   : constant String := Object_Field_Value (Fragment, Value_Field);
      begin
         if Object_Field_Value (Fragment, Match_Field) = Match_Value
           and then Object_Field_Value (Fragment, "isfolder") = "false"
           and then Candidate'Length > 0
         then
            return Candidate;
         end if;

         Skip_WS (Fragment, Pos);
         if Pos > Fragment'Last or else Fragment (Pos) /= '{' then
            return "";
         end if;
         Pos := Pos + 1;
         loop
            Skip_WS (Fragment, Pos);
            exit when Pos > Fragment'Last or else Fragment (Pos) = '}';
            if Fragment (Pos) /= '"' then
               return "";
            end if;
            declare
               Ignored_Key : constant String := Parse_String (Fragment, Pos);
            begin
               null;
            end;
            Skip_WS (Fragment, Pos);
            exit when Pos > Fragment'Last or else Fragment (Pos) /= ':';
            Pos := Pos + 1;
            Value_Slice (Fragment, Pos, Field_First, Field_Last, Field_Kind);
            declare
               Found : constant String := Scan_Value (Fragment, Field_First, Field_Last);
            begin
               if Found'Length > 0 then
                  return Found;
               end if;
            end;
            Skip_WS (Fragment, Pos);
            exit when Pos > Fragment'Last or else Fragment (Pos) /= ',';
            Pos := Pos + 1;
         end loop;
         return "";
      end Scan_Object;

      function Scan_Array (Fragment : String) return String is
         Pos : Natural := Fragment'First + 1;
         Item_First : Natural;
         Item_Last  : Natural;
         Item_Kind  : Value_Kind;
      begin
         while Pos <= Fragment'Last loop
            Skip_WS (Fragment, Pos);
            exit when Pos > Fragment'Last or else Fragment (Pos) = ']';
            Value_Slice (Fragment, Pos, Item_First, Item_Last, Item_Kind);
            declare
               Found : constant String := Scan_Value (Fragment, Item_First, Item_Last);
            begin
               if Found'Length > 0 then
                  return Found;
               end if;
            end;
            Skip_WS (Fragment, Pos);
            exit when Pos > Fragment'Last or else Fragment (Pos) /= ',';
            Pos := Pos + 1;
         end loop;
         return "";
      end Scan_Array;

      function Scan_Value (Fragment : String; First : Natural; Last : Natural) return String is
      begin
         if First = 0 or else Last < First or else Last > Fragment'Last then
            return "";
         elsif Fragment (First) = '{' then
            return Scan_Object (Fragment (First .. Last));
         elsif Fragment (First) = '[' then
            return Scan_Array (Fragment (First .. Last));
         end if;
         return "";
      end Scan_Value;
   begin
      return Scan_Value (Text, Text'First, Text'Last);
   exception
      when others =>
         return "";
   end Find_Object_Field;

   procedure For_Each_Array_Object_Field
     (Text    : String;
      Field   : String;
      Process : not null access procedure (Value : String))
   is
      Pos        : Natural := Text'First;
      Item_First : Natural;
      Item_Last  : Natural;
      Item_Kind  : Value_Kind;
   begin
      Skip_WS (Text, Pos);
      if Pos > Text'Last or else Text (Pos) /= '[' then
         return;
      end if;
      Pos := Pos + 1;

      loop
         Skip_WS (Text, Pos);
         exit when Pos > Text'Last or else Text (Pos) = ']';
         Value_Slice (Text, Pos, Item_First, Item_Last, Item_Kind);

         if Item_Kind = Object_Value and then Item_First > 0 then
            declare
               Value : constant String :=
                 Object_Field_Value (Text (Item_First .. Item_Last), Field);
            begin
               if Value'Length > 0 then
                  Process (Value);
               end if;
            end;
         end if;

         Skip_WS (Text, Pos);
         exit when Pos > Text'Last or else Text (Pos) /= ',';
         Pos := Pos + 1;
      end loop;
   exception
      when others =>
         null;
   end For_Each_Array_Object_Field;
end Project_Tools.JSON;
