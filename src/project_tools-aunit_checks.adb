with Ada.Command_Line;
with Ada.Directories;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;

with Project_Tools.Text;

package body Project_Tools.AUnit_Checks is
   procedure Error (Errors : in out Natural; Message : String; Quiet : Boolean) is
   begin
      Errors := Errors + 1;
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      if not Quiet then
         Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, "error: " & Message);
      end if;
   end Error;

   function Spec_Name (Body_Name : String) return String is
   begin
      if Body_Name'Length < 4 or else Body_Name (Body_Name'Last - 3 .. Body_Name'Last) /= ".adb" then
         return Body_Name & ".ads";
      end if;
      return Body_Name (Body_Name'First .. Body_Name'Last - 3) & "ads";
   end Spec_Name;

   function Registration_Count (Text : String) return Natural is
   begin
      return Project_Tools.Text.Count (Text, "Register_Routine");
   end Registration_Count;

   function Assertion_Count (Text : String) return Natural is
   begin
      return Project_Tools.Text.Count (Text, "Assert");
   end Assertion_Count;

   function Test_Body_Count (Text : String) return Natural is
   begin
      return Project_Tools.Text.Count (Text, "procedure Test_")
        + Project_Tools.Text.Count (Text, "procedure AUnit_Test_");
   end Test_Body_Count;

   function Collect_Suite_Metrics
     (Directory : String;
      Pattern   : String) return Suite_Metrics
   is
      Search      : Ada.Directories.Search_Type;
      Search_Open : Boolean := False;
      Item        : Ada.Directories.Directory_Entry_Type;
      Metrics     : Suite_Metrics;
   begin
      Ada.Directories.Start_Search
        (Search    => Search,
         Directory => Directory,
         Pattern   => Pattern,
         Filter    => [Ada.Directories.Ordinary_File => True, others => False]);
      Search_Open := True;

      while Ada.Directories.More_Entries (Search) loop
         Ada.Directories.Get_Next_Entry (Search, Item);
         declare
            Text : constant String :=
              To_String
                (Project_Tools.Text.Read_Text_File
                   (Ada.Directories.Full_Name (Item)));
         begin
            Metrics.Section_Count := Metrics.Section_Count + 1;
            Metrics.Registration_Count :=
              Metrics.Registration_Count + Registration_Count (Text);
            Metrics.Assertion_Count :=
              Metrics.Assertion_Count + Assertion_Count (Text);
            Metrics.Test_Body_Count :=
              Metrics.Test_Body_Count + Test_Body_Count (Text);
            Append (Metrics.Registered_Text, Text);
         end;
      end loop;

      Ada.Directories.End_Search (Search);
      return Metrics;
   exception
      when others =>
         if Search_Open then
            Ada.Directories.End_Search (Search);
         end if;
         raise;
   end Collect_Suite_Metrics;

   procedure Check_Section_Suite
     (Errors               : in out Natural;
      Body_Path            : String;
      Spec_Path            : String;
      Display_Name         : String;
      Required_Spec_Tokens : Text_List;
      Required_Body_Tokens : Text_List;
      Forbidden_Body_Tokens : Text_List;
      Max_Registrations    : Natural;
      Metrics              : in out Suite_Metrics;
      Quiet                : Boolean := False)
   is
      Body_Text : constant String := To_String (Project_Tools.Text.Read_Text_File (Body_Path));
      Spec_Text : constant String := To_String (Project_Tools.Text.Read_Text_File (Spec_Path));
      Regs      : constant Natural := Registration_Count (Body_Text);
      Tests     : constant Natural := Test_Body_Count (Body_Text);
   begin
      Metrics.Section_Count := Metrics.Section_Count + 1;
      Metrics.Registration_Count := Metrics.Registration_Count + Regs;
      Metrics.Assertion_Count := Metrics.Assertion_Count + Assertion_Count (Body_Text);
      Metrics.Test_Body_Count := Metrics.Test_Body_Count + Tests;
      Append (Metrics.Registered_Text, Body_Text);

      if Spec_Text = "" then
         Error (Errors, "missing section AUnit suite spec: " & Spec_Path, Quiet);
      else
         for Required of Required_Spec_Tokens loop
            declare
               Token : constant String := To_String (Required);
            begin
               if not Project_Tools.Text.Contains (Spec_Text, Token) then
                  Error
                    (Errors,
                     Display_Name & " spec is not an explicit AUnit Test_Case spec; missing: " & Token,
                     Quiet);
               end if;
            end;
         end loop;
      end if;

      for Required of Required_Body_Tokens loop
         declare
            Token : constant String := To_String (Required);
         begin
            if not Project_Tools.Text.Contains (Body_Text, Token) then
               Error (Errors, Display_Name & " missing AUnit section body structure: " & Token, Quiet);
            end if;
         end;
      end loop;

      for Forbidden of Forbidden_Body_Tokens loop
         declare
            Token : constant String := To_String (Forbidden);
         begin
            if Project_Tools.Text.Contains (Body_Text, Token) then
               Error (Errors, Display_Name & " must not contain obsolete section token: " & Token, Quiet);
            end if;
         end;
      end loop;

      if Regs > Max_Registrations then
         Error
           (Errors,
            Display_Name & " has too many registrations; split further instead of recreating a monolithic suite",
            Quiet);
      end if;
      if Tests < Regs then
         Error
           (Errors,
            Display_Name & " must define at least one local Test_* body per registered routine",
            Quiet);
      end if;
   end Check_Section_Suite;
end Project_Tools.AUnit_Checks;
