with Ada.Command_Line;
with Ada.Strings.Fixed;
with Ada.Text_IO;

package body Project_Tools.Gcov is
   Prefix : constant String := "Lines executed:";
   Of_Text : constant String := "% of ";
   File_Prefix_Text : constant String := "File '";

   procedure Error
     (Errors  : in out Natural;
      Message : String;
      Quiet   : Boolean)
   is
   begin
      Errors := Errors + 1;
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      if not Quiet then
         Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, "error: " & Message);
      end if;
   end Error;

   function Summary
     (Lines_Covered : Natural;
      Lines_Total   : Natural) return Coverage_Summary is
     ((Lines_Covered => Lines_Covered,
       Lines_Total   => Lines_Total));

   function Covered_Lines (Item : Coverage_Summary) return Natural is
     (Item.Lines_Covered);

   function Total_Lines (Item : Coverage_Summary) return Natural is
     (Item.Lines_Total);

   function Percent_Basis_Points (Item : Coverage_Summary) return Natural is
   begin
      if Item.Lines_Total = 0 then
         return 0;
      end if;

      if Item.Lines_Covered > Natural'Last / 10_000 then
         return Natural'Last;
      end if;

      return (Item.Lines_Covered * 10_000) / Item.Lines_Total;
   end Percent_Basis_Points;

   function Two_Digit_Image (Value : Natural) return String is
      Tens : constant Natural := Value / 10;
      Ones : constant Natural := Value mod 10;
   begin
      return String'
        (1 => Character'Val (Character'Pos ('0') + Tens),
         2 => Character'Val (Character'Pos ('0') + Ones));
   end Two_Digit_Image;

   function Trimmed_Natural (Value : Natural) return String is
      Image : constant String := Natural'Image (Value);
   begin
      return Image (Image'First + 1 .. Image'Last);
   end Trimmed_Natural;

   function Percent_Image (Item : Coverage_Summary) return String is
      Basis : constant Natural := Percent_Basis_Points (Item);
   begin
      return Trimmed_Natural (Basis / 100) & "."
        & Two_Digit_Image (Basis mod 100) & "%";
   end Percent_Image;

   function Parse_Natural
     (Text  : String;
      First : Positive;
      Last  : Natural;
      Value : out Natural) return Boolean
   is
      Accum : Natural := 0;
   begin
      if Last < First then
         return False;
      end if;

      for Index in First .. Last loop
         if Text (Index) not in '0' .. '9' then
            return False;
         end if;

         declare
            Digit : constant Natural :=
              Character'Pos (Text (Index)) - Character'Pos ('0');
         begin
            if Accum > (Natural'Last - Digit) / 10 then
               return False;
            end if;
            Accum := Accum * 10 + Digit;
         end;
      end loop;

      Value := Accum;
      return True;
   end Parse_Natural;

   procedure Add_Line
     (Line    : String;
      Summary : in out Coverage_Summary)
   is
      Prefix_Pos : constant Natural :=
        Ada.Strings.Fixed.Index (Line, Prefix);
   begin
      if Prefix_Pos = 0 then
         return;
      end if;

      declare
         Of_Pos : constant Natural :=
           Ada.Strings.Fixed.Index
             (Line, Of_Text, From => Prefix_Pos + Prefix'Length);
      begin
         if Of_Pos = 0 then
            return;
         end if;

         declare
            Total_First : constant Positive := Of_Pos + Of_Text'Length;
            Total_Last  : Natural := Line'Last;
            Total       : Natural := 0;
         begin
            while Total_Last >= Total_First
              and then Line (Total_Last) = ASCII.CR
            loop
               Total_Last := Total_Last - 1;
            end loop;

            if Parse_Natural (Line, Total_First, Total_Last, Total) then
               declare
                  Percent_First : constant Positive :=
                    Prefix_Pos + Prefix'Length;
                  Percent_Last  : constant Natural := Of_Pos - 1;
                  Dot_Pos       : Natural := 0;
                  Whole         : Natural := 0;
                  Fraction      : Natural := 0;
                  Covered       : Natural := 0;
               begin
                  for Index in Percent_First .. Percent_Last loop
                     if Line (Index) = '.' then
                        Dot_Pos := Index;
                        exit;
                     end if;
                  end loop;

                  if Dot_Pos > 0
                    and then Parse_Natural
                      (Line, Percent_First, Dot_Pos - 1, Whole)
                    and then Parse_Natural
                      (Line, Dot_Pos + 1, Percent_Last, Fraction)
                  then
                     declare
                        Basis : constant Natural := Whole * 100 + Fraction;
                     begin
                        Covered := (Total * Basis + 5_000) / 10_000;
                     end;
                  elsif Parse_Natural
                    (Line, Percent_First, Percent_Last, Whole)
                  then
                     Covered := (Total * Whole + 50) / 100;
                  else
                     return;
                  end if;

                  if Summary.Lines_Total <= Natural'Last - Total
                    and then Summary.Lines_Covered <= Natural'Last - Covered
                  then
                     Summary.Lines_Total := Summary.Lines_Total + Total;
                     Summary.Lines_Covered := Summary.Lines_Covered + Covered;
                  end if;
               end;
            end if;
         end;
      end;
   end Add_Line;

   function Parse_Lines_Executed_Output
     (Output : String) return Coverage_Summary is
     (Parse_Lines_Executed_Output (Output, ""));

   function Parse_Lines_Executed_Output
     (Output      : String;
      File_Prefix : String) return Coverage_Summary
   is
      Result : Coverage_Summary;
      Start  : Positive := Output'First;
      Accept_Current_File : Boolean := File_Prefix = "";

      procedure Inspect_Line (Line : String) is
      begin
         if Line'Length >= File_Prefix_Text'Length
           and then Line
             (Line'First .. Line'First + File_Prefix_Text'Length - 1) =
               File_Prefix_Text
         then
            declare
               Path_First : constant Positive :=
                 Line'First + File_Prefix_Text'Length;
               Path_Last  : Natural := Path_First - 1;
            begin
               for Index in Path_First .. Line'Last loop
                  exit when Line (Index) = Character'Val (39);
                  Path_Last := Index;
               end loop;

               Accept_Current_File :=
                 File_Prefix = ""
                 or else
                   (Path_Last >= Path_First
                    and then Path_Last - Path_First + 1 >= File_Prefix'Length
                    and then Line
                      (Path_First .. Path_First + File_Prefix'Length - 1) =
                        File_Prefix);
            end;
         elsif Accept_Current_File then
            Add_Line (Line, Result);
         end if;
      end Inspect_Line;
   begin
      if Output = "" then
         return Result;
      end if;

      while Start <= Output'Last loop
         declare
            Stop : Natural :=
              Ada.Strings.Fixed.Index
                (Output, String'(1 => ASCII.LF), From => Start);
         begin
            if Stop = 0 then
               Stop := Output'Last + 1;
            end if;

            if Stop > Start then
               Inspect_Line (Output (Start .. Stop - 1));
            end if;

            exit when Stop > Output'Last;
            Start := Stop + 1;
         end;
      end loop;

      return Result;
   end Parse_Lines_Executed_Output;

   procedure Require_Minimum_Line_Coverage
     (Errors                   : in out Natural;
      Item                     : Coverage_Summary;
      Minimum_Basis_Points     : Natural;
      Minimum_Executable_Lines : Natural;
      Purpose                  : String := "line coverage";
      Quiet                    : Boolean := False)
   is
   begin
      if Item.Lines_Total < Minimum_Executable_Lines then
         Error
           (Errors,
            Purpose & " has too few executable lines: "
            & Trimmed_Natural (Item.Lines_Total),
            Quiet);
      end if;

      if Percent_Basis_Points (Item) < Minimum_Basis_Points then
         Error
           (Errors,
            Purpose & " below minimum: "
            & Percent_Image (Item),
            Quiet);
      end if;
   end Require_Minimum_Line_Coverage;
end Project_Tools.Gcov;
