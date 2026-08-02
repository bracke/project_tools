with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Ada.Text_IO;

package body Project_Tools.Text is
   use Ada.Strings.Unbounded;

   function Contains (Text : String; Pattern : String) return Boolean
     with SPARK_Mode => On
   is
   begin
      if Pattern'Length = 0 then
         return True;
      end if;

      return Ada.Strings.Fixed.Index (Text, Pattern) /= 0;
   end Contains;

   function Count (Text : String; Pattern : String) return Natural
     with SPARK_Mode => On
   is
   begin
      if Pattern'Length = 0 or else Text'Length = 0 then
         return 0;
      end if;

      return Ada.Strings.Fixed.Count (Text, Pattern);
   end Count;

   function Index (Text : String; Pattern : String) return Natural
     with SPARK_Mode => On
   is
   begin
      if Pattern'Length = 0 then
         return 0;
      end if;

      return Ada.Strings.Fixed.Index (Text, Pattern);
   end Index;

   function Index_From (Text : String; Pattern : String; From : Positive) return Natural is
   begin
      if From > Text'Last then
         return 0;
      end if;

      return Ada.Strings.Fixed.Index (Text (From .. Text'Last), Pattern);
   end Index_From;

   function Starts_With (Value : String; Prefix : String) return Boolean
     with SPARK_Mode => On
   is
   begin
      return Value'Length >= Prefix'Length
        and then Value (Value'First .. Value'First + Prefix'Length - 1) = Prefix;
   end Starts_With;

   function Ends_With (Value : String; Suffix : String) return Boolean
     with SPARK_Mode => On
   is
   begin
      return Value'Length >= Suffix'Length
        and then Value (Value'Last - Suffix'Length + 1 .. Value'Last) = Suffix;
   end Ends_With;

   function Line_Value
     (Text      : String;
      Key       : String;
      Separator : String := " =")
      return String
   is
      Prefix : constant String := Key & Separator;
      Start  : Positive;
   begin
      if Text'Length < Prefix'Length then
         return "";
      end if;

      for Index in Text'First .. Text'Last - Prefix'Length + 1 loop
         if (Index = Text'First or else Text (Index - 1) = Ada.Characters.Latin_1.LF)
           and then Text (Index .. Index + Prefix'Length - 1) = Prefix
         then
            Start := Index + Prefix'Length;
            if Start <= Text'Last and then Text (Start) = ' ' then
               Start := Start + 1;
            end if;

            for Last in Start .. Text'Last loop
               if Text (Last) = Ada.Characters.Latin_1.LF then
                  return Text (Start .. Last - 1);
               end if;
            end loop;

            return Text (Start .. Text'Last);
         end if;
      end loop;

      return "";
   end Line_Value;

   function Read_Text_File (Path : String) return Unbounded_String is
      File   : Ada.Text_IO.File_Type;
      Result : Unbounded_String := Null_Unbounded_String;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         Append (Result, Ada.Text_IO.Get_Line (File));
         Append (Result, Ada.Characters.Latin_1.LF);
      end loop;
      Ada.Text_IO.Close (File);
      return Result;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return Null_Unbounded_String;
   end Read_Text_File;
end Project_Tools.Text;
