with Ada.Command_Line;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Project_Tools.Text;
with Project_Tools.TOML;

package body Project_Tools.Coverage_Ratchets is
   use type Project_Tools.TOML.Natural_Parse_Status;
   use type Project_Tools.TOML.String_Parse_Status;

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

   function Read_File (Path : String) return String is
     (Ada.Strings.Unbounded.To_String (Project_Tools.Text.Read_Text_File (Path)));

   function Occurrence_Count
     (Text    : String;
      Pattern : String)
      return Natural
   is
      Position : Positive := Text'First;
      Count    : Natural := 0;
   begin
      if Pattern = "" then
         return 0;
      end if;

      loop
         declare
            Found : constant Natural :=
              Ada.Strings.Fixed.Index (Text, Pattern, From => Position);
         begin
            exit when Found = 0;
            Count := Count + 1;
            exit when Found + Pattern'Length > Text'Last;
            Position := Found + Pattern'Length;
         end;
      end loop;

      return Count;
   end Occurrence_Count;

   procedure Check_Category_Ratchets
     (Errors          : in out Natural;
      Root            : String;
      Coverage_Path   : String;
      Manifest_Path   : String;
      Coverage_Key    : String;
      Minimum_Entries : Natural;
      Purpose         : String := "coverage category ratchet";
      Quiet           : Boolean := False)
   is
      Coverage : constant String := Read_File (Root & "/" & Coverage_Path);
      Manifest : constant String := Read_File (Root & "/" & Manifest_Path);
      Count    : Natural := 0;

      function Category_In_Manifest (Category : String) return Boolean is
         Found : Boolean := False;

         procedure Check_Entry (Entry_Pos : Positive) is
            Entry_Category : constant String :=
              Project_Tools.TOML.String_Value_After
                (Manifest, "category = ", Entry_Pos);
         begin
            if Entry_Category = Category then
               Found := True;
            end if;
         end Check_Entry;

         procedure Check_Entries is new Project_Tools.TOML.Iterate_Section
           (Check_Entry);
      begin
         Check_Entries (Manifest, "category");
         return Found;
      end Category_In_Manifest;

      procedure Check_Budget (Entry_Pos : Positive) is
         Category : constant String :=
           Project_Tools.TOML.String_Value_After
             (Manifest, "category = ", Entry_Pos);
         Max_Count_Result : constant Project_Tools.TOML.Natural_Parse_Result :=
           Project_Tools.TOML.Parse_Natural_After
             (Manifest, "max_count = ", Entry_Pos);
         Usecase : constant String :=
           Project_Tools.TOML.String_Value_After
             (Manifest, "usecase = ", Entry_Pos);
      begin
         if Category = "" or else Usecase = ""
           or else Max_Count_Result.Status /= Project_Tools.TOML.Parsed_Natural
         then
            Error (Errors, Purpose & " entry is incomplete", Quiet);
         else
            declare
               Actual : constant Natural :=
                 Occurrence_Count
                   (Coverage, Coverage_Key & " = """ & Category & """");
            begin
               if Actual > Max_Count_Result.Value then
                  Error
                    (Errors,
                     Purpose & " exceeded for " & Category,
                     Quiet);
               end if;
            end;
            Count := Count + 1;
         end if;
      end Check_Budget;

      procedure Check_Budgets is new Project_Tools.TOML.Iterate_Section
        (Check_Budget);

      procedure Check_Coverage_Categories is
         Pattern  : constant String := Coverage_Key & " = ";
         Position : Positive := Coverage'First;
      begin
         loop
            declare
               Found : constant Natural :=
                 Ada.Strings.Fixed.Index
                   (Coverage, Pattern, From => Position);
            begin
               exit when Found = 0;
               declare
                  Parsed : constant Project_Tools.TOML.String_Parse_Result :=
                    Project_Tools.TOML.Parse_String_After
                      (Coverage, Pattern, Found);
                  Category : constant String :=
                    Ada.Strings.Unbounded.To_String (Parsed.Value);
               begin
                  if Parsed.Status /= Project_Tools.TOML.Parsed_String then
                     Error
                       (Errors,
                        Purpose & " coverage category is malformed",
                        Quiet);
                  elsif not Category_In_Manifest (Category) then
                     Error
                       (Errors,
                        Purpose & " missing category budget for "
                        & Category,
                        Quiet);
                  end if;
               end;

               exit when Found + Pattern'Length > Coverage'Last;
               Position := Found + Pattern'Length;
            end;
         end loop;
      end Check_Coverage_Categories;
   begin
      Check_Budgets (Manifest, "category");
      if Count < Minimum_Entries then
         Error (Errors, Purpose & " manifest covers too few categories", Quiet);
      end if;

      Check_Coverage_Categories;
   end Check_Category_Ratchets;
end Project_Tools.Coverage_Ratchets;
