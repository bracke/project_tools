with Ada.Directories;
with Ada.Strings.Unbounded;

with GNAT.OS_Lib;

with AUnit;
with AUnit.Assertions;
with AUnit.Simple_Test_Cases;

with Project_Tools.Alire_Manifests;
with Project_Tools.AUnit_Checks;
with Project_Tools.Files;
with Project_Tools.Processes;
with Project_Tools.Security_Corpus;
with Project_Tools.Text;
with Project_Tools.Tree_Checks;

with Project_Tools_Test_Suite.Support;
with Project_Tools_Test_Suite.Files_Tests;
with Project_Tools_Test_Suite.Processes_Tests;
with Project_Tools_Test_Suite.Checks_Tests;

package body Project_Tools_Test_Suite is
   use AUnit.Assertions;
   use Ada.Strings.Unbounded;
   use Project_Tools_Test_Suite.Support;

   type Focus_Area is
     (Focus_Text_Contains,
      Focus_Text_Count,
      Focus_File_Exists,
      Focus_File_Contains,
      Focus_Manifest_No_Pins,
      Focus_Manifest_Dependency,
      Focus_Process_Status,
      Focus_AUnit_Spec_Name,
      Focus_Tree_Check_Clean,
      Focus_Security_Corpus_Clean);
   type Focused_Test (Area : Focus_Area) is new AUnit.Simple_Test_Cases.Test_Case with null record;

   overriding function Name (Item : Focused_Test) return AUnit.Message_String;

   overriding procedure Run_Test (Item : in out Focused_Test);

   overriding function Name (Item : Focused_Test) return AUnit.Message_String is
   begin
      case Item.Area is
         when Focus_Text_Contains =>
            return AUnit.Format ("Focused text contains");
         when Focus_Text_Count =>
            return AUnit.Format ("Focused text count");
         when Focus_File_Exists =>
            return AUnit.Format ("Focused file exists");
         when Focus_File_Contains =>
            return AUnit.Format ("Focused file contains");
         when Focus_Manifest_No_Pins =>
            return AUnit.Format ("Focused manifest no pins");
         when Focus_Manifest_Dependency =>
            return AUnit.Format ("Focused manifest dependency");
         when Focus_Process_Status =>
            return AUnit.Format ("Focused process status");
         when Focus_AUnit_Spec_Name =>
            return AUnit.Format ("Focused AUnit spec name");
         when Focus_Tree_Check_Clean =>
            return AUnit.Format ("Focused tree check clean");
         when Focus_Security_Corpus_Clean =>
            return AUnit.Format ("Focused security corpus clean");
      end case;
   end Name;

   overriding procedure Run_Test (Item : in out Focused_Test) is
      Args : GNAT.OS_Lib.Argument_List (1 .. 0);
   begin
      case Item.Area is
         when Focus_Text_Contains =>
            Assert (Project_Tools.Text.Contains ("project_tools", "tools"), "contains focused substring");

         when Focus_Text_Count =>
            Assert (Project_Tools.Text.Count ("aaaa", "aa") = 2, "count focused non-overlap");

         when Focus_File_Exists =>
            Delete_Tree_If_Present (Root);
            Ada.Directories.Create_Path (Root);
            Write_File (Root & "/exists.txt", "x" & ASCII.LF);
            Assert (Project_Tools.Files.File_Exists (Root & "/exists.txt"), "focused file exists");
            Delete_Tree_If_Present (Root);

         when Focus_File_Contains =>
            Delete_Tree_If_Present (Root);
            Ada.Directories.Create_Path (Root);
            Write_File (Root & "/contains.txt", "alpha beta" & ASCII.LF);
            Assert (Project_Tools.Files.File_Contains (Root & "/contains.txt", "beta"), "focused file contains");
            Delete_Tree_If_Present (Root);

         when Focus_Manifest_No_Pins =>
            Delete_Tree_If_Present (Root);
            Ada.Directories.Create_Path (Root);
            Write_File (Root & "/release.toml", "name = ""example""" & ASCII.LF);
            Project_Tools.Alire_Manifests.Require_No_Local_Pins (Root & "/release.toml", Quiet => True);
            Delete_Tree_If_Present (Root);

         when Focus_Manifest_Dependency =>
            Delete_Tree_If_Present (Root);
            Ada.Directories.Create_Path (Root);
            Write_File
              (Root & "/release.toml",
               "name = ""example""" & ASCII.LF
               & "[[depends-on]]" & ASCII.LF
               & "dep = ""*""" & ASCII.LF);
            Project_Tools.Alire_Manifests.Require_Release_Dependency
              (Root & "/release.toml", "dep", Quiet => True);
            Delete_Tree_If_Present (Root);

         when Focus_Process_Status =>
            Assert
              (Project_Tools.Processes.Run_Status
                 (Label   => "focused true",
                  Dir     => Ada.Directories.Current_Directory,
                  Program => Project_Tools.Processes.Locate_Command ("true"),
                  Args    => Args,
                  Quiet   => True) = 0,
               "focused process status");

         when Focus_AUnit_Spec_Name =>
            Assert
              (Project_Tools.AUnit_Checks.Spec_Name ("sample-tests.adb") = "sample-tests.ads",
               "focused spec name");

         when Focus_Tree_Check_Clean =>
            declare
               Errors : Natural := 0;
            begin
               Delete_Tree_If_Present (Root);
               Ada.Directories.Create_Path (Root & "/clean");
               Write_File (Root & "/clean/file.txt", "alpha" & ASCII.LF);
               Project_Tools.Tree_Checks.Check_No_Generated_Python
                 (Errors, Root & "/clean", Quiet => True);
               Assert (Errors = 0, "focused clean tree");
               Delete_Tree_If_Present (Root);
            end;

         when Focus_Security_Corpus_Clean =>
            declare
               Errors : Natural := 0;
            begin
               Delete_Tree_If_Present (Root);
               Ada.Directories.Create_Path (Root & "/corpus/auth");
               Write_File (Root & "/corpus/README.md", "redaction rules" & ASCII.LF);
               Write_File (Root & "/corpus/auth/case.txt", "Authorization: Bearer test" & ASCII.LF);
               Project_Tools.Security_Corpus.Check_Corpus
                 (Errors,
                  Root & "/corpus",
                  [To_Unbounded_String ("auth")],
                  [To_Unbounded_String ("production-secret")],
                  [To_Unbounded_String ("redaction rules")],
                  4096,
                  Quiet => True);
               Assert (Errors = 0, "focused security corpus clean");
               Delete_Tree_If_Present (Root);
            end;
      end case;
   exception
      when others =>
         Delete_Tree_If_Present (Root);
         raise;
   end Run_Test;

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      --  Add_Test takes an anonymous access parameter; allocating straight into
      --  it yields an anonymous-access allocator whose pool is implementation
      --  defined. Naming the type pins the cases to the standard pool.
      type Test_Case_Access is access all AUnit.Simple_Test_Cases.Test_Case'Class;

      Result : constant AUnit.Test_Suites.Access_Test_Suite := AUnit.Test_Suites.New_Suite;
   begin
      Result.Add_Test (Test_Case_Access'(new Project_Tools_Test_Suite.Files_Tests.Text_Helper_Test));
      Result.Add_Test (Test_Case_Access'(new Project_Tools_Test_Suite.Files_Tests.File_Helper_Test));
      Result.Add_Test (Test_Case_Access'(new Project_Tools_Test_Suite.Files_Tests.File_Failure_Test));
      Result.Add_Test (Test_Case_Access'(new Project_Tools_Test_Suite.Checks_Tests.Alire_Manifest_Failure_Test));
      Result.Add_Test (Test_Case_Access'(new Project_Tools_Test_Suite.Processes_Tests.Process_Helper_Test));
      Result.Add_Test (Test_Case_Access'(new Project_Tools_Test_Suite.Processes_Tests.Process_Failure_Test));
      Result.Add_Test (Test_Case_Access'(new Project_Tools_Test_Suite.Processes_Tests.Process_Output_Test));
      Result.Add_Test (Test_Case_Access'(new Project_Tools_Test_Suite.Processes_Tests.Promoted_Helpers_Test));
      Result.Add_Test (Test_Case_Access'(new Project_Tools_Test_Suite.Checks_Tests.Release_Checks_Fail_Test));
      Result.Add_Test (Test_Case_Access'(new Project_Tools_Test_Suite.Checks_Tests.Release_Checks_Git_Test));
      Result.Add_Test (Test_Case_Access'(new Project_Tools_Test_Suite.Checks_Tests.AUnit_Check_Helper_Test));
      Result.Add_Test (Test_Case_Access'(new Project_Tools_Test_Suite.Checks_Tests.Tree_Check_Helper_Test));
      Result.Add_Test (Test_Case_Access'(new Project_Tools_Test_Suite.Checks_Tests.Security_Corpus_Helper_Test));
      Result.Add_Test (Test_Case_Access'(new Project_Tools_Test_Suite.Files_Tests.JSON_Helper_Test));
      Result.Add_Test (Test_Case_Access'(new Focused_Test (Area => Focus_Text_Contains)));
      Result.Add_Test (Test_Case_Access'(new Focused_Test (Area => Focus_Text_Count)));
      Result.Add_Test (Test_Case_Access'(new Focused_Test (Area => Focus_File_Exists)));
      Result.Add_Test (Test_Case_Access'(new Focused_Test (Area => Focus_File_Contains)));
      Result.Add_Test (Test_Case_Access'(new Focused_Test (Area => Focus_Manifest_No_Pins)));
      Result.Add_Test (Test_Case_Access'(new Focused_Test (Area => Focus_Manifest_Dependency)));
      Result.Add_Test (Test_Case_Access'(new Focused_Test (Area => Focus_Process_Status)));
      Result.Add_Test (Test_Case_Access'(new Focused_Test (Area => Focus_AUnit_Spec_Name)));
      Result.Add_Test (Test_Case_Access'(new Focused_Test (Area => Focus_Tree_Check_Clean)));
      Result.Add_Test (Test_Case_Access'(new Focused_Test (Area => Focus_Security_Corpus_Clean)));
      return Result;
   end Suite;
end Project_Tools_Test_Suite;
