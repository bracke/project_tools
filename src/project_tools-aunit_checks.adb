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

   function Test_Package_Name (Spec_Name : String) return String
   is
      Stem_Last  : constant Natural := Spec_Name'Last - 4;
      Result     : String (Spec_Name'First .. Stem_Last);
      Upper_Next : Boolean := True;
   begin
      for I in Result'Range loop
         if Spec_Name (I) = '_' then
            Result (I) := '_';
            Upper_Next := True;
         elsif Upper_Next and then Spec_Name (I) in 'a' .. 'z' then
            Result (I) := Character'Val
              (Character'Pos (Spec_Name (I)) - Character'Pos ('a') + Character'Pos ('A'));
            Upper_Next := False;
         else
            Result (I) := Spec_Name (I);
            Upper_Next := False;
         end if;
      end loop;

      return Result;
   end Test_Package_Name;

   function Declared_Package_Name (Spec_Path : String; Fallback_Name : String) return String is
      File   : Ada.Text_IO.File_Type;
      Buffer : String (1 .. 4096);
      Last   : Natural;
      Prefix : constant String := "package ";

      function Trim (Text : String) return String is
         First : Natural := Text'First;
         Last_Char : Natural := Text'Last;
      begin
         while First <= Text'Last and then Text (First) = ' ' loop
            First := First + 1;
         end loop;

         while Last_Char >= First and then Text (Last_Char) = ' ' loop
            Last_Char := Last_Char - 1;
         end loop;

         if First > Last_Char then
            return "";
         else
            return Text (First .. Last_Char);
         end if;
      end Trim;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Spec_Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         Ada.Text_IO.Get_Line (File, Buffer, Last);
         declare
            Line : constant String := Trim (Buffer (1 .. Last));
         begin
            if Project_Tools.Text.Starts_With (Line, Prefix) then
               declare
                  Rest : constant String := Line (Line'First + Prefix'Length .. Line'Last);
                  Stop : Natural := Rest'First;
               begin
                  while Stop <= Rest'Last and then Rest (Stop) /= ' ' and then Rest (Stop) /= ';' loop
                     Stop := Stop + 1;
                  end loop;

                  Ada.Text_IO.Close (File);
                  return Rest (Rest'First .. Stop - 1);
               end;
            end if;
         end;
      end loop;

      Ada.Text_IO.Close (File);
      return Fallback_Name;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return Fallback_Name;
   end Declared_Package_Name;

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

   procedure Require_Registered_Test_Packages
     (Test_Dir                 : String;
      Spec_Pattern             : String;
      Suite_Path               : String;
      Documentation_Path       : String;
      Documented_Stem_Prefix   : String;
      Suite_Add_Prefix         : String := "Result.Add_Test (new ";
      Suite_Add_Suffix         : String := ".Test_Case)";
      Registration_Token       : String := "Register_Routine";
      Required_Stem_Suffix     : String := "_tests";
      Quiet                    : Boolean := False)
   is
      Search : Ada.Directories.Search_Type;
      Open   : Boolean := False;
      Errors : Natural := 0;

      function Has_Suffix (Text : String; Suffix : String) return Boolean is
        (Text'Length >= Suffix'Length
         and then Text (Text'Last - Suffix'Length + 1 .. Text'Last) = Suffix);

      function Has_Prefix (Text : String; Prefix : String) return Boolean is
        (Text'Length >= Prefix'Length
         and then Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix);

      procedure Require_Documented_AUnit_Tests_Exist is
         File   : Ada.Text_IO.File_Type;
         Buffer : String (1 .. 4096);
         Last   : Natural;
      begin
         Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Documentation_Path);
         while not Ada.Text_IO.End_Of_File (File) loop
            Ada.Text_IO.Get_Line (File, Buffer, Last);
            if Last >= Documented_Stem_Prefix'Length
              and then Has_Prefix (Buffer (1 .. Last), Documented_Stem_Prefix)
            then
               declare
                  Open_Backtick  : Natural := 0;
                  Close_Backtick : Natural := 0;
               begin
                  for I in 1 .. Last loop
                     if Buffer (I) = '`' then
                        Open_Backtick := I;
                        exit;
                     end if;
                  end loop;

                  if Open_Backtick > 0 then
                     for I in Open_Backtick + 1 .. Last loop
                        if Buffer (I) = '`' then
                           Close_Backtick := I;
                           exit;
                        end if;
                     end loop;
                  end if;

                  if Open_Backtick = 0 or else Close_Backtick = 0 then
                     Error (Errors, "malformed AUnit inventory entry in " & Documentation_Path, Quiet);
                  else
                     declare
                        Stem : constant String :=
                          Buffer (Open_Backtick + 1 .. Close_Backtick - 1);
                     begin
                        if Has_Suffix (Stem, Required_Stem_Suffix)
                          and then not Ada.Directories.Exists (Test_Dir & "/" & Stem & ".ads")
                        then
                           Error
                             (Errors,
                              Documentation_Path & " lists missing AUnit test package: " & Stem,
                              Quiet);
                        end if;
                     end;
                  end if;
               end;
            end if;
         end loop;

         Ada.Text_IO.Close (File);
      exception
         when others =>
            if Ada.Text_IO.Is_Open (File) then
               Ada.Text_IO.Close (File);
            end if;
            raise;
      end Require_Documented_AUnit_Tests_Exist;
   begin
      Ada.Directories.Start_Search (Search, Test_Dir, Spec_Pattern);
      Open := True;
      while Ada.Directories.More_Entries (Search) loop
         declare
            Item : Ada.Directories.Directory_Entry_Type;
         begin
            Ada.Directories.Get_Next_Entry (Search, Item);
            declare
               Name      : constant String := Ada.Directories.Simple_Name (Item);
               Stem      : constant String := Name (Name'First .. Name'Last - 4);
               Body_Path : constant String := Test_Dir & "/" & Stem & ".adb";
               Spec_Path : constant String := Test_Dir & "/" & Name;
               Test_Pkg  : constant String :=
                 Declared_Package_Name (Spec_Path, Test_Package_Name (Name));
            begin
               if not Ada.Directories.Exists (Body_Path) then
                  Error (Errors, "AUnit test package spec has no body: " & Name, Quiet);
               elsif not Project_Tools.Files.File_Contains (Body_Path, Registration_Token) then
                  Error (Errors, "AUnit test package registers no routines: " & Stem, Quiet);
               end if;

               if not Project_Tools.Files.File_Contains (Suite_Path, "with " & Test_Pkg & ";") then
                  Error (Errors, "AUnit test package is not withed by suite: " & Test_Pkg, Quiet);
               end if;

               if not Project_Tools.Files.File_Contains
                 (Suite_Path, Suite_Add_Prefix & Test_Pkg & Suite_Add_Suffix)
               then
                  Error (Errors, "AUnit test package is not added to suite: " & Test_Pkg, Quiet);
               end if;

               if not Project_Tools.Files.File_Contains (Documentation_Path, "`" & Stem & "`") then
                  Error
                    (Errors,
                     "AUnit test package is not listed in " & Documentation_Path & ": " & Stem,
                     Quiet);
               end if;
            end;
         end;
      end loop;

      Ada.Directories.End_Search (Search);
      Open := False;

      Ada.Directories.Start_Search
        (Search, Test_Dir, "*" & Required_Stem_Suffix & ".adb");
      Open := True;
      while Ada.Directories.More_Entries (Search) loop
         declare
            Item : Ada.Directories.Directory_Entry_Type;
         begin
            Ada.Directories.Get_Next_Entry (Search, Item);
            declare
               Name      : constant String := Ada.Directories.Simple_Name (Item);
               Stem      : constant String := Name (Name'First .. Name'Last - 4);
               Spec_Path : constant String := Test_Dir & "/" & Stem & ".ads";
            begin
               if not Ada.Directories.Exists (Spec_Path) then
                  Error (Errors, "AUnit test package body has no spec: " & Name, Quiet);
               end if;
            end;
         end;
      end loop;

      Ada.Directories.End_Search (Search);
      Open := False;

      Require_Documented_AUnit_Tests_Exist;

      if Errors > 0 then
         raise Program_Error;
      end if;
   exception
      when others =>
         if Open then
            begin
               Ada.Directories.End_Search (Search);
            exception
               when others =>
                  null;
            end;
         end if;

         if Errors > 0 then
            raise Program_Error;
         end if;

         raise;
   end Require_Registered_Test_Packages;
end Project_Tools.AUnit_Checks;
