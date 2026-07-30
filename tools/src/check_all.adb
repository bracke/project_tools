with Ada.Characters.Handling;
with Ada.Command_Line;
with Ada.Directories;
with Ada.Exceptions;
with Ada.Text_IO;

with GNAT.OS_Lib;
with Project_Tools.Files;
with Project_Tools.Processes;
with Project_Tools.Release_Checks;
with Project_Tools.Text;
with Project_Tools.Tree_Checks;

procedure Check_All is
   use Ada.Text_IO;
   use type Ada.Directories.File_Kind;

   function Project_Root return String is
      Here : constant String := Ada.Directories.Current_Directory;
   begin
      if Ada.Directories.Exists (Here & "/project_tools.gpr") then
         return Here;
      elsif Ada.Directories.Exists (Here & "/../project_tools.gpr") then
         return Ada.Directories.Full_Name (Here & "/..");
      else
         return Here;
      end if;
   end Project_Root;

   Root   : constant String := Project_Root;
   Alr    : constant String := Project_Tools.Processes.Locate_Command ("alr");
   Checks : constant Project_Tools.Release_Checks.Checker :=
     Project_Tools.Release_Checks.Create (Root);

   procedure Require (Name : String) is
   begin
      Project_Tools.Processes.Require_Command
        (Name, Name & " is required for the project_tools release checklist");
   end Require;

   procedure Run
     (Label   : String;
      Dir     : String;
      Program : String;
      Args    : GNAT.OS_Lib.Argument_List;
      Quiet   : Boolean := False) renames Project_Tools.Release_Checks.Run;

   procedure Require_File (Relative_Path : String) is
   begin
      Project_Tools.Release_Checks.Require_File (Checks, Relative_Path);
   end Require_File;

   procedure Require_Text (Relative_Path : String; Text : String) is
   begin
      Project_Tools.Release_Checks.Require_Text (Checks, Relative_Path, Text);
   end Require_Text;

   --  Ada-only-tooling gate. project_tools provides the "no Python/shell
   --  helper scripts" discipline to its consumers, so it must enforce the same
   --  policy on its own tree: no shell scripts (.sh and friends), no shebang
   --  helper scripts, and no packaged Python sources.

   function Is_Generated_Directory_Name (Name : String) return Boolean is
   --  @param Name Simple directory name to test.
   --  @return True for build/tooling caches that must not be scanned.
   begin
      return Name = "bin"
        or else Name = "obj"
        or else Name = "lib"
        or else Name = "alire"
        or else Name = ".git";
   end Is_Generated_Directory_Name;

   function Has_Shell_Tooling_Extension (Name : String) return Boolean is
   --  @param Name Simple file name to test.
   --  @return True when Name has a shell-script extension.
      Lower : constant String := Ada.Characters.Handling.To_Lower (Name);
   begin
      return Project_Tools.Text.Ends_With (Lower, ".sh")
        or else Project_Tools.Text.Ends_With (Lower, ".bash")
        or else Project_Tools.Text.Ends_With (Lower, ".zsh")
        or else Project_Tools.Text.Ends_With (Lower, ".ksh")
        or else Project_Tools.Text.Ends_With (Lower, ".fish");
   end Has_Shell_Tooling_Extension;

   function Has_Shebang (Path : String) return Boolean is
   --  @param Path File to inspect.
   --  @return True when the first two bytes of Path are "#!".
      File   : Ada.Text_IO.File_Type;
      Buffer : String (1 .. 2);
      Last   : Natural := 0;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      if not Ada.Text_IO.End_Of_File (File) then
         Ada.Text_IO.Get_Line (File, Buffer, Last);
      end if;
      Ada.Text_IO.Close (File);
      return Last = 2 and then Buffer = "#!";
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return False;
   end Has_Shebang;

   procedure Check_Ada_Only_Tooling_In_Tree (Path : String) is
   --  Recursively reject shell/shebang tooling below Path.
   --  @param Path Directory tree to scan.
      Search    : Ada.Directories.Search_Type;
      Dir_Entry : Ada.Directories.Directory_Entry_Type;
      Started   : Boolean := False;
   begin
      if not Project_Tools.Files.Directory_Exists (Path) then
         return;
      end if;

      Ada.Directories.Start_Search
        (Search,
         Directory => Path,
         Pattern   => "*",
         Filter    =>
           [Ada.Directories.Ordinary_File => True,
            Ada.Directories.Directory     => True,
            Ada.Directories.Special_File  => False]);
      Started := True;

      while Ada.Directories.More_Entries (Search) loop
         Ada.Directories.Get_Next_Entry (Search, Dir_Entry);
         declare
            Name : constant String := Ada.Directories.Simple_Name (Dir_Entry);
            Full : constant String := Ada.Directories.Full_Name (Dir_Entry);
         begin
            if Name = "." or else Name = ".." then
               null;
            elsif Ada.Directories.Kind (Dir_Entry) = Ada.Directories.Directory then
               if not Is_Generated_Directory_Name (Name) then
                  Check_Ada_Only_Tooling_In_Tree (Full);
               end if;
            elsif Has_Shell_Tooling_Extension (Name) then
               Put_Line (Standard_Error, Full & ": shell helper tooling is not allowed");
               Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
               raise Program_Error;
            elsif Has_Shebang (Full) then
               Put_Line (Standard_Error, Full & ": shebang helper tooling is not allowed");
               Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
               raise Program_Error;
            end if;
         end;
      end loop;

      Ada.Directories.End_Search (Search);
      Started := False;
   exception
      when others =>
         if Started then
            Ada.Directories.End_Search (Search);
         end if;
         raise;
   end Check_Ada_Only_Tooling_In_Tree;

   procedure Check_Ada_Only_Tooling is
   --  Enforce the Ada-only-tooling policy over the whole project_tools tree:
   --  reject shell scripts, shebang scripts, and packaged Python artifacts.
      Python_Errors : Natural := 0;
   begin
      Check_Ada_Only_Tooling_In_Tree (Root);
      Project_Tools.Tree_Checks.Check_No_Generated_Python (Python_Errors, Root & "/src");
      Project_Tools.Tree_Checks.Check_No_Generated_Python (Python_Errors, Root & "/tests");
      Project_Tools.Tree_Checks.Check_No_Generated_Python (Python_Errors, Root & "/tools");
      Project_Tools.Tree_Checks.Check_No_Generated_Python (Python_Errors, Root & "/public_api_smoke");
      Project_Tools.Tree_Checks.Check_No_Generated_Python (Python_Errors, Root & "/docs");
      Project_Tools.Tree_Checks.Check_No_Generated_Python (Python_Errors, Root & "/config");
      if Python_Errors > 0 then
         raise Program_Error;
      end if;
   end Check_Ada_Only_Tooling;

begin
   if not Ada.Directories.Exists (Root & "/project_tools.gpr") then
      Put_Line (Standard_Error, "check_all must be run from the project_tools root or tools directory");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;

   Require ("alr");
   Require ("gprbuild");
   Require ("gnatprove");

   Require_File ("src/project_tools-release_checks.ads");
   Require_File ("src/project_tools-release_checks.adb");
   Require_File ("tools/src/check_generated_artifacts.adb");
   Require_File ("tools/src/optional_tool.adb");
   Require_Text ("src/project_tools-tree_checks.ads", "Require_No_Nonempty_Stderr");
   Require_Text ("public_api_smoke/src/project_tools_public_api_smoke.adb", "Project_Tools.Release_Checks");
   Require_Text ("README.md", "Project_Tools.Release_Checks");
   Require_Text ("README.md", "check_generated_artifacts");

   Check_Ada_Only_Tooling;

   --  Warnings and style, made to fail rather than merely print.
   --
   --  The switches come from the Alire profile, not from project_tools.gpr.
   --  This crate pins "*" = "development" in its manifest, which supplies
   --  -gnatwa, -gnatVa and the full -gnaty set -- but only reports them.
   --  --validation adds -gnatwe, which turns each one into an error. Forced,
   --  because a warning surfaces only when its file recompiles and an
   --  incremental build would quietly skip the file that has one.
   --
   --  All three crates, because a style bar over the library alone leaves the
   --  test and smoke sources ungoverned. tools/ is deliberately not among them:
   --  it holds the binary running this check, and relinking it while it
   --  executes is a way to fail for reasons that have nothing to do with style.
   Run
     ("library warnings as errors", Root, Alr,
      [new String'("build"), new String'("--validation"), new String'("--"),
       new String'("-f")]);
   Run
     ("tests warnings as errors", Root & "/tests", Alr,
      [new String'("build"), new String'("--validation"), new String'("--"),
       new String'("-f")]);
   Run
     ("public API smoke warnings as errors", Root & "/public_api_smoke", Alr,
      [new String'("build"), new String'("--validation"), new String'("--"),
       new String'("-f")]);

   Run ("alr build", Root, Alr, [1 => new String'("build")]);
   Run
     ("project_tools GNATprove", Root, Alr,
      [new String'("exec"), new String'("--"), new String'("gnatprove"),
       new String'("-P"), new String'("project_tools.gpr"),
       new String'("--level=0"), new String'("--mode=check")]);
   Run ("alr test", Root, Alr, [1 => new String'("test")]);
   Run ("tests build", Root & "/tests", Alr, [1 => new String'("build")]);
   Run ("AUnit tests", Root & "/tests", "./bin/project_tools_tests", []);
   Run ("public API smoke build", Root & "/public_api_smoke", Alr, [1 => new String'("build")]);
   Run
     ("public API smoke", Root & "/public_api_smoke",
      "./bin/project_tools_public_api_smoke", []);

   Project_Tools.Tree_Checks.Require_No_Nonempty_Stderr (Root & "/obj");
   Project_Tools.Tree_Checks.Require_No_Nonempty_Stderr (Root & "/tests/obj");
   Project_Tools.Tree_Checks.Require_No_Nonempty_Stderr (Root & "/tools/obj");
   Project_Tools.Tree_Checks.Require_No_Nonempty_Stderr (Root & "/public_api_smoke/obj");

   Put_Line ("project_tools release checklist passed");
   Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
exception
   when Program_Error =>
      null;
   when E : others =>
      Put_Line
        (Standard_Error,
         "project_tools release checklist failed: " & Ada.Exceptions.Exception_Message (E));
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
end Check_All;
