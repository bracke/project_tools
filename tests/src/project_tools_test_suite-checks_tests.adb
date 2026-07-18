with Ada.Command_Line;
with Ada.Directories;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with GNAT.OS_Lib;

with AUnit;
with AUnit.Assertions;
with AUnit.Simple_Test_Cases;

with Project_Tools.Alire_Manifests;
with Project_Tools.Ada_Source;
with Project_Tools.AUnit_Checks;
with Project_Tools.Files;
with Project_Tools.JSON;
with Project_Tools.Processes;
with Project_Tools.Release_Checks;
with Project_Tools.Security_Corpus;
with Project_Tools.Text;
with Project_Tools.Tree_Checks;

with Project_Tools_Test_Suite.Support;

package body Project_Tools_Test_Suite.Checks_Tests is
   use AUnit.Assertions;
   use Ada.Strings.Unbounded;
   use type GNAT.OS_Lib.String_Access;
   use Project_Tools_Test_Suite.Support;

   overriding function Name (Item : Alire_Manifest_Failure_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("Alire manifest failures");
   end Name;

   overriding procedure Run_Test (Item : in out Alire_Manifest_Failure_Test) is
      pragma Unreferenced (Item);
   begin
      Delete_Tree_If_Present (Root);
      Ada.Directories.Create_Path (Root);
      Write_File
        (Root & "/pinned.toml",
         "name = ""example""" & ASCII.LF
         & "[[depends-on]]" & ASCII.LF
         & "dep = ""*""" & ASCII.LF
         & "[[pins]]" & ASCII.LF
         & "dep = { path = ""../dep"" }" & ASCII.LF);
      Write_File
        (Root & "/release.toml",
         "name = ""example""" & ASCII.LF
         & "[[depends-on]]" & ASCII.LF
         & "dep = ""*""" & ASCII.LF);
      Write_File
        (Root & "/bad-imports.ads",
         "with I18N.Runtime, I18N.Parser;" & ASCII.LF
         & "package Bad_Imports is end Bad_Imports;" & ASCII.LF);
      Write_File
        (Root & "/bad-policy.adb",
         "package body Bad_Policy is" & ASCII.LF
         & "   function Label return String is" & ASCII.LF
         & "   begin" & ASCII.LF
         & "      return ""yesterday"";" & ASCII.LF
         & "   end Label;" & ASCII.LF
         & "end Bad_Policy;" & ASCII.LF);
      Write_File
        (Root & "/duplicate-returns.adb",
         "package body Duplicate_Returns is" & ASCII.LF
         & "   function Key (Id : Integer) return String is" & ASCII.LF
         & "   begin" & ASCII.LF
         & "      case Id is" & ASCII.LF
         & "         when 1 => return ""same"";" & ASCII.LF
         & "         when others => return ""same"";" & ASCII.LF
         & "      end case;" & ASCII.LF
         & "   end Key;" & ASCII.LF
         & "end Duplicate_Returns;" & ASCII.LF);
      Write_File
        (Root & "/bad-gnatdoc.ads",
         "package Bad_GNATdoc is" & ASCII.LF
         & "--  Missing the return tag entirely." & ASCII.LF
         & "--  @param Input input value" & ASCII.LF
         & "function Value (Input : Integer) return Integer;" & ASCII.LF
         & "end Bad_GNATdoc;" & ASCII.LF);
      Ada.Directories.Create_Path (Root & "/staged");
      Write_File (Root & "/staged/alire.toml", "name = ""staged""" & ASCII.LF);

      declare
         procedure Missing_GNATdoc_Return is
         begin
            Project_Tools.Ada_Source.Require_Public_GNATdoc_Tags
              (Root & "/bad-gnatdoc.ads", Quiet => True);
         end Missing_GNATdoc_Return;

         procedure Local_Pin_In_Release is
         begin
            Project_Tools.Alire_Manifests.Require_No_Local_Pins (Root & "/pinned.toml", Quiet => True);
         end Local_Pin_In_Release;

         procedure Missing_Release_Dependency is
         begin
            Project_Tools.Alire_Manifests.Require_Release_Dependency
              (Root & "/release.toml", "missing_dep", Quiet => True);
         end Missing_Release_Dependency;

         procedure Wrong_Crate_Name is
         begin
            Project_Tools.Alire_Manifests.Require_Pin_Free_Crate_Manifest
              (Root & "/release.toml", "other", Quiet => True);
         end Wrong_Crate_Name;

         procedure Missing_Staged_Source_File is
         begin
            Project_Tools.Alire_Manifests.Require_Staged_Crate_Source
              (Root & "/staged", "staged", "staged.gpr", Quiet => True);
         end Missing_Staged_Source_File;

         procedure Missing_Build_Overlay_Pin is
         begin
            Project_Tools.Alire_Manifests.Require_Build_Overlay
              (Root & "/release.toml",
               Root & "/release.toml",
               [To_Unbounded_String ("missing = { path = ""../missing"" }")],
               Quiet => True);
         end Missing_Build_Overlay_Pin;

         procedure Disallowed_With_Clause is
         begin
            Project_Tools.Ada_Source.Require_Only_Allowed_With_Clauses
              (Root & "/bad-imports.ads",
               "I18N.",
               [1 => To_Unbounded_String ("I18N.Runtime")],
               Quiet => True);
         end Disallowed_With_Clause;

         procedure Forbidden_Code_Token is
         begin
            Project_Tools.Ada_Source.Require_No_Code_Tokens
              (Root & "/bad-policy.adb",
               [1 => To_Unbounded_String ("yesterday")],
               Quiet => True);
         end Forbidden_Code_Token;

         procedure Duplicate_String_Return is
         begin
            Project_Tools.Ada_Source.Require_Unique_String_Returns
              (Root & "/duplicate-returns.adb", "Key", Quiet => True);
         end Duplicate_String_Return;
      begin
         Expect_Program_Error
           (Missing_GNATdoc_Return'Access, "missing @return raises Program_Error");
         Expect_Program_Error (Local_Pin_In_Release'Access, "local pin rejection raises Program_Error");
         Expect_Program_Error
           (Missing_Release_Dependency'Access, "missing release dependency raises Program_Error");
         Expect_Program_Error (Wrong_Crate_Name'Access, "wrong crate name raises Program_Error");
         Expect_Program_Error
           (Missing_Staged_Source_File'Access, "incomplete staged source raises Program_Error");
         Expect_Program_Error (Missing_Build_Overlay_Pin'Access, "incomplete build overlay raises Program_Error");
         Expect_Program_Error (Disallowed_With_Clause'Access, "disallowed with clause raises Program_Error");
         Expect_Program_Error (Forbidden_Code_Token'Access, "forbidden code token raises Program_Error");
         Expect_Program_Error (Duplicate_String_Return'Access, "duplicate string return raises Program_Error");
      end;

      Delete_Tree_If_Present (Root);
   exception
      when others =>
         Delete_Tree_If_Present (Root);
         raise;
   end Run_Test;

   overriding function Name (Item : Release_Checks_Fail_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("Release_Checks.Fail");
   end Name;

   overriding procedure Run_Test (Item : in out Release_Checks_Fail_Test) is
      pragma Unreferenced (Item);
      Lock_Path : constant String := Root & "/workspace-build.lock";
      procedure Do_Fail is
      begin
         Project_Tools.Release_Checks.Fail ("intentional release failure", Quiet => True);
      end Do_Fail;

      procedure Duplicate_Lock_Fails is
      begin
         Project_Tools.Release_Checks.Create_Workspace_Build_Lock
           (Lock_Path, "second owner", Quiet => True);
      end Duplicate_Lock_Fails;

      procedure Active_Lock_Wait_Fails is
      begin
         Project_Tools.Release_Checks.Wait_For_Workspace_Build_Lock
           (Lock_Path, 0, Quiet => True);
      end Active_Lock_Wait_Fails;
   begin
      Expect_Program_Error
        (Do_Fail'Access, "Release_Checks.Fail raises Program_Error on failure");
      Delete_Tree_If_Present (Root);
      Ada.Directories.Create_Path (Root);
      Project_Tools.Release_Checks.Create_Workspace_Build_Lock
        (Lock_Path, "test owner", Quiet => True);
      Assert
        (Project_Tools.Files.Directory_Exists (Lock_Path),
         "workspace build lock uses an atomic directory");
      Assert
        (Project_Tools.Files.File_Contains (Lock_Path & "/owner", "test owner"),
         "workspace build lock records owner metadata");
      Expect_Program_Error
        (Duplicate_Lock_Fails'Access,
         "workspace build lock rejects duplicate acquisition");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
      Expect_Program_Error
        (Active_Lock_Wait_Fails'Access,
         "workspace build lock wait fails when timeout is zero");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
      Project_Tools.Release_Checks.Remove_Workspace_Build_Lock
        (Lock_Path, Quiet => True);
      Assert
        (not Project_Tools.Files.Exists (Lock_Path),
         "workspace build lock cleanup removes lock directory");
      Delete_Tree_If_Present (Root);
   end Run_Test;

   overriding function Name (Item : Release_Checks_Git_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("Release_Checks.Require_Clean_Git_Worktree");
   end Name;

   overriding procedure Run_Test (Item : in out Release_Checks_Git_Test) is
      pragma Unreferenced (Item);
      Git_Path : constant String := Project_Tools.Processes.Locate_Command ("git");
      Git_Args : GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("init"), new String'("--quiet")];
      Repo     : constant String := Root & "/git-clean";

      procedure Require_Dirty_Fails is
      begin
         Project_Tools.Release_Checks.Require_Clean_Git_Worktree
           ("test repo", Repo, Quiet => True);
      end Require_Dirty_Fails;
   begin
      Assert (Git_Path /= "", "git executable is available on PATH");
      Delete_Tree_If_Present (Root);
      Ada.Directories.Create_Path (Repo);
      Project_Tools.Processes.Run
        (Label   => "initialize temporary git repository",
         Dir     => Repo,
         Program => Git_Path,
         Args    => Git_Args,
         Quiet   => True);

      Project_Tools.Release_Checks.Require_Clean_Git_Worktree
        ("test repo", Repo, Quiet => True);
      Write_File (Repo & "/untracked.txt", "dirty" & ASCII.LF);
      Expect_Program_Error
        (Require_Dirty_Fails'Access,
         "Require_Clean_Git_Worktree raises Program_Error for dirty status");

      GNAT.OS_Lib.Free (Git_Args (1));
      GNAT.OS_Lib.Free (Git_Args (2));
      Delete_Tree_If_Present (Root);
   exception
      when others =>
         if Git_Args (1) /= null then
            GNAT.OS_Lib.Free (Git_Args (1));
         end if;
         if Git_Args (2) /= null then
            GNAT.OS_Lib.Free (Git_Args (2));
         end if;
         Delete_Tree_If_Present (Root);
         raise;
   end Run_Test;

   overriding function Name (Item : AUnit_Check_Helper_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("AUnit check helpers");
   end Name;

   overriding procedure Run_Test (Item : in out AUnit_Check_Helper_Test) is
      pragma Unreferenced (Item);
      Body_Path : constant String := Root & "/sample-tests.adb";
      Spec_Path : constant String := Root & "/sample-tests.ads";
      Metrics   : Project_Tools.AUnit_Checks.Suite_Metrics;
      Errors    : Natural := 0;
   begin
      Delete_Tree_If_Present (Root);
      Ada.Directories.Create_Path (Root);
      Write_File
        (Spec_Path,
         "with AUnit;" & ASCII.LF
         & "with AUnit.Test_Cases;" & ASCII.LF
         & "package Sample.Tests is" & ASCII.LF
         & "type Section_Test_Case is new AUnit.Test_Cases.Test_Case with null record;" & ASCII.LF
         & "function Name (T : Section_Test_Case) return AUnit.Message_String;" & ASCII.LF
         & "procedure Register_Tests (T : in out Section_Test_Case);" & ASCII.LF
         & "end Sample.Tests;" & ASCII.LF);
      Write_File
        (Body_Path,
         "package body Sample.Tests is" & ASCII.LF
         & "procedure Test_One is begin Assert (True, ""ok""); end Test_One;" & ASCII.LF
         & "procedure Register_Tests is begin Register_Routine; end Register_Tests;" & ASCII.LF
         & "function Name return String is begin return ""Sample""; end Name;" & ASCII.LF
         & "end Sample.Tests;" & ASCII.LF);
      Project_Tools.AUnit_Checks.Check_Section_Suite
        (Errors,
         Body_Path,
         Spec_Path,
         "sample-tests.adb",
         [To_Unbounded_String ("with AUnit;"), To_Unbounded_String ("procedure Register_Tests")],
         [To_Unbounded_String ("Register_Tests"), To_Unbounded_String ("function Name")],
         [To_Unbounded_String ("Offline_Test_Cases")],
         10,
         Metrics,
         Quiet => True);
      Assert (Errors = 0, "valid section suite has no helper errors");
      Assert (Metrics.Section_Count = 1, "section metric increments");
      Assert (Metrics.Registration_Count = 1, "registration metric counts registrations");
      Assert (Metrics.Assertion_Count = 1, "assertion metric counts assertions");
      Assert
        (Project_Tools.AUnit_Checks.Spec_Name ("sample-tests.adb") = "sample-tests.ads",
         "spec-name helper maps body to spec");
      declare
         Collected : constant Project_Tools.AUnit_Checks.Suite_Metrics :=
           Project_Tools.AUnit_Checks.Collect_Suite_Metrics (Root, "*.adb");
      begin
         Assert (Collected.Section_Count = 1, "collector counts matching section files");
         Assert (Collected.Registration_Count = 1, "collector counts registrations");
         Assert (Collected.Assertion_Count = 1, "collector counts assertions");
         Assert (Collected.Test_Body_Count = 1, "collector counts test bodies");
      end;
      Ada.Directories.Create_Path (Root & "/suite");
      Write_File
        (Root & "/suite/sample_one_tests.ads",
         "package Sample_One_Tests is type Test_Case is null record; end Sample_One_Tests;" & ASCII.LF);
      Write_File
        (Root & "/suite/sample_one_tests.adb",
         "package body Sample_One_Tests is Register_Routine; end Sample_One_Tests;" & ASCII.LF);
      Write_File
        (Root & "/suite/suite.adb",
         "with Sample_One_Tests;" & ASCII.LF
         & "procedure Suite is begin Result.Add_Test (new Sample_One_Tests.Test_Case); end Suite;" & ASCII.LF);
      Write_File (Root & "/suite/TESTING.md", "- `sample_one_tests`" & ASCII.LF);
      Project_Tools.AUnit_Checks.Require_Registered_Test_Packages
        (Test_Dir               => Root & "/suite",
         Spec_Pattern           => "sample_*_tests.ads",
         Suite_Path             => Root & "/suite/suite.adb",
         Documentation_Path     => Root & "/suite/TESTING.md",
         Documented_Stem_Prefix => "- `sample_",
         Quiet                  => True);

      --  Hierarchical aggregate style: section packages expose a Suite
      --  function added via Result.Add_Test (Pkg.Suite); no docs inventory,
      --  a support package without Suite is skipped, and a runner-like
      --  sibling (demo_suite_tests.adb) must not trip the orphan-body scan.
      Ada.Directories.Create_Path (Root & "/hsuite");
      Write_File
        (Root & "/hsuite/demo_suite-alpha.ads",
         "with AUnit.Test_Suites;" & ASCII.LF
         & "package Demo_Suite.Alpha is" & ASCII.LF
         & "function Suite return AUnit.Test_Suites.Access_Test_Suite;" & ASCII.LF
         & "end Demo_Suite.Alpha;" & ASCII.LF);
      Write_File
        (Root & "/hsuite/demo_suite-alpha.adb",
         "package body Demo_Suite.Alpha is Register_Routine; end Demo_Suite.Alpha;" & ASCII.LF);
      Write_File
        (Root & "/hsuite/demo_suite-support.ads",
         "package Demo_Suite.Support is X : constant Integer := 0; end Demo_Suite.Support;" & ASCII.LF);
      Write_File
        (Root & "/hsuite/demo_suite-support.adb",
         "package body Demo_Suite.Support is end Demo_Suite.Support;" & ASCII.LF);
      Write_File
        (Root & "/hsuite/demo_suite.adb",
         "with Demo_Suite.Alpha;" & ASCII.LF
         & "package body Demo_Suite is" & ASCII.LF
         & "function Suite return AUnit.Test_Suites.Access_Test_Suite is" & ASCII.LF
         & "begin Result.Add_Test (Demo_Suite.Alpha.Suite); return Result; end Suite;" & ASCII.LF
         & "end Demo_Suite;" & ASCII.LF);
      Write_File
        (Root & "/hsuite/demo_suite_tests.adb",
         "procedure Demo_Suite_Tests is begin null; end Demo_Suite_Tests;" & ASCII.LF);
      Project_Tools.AUnit_Checks.Require_Registered_Test_Packages
        (Test_Dir         => Root & "/hsuite",
         Spec_Pattern     => "demo_suite-*.ads",
         Suite_Path       => Root & "/hsuite/demo_suite.adb",
         Suite_Add_Prefix => "Result.Add_Test (",
         Suite_Add_Suffix => ".Suite)",
         Section_Marker   => "function Suite",
         Quiet            => True);
      Delete_Tree_If_Present (Root);
   exception
      when others =>
         Delete_Tree_If_Present (Root);
         raise;
   end Run_Test;

   overriding function Name (Item : Tree_Check_Helper_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("Tree check helpers");
   end Name;

   overriding procedure Run_Test (Item : in out Tree_Check_Helper_Test) is
      pragma Unreferenced (Item);
      Errors : Natural := 0;
   begin
      Delete_Tree_If_Present (Root);
      Ada.Directories.Create_Path (Root & "/clean");
      Write_File (Root & "/clean/file.txt", "alpha" & ASCII.LF);
      Project_Tools.Tree_Checks.Check_No_Generated_Python (Errors, Root & "/clean", Quiet => True);
      Project_Tools.Tree_Checks.Check_No_Forbidden_Tokens
        (Errors, Root & "/clean", [To_Unbounded_String ("forbidden")], "clean tree", Quiet => True);
      Project_Tools.Tree_Checks.Check_No_Forbidden_Tree_Artifacts
        (Errors,
         Root & "/clean",
         [To_Unbounded_String ("obj")],
         [To_Unbounded_String (".ali")],
         "clean tree",
         Quiet => True);
      Assert (Errors = 0, "clean tree has no hygiene errors");
      Project_Tools.Tree_Checks.Require_No_Nonempty_Stderr (Root & "/clean", Quiet => True);
      Write_File
        (Root & "/clean/sample.ads.stderr",
         "cannot generate code for file sample.ads (package spec)" & ASCII.LF);
      Project_Tools.Tree_Checks.Require_No_Nonempty_Stderr
        (Root & "/clean",
         Quiet                         => True,
         Allow_GNAT_Package_Spec_Stderr => True);

      --  A gnatprove info note spans a primary "info:" line plus indented
      --  continuation text; the whole file is benign and must not be flagged.
      Ada.Directories.Create_Path (Root & "/prove");
      Write_File
        (Root & "/prove/unit.adb.stderr",
         "unit.adb:5:18: info: SPARK_Mode not applied to this compilation unit" & ASCII.LF
         & "  only enclosed declarations with SPARK_Mode will be analyzed" & ASCII.LF);
      Project_Tools.Tree_Checks.Require_No_Nonempty_Stderr (Root & "/prove", Quiet => True);

      --  A real warning at column 1 is still rejected.
      Write_File
        (Root & "/prove/bad.adb.stderr", "bad.adb:1:1: warning: dubious" & ASCII.LF);
      declare
         Raised : Boolean := False;
      begin
         begin
            Project_Tools.Tree_Checks.Require_No_Nonempty_Stderr (Root & "/prove", Quiet => True);
         exception
            when Program_Error =>
               Raised := True;
         end;
         Assert (Raised, "a real warning stderr line is still rejected");
      end;

      --  The gnatprove output tree is skipped wholesale: even a warning-looking
      --  line under a "gnatprove" directory is not flagged, because gnatprove's
      --  exit status already gates real errors.
      Ada.Directories.Create_Path (Root & "/staged/obj/gnatprove");
      Write_File
        (Root & "/staged/obj/gnatprove/unit.adb.stderr",
         "unit.adb:1:1: warning: this would trip a normal scan" & ASCII.LF);
      Project_Tools.Tree_Checks.Require_No_Nonempty_Stderr (Root & "/staged", Quiet => True);

      Write_File (Root & "/clean/script.py", "print('x')" & ASCII.LF);
      Project_Tools.Tree_Checks.Check_No_Generated_Python (Errors, Root & "/clean", Quiet => True);
      Assert (Errors = 1, "python artifact increments hygiene errors");
      Write_File (Root & "/clean/generated.ali", "artifact" & ASCII.LF);
      Project_Tools.Tree_Checks.Check_No_Forbidden_Tree_Artifacts
        (Errors,
         Root & "/clean",
         [To_Unbounded_String ("obj")],
         [To_Unbounded_String (".ali")],
         "dirty tree",
         Quiet => True);
      Assert (Errors = 2, "forbidden suffix increments hygiene errors");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);

      Delete_Tree_If_Present (Root);
   exception
      when others =>
         Delete_Tree_If_Present (Root);
         raise;
   end Run_Test;

   overriding function Name (Item : Security_Corpus_Helper_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("Security corpus helpers");
   end Name;

   overriding procedure Run_Test (Item : in out Security_Corpus_Helper_Test) is
      pragma Unreferenced (Item);
      Errors : Natural := 0;
   begin
      Delete_Tree_If_Present (Root);
      Ada.Directories.Create_Path (Root & "/corpus/auth");
      Write_File
        (Root & "/corpus/README.md",
         "do not include production credentials" & ASCII.LF
         & "random fuzz campaigns must print" & ASCII.LF);
      Write_File (Root & "/corpus/auth/case.txt", "Authorization: Bearer test" & ASCII.LF);
      Project_Tools.Security_Corpus.Check_Corpus
        (Errors,
         Root & "/corpus",
         [To_Unbounded_String ("auth")],
         [To_Unbounded_String ("production-secret")],
         [To_Unbounded_String ("do not include production credentials")],
         4096,
         Quiet => True);
      Assert (Errors = 0, "valid security corpus has no helper errors");
      Write_File (Root & "/corpus/auth/secret.txt", "production-secret" & ASCII.LF);
      Project_Tools.Security_Corpus.Check_Corpus
        (Errors,
         Root & "/corpus",
         [To_Unbounded_String ("auth")],
         [To_Unbounded_String ("production-secret")],
         [To_Unbounded_String ("do not include production credentials")],
         4096,
         Quiet => True);
      Assert (Errors > 0, "secret-like token increments corpus errors");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
      Delete_Tree_If_Present (Root);
   exception
      when others =>
         Delete_Tree_If_Present (Root);
         raise;
   end Run_Test;

end Project_Tools_Test_Suite.Checks_Tests;
