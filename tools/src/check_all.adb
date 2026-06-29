with Ada.Command_Line;
with Ada.Directories;
with Ada.Exceptions;
with Ada.Text_IO;

with GNAT.OS_Lib;
with Project_Tools.Processes;
with Project_Tools.Release_Checks;
with Project_Tools.Tree_Checks;

procedure Check_All is
   use Ada.Text_IO;

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
   Require_File ("tools/check_generated_artifacts.sh");
   Require_File ("tools/optional_tool.sh");
   Require_Text ("src/project_tools-tree_checks.ads", "Require_No_Nonempty_Stderr");
   Require_Text ("public_api_smoke/src/project_tools_public_api_smoke.adb", "Project_Tools.Release_Checks");
   Require_Text ("README.md", "Project_Tools.Release_Checks");
   Require_Text ("README.md", "check_generated_artifacts.sh");

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
