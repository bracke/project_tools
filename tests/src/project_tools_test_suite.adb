with Ada.Command_Line;
with Ada.Directories;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with GNAT.OS_Lib;

with AUnit;
with AUnit.Assertions;
with AUnit.Simple_Test_Cases;
with AUnit.Test_Suites;

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

package body Project_Tools_Test_Suite is
   use AUnit.Assertions;
   use Ada.Strings.Unbounded;
   use type GNAT.OS_Lib.String_Access;

   type Text_Helper_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   type File_Helper_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   type File_Failure_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   type Alire_Manifest_Failure_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   type Process_Helper_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   type Process_Failure_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   type Process_Output_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   type Promoted_Helpers_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   type Release_Checks_Fail_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   type Release_Checks_Git_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   type AUnit_Check_Helper_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   type Tree_Check_Helper_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   type Security_Corpus_Helper_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   type JSON_Helper_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;

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

   overriding function Name (Item : Text_Helper_Test) return AUnit.Message_String;
   overriding function Name (Item : File_Helper_Test) return AUnit.Message_String;
   overriding function Name (Item : File_Failure_Test) return AUnit.Message_String;
   overriding function Name (Item : Alire_Manifest_Failure_Test) return AUnit.Message_String;
   overriding function Name (Item : Process_Helper_Test) return AUnit.Message_String;
   overriding function Name (Item : Process_Failure_Test) return AUnit.Message_String;
   overriding function Name (Item : Process_Output_Test) return AUnit.Message_String;
   overriding function Name (Item : Promoted_Helpers_Test) return AUnit.Message_String;
   overriding function Name (Item : Release_Checks_Fail_Test) return AUnit.Message_String;
   overriding function Name (Item : Release_Checks_Git_Test) return AUnit.Message_String;
   overriding function Name (Item : AUnit_Check_Helper_Test) return AUnit.Message_String;
   overriding function Name (Item : Tree_Check_Helper_Test) return AUnit.Message_String;
   overriding function Name (Item : Security_Corpus_Helper_Test) return AUnit.Message_String;
   overriding function Name (Item : JSON_Helper_Test) return AUnit.Message_String;
   overriding function Name (Item : Focused_Test) return AUnit.Message_String;

   overriding procedure Run_Test (Item : in out Text_Helper_Test);
   overriding procedure Run_Test (Item : in out File_Helper_Test);
   overriding procedure Run_Test (Item : in out File_Failure_Test);
   overriding procedure Run_Test (Item : in out Alire_Manifest_Failure_Test);
   overriding procedure Run_Test (Item : in out Process_Helper_Test);
   overriding procedure Run_Test (Item : in out Process_Failure_Test);
   overriding procedure Run_Test (Item : in out Process_Output_Test);
   overriding procedure Run_Test (Item : in out Promoted_Helpers_Test);
   overriding procedure Run_Test (Item : in out Release_Checks_Fail_Test);
   overriding procedure Run_Test (Item : in out Release_Checks_Git_Test);
   overriding procedure Run_Test (Item : in out AUnit_Check_Helper_Test);
   overriding procedure Run_Test (Item : in out Tree_Check_Helper_Test);
   overriding procedure Run_Test (Item : in out Security_Corpus_Helper_Test);
   overriding procedure Run_Test (Item : in out JSON_Helper_Test);
   overriding procedure Run_Test (Item : in out Focused_Test);

   Root : constant String := "/tmp/project_tools_tests";

   procedure Delete_Tree_If_Present (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_Tree (Path);
      end if;
   end Delete_Tree_If_Present;

   procedure Write_File (Path : String; Content : String) is
   begin
      Project_Tools.Files.Write_Text_File (Path, Content);
   end Write_File;

   procedure Expect_Program_Error
     (Action  : not null access procedure;
      Message : String) is
   begin
      Action.all;
      Assert (False, Message);
   exception
      when Program_Error =>
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end Expect_Program_Error;

   overriding function Name (Item : Text_Helper_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("Text helpers");
   end Name;

   overriding function Name (Item : File_Helper_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("File helpers");
   end Name;

   overriding function Name (Item : File_Failure_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("File helper failures");
   end Name;

   overriding function Name (Item : Alire_Manifest_Failure_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("Alire manifest failures");
   end Name;

   overriding function Name (Item : Process_Helper_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("Process helpers");
   end Name;

   overriding function Name (Item : Process_Failure_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("Process helper failures");
   end Name;

   overriding function Name (Item : Process_Output_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("Process output capture");
   end Name;

   overriding function Name (Item : Promoted_Helpers_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("Promoted version helpers");
   end Name;

   overriding function Name (Item : Release_Checks_Fail_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("Release_Checks.Fail");
   end Name;

   overriding function Name (Item : Release_Checks_Git_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("Release_Checks.Require_Clean_Git_Worktree");
   end Name;

   overriding function Name (Item : AUnit_Check_Helper_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("AUnit check helpers");
   end Name;

   overriding function Name (Item : Tree_Check_Helper_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("Tree check helpers");
   end Name;

   overriding function Name (Item : Security_Corpus_Helper_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("Security corpus helpers");
   end Name;

   overriding function Name (Item : JSON_Helper_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("JSON helpers");
   end Name;

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

   overriding procedure Run_Test (Item : in out JSON_Helper_Test) is
      pragma Unreferenced (Item);
      Text : constant String :=
        "{""result"":0,""metadata"":{""size"":12,""sha1"":""abc\nxyz""}," &
        """fileids"":[101],""hosts"":[""api.pcloud.test""]," &
        """contents"":[{""name"":""folder"",""isfolder"":true,""fileid"":1}," &
        "{""name"":""archive.zip"",""isfolder"":false,""fileid"":42}]}";
   begin
      Assert (Project_Tools.JSON.Field_Value (Text, "size") = "12", "recursive number field lookup");
      Assert
        (Project_Tools.JSON.Field_Value (Text, "sha1") = "abc" & ASCII.LF & "xyz",
         "string escapes are decoded");
      Assert (Project_Tools.JSON.Array_First_Value (Text, "fileids") = "101", "first array number");
      Assert (Project_Tools.JSON.Array_First_Value (Text, "hosts") = "api.pcloud.test", "first array string");
      Assert
        (Project_Tools.JSON.Find_Object_Field (Text, "name", "archive.zip", "fileid") = "42",
         "object search ignores folders and returns matching file field");
      Assert
        (Project_Tools.JSON.Object_Field_Value (Text, "size") = "",
         "object-local lookup does not inspect nested metadata");
   end Run_Test;

   overriding procedure Run_Test (Item : in out Text_Helper_Test) is
      pragma Unreferenced (Item);
   begin
      Assert (Project_Tools.Text.Contains ("abc def", "bc"), "contains finds a substring");
      Assert (not Project_Tools.Text.Contains ("abc def", "xy"), "contains rejects missing substring");
      Assert (Project_Tools.Text.Count ("one one one", "one") = 3, "count finds non-overlapping matches");
      Assert (Project_Tools.Text.Count ("aaaa", "aa") = 2, "count advances by pattern length");
      Assert (Project_Tools.Text.Count ("abc", "") = 0, "count ignores empty patterns");
      Assert
        (Project_Tools.Files.File_Contains
           ("README.md", "alr exec -- gnatprove -P project_tools.gpr --level=0 --mode=check")
         or else Project_Tools.Files.File_Contains
           ("../README.md", "alr exec -- gnatprove -P project_tools.gpr --level=0 --mode=check"),
         "release verification documents the GNATprove check");
   end Run_Test;

   overriding procedure Run_Test (Item : in out File_Helper_Test) is
      pragma Unreferenced (Item);
      Text_Path   : constant String := Root & "/text.txt";
      Prefix_Path : constant String := Root & "/prefix.txt";
      Long_Prefix_Path : constant String := Root & "/long-prefix.txt";
   begin
      Delete_Tree_If_Present (Root);
      Ada.Directories.Create_Path (Root);

      Write_File (Text_Path, "alpha" & ASCII.LF & "beta" & ASCII.LF);
      Write_File (Prefix_Path, "alpha");
      Write_File (Long_Prefix_Path, "alpha beta gamma");
      Write_File
        (Root & "/alire.toml",
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

      Assert (Project_Tools.Files.Exists (Text_Path), "exists sees files");
      Assert (Project_Tools.Files.File_Exists (Text_Path), "file exists sees ordinary files");
      Assert (Project_Tools.Files.Directory_Exists (Root), "directory exists sees directories");
      Assert (Project_Tools.Files.File_Contains (Text_Path, "beta"), "file contains finds text");
      Assert (not Project_Tools.Files.File_Contains (Text_Path, "gamma"), "file contains rejects missing text");
      Assert
        (Project_Tools.Files.File_Starts_With_File (Text_Path, Prefix_Path),
         "prefix comparison accepts matching prefix file");
      Assert
        (Project_Tools.Files.Read_Raw_File (Text_Path)'Length > Project_Tools.Files.Read_Raw_File (Prefix_Path)'Length,
         "raw file reader preserves bytes");
      Project_Tools.Alire_Manifests.Require_Workspace_Pin
        (Root & "/alire.toml", "dep", "../dep", Quiet => True);
      Project_Tools.Alire_Manifests.Require_No_Local_Pins
        (Root & "/release.toml", Quiet => True);
      Project_Tools.Alire_Manifests.Require_Release_Dependency
        (Root & "/release.toml", "dep", Quiet => True);
      Project_Tools.Alire_Manifests.Require_Release_Dependencies
        (Root & "/release.toml", [To_Unbounded_String ("dep")], Quiet => True);
      Project_Tools.Alire_Manifests.Require_Pin_Free_Crate_Manifest
        (Root & "/release.toml", "example", Quiet => True);
      Project_Tools.Alire_Manifests.Copy_Release_Manifest
        (Root & "/release.toml", Root & "/release-copy.toml", Quiet => True);
      Assert
        (Project_Tools.Files.File_Contains (Root & "/release-copy.toml", "dep = ""*"""),
         "release manifest copy writes target template");
      Ada.Directories.Create_Path (Root & "/staged/src");
      Write_File (Root & "/staged/alire.toml", "name = ""staged""" & ASCII.LF);
      Write_File (Root & "/staged/staged.gpr", "project Staged is end Staged;" & ASCII.LF);
      Write_File (Root & "/staged/README.md", "readme" & ASCII.LF);
      Write_File (Root & "/staged/LICENSE", "license" & ASCII.LF);
      Project_Tools.Alire_Manifests.Require_Staged_Crate_Source
        (Root & "/staged", "staged", "staged.gpr", Quiet => True);
      Project_Tools.Alire_Manifests.Write_Build_Manifest_Overlay
        (Root & "/release.toml",
         Root & "/overlay.toml",
         "[[pins]]" & ASCII.LF
         & "dep = { path = ""../dep"" }" & ASCII.LF,
         Quiet => True);
      Project_Tools.Alire_Manifests.Require_Build_Overlay
        (Root & "/overlay.toml",
         Root & "/release.toml",
         [To_Unbounded_String ("dep = { path = ""../dep"" }")],
         Quiet => True);
      Ada.Directories.Create_Path (Root & "/manifest-swap");
      Write_File (Root & "/manifest-swap/alire.toml", "name = ""publish""" & ASCII.LF);
      Write_File (Root & "/manifest-swap/alire.build.toml", "name = ""build""" & ASCII.LF);
      Project_Tools.Alire_Manifests.Activate_Build_Manifest
        (Root & "/manifest-swap", Quiet => True);
      Assert
        (Project_Tools.Files.File_Contains (Root & "/manifest-swap/alire.toml", "build"),
         "build manifest activation installs build manifest");
      Assert
        (Project_Tools.Files.File_Contains (Root & "/manifest-swap/alire.publish.toml", "publish"),
         "build manifest activation saves publish manifest");
      Project_Tools.Alire_Manifests.Restore_Publish_Manifest (Root & "/manifest-swap");
      Assert
        (Project_Tools.Files.File_Contains (Root & "/manifest-swap/alire.toml", "publish"),
         "publish manifest restore reinstalls saved manifest");
      Assert
        (not Project_Tools.Files.File_Exists (Root & "/manifest-swap/alire.publish.toml"),
         "publish manifest restore removes saved manifest");

      Project_Tools.Files.Write_Text_File (Root & "/written.txt", "delta" & ASCII.LF);
      Assert
        (Project_Tools.Files.File_Contains (Root & "/written.txt", "delta"),
         "write text file creates content");
      Project_Tools.Files.Write_Raw_File
        (Root & "/raw.bin", "a" & Character'Val (0) & Character'Val (255));
      Assert
        (Project_Tools.Files.Read_Raw_File (Root & "/raw.bin")
         = "a" & Character'Val (0) & Character'Val (255),
         "raw write preserves byte-like string content");
      Project_Tools.Files.Append_Text_File (Text_Path, "gamma" & ASCII.LF);
      Assert (Project_Tools.Files.File_Contains (Text_Path, "gamma"), "append writes trailing text");
      Project_Tools.Files.Require_File (Text_Path, "text file exists", Quiet => True);
      Project_Tools.Files.Require_Files
        ([To_Unbounded_String (Text_Path), To_Unbounded_String (Prefix_Path)],
         "listed files exist",
         Quiet => True);
      Project_Tools.Files.Require_Directory (Root, "root directory exists", Quiet => True);
      Project_Tools.Files.Require_Directories
        ([To_Unbounded_String (Root), To_Unbounded_String (Root & "/staged")],
         "listed directories exist",
         Quiet => True);
      Project_Tools.Files.Require_Contains (Text_Path, "gamma", "text file contains gamma", Quiet => True);
      Project_Tools.Files.Require_File_Starts_With_File
        (Text_Path, Prefix_Path, "text file starts with prefix", Quiet => True);

      declare
         Check : constant Project_Tools.Release_Checks.Checker :=
           Project_Tools.Release_Checks.Create (Root);
      begin
         Project_Tools.Release_Checks.Require_File (Check, "text.txt", Quiet => True);
         Project_Tools.Release_Checks.Require_Directory (Check, "staged", Quiet => True);
         Project_Tools.Release_Checks.Require_Text (Check, "text.txt", "gamma", Quiet => True);
         Project_Tools.Release_Checks.Require_Absolute_File (Text_Path, Quiet => True);
         Project_Tools.Release_Checks.Require_Absolute_Directory (Root, Quiet => True);
      end;
      Ada.Directories.Create_Path (Root & "/tools/fuzz");
      Write_File
        (Root & "/tools/tools.gpr",
         "project Tools is" & ASCII.LF
         & "for Main use (""tool_one.adb"", ""fuzz_case.adb"");" & ASCII.LF
         & "end Tools;" & ASCII.LF);
      Write_File (Root & "/tools/tool_one.adb", "procedure Tool_One is begin null; end Tool_One;" & ASCII.LF);
      Write_File (Root & "/tools/fuzz/fuzz_case.adb", "procedure Fuzz_Case is begin null; end Fuzz_Case;" & ASCII.LF);
      Write_File (Root & "/tools/README.md", "tool_one" & ASCII.LF & "fuzz_case" & ASCII.LF);
      Write_File
        (Root & "/docs-fuzz.md",
         "tools/fuzz/fuzz_case.adb" & ASCII.LF & "`fuzz_case`" & ASCII.LF);
      Write_File (Root & "/runner.adb", "./tools/bin/fuzz_case" & ASCII.LF);
      Project_Tools.Release_Checks.Require_GPR_Main_Inventory
        (Project_File                 => Root & "/tools/tools.gpr",
         Documentation_File           => Root & "/tools/README.md",
         Source_Directory             => Root & "/tools",
         Alternate_Stem_Prefix        => "fuzz_",
         Alternate_Source_Directory   => Root & "/tools/fuzz",
         Alternate_Documentation_File => Root & "/docs-fuzz.md",
         Runner_File                  => Root & "/runner.adb",
         Runner_Token_Prefix          => "./tools/bin/",
         Quiet                        => True);
      --  House convention: the GNATdoc block precedes each declaration.
      Write_File
        (Root & "/api.ads",
         "package API is" & ASCII.LF
         & "--  Transform an input value." & ASCII.LF
         & "--  @param Input input value" & ASCII.LF
         & "--  @param Status status output" & ASCII.LF
         & "--  @return transformed value" & ASCII.LF
         & "function Value (Input : Integer; Status : out Integer) return Integer;" & ASCII.LF
         & "--  Reset internal state." & ASCII.LF
         & "--  @param State state to reset" & ASCII.LF
         & "procedure Reset (State : out Integer);" & ASCII.LF
         & "private" & ASCII.LF
         & "function Private_Value (Input : Integer) return Integer;" & ASCII.LF
         & "end API;" & ASCII.LF);
      Project_Tools.Ada_Source.Require_Public_GNATdoc_Tags
        (Root & "/api.ads", Quiet => True);
      --  Trailing-comment convention is still accepted via Tags_Before => False.
      Write_File
        (Root & "/api-after.ads",
         "package API_After is" & ASCII.LF
         & "function Value (Input : Integer; Status : out Integer) return Integer;" & ASCII.LF
         & "--  @param Input input value" & ASCII.LF
         & "--  @param Status status output" & ASCII.LF
         & "--  @return transformed value" & ASCII.LF
         & "procedure Reset (State : out Integer);" & ASCII.LF
         & "--  @param State state to reset" & ASCII.LF
         & "end API_After;" & ASCII.LF);
      Project_Tools.Ada_Source.Require_Public_GNATdoc_Tags
        (Root & "/api-after.ads", Tags_Before => False, Quiet => True);
      Write_File
        (Root & "/imports.ads",
         "with Ada.Text_IO;" & ASCII.LF
         & "--  with I18N.Parser;" & ASCII.LF
         & "limited with I18N.Runtime, " & ASCII.LF
         & "  I18N.Locales;" & ASCII.LF
         & "private with I18N.Result;" & ASCII.LF
         & "package Imports is end Imports;" & ASCII.LF);
      Project_Tools.Ada_Source.Require_Only_Allowed_With_Clauses
        (Root & "/imports.ads",
         "I18N.",
         [To_Unbounded_String ("I18N.Runtime"),
          To_Unbounded_String ("I18N.Locales"),
          To_Unbounded_String ("I18N.Result")],
         Quiet => True);
      Write_File
        (Root & "/policy-ok.adb",
         "package body Policy_OK is" & ASCII.LF
         & "   -- yesterday is fine in comments" & ASCII.LF
         & "   function Key (Id : Integer) return String is" & ASCII.LF
         & "   begin" & ASCII.LF
         & "      case Id is" & ASCII.LF
         & "         when 0 => return """";" & ASCII.LF
         & "         when 1 => return ""alpha"";" & ASCII.LF
         & "         when others => return ""beta"";" & ASCII.LF
         & "      end case;" & ASCII.LF
         & "   end Key;" & ASCII.LF
         & "end Policy_OK;" & ASCII.LF);
      Project_Tools.Ada_Source.Require_No_Code_Tokens
        (Root & "/policy-ok.adb",
         [To_Unbounded_String ("yesterday"), To_Unbounded_String ("tomorrow")],
         Quiet => True);
      Project_Tools.Ada_Source.Require_Unique_String_Returns
        (Root & "/policy-ok.adb", "Key", Allow_Empty => True, Quiet => True);
      Assert
        (not Project_Tools.Files.File_Starts_With_File (Text_Path, Long_Prefix_Path),
         "prefix comparison rejects longer non-matching prefix files");
      Ada.Directories.Create_Path (Root & "/copy-src/keep");
      Ada.Directories.Create_Path (Root & "/copy-src/skipdir");
      Write_File (Root & "/copy-src/keep/file.txt", "kept");
      Write_File (Root & "/copy-src/skipdir/file.txt", "skipped dir");
      Write_File (Root & "/copy-src/alire.lock", "skipped file");
      Project_Tools.Files.Copy_Release_Source_Tree
        (Root & "/copy-src",
         Root & "/copy-dst",
         [To_Unbounded_String ("skipdir")],
         [To_Unbounded_String ("alire.lock")],
         Quiet => True);
      Assert
        (Project_Tools.Files.File_Exists (Root & "/copy-dst/keep/file.txt"),
         "filtered tree copy keeps ordinary files");
      Assert
        (not Project_Tools.Files.File_Exists (Root & "/copy-dst/skipdir/file.txt"),
         "filtered tree copy skips named directories");
      Assert
        (not Project_Tools.Files.File_Exists (Root & "/copy-dst/alire.lock"),
         "filtered tree copy skips named files");

      Ada.Directories.Create_Path (Root & "/manifest-src");
      Ada.Directories.Create_Path (Root & "/manifest-dst");
      Write_File (Root & "/manifest-src/alire.toml", "name = ""manifest""" & ASCII.LF);
      Project_Tools.Alire_Manifests.Copy_Dependency_Manifest
        (Root & "/manifest-src", Root & "/manifest-dst", Quiet => True);
      Assert
        (Project_Tools.Files.File_Contains (Root & "/manifest-dst/alire.toml", "manifest"),
         "dependency manifest copy writes target manifest");

      Delete_Tree_If_Present (Root);
   exception
      when others =>
         Delete_Tree_If_Present (Root);
         raise;
   end Run_Test;

   overriding procedure Run_Test (Item : in out File_Failure_Test) is
      pragma Unreferenced (Item);
      Text_Path : constant String := Root & "/text.txt";
   begin
      Delete_Tree_If_Present (Root);
      Ada.Directories.Create_Path (Root);
      Write_File (Text_Path, "alpha" & ASCII.LF);

      declare
         procedure Missing_File is
         begin
            Project_Tools.Files.Require_File (Root & "/missing.txt", "missing file", Quiet => True);
         end Missing_File;

         procedure Missing_File_List is
         begin
            Project_Tools.Files.Require_Files
              ([To_Unbounded_String (Text_Path), To_Unbounded_String (Root & "/missing.txt")],
               "missing listed file",
               Quiet => True);
         end Missing_File_List;

         procedure Missing_Directory is
         begin
            Project_Tools.Files.Require_Directory (Root & "/missing-dir", "missing directory", Quiet => True);
         end Missing_Directory;

         procedure Missing_Directory_List is
         begin
            Project_Tools.Files.Require_Directories
              ([To_Unbounded_String (Root), To_Unbounded_String (Root & "/missing-dir")],
               "missing listed directory",
               Quiet => True);
         end Missing_Directory_List;

         procedure Missing_Text is
         begin
            Project_Tools.Files.Require_Contains (Text_Path, "not-present", "missing text", Quiet => True);
         end Missing_Text;

         procedure Bad_Prefix is
         begin
            Project_Tools.Files.Require_File_Starts_With_File
              (Text_Path, Root & "/missing-prefix.txt", "missing prefix file", Quiet => True);
         end Bad_Prefix;
      begin
         Expect_Program_Error (Missing_File'Access, "missing file requirement raises Program_Error");
         Expect_Program_Error (Missing_File_List'Access, "missing file list requirement raises Program_Error");
         Expect_Program_Error (Missing_Directory'Access, "missing directory requirement raises Program_Error");
         Expect_Program_Error
           (Missing_Directory_List'Access, "missing directory list requirement raises Program_Error");
         Expect_Program_Error (Missing_Text'Access, "missing text requirement raises Program_Error");
         Expect_Program_Error (Bad_Prefix'Access, "bad prefix requirement raises Program_Error");
      end;

      Delete_Tree_If_Present (Root);
   exception
      when others =>
         Delete_Tree_If_Present (Root);
         raise;
   end Run_Test;

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

   overriding procedure Run_Test (Item : in out Process_Output_Test) is
      pragma Unreferenced (Item);
      Echo_Path : GNAT.OS_Lib.String_Access := GNAT.OS_Lib.Locate_Exec_On_Path ("echo");
      Args      : GNAT.OS_Lib.Argument_List (1 .. 1) :=
        (1 => new String'("project-tools-capture"));
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

   overriding procedure Run_Test (Item : in out Release_Checks_Fail_Test) is
      pragma Unreferenced (Item);
      procedure Do_Fail is
      begin
         Project_Tools.Release_Checks.Fail ("intentional release failure", Quiet => True);
      end Do_Fail;
   begin
      Expect_Program_Error
        (Do_Fail'Access, "Release_Checks.Fail raises Program_Error on failure");
   end Run_Test;

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
      Assert (Errors = 0, "clean tree has no hygiene errors");
      Project_Tools.Tree_Checks.Require_No_Nonempty_Stderr (Root & "/clean", Quiet => True);
      Write_File
        (Root & "/clean/sample.ads.stderr",
         "cannot generate code for file sample.ads (package spec)" & ASCII.LF);
      Project_Tools.Tree_Checks.Require_No_Nonempty_Stderr
        (Root & "/clean",
         Quiet                         => True,
         Allow_GNAT_Package_Spec_Stderr => True);
      Write_File (Root & "/clean/script.py", "print('x')" & ASCII.LF);
      Project_Tools.Tree_Checks.Check_No_Generated_Python (Errors, Root & "/clean", Quiet => True);
      Assert (Errors = 1, "python artifact increments hygiene errors");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);

      Delete_Tree_If_Present (Root);
   exception
      when others =>
         Delete_Tree_If_Present (Root);
         raise;
   end Run_Test;

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
      Result : constant AUnit.Test_Suites.Access_Test_Suite := AUnit.Test_Suites.New_Suite;
   begin
      Result.Add_Test (new Text_Helper_Test);
      Result.Add_Test (new File_Helper_Test);
      Result.Add_Test (new File_Failure_Test);
      Result.Add_Test (new Alire_Manifest_Failure_Test);
      Result.Add_Test (new Process_Helper_Test);
      Result.Add_Test (new Process_Failure_Test);
      Result.Add_Test (new Process_Output_Test);
      Result.Add_Test (new Promoted_Helpers_Test);
      Result.Add_Test (new Release_Checks_Fail_Test);
      Result.Add_Test (new Release_Checks_Git_Test);
      Result.Add_Test (new AUnit_Check_Helper_Test);
      Result.Add_Test (new Tree_Check_Helper_Test);
      Result.Add_Test (new Security_Corpus_Helper_Test);
      Result.Add_Test (new JSON_Helper_Test);
      Result.Add_Test (new Focused_Test (Area => Focus_Text_Contains));
      Result.Add_Test (new Focused_Test (Area => Focus_Text_Count));
      Result.Add_Test (new Focused_Test (Area => Focus_File_Exists));
      Result.Add_Test (new Focused_Test (Area => Focus_File_Contains));
      Result.Add_Test (new Focused_Test (Area => Focus_Manifest_No_Pins));
      Result.Add_Test (new Focused_Test (Area => Focus_Manifest_Dependency));
      Result.Add_Test (new Focused_Test (Area => Focus_Process_Status));
      Result.Add_Test (new Focused_Test (Area => Focus_AUnit_Spec_Name));
      Result.Add_Test (new Focused_Test (Area => Focus_Tree_Check_Clean));
      Result.Add_Test (new Focused_Test (Area => Focus_Security_Corpus_Clean));
      return Result;
   end Suite;
end Project_Tools_Test_Suite;
