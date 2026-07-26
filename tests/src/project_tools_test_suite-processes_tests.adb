with Ada.Directories;
with Ada.Strings.Unbounded;

with GNAT.OS_Lib;

with AUnit.Assertions;

with Project_Tools.Files;
with Project_Tools.Processes;
with Project_Tools.Release_Checks;
with Project_Tools.Text;

with Project_Tools_Test_Suite.Support;

package body Project_Tools_Test_Suite.Processes_Tests is
   use AUnit.Assertions;
   use type GNAT.OS_Lib.String_Access;
   use Project_Tools_Test_Suite.Support;

   overriding function Name (Item : Process_Helper_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("Process helpers");
   end Name;

   overriding procedure Run_Test (Item : in out Process_Helper_Test) is
      pragma Unreferenced (Item);
      True_Path : GNAT.OS_Lib.String_Access := GNAT.OS_Lib.Locate_Exec_On_Path ("true");
      Args      : GNAT.OS_Lib.Argument_List (1 .. 0);
   begin
      Assert (True_Path /= null, "true executable is available on PATH");
      Project_Tools.Processes.Run
        (Label   => "run true",
         Dir     => Ada.Directories.Current_Directory,
         Program => True_Path.all,
         Args    => Args,
         Quiet   => True);
      Assert
        (Project_Tools.Processes.Run_Status
           (Label   => "status true",
            Dir     => Ada.Directories.Current_Directory,
            Program => True_Path.all,
            Args    => Args,
            Quiet   => True) = 0,
         "run status returns child status");
      Assert
        (not Project_Tools.Processes.Has_Argument ("--definitely-not-present-project-tools"),
         "Has_Argument rejects an absent command-line argument");
      GNAT.OS_Lib.Free (True_Path);
   exception
      when others =>
         if True_Path /= null then
            GNAT.OS_Lib.Free (True_Path);
         end if;
         raise;
   end Run_Test;

   overriding function Name (Item : Process_Failure_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("Process helper failures");
   end Name;

   overriding procedure Run_Test (Item : in out Process_Failure_Test) is
      pragma Unreferenced (Item);
      False_Path : GNAT.OS_Lib.String_Access := GNAT.OS_Lib.Locate_Exec_On_Path ("false");
      Args       : GNAT.OS_Lib.Argument_List (1 .. 0);
   begin
      Assert (False_Path /= null, "false executable is available on PATH");
      Assert
        (Project_Tools.Processes.Run_Status
           (Label   => "status false",
            Dir     => Ada.Directories.Current_Directory,
            Program => False_Path.all,
            Args    => Args,
            Quiet   => True) /= 0,
         "run status returns failing child status");

      declare
         procedure Run_False is
         begin
            Project_Tools.Processes.Run
              (Label   => "run false",
               Dir     => Ada.Directories.Current_Directory,
               Program => False_Path.all,
               Args    => Args,
               Quiet   => True);
         end Run_False;
      begin
         Expect_Program_Error (Run_False'Access, "failing process raises Program_Error");
      end;

      GNAT.OS_Lib.Free (False_Path);
   exception
      when others =>
         if False_Path /= null then
            GNAT.OS_Lib.Free (False_Path);
         end if;
         raise;
   end Run_Test;

   overriding function Name (Item : Process_Output_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("Process output capture");
   end Name;

   overriding procedure Run_Test (Item : in out Process_Output_Test) is
      pragma Unreferenced (Item);
      Echo_Path : GNAT.OS_Lib.String_Access := GNAT.OS_Lib.Locate_Exec_On_Path ("echo");
      Args      : GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [1 => new String'("project-tools-capture")];
      Output    : Ada.Strings.Unbounded.Unbounded_String;
      Status    : Integer;
   begin
      Delete_Tree_If_Present (Root);
      Ada.Directories.Create_Path (Root);
      Assert (Echo_Path /= null, "echo executable is available on PATH");
      Status :=
        Project_Tools.Processes.Run_Status
          (Label   => "capture echo",
           Dir     => Ada.Directories.Current_Directory,
           Program => Echo_Path.all,
           Args    => Args,
           Output  => Output,
           Quiet   => True);
      Assert (Status = 0, "captured run returns child status");
      Assert
        (Project_Tools.Text.Contains
           (Ada.Strings.Unbounded.To_String (Output), "project-tools-capture"),
         "Run_Status output overload returns the child's standard output");

      Write_File
        (Root & "/expected.md",
         "# Expected" & ASCII.LF
         & "```text" & ASCII.LF
         & "project-tools-capture" & ASCII.LF
         & "```" & ASCII.LF);
      Project_Tools.Release_Checks.Require_Program_Output_Matches_Fenced_Text
        (Expected_File => Root & "/expected.md",
         Fence_Label   => "text",
         Dir           => Ada.Directories.Current_Directory,
         Program       => Echo_Path.all,
         Args          => Args,
         Label         => "echo expected output",
         Quiet         => True);

      Write_File
        (Root & "/wrong-expected.md",
         "# Expected" & ASCII.LF
         & "```text" & ASCII.LF
         & "different" & ASCII.LF
         & "```" & ASCII.LF);
      declare
         procedure Wrong_Output is
         begin
            Project_Tools.Release_Checks.Require_Program_Output_Matches_Fenced_Text
              (Expected_File => Root & "/wrong-expected.md",
               Fence_Label   => "text",
               Dir           => Ada.Directories.Current_Directory,
               Program       => Echo_Path.all,
               Args          => Args,
               Label         => "echo wrong output",
               Quiet         => True);
         end Wrong_Output;
      begin
         Expect_Program_Error (Wrong_Output'Access, "mismatched expected output raises Program_Error");
      end;

      GNAT.OS_Lib.Free (Echo_Path);
      GNAT.OS_Lib.Free (Args (1));
      Delete_Tree_If_Present (Root);
   exception
      when others =>
         if Echo_Path /= null then
            GNAT.OS_Lib.Free (Echo_Path);
         end if;
         if Args (1) /= null then
            GNAT.OS_Lib.Free (Args (1));
         end if;
         Delete_Tree_If_Present (Root);
         raise;
   end Run_Test;

   overriding function Name (Item : Promoted_Helpers_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("Promoted version helpers");
   end Name;

   overriding procedure Run_Test (Item : in out Promoted_Helpers_Test) is
      pragma Unreferenced (Item);
      Dir : constant String := Root & "/promoted";
   begin
      --  Text helpers promoted from version's tool support.
      Assert (Project_Tools.Text.Index ("abcdef", "cd") = 3,
              "Index returns the substring position");
      Assert (Project_Tools.Text.Index ("abc", "z") = 0,
              "Index returns 0 when the pattern is absent");
      Assert (Project_Tools.Text.Index ("abc", "") = 0,
              "Index returns 0 for an empty pattern");
      Assert (Project_Tools.Text.Starts_With ("hello", "he"),
              "Starts_With detects a leading substring");
      Assert (not Project_Tools.Text.Starts_With ("hello", "lo"),
              "Starts_With rejects a non-prefix");
      Assert (Project_Tools.Text.Ends_With ("hello", "lo"),
              "Ends_With detects a trailing substring");
      Assert (not Project_Tools.Text.Ends_With ("hello", "he"),
              "Ends_With rejects a non-suffix");

      --  Files helpers.
      Assert (Project_Tools.Files.Join ("a", "b") = "a/b",
              "Join inserts a single separator");
      Assert (Project_Tools.Files.Join ("a/", "b") = "a/b",
              "Join avoids a double separator");
      Assert (Project_Tools.Files.Join ("", "b") = "b",
              "Join with an empty left segment returns the right segment");

      Delete_Tree_If_Present (Dir);
      Ada.Directories.Create_Path (Dir & "/nested");
      Write_File (Dir & "/data.txt", "alpha" & ASCII.LF & "key=value" & ASCII.LF);
      Write_File (Dir & "/nested/target.txt", "x" & ASCII.LF);

      Assert (Project_Tools.Files.Has_Line (Dir & "/data.txt", "alpha"),
              "Has_Line finds an exact line");
      Assert (not Project_Tools.Files.Has_Line (Dir & "/data.txt", "alph"),
              "Has_Line requires a full-line match");
      Assert (Project_Tools.Files.Value_Of (Dir & "/data.txt", "key") = "value",
              "Value_Of reads a key=value line");
      Assert (Project_Tools.Files.Value_Of (Dir & "/data.txt", "missing") = "",
              "Value_Of returns empty for an absent key");
      Assert (Project_Tools.Files.Find_File (Dir, "target.txt")
                = Dir & "/nested/target.txt",
              "Find_File locates a nested file");
      Assert (Project_Tools.Files.Find_File (Dir, "nope.txt") = "",
              "Find_File returns empty when absent");
      Assert (Project_Tools.Files.Find_Root_Upward (Dir & "/nested", "data.txt") = Dir,
              "Find_Root_Upward locates the nearest ancestor marker");
      Assert (Project_Tools.Files.Find_Root_Upward (Dir & "/nested", "missing.marker") = "",
              "Find_Root_Upward returns empty for a missing marker");

      --  Processes shell helpers.
      Assert (Project_Tools.Processes.Shell_Quote ("a b") = "'a b'",
              "Shell_Quote wraps a value in single quotes");
      Assert (Project_Tools.Processes.Run_Shell ("true") = 0,
              "Run_Shell returns 0 for a succeeding command");
      Assert (Project_Tools.Processes.Run_Shell ("false") /= 0,
              "Run_Shell returns non-zero for a failing command");
      Assert (Project_Tools.Text.Contains
                (Project_Tools.Processes.Shell_Output ("echo promoted-helper"),
                 "promoted-helper"),
              "Shell_Output captures standard output");
      Assert (Project_Tools.Processes.Shell_Output ("false") = "",
              "Shell_Output returns empty on command failure");
      Assert (Project_Tools.Processes.Shell_Output_Trimmed
                ("printf 'first\nsecond'") = "first",
              "Shell_Output_Trimmed returns the trimmed first line");

      Delete_Tree_If_Present (Dir);
   exception
      when others =>
         Delete_Tree_If_Present (Dir);
         raise;
   end Run_Test;

end Project_Tools_Test_Suite.Processes_Tests;
