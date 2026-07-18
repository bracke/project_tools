with Ada.Command_Line;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;

with Project_Tools.Files;
with Project_Tools.Processes;
with Project_Tools.Text;

package body Project_Tools.Release_Checks is
   function Create (Root : String) return Checker is
      Result : Checker;
   begin
      if Root'Length > Result.Root'Length then
         raise Constraint_Error;
      end if;
      Result.Root (1 .. Root'Length) := Root;
      Result.Last := Root'Length;
      return Result;
   end Create;

   function Root_Path (Check : Checker) return String is
   begin
      return Check.Root (1 .. Check.Last);
   end Root_Path;

   function Join (Check : Checker; Relative_Path : String) return String is
   begin
      return Root_Path (Check) & "/" & Relative_Path;
   end Join;

   procedure Require_File
     (Check         : Checker;
      Relative_Path : String;
      Quiet         : Boolean := False)
   is
   begin
      Project_Tools.Files.Require_File
        (Join (Check, Relative_Path),
         "required release file missing: " & Relative_Path,
         Quiet);
   end Require_File;

   procedure Require_Directory
     (Check         : Checker;
      Relative_Path : String;
      Quiet         : Boolean := False)
   is
   begin
      Project_Tools.Files.Require_Directory
        (Join (Check, Relative_Path),
         "required release directory missing: " & Relative_Path,
         Quiet);
   end Require_Directory;

   procedure Require_Text
     (Check         : Checker;
      Relative_Path : String;
      Text          : String;
      Quiet         : Boolean := False)
   is
   begin
      Project_Tools.Files.Require_Contains
        (Join (Check, Relative_Path),
         Text,
         Relative_Path & " must contain: " & Text,
         Quiet);
   end Require_Text;

   procedure Require_Absolute_File
     (Path  : String;
      Quiet : Boolean := False)
   is
   begin
      Project_Tools.Files.Require_File
        (Path, "required installed file missing", Quiet);
   end Require_Absolute_File;

   procedure Require_Absolute_Directory
     (Path  : String;
      Quiet : Boolean := False)
   is
   begin
      Project_Tools.Files.Require_Directory
        (Path, "required installed directory missing", Quiet);
   end Require_Absolute_Directory;

   procedure Require_Clean_Git_Worktree
     (Label : String;
      Path  : String;
      Quiet : Boolean := False)
   is
      Git_Args : GNAT.OS_Lib.Argument_List :=
        [new String'("-C"),
         new String'(Path),
         new String'("status"),
         new String'("--porcelain")];
      Output   : Unbounded_String;
      Git_Path : constant String := Project_Tools.Processes.Locate_Command ("git");
      Status   : Integer;
   begin
      if Git_Path = "" then
         Fail ("git executable not found on PATH", Quiet);
      end if;

      Status :=
        Project_Tools.Processes.Run_Status
          (Label   => "check " & Label & " git status",
           Dir     => ".",
           Program => Git_Path,
           Args    => Git_Args,
           Output  => Output,
           Quiet   => True);

      if Status /= 0 then
         Fail (Label & " worktree status could not be read", Quiet);
      elsif To_String (Output) /= "" then
         Fail (Label & " worktree must be clean", Quiet);
      end if;
   end Require_Clean_Git_Worktree;

   function Nonempty_Stderr_Files
     (Dirs : Project_Tools.Files.Path_List)
      return String
   is
      Command : Unbounded_String := Null_Unbounded_String;
   begin
      Append (Command, "find");
      for Dir of Dirs loop
         Append
           (Command,
            " " & Project_Tools.Processes.Shell_Quote (To_String (Dir)));
      end loop;
      Append (Command, " -type f -name '*.stderr' -size +0c -print");
      return Project_Tools.Processes.Shell_Output (To_String (Command));
   end Nonempty_Stderr_Files;

   function Ada_Build_Processes
     (Path_Token : String := "")
      return String
   is
      Command : Unbounded_String :=
        To_Unbounded_String
          ("ps -eo pid,ppid,stat,etime,comm,args");
   begin
      if Path_Token /= "" then
         Append
           (Command,
            " | grep " & Project_Tools.Processes.Shell_Quote (Path_Token));
      end if;

      Append
        (Command,
         " | grep -E '(^|/| )(alr|gprbuild|gcc|gnat1|gnatbind|gnatlink)( |$)'"
         & " | grep -v grep");
      return Project_Tools.Processes.Shell_Output (To_String (Command));
   end Ada_Build_Processes;

   procedure Require_GPR_Main_Inventory
     (Project_File                   : String;
      Documentation_File             : String;
      Source_Directory               : String;
      Alternate_Stem_Prefix          : String := "";
      Alternate_Source_Directory     : String := "";
      Alternate_Documentation_File   : String := "";
      Runner_File                    : String := "";
      Runner_Token_Prefix            : String := "";
      Runner_Token_Suffix            : String := "";
      Quiet                          : Boolean := False)
   is
      File   : Ada.Text_IO.File_Type;
      Buffer : String (1 .. 4096);
      Last   : Natural;
      Errors : Natural := 0;

      function Has_Suffix (Text : String; Suffix : String) return Boolean is
        (Text'Length >= Suffix'Length
         and then Text (Text'Last - Suffix'Length + 1 .. Text'Last) = Suffix);

      procedure Error (Message : String) is
      begin
         Errors := Errors + 1;
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
         if not Quiet then
            Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, "error: " & Message);
         end if;
      end Error;

      procedure Check_Main (Main_Name : String) is
         Stem        : constant String := Main_Name (Main_Name'First .. Main_Name'Last - 4);
         Alternate   : constant Boolean :=
           Alternate_Stem_Prefix /= ""
           and then Project_Tools.Text.Starts_With (Stem, Alternate_Stem_Prefix);
         Source_Path : constant String :=
           (if Alternate and then Alternate_Source_Directory /= ""
            then Alternate_Source_Directory & "/" & Main_Name
            else Source_Directory & "/" & Main_Name);
      begin
         if not Project_Tools.Files.File_Exists (Source_Path) then
            Error (Project_File & " lists missing tool source: " & Main_Name);
         end if;

         if not Project_Tools.Files.File_Contains (Documentation_File, Stem) then
            Error (Documentation_File & " does not document tool executable: " & Stem);
         end if;

         if Alternate then
            if Alternate_Documentation_File /= ""
              and then not Project_Tools.Files.File_Contains
                (Alternate_Documentation_File, Main_Name)
            then
               Error (Alternate_Documentation_File & " does not list source: " & Main_Name);
            end if;

            if Alternate_Documentation_File /= ""
              and then not Project_Tools.Files.File_Contains
                (Alternate_Documentation_File, "`" & Stem & "`")
            then
               Error (Alternate_Documentation_File & " does not document driver: " & Stem);
            end if;

            if Runner_File /= ""
              and then not Project_Tools.Files.File_Contains
                (Runner_File, Runner_Token_Prefix & Stem & Runner_Token_Suffix)
            then
               Error (Runner_File & " does not run tool executable: " & Stem);
            end if;
         end if;
      end Check_Main;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Project_File);
      while not Ada.Text_IO.End_Of_File (File) loop
         Ada.Text_IO.Get_Line (File, Buffer, Last);
         if Last >= 7 then
            for Start in 1 .. Last - 6 loop
               if Buffer (Start) = '"' then
                  declare
                     Close : Natural := 0;
                  begin
                     for I in Start + 1 .. Last loop
                        if Buffer (I) = '"' then
                           Close := I;
                           exit;
                        end if;
                     end loop;

                     if Close > Start then
                        declare
                           Main_Name : constant String := Buffer (Start + 1 .. Close - 1);
                        begin
                           if Has_Suffix (Main_Name, ".adb") then
                              Check_Main (Main_Name);
                           end if;
                        end;
                     end if;
                  end;
               end if;
            end loop;
         end if;
      end loop;

      Ada.Text_IO.Close (File);

      if Errors > 0 then
         raise Program_Error;
      end if;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;

         if Errors > 0 then
            raise Program_Error;
         end if;

         raise;
   end Require_GPR_Main_Inventory;

   function Fenced_Text
     (Expected_File : String;
      Fence_Label   : String)
      return String
   is
      Text         : constant String :=
        To_String (Project_Tools.Text.Read_Text_File (Expected_File));
      Fence        : constant String := "```" & Fence_Label;
      Start_Fence  : constant Natural := Project_Tools.Text.Index (Text, Fence);
      Content_From : Natural;
      End_Fence    : Natural;
   begin
      if Start_Fence = 0 then
         raise Program_Error;
      end if;

      Content_From := Start_Fence + Fence'Length;
      if Content_From <= Text'Last and then Text (Content_From) = ASCII.LF then
         Content_From := Content_From + 1;
      end if;

      End_Fence := Project_Tools.Text.Index_From (Text, "```", Content_From);
      if End_Fence = 0 or else End_Fence < Content_From then
         raise Program_Error;
      end if;

      return Text (Content_From .. End_Fence - 1);
   end Fenced_Text;

   procedure Require_Program_Output_Matches_Fenced_Text
     (Expected_File : String;
      Fence_Label   : String;
      Dir           : String;
      Program       : String;
      Args          : GNAT.OS_Lib.Argument_List;
      Label         : String;
      Quiet         : Boolean := False)
   is
      Expected : constant String := Fenced_Text (Expected_File, Fence_Label);
      Actual   : Unbounded_String;
   begin
      Project_Tools.Processes.Run
        (Label   => Label,
         Dir     => Dir,
         Program => Program,
         Args    => Args,
         Output  => Actual,
         Quiet   => Quiet);

      if To_String (Actual) /= Expected then
         Fail (Label & " output differs from " & Expected_File, Quiet);
      end if;
   exception
      when Program_Error =>
         Fail (Label & " expected-output check failed", Quiet);
   end Require_Program_Output_Matches_Fenced_Text;

   procedure Fail (Message : String; Quiet : Boolean := False) is
   begin
      if not Quiet then
         Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, Message);
      end if;
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      raise Program_Error;
   end Fail;
end Project_Tools.Release_Checks;
