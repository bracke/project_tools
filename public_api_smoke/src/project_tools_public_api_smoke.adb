with Ada.Directories;
with Ada.Strings.Unbounded;

with GNAT.OS_Lib;

with Project_Tools.Alire_Manifests;
with Project_Tools.Alire_Manifests.Staging;
with Project_Tools.Alire_Manifests.Validation;
with Project_Tools.Files;
with Project_Tools.Processes;
with Project_Tools.Release_Checks;
with Project_Tools.Text;
with Project_Tools.Tree_Checks;

procedure Project_Tools_Public_API_Smoke is
   use Ada.Strings.Unbounded;

   Empty_Paths : constant Project_Tools.Files.Path_List (1 .. 1) := [To_Unbounded_String (".")];
   Empty_Names : constant Project_Tools.Files.Name_List (1 .. 1) := [To_Unbounded_String ("obj")];
   Deps        : constant Project_Tools.Alire_Manifests.String_List (1 .. 1) := [To_Unbounded_String ("project_tools")];
   Args        : GNAT.OS_Lib.Argument_List (1 .. 0);
begin
   pragma Assert (Project_Tools.Text.Contains ("project_tools", "tools"));
   pragma Assert (Project_Tools.Text.Count ("aa", "a") = 2);
   pragma Assert (Project_Tools.Files.Exists (Ada.Directories.Current_Directory));
   pragma Assert (Project_Tools.Files.Directory_Exists (Ada.Directories.Current_Directory));
   Project_Tools.Files.Require_Directories (Empty_Paths, "current directory exists", Quiet => True);
   pragma Assert (Empty_Names'Length = 1);
   pragma Assert (Deps'Length = 1);
   pragma Assert
     (Project_Tools.Processes.Run_Status
        (Label   => "true",
         Dir     => Ada.Directories.Current_Directory,
         Program => "/usr/bin/true",
         Args    => Args,
         Quiet   => True) = 0);


   declare
      Check : constant Project_Tools.Release_Checks.Checker :=
        Project_Tools.Release_Checks.Create (Ada.Directories.Current_Directory);
   begin
      Project_Tools.Release_Checks.Require_Absolute_Directory
        (Ada.Directories.Current_Directory, Quiet => True);
      Project_Tools.Tree_Checks.Require_No_Nonempty_Stderr
        (Ada.Directories.Current_Directory & "/missing", Quiet => True);
      pragma Unreferenced (Check);
   end;

   --  Compile-only API checks for facade and child package visibility.
   declare
      procedure Facade_Copy
        (Template : String;
         Target   : String;
         Quiet    : Boolean := False)
      renames Project_Tools.Alire_Manifests.Copy_Release_Manifest;

      procedure Staging_Copy
        (Template : String;
         Target   : String;
         Quiet    : Boolean := False)
      renames Project_Tools.Alire_Manifests.Staging.Copy_Release_Manifest;

      procedure Facade_Check
        (Manifest : String;
         Quiet    : Boolean := False)
      renames Project_Tools.Alire_Manifests.Require_No_Local_Pins;

      procedure Validation_Check
        (Manifest : String;
         Quiet    : Boolean := False)
      renames Project_Tools.Alire_Manifests.Validation.Require_No_Local_Pins;
   begin
      null;
   end;
end Project_Tools_Public_API_Smoke;
