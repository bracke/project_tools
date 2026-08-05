with Ada.Command_Line;
with Ada.Directories;
with Ada.Strings.Unbounded;

with GNAT.OS_Lib;

with AUnit.Assertions;

with Project_Tools.Alire_Manifests;
with Project_Tools.Alire;
with Project_Tools.Ada_Source;
with Project_Tools.Coverage_Ratchets;
with Project_Tools.Files;
with Project_Tools.Gcov;
with Project_Tools.Generated_Artifacts;
with Project_Tools.Generated_Docs;
with Project_Tools.JSON;
with Project_Tools.Release_Checks;
with Project_Tools.Source_Budgets;
with Project_Tools.Text;
with Project_Tools.Test_Fixtures;
with Project_Tools.TOML;

with Project_Tools_Test_Suite.Support;

package body Project_Tools_Test_Suite.Files_Tests is
   use AUnit.Assertions;
   use Ada.Strings.Unbounded;
   use type GNAT.OS_Lib.String_Access;
   use type Project_Tools.Test_Fixtures.Deterministic_Seed;
   use Project_Tools_Test_Suite.Support;

   function Toy_Hash (Text : String) return String is
      Image : constant String := Natural'Image (Text'Length);
   begin
      return "len-" & Image (Image'First + 1 .. Image'Last);
   end Toy_Hash;

   overriding function Name (Item : Text_Helper_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("Text helpers");
   end Name;

   overriding procedure Run_Test (Item : in out Text_Helper_Test) is
      pragma Unreferenced (Item);
   begin
      Assert (Project_Tools.Text.Contains ("abc def", "bc"), "contains finds a substring");
      Assert (not Project_Tools.Text.Contains ("abc def", "xy"), "contains rejects missing substring");
      Assert (Project_Tools.Text.Count ("one one one", "one") = 3, "count finds non-overlapping matches");
      Assert (Project_Tools.Text.Count ("aaaa", "aa") = 2, "count advances by pattern length");
      Assert (Project_Tools.Text.Count ("abc", "") = 0, "count ignores empty patterns");
      Assert
        (Project_Tools.Text.Line_Value
           ("alpha = one" & ASCII.LF & "beta = two" & ASCII.LF, "beta") = "two",
         "line value reads catalog-style values");
      Assert
        (Project_Tools.Text.Line_Value
           ("name=value" & ASCII.LF, "name", Separator => "=") = "value",
         "line value supports caller-selected separators");
      Assert
        (Project_Tools.Files.File_Contains
           ("README.md", "alr exec -- gnatprove -P project_tools.gpr --level=0 --mode=check")
         or else Project_Tools.Files.File_Contains
           ("../README.md", "alr exec -- gnatprove -P project_tools.gpr --level=0 --mode=check"),
         "release verification documents the GNATprove check");
   end Run_Test;

   overriding function Name (Item : File_Helper_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("File helpers");
   end Name;

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
      Ada.Directories.Create_Path (Root & "/scan/sub");
      Write_File (Root & "/scan/sub/tool.py", "print('not Ada workflow')" & ASCII.LF);

      Assert (Project_Tools.Files.Exists (Text_Path), "exists sees files");
      Assert (Project_Tools.Files.File_Exists (Text_Path), "file exists sees ordinary files");
      Assert (Project_Tools.Files.Directory_Exists (Root), "directory exists sees directories");
      Assert (Project_Tools.Files.File_Contains (Text_Path, "beta"), "file contains finds text");
      Assert (not Project_Tools.Files.File_Contains (Text_Path, "gamma"), "file contains rejects missing text");
      Assert
        (Project_Tools.Files.File_Starts_With_File (Text_Path, Prefix_Path),
         "prefix comparison accepts matching prefix file");
      declare
         First_Seed  : Project_Tools.Test_Fixtures.Deterministic_Seed :=
           16#1234_5678#;
         Second_Seed : Project_Tools.Test_Fixtures.Deterministic_Seed :=
           16#1234_5678#;
         First_Value  : Natural;
         Second_Value : Natural;
      begin
         Project_Tools.Test_Fixtures.Advance (First_Seed, First_Value);
         Project_Tools.Test_Fixtures.Advance (Second_Seed, Second_Value);
         Assert
           (First_Seed = Second_Seed and then First_Value = Second_Value,
            "deterministic seed advancement is stable");
         Assert
           (Project_Tools.Test_Fixtures.Seed_Image (First_Seed)'Length > 0,
            "seed image is nonempty for diagnostics");
      end;
      Assert
        (Project_Tools.Test_Fixtures.Generated_Text
           (16#CAFE_BABE#, 12, (First => 'a', Last => 'c')) =
         Project_Tools.Test_Fixtures.Generated_Text
           (16#CAFE_BABE#, 12, (First => 'a', Last => 'c')),
         "deterministic text generation repeats by seed");
      Assert
        (Project_Tools.Test_Fixtures.Generated_Text
           (16#CAFE_BABE#,
            12,
            (First => 'a', Last => 'c'),
            Include_LF => True,
            Final_LF   => True)'Length = 12,
         "deterministic text generation respects byte limit");
      Assert
        (Project_Tools.Files.Read_Raw_File (Text_Path)'Length > Project_Tools.Files.Read_Raw_File (Prefix_Path)'Length,
         "raw file reader preserves bytes");
      Assert
        (Project_Tools.Files.First_File_Name_Containing
           (Root & "/scan",
            [To_Unbounded_String (".py")])
         = Root & "/scan/sub/tool.py",
         "filename token scanner reports first matching tree path");
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
         Line  : constant String :=
           Project_Tools.Release_Checks.Manifest_Line (Root, "text.txt");
      begin
         Project_Tools.Release_Checks.Require_File (Check, "text.txt", Quiet => True);
         Project_Tools.Release_Checks.Require_Directory (Check, "staged", Quiet => True);
         Project_Tools.Release_Checks.Require_Text (Check, "text.txt", "gamma", Quiet => True);
         Project_Tools.Release_Checks.Require_Absolute_File (Text_Path, Quiet => True);
         Project_Tools.Release_Checks.Require_Absolute_Directory (Root, Quiet => True);
         Assert
           (Project_Tools.Text.Contains (Line, "text.txt bytes=")
            and then Project_Tools.Text.Contains (Line, " fnv1a64="),
            "release manifest line includes byte count and FNV-1a-64");
         Write_File (Root & "/MANIFEST.txt", Line & ASCII.LF);
         Project_Tools.Release_Checks.Require_Manifest_Entry
           (Root & "/MANIFEST.txt", Root, "text.txt", Quiet => True);
         Assert
           (Project_Tools.Release_Checks.Manifest_Line_Count (Root & "/MANIFEST.txt") = 1,
            "release manifest line count handles final newline");
         Project_Tools.Files.Write_Raw_File (Root & "/empty.bin", "");
         Assert
           (Project_Tools.Release_Checks.File_Length (Root & "/empty.bin") = 0,
            "release file length reports empty files");
         Assert
           (Project_Tools.Release_Checks.FNV1A64 (Root & "/empty.bin") = "cbf29ce484222325",
            "FNV-1a-64 helper uses standard offset basis for empty files");
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
      Ada.Directories.Create_Path (Root & "/srcpolicy");
      Write_File
        (Root & "/srcpolicy/bridge.adb",
         "with Messages;" & ASCII.LF
         & "procedure Bridge is begin null; end Bridge;" & ASCII.LF);
      Write_File
        (Root & "/srcpolicy/presentation.ads",
         "with Terminal_Styles;" & ASCII.LF
         & "package Presentation is end Presentation;" & ASCII.LF);
      Write_File
        (Root & "/srcpolicy/comments.adb",
         "procedure Comments is begin null; end Comments; -- gawk" & ASCII.LF);
      Assert
        (Project_Tools.Ada_Source.First_Source_File_Containing
           (Root & "/srcpolicy",
            "with Messages",
            Allowed_Files => [To_Unbounded_String (Root & "/srcpolicy/bridge.adb")]) = "",
         "source tree scanner honors exact allowed files");
      Assert
        (Project_Tools.Ada_Source.First_Source_File_Containing
           (Root & "/srcpolicy", "with Terminal_Styles") = Root & "/srcpolicy/presentation.ads",
         "source tree scanner reports first unexpected source file");
      Project_Tools.Ada_Source.Require_No_Code_Tokens_In_Tree
        (Root & "/srcpolicy",
         [To_Unbounded_String ("gawk"), To_Unbounded_String ("mawk")],
         Quiet => True);
      Write_File
        (Root & "/exception-scan.adb",
         "package body Exception_Scan is" & ASCII.LF
         & "   function Label (Id : Integer) return String is" & ASCII.LF
         & "   begin" & ASCII.LF
         & "      if Id = 0 then" & ASCII.LF
         & "         return ""when others => is data, not code"";" & ASCII.LF
         & "      end if;" & ASCII.LF
         & "      case Id is" & ASCII.LF
         & "         when others => return ""case fallback"";" & ASCII.LF
         & "      end case;" & ASCII.LF
         & "      case Id is" & ASCII.LF
         & "         when 1 =>" & ASCII.LF
         & "            case Id + 1 is" & ASCII.LF
         & "               when others => return ""nested generated fallback"";" & ASCII.LF
         & "            end case;" & ASCII.LF
         & "         when others => return ""outer generated fallback"";" & ASCII.LF
         & "      end case;" & ASCII.LF
         & "   exception" & ASCII.LF
         & "      when others => null; -- intentional silent recovery" & ASCII.LF
         & "   end Label;" & ASCII.LF
         & "   procedure Recover (Id : Integer) is" & ASCII.LF
         & "   begin" & ASCII.LF
         & "      null;" & ASCII.LF
         & "   exception" & ASCII.LF
         & "      case Id is" & ASCII.LF
         & "         when others => null;" & ASCII.LF
         & "      end case;" & ASCII.LF
         & "      when Constraint_Error | others => null; -- defensive recovery" & ASCII.LF
         & "   end Recover;" & ASCII.LF
         & "end Exception_Scan;" & ASCII.LF);
      declare
         Broad_Handler_Count : Natural := 0;

         procedure Count_Broad_Handler
           (Line_Number : Positive;
            Source_Line : String)
         is
            pragma Unreferenced (Line_Number);
         begin
            Broad_Handler_Count := Broad_Handler_Count + 1;
            Assert
              (Project_Tools.Text.Contains (Source_Line, "intentional silent recovery")
               or else Project_Tools.Text.Contains (Source_Line, "defensive recovery"),
               "broad handler scan returns real exception handlers");
         end Count_Broad_Handler;
      begin
         Project_Tools.Ada_Source.Scan_Broad_Exception_Handlers
           (Root & "/exception-scan.adb", Count_Broad_Handler'Access);
         Assert
           (Broad_Handler_Count = 2,
            "broad handler scan ignores case alternatives and string literals");
      end;
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

      declare
         TOML_Text : constant String :=
           "[[entry]]" & ASCII.LF
           & "name = ""alpha""" & ASCII.LF
           & "count = 12" & ASCII.LF
           & "enabled = true" & ASCII.LF
           & "disabled = false" & ASCII.LF
           & "broken = maybe" & ASCII.LF
           & ASCII.LF
           & "[[entry]]" & ASCII.LF
           & "name = ""beta""" & ASCII.LF;
         Sections : Natural := 0;

         procedure Count_Entry (Entry_Pos : Positive) is
            use type Project_Tools.TOML.Boolean_Parse_Status;

            Enabled : constant Project_Tools.TOML.Boolean_Parse_Result :=
              Project_Tools.TOML.Parse_Boolean_After
                (TOML_Text, "enabled = ", Entry_Pos);
            Disabled : constant Project_Tools.TOML.Boolean_Parse_Result :=
              Project_Tools.TOML.Parse_Boolean_After
                (TOML_Text, "disabled = ", Entry_Pos);
            Broken : constant Project_Tools.TOML.Boolean_Parse_Result :=
              Project_Tools.TOML.Parse_Boolean_After
                (TOML_Text, "broken = ", Entry_Pos);
            Missing : constant Project_Tools.TOML.Boolean_Parse_Result :=
              Project_Tools.TOML.Parse_Boolean_After
                (TOML_Text, "missing = ", Entry_Pos);
         begin
            Sections := Sections + 1;
            if Sections = 1 then
               Assert
                 (Project_Tools.TOML.String_Value_After
                    (TOML_Text, "name = ", Entry_Pos) = "alpha",
                  "TOML string values are parsed from a section");
               Assert
                 (Project_Tools.TOML.Natural_Value_After
                    (TOML_Text, "count = ", Entry_Pos) = 12,
                  "TOML natural values are parsed from a section");
               Assert
                 (Enabled.Status = Project_Tools.TOML.Parsed_Boolean
                  and then Enabled.Value,
                  "TOML true boolean values are parsed from a section");
               Assert
                 (Disabled.Status = Project_Tools.TOML.Parsed_Boolean
                  and then not Disabled.Value,
                  "TOML false boolean values are parsed from a section");
               Assert
                 (Broken.Status = Project_Tools.TOML.Malformed_Boolean,
                  "TOML malformed boolean values are reported");
               Assert
                 (Missing.Status = Project_Tools.TOML.Missing_Boolean,
                  "TOML missing boolean values are reported");
            end if;
         end Count_Entry;

         procedure Iterate_Entries is new Project_Tools.TOML.Iterate_Section
           (Count_Entry);
      begin
         Iterate_Entries (TOML_Text, "entry");
         Assert (Sections = 2, "TOML section iteration finds repeated entries");
      end;

      declare
         Exec_Args : constant GNAT.OS_Lib.Argument_List :=
           Project_Tools.Alire.Noninteractive_Exec_Args
             ([new String'("gprbuild"), new String'("-P"), new String'("test.gpr")]);
         Build_Args : constant GNAT.OS_Lib.Argument_List :=
           Project_Tools.Alire.Noninteractive_Build_Args;
      begin
         Assert (Exec_Args (1).all = "--non-interactive", "Alire exec args are noninteractive");
         Assert (Exec_Args (2).all = "exec", "Alire exec args preserve command");
         Assert (Exec_Args (4).all = "gprbuild", "Alire exec args append tool arguments");
         Assert (Build_Args (1).all = "--non-interactive", "Alire build args are noninteractive");
      end;

      Ada.Directories.Create_Path (Root & "/src");
      Write_File
        (Root & "/src/small.adb",
         "procedure Small is" & ASCII.LF
         & "begin" & ASCII.LF
         & "   null;" & ASCII.LF
         & "end Small;" & ASCII.LF);
      Write_File
        (Root & "/structural.toml",
         "[[body]]" & ASCII.LF
         & "path = ""src/small.adb""" & ASCII.LF
         & "split_prefix = """"" & ASCII.LF
         & "target_lines = 8" & ASCII.LF
         & "max_lines = 12" & ASCII.LF
         & "min_headroom_lines = 2" & ASCII.LF
         & "max_bytes = 1000" & ASCII.LF
         & "min_split_bodies = 0" & ASCII.LF
         & "usecase = ""test""" & ASCII.LF);
      declare
         Errors : Natural := 0;
      begin
         Project_Tools.Source_Budgets.Check_Structural_Baseline
           (Errors, Root, "structural.toml", 1, Quiet => True);
         Assert (Errors = 0, "structural budget manifest accepts matching files");
      end;
      Write_File
        (Root & "/src/large_unbudgeted.ads",
         "package Large_Unbudgeted is" & ASCII.LF
         & "   X : constant Natural := 1;" & ASCII.LF
         & "   Y : constant Natural := 2;" & ASCII.LF
         & "end Large_Unbudgeted;" & ASCII.LF);
      declare
         Errors : Natural := 0;
      begin
         Project_Tools.Source_Budgets.Check_Large_Source_Budget_Coverage
           (Errors, Root, "src", 4,
            [Project_Tools.Source_Budgets.Coverage_Manifest_Entry
               ("structural.toml", "body")],
            Quiet => True);
         Assert
           (Errors > 0,
            "large source coverage rejects unbudgeted source files");
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
      end;
      Write_File
        (Root & "/facades.toml",
         "[[facade]]" & ASCII.LF
         & "path = ""src/large_unbudgeted.ads""" & ASCII.LF);
      declare
         Errors : Natural := 0;
      begin
         Project_Tools.Source_Budgets.Check_Large_Source_Budget_Coverage
           (Errors, Root, "src", 4,
            [Project_Tools.Source_Budgets.Coverage_Manifest_Entry
               ("structural.toml", "body"),
             Project_Tools.Source_Budgets.Coverage_Manifest_Entry
               ("facades.toml", "facade")],
            Quiet => True);
         Assert
           (Errors = 0,
            "large source coverage accepts secondary manifest ownership");
      end;

      Ada.Directories.Create_Path (Root & "/tests/src");
      Write_File
        (Root & "/tests/src/example-tests.adb",
         "procedure Example_Tests is" & ASCII.LF
         & "begin" & ASCII.LF
         & "   null;" & ASCII.LF
         & "end Example_Tests;" & ASCII.LF);
      Write_File
        (Root & "/tests/src/example-tests-test_case.adb",
         "separate (Example_Tests)" & ASCII.LF
         & "procedure Test_Case is" & ASCII.LF
         & "begin" & ASCII.LF
         & "   null;" & ASCII.LF
         & "end Test_Case;" & ASCII.LF);
      Write_File
        (Root & "/test-budgets.toml",
         "[[suite]]" & ASCII.LF
         & "prefix = ""tests/src/example-tests""" & ASCII.LF
         & "parent_max_lines = 8" & ASCII.LF
         & "subunit_max_lines = 8" & ASCII.LF
         & "usecase = ""fixture tests""" & ASCII.LF);
      declare
         Errors : Natural := 0;
      begin
         Project_Tools.Source_Budgets.Check_Test_Source_Budgets
           (Errors, Root, "test-budgets.toml", "tests/src",
            "example-tests*.adb", 1, Quiet => True);
         Assert (Errors = 0, "test source budget manifest accepts matching files");
      end;

      Write_File
        (Root & "/src/generated.adb",
         "--  generated data marker" & ASCII.LF
         & "package body Generated is end Generated;" & ASCII.LF);
      Write_File
        (Root & "/generated.toml",
         "[[artifact]]" & ASCII.LF
         & "path = ""src/generated.adb""" & ASCII.LF
         & "kind = ""table""" & ASCII.LF
         & "owner = ""test""" & ASCII.LF
         & "source = ""fixture""" & ASCII.LF
         & "currentness = ""checked""" & ASCII.LF
         & "coverage = ""covered""" & ASCII.LF
         & "marker = ""generated data marker""" & ASCII.LF
         & "line_count = 2" & ASCII.LF
         & "sha256 = """ & Toy_Hash
           ("--  generated data marker" & ASCII.LF
            & "package body Generated is end Generated;" & ASCII.LF)
         & """" & ASCII.LF);
      declare
         Errors : Natural := 0;
      begin
         Project_Tools.Generated_Artifacts.Check_Data_Manifest
           (Errors, Root, "generated.toml", 1, Toy_Hash'Access,
            Allowed_Kinds => [1 => new String'("table")], Quiet => True);
         Assert (Errors = 0, "generated artifact manifest accepts matching metadata");
      end;
      declare
         Errors : Natural := 0;
      begin
         Project_Tools.Generated_Artifacts.Check_Data_Manifest
           (Errors, Root, "generated.toml", 1, Toy_Hash'Access,
            Allowed_Kinds => [1 => new String'("other")], Quiet => True);
         Assert (Errors > 0, "generated artifact manifest rejects disallowed kinds");
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
      end;
      Write_File
        (Root & "/src/generated_shard.adb",
         "--  generated data marker" & ASCII.LF
         & "package body Generated_Shard is end Generated_Shard;" & ASCII.LF);
      Write_File
        (Root & "/generated-shard.toml",
         "[[artifact]]" & ASCII.LF
         & "path = ""src/generated.adb""" & ASCII.LF
         & "kind = ""table""" & ASCII.LF
         & "owner = ""test""" & ASCII.LF
         & "source = ""fixture""" & ASCII.LF
         & "currentness = ""checked""" & ASCII.LF
         & "coverage = ""covered""" & ASCII.LF
         & "marker = ""generated data marker""" & ASCII.LF
         & "line_count = 2" & ASCII.LF
         & "sha256 = """ & Toy_Hash
           ("--  generated data marker" & ASCII.LF
            & "package body Generated is end Generated;" & ASCII.LF)
         & """" & ASCII.LF
         & ASCII.LF
         & "[[artifact]]" & ASCII.LF
         & "path = ""src/generated_shard.adb""" & ASCII.LF
         & "kind = ""table-shard""" & ASCII.LF
         & "owner = ""test""" & ASCII.LF
         & "source = ""fixture""" & ASCII.LF
         & "currentness = ""checked""" & ASCII.LF
         & "coverage = ""covered shard""" & ASCII.LF
         & "marker = ""generated data marker""" & ASCII.LF
         & "line_count = 2" & ASCII.LF
         & "sha256 = """ & Toy_Hash
           ("--  generated data marker" & ASCII.LF
            & "package body Generated_Shard is end Generated_Shard;"
            & ASCII.LF)
         & """" & ASCII.LF);
      declare
         Errors : Natural := 0;
      begin
         Project_Tools.Generated_Artifacts.Check_Data_Manifest
           (Errors, Root, "generated-shard.toml", 2, Toy_Hash'Access,
            Max_Shard_Lines => 10, Quiet => True);
         Assert
           (Errors = 0,
            "generated artifact manifest accepts shard with matching parent");
      end;

      Write_File
        (Root & "/coverage.toml",
         "[[unit]]" & ASCII.LF
         & "name = ""A""" & ASCII.LF
         & "perf_exempt_category = ""pure""" & ASCII.LF
         & ASCII.LF
         & "[[unit]]" & ASCII.LF
         & "name = ""B""" & ASCII.LF
         & "perf_exempt_category = ""wrapper""" & ASCII.LF);
      Write_File
        (Root & "/category-ratchets.toml",
         "[[category]]" & ASCII.LF
         & "category = ""pure""" & ASCII.LF
         & "max_count = 1" & ASCII.LF
         & "usecase = ""pure packages""" & ASCII.LF
         & ASCII.LF
         & "[[category]]" & ASCII.LF
         & "category = ""wrapper""" & ASCII.LF
         & "max_count = 1" & ASCII.LF
         & "usecase = ""wrappers""" & ASCII.LF);
      declare
         Errors : Natural := 0;
      begin
         Project_Tools.Coverage_Ratchets.Check_Category_Ratchets
           (Errors, Root, "coverage.toml", "category-ratchets.toml",
            "perf_exempt_category", 2, Quiet => True);
         Assert (Errors = 0, "category ratchets accept covered categories");
      end;
      Write_File
        (Root & "/coverage-over.toml",
         "[[unit]]" & ASCII.LF
         & "perf_exempt_category = ""pure""" & ASCII.LF
         & ASCII.LF
         & "[[unit]]" & ASCII.LF
         & "perf_exempt_category = ""pure""" & ASCII.LF);
      declare
         Errors : Natural := 0;
      begin
         Project_Tools.Coverage_Ratchets.Check_Category_Ratchets
           (Errors, Root, "coverage-over.toml", "category-ratchets.toml",
            "perf_exempt_category", 2, Quiet => True);
         Assert (Errors > 0, "category ratchets reject cap growth");
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
      end;
      Write_File
        (Root & "/coverage-missing-category.toml",
         "[[unit]]" & ASCII.LF
         & "perf_exempt_category = ""unknown""" & ASCII.LF);
      declare
         Errors : Natural := 0;
      begin
         Project_Tools.Coverage_Ratchets.Check_Category_Ratchets
           (Errors, Root, "coverage-missing-category.toml",
            "category-ratchets.toml", "perf_exempt_category", 2,
            Quiet => True);
         Assert (Errors > 0, "category ratchets require manifest ownership");
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
      end;

      Write_File (Root & "/doc.md", "generated doc" & ASCII.LF);
      Write_File
        (Root & "/checker.adb",
         "procedure Checker is" & ASCII.LF
         & "begin" & ASCII.LF
         & "   if False then" & ASCII.LF
         & "      null; --  --print-doc" & ASCII.LF
         & "   end if;" & ASCII.LF
         & "end Checker;" & ASCII.LF);
      Write_File
        (Root & "/docs.toml",
         "[[doc]]" & ASCII.LF
         & "path = ""doc.md""" & ASCII.LF
         & "command = ""./bin/check --print-doc""" & ASCII.LF
         & "owner = ""test""" & ASCII.LF
         & "source = ""fixture""" & ASCII.LF);
      declare
         Errors : Natural := 0;
      begin
         Assert
           (Project_Tools.Generated_Docs.Equivalent_Text
              ("generated doc" & ASCII.LF, "generated doc"),
            "generated doc equivalence tolerates one trailing newline");
         Project_Tools.Generated_Docs.Check_Docs_Manifest
           (Errors, Root, "docs.toml", "checker.adb", "./bin/check", 1,
            Quiet => True);
         Assert (Errors = 0, "generated docs manifest accepts matching metadata");
      end;

      Ada.Directories.Create_Path (Root & "/obj");
      Write_File (Root & "/obj/unit.stderr", "warning" & ASCII.LF);
      Assert
        (Project_Tools.Text.Contains
           (Project_Tools.Release_Checks.Nonempty_Stderr_Files
              ([1 => To_Unbounded_String (Root & "/obj")]),
            "unit.stderr"),
         "release checks can list nonempty compiler stderr files");

      Delete_Tree_If_Present (Root);
   exception
      when others =>
         Delete_Tree_If_Present (Root);
         raise;
   end Run_Test;

   overriding function Name (Item : File_Failure_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("File helper failures");
   end Name;

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

   overriding function Name (Item : JSON_Helper_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("JSON helpers");
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

      --  A top-level array of objects, the GitHub directory-listing shape:
      --  every object's "name" is visited, non-object and field-less items are
      --  skipped.
      declare
         Listing : constant String :=
           "[{""name"":""a.xml"",""type"":""file""}," &
           "{""name"":""b.xml""},{""type"":""dir""},{""name"":""c.xml""}]";
         Buffer  : String (1 .. 64);
         Last    : Natural := 0;
         procedure Collect (Value : String) is
         begin
            Buffer (Last + 1 .. Last + Value'Length) := Value;
            Last := Last + Value'Length + 1;
            Buffer (Last) := ';';
         end Collect;
      begin
         Project_Tools.JSON.For_Each_Array_Object_Field
           (Listing, "name", Collect'Access);
         Assert
           (Buffer (1 .. Last) = "a.xml;b.xml;c.xml;",
            "each array object's name field is visited, others skipped");
      end;
   end Run_Test;

   overriding function Name (Item : Gcov_Helper_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("Gcov helpers");
   end Name;

   overriding procedure Run_Test (Item : in out Gcov_Helper_Test) is
      pragma Unreferenced (Item);
      Output : constant String :=
        "File '/tmp/project/src/a.adb'" & ASCII.LF &
        "Lines executed:75.00% of 20" & ASCII.LF &
        "File '/tmp/runtime/b.adb'" & ASCII.LF &
        "Lines executed:50.00% of 10" & ASCII.LF &
        "No executable lines" & ASCII.LF;
      Summary : constant Project_Tools.Gcov.Coverage_Summary :=
        Project_Tools.Gcov.Parse_Lines_Executed_Output (Output);
      Filtered : constant Project_Tools.Gcov.Coverage_Summary :=
        Project_Tools.Gcov.Parse_Lines_Executed_Output
          (Output, "/tmp/project/src/");
      Errors  : Natural := 0;
   begin
      Assert
        (Project_Tools.Gcov.Covered_Lines (Summary) = 20,
         "covered lines are summed from gcov percentages");
      Assert
        (Project_Tools.Gcov.Total_Lines (Summary) = 30,
         "total executable lines are summed");
      Assert
        (Project_Tools.Gcov.Percent_Basis_Points (Summary) = 6666,
         "percentage is represented in basis points");
      Assert
        (Project_Tools.Gcov.Percent_Image (Summary) = "66.66%",
         "percentage image is deterministic");
      Assert
        (Project_Tools.Gcov.Covered_Lines (Filtered) = 15,
         "filtered coverage keeps matching project files");
      Assert
        (Project_Tools.Gcov.Total_Lines (Filtered) = 20,
         "filtered coverage excludes nonmatching files");

      Project_Tools.Gcov.Require_Minimum_Line_Coverage
        (Errors, Summary, 6_000, 30, Quiet => True);
      Assert (Errors = 0, "coverage threshold accepts sufficient summary");

      Project_Tools.Gcov.Require_Minimum_Line_Coverage
        (Errors, Summary, 8_000, 30, Quiet => True);
      Assert (Errors = 1, "coverage threshold rejects low percentage");

      Project_Tools.Gcov.Require_Minimum_Line_Coverage
        (Errors, Summary, 6_000, 31, Quiet => True);
      Assert (Errors = 2, "coverage threshold rejects weak evidence");

      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end Run_Test;

   overriding function Name (Item : Ada_Source_Query_Test) return AUnit.Message_String is
      pragma Unreferenced (Item);
   begin
      return AUnit.Format ("Ada source query helpers");
   end Name;

   overriding procedure Run_Test (Item : in out Ada_Source_Query_Test) is
      pragma Unreferenced (Item);
      Source_Root : constant String := Root & "/ada-query";
      Skip_List   : constant Project_Tools.Files.Name_List :=
        [To_Unbounded_String ("obj")];
      Forbidden   : constant Project_Tools.Ada_Source.String_List :=
        [To_Unbounded_String ("goto")];
   begin
      Delete_Tree_If_Present (Root);
      Ada.Directories.Create_Path (Source_Root & "/obj");
      Write_File
        (Source_Root & "/clean.adb",
         "procedure Clean is" & ASCII.LF
         & "   Text : constant String := ""goto in a string"";" & ASCII.LF
         & "begin" & ASCII.LF
         & "   null; -- goto in a comment" & ASCII.LF
         & "end Clean;" & ASCII.LF);
      Write_File
        (Source_Root & "/obj/generated.adb",
         "procedure Generated is" & ASCII.LF
         & "begin" & ASCII.LF
         & "   goto Done;" & ASCII.LF
         & "   <<Done>> null;" & ASCII.LF
         & "end Generated;" & ASCII.LF);

      Assert
        (Project_Tools.Ada_Source.First_Source_File_With_Code_Token
           (Source_Root, Forbidden, Skip_List) = "",
         "code-token query ignores strings, comments, and skipped paths");

      Write_File
        (Source_Root & "/bad.adb",
         "procedure Bad is" & ASCII.LF
         & "begin" & ASCII.LF
         & "   goto Done;" & ASCII.LF
         & "   <<Done>> null;" & ASCII.LF
         & "end Bad;" & ASCII.LF);
      Assert
        (Project_Tools.Text.Ends_With
           (Project_Tools.Ada_Source.First_Source_File_With_Code_Token
              (Source_Root, Forbidden, Skip_List),
            "/bad.adb"),
         "code-token query reports the first source file with a real token");

      Delete_Tree_If_Present (Root);
   exception
      when others =>
         Delete_Tree_If_Present (Root);
         raise;
   end Run_Test;

end Project_Tools_Test_Suite.Files_Tests;
