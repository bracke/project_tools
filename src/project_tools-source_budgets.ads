with Ada.Strings.Unbounded;

package Project_Tools.Source_Budgets is
   type Coverage_Manifest is private;
   type Coverage_Manifest_List is array (Positive range <>) of Coverage_Manifest;

   function Coverage_Manifest_Entry
     (Manifest_Path : String;
      Section       : String)
      return Coverage_Manifest;
   --  Describe one manifest section that owns source budget coverage.
   --  @param Manifest_Path Manifest file, relative to the project root.
   --  @param Section Section within that manifest which owns the coverage.
   --  @return The described section, for passing to
   --          Check_Large_Source_Budget_Coverage.

   procedure Check_Line_Byte_Budget
     (Errors             : in out Natural;
      Root               : String;
      Relative_Path      : String;
      Label              : String;
      Target_Lines       : Natural;
      Max_Lines          : Natural;
      Min_Headroom_Lines : Natural;
      Max_Bytes          : Natural;
      Quiet              : Boolean := False);
   --  Check one source file against line ratchet, hard line cap, and byte cap.
   --  @param Errors Error counter incremented for each budget violation.
   --  @param Root Project root the relative path is resolved against.
   --  @param Relative_Path Source file to measure.
   --  @param Label Name for the file in diagnostics.
   --  @param Target_Lines Line count the file is expected to be at or below.
   --  @param Max_Lines Hard cap; exceeding it is a failure whatever the target.
   --  @param Min_Headroom_Lines Lines that must remain between the file and
   --         Max_Lines, so a file cannot sit against the cap.
   --  @param Max_Bytes Byte cap for the same file.
   --  @param Quiet Suppress diagnostics when True.

   procedure Check_Structural_Baseline
     (Errors          : in out Natural;
      Root            : String;
      Manifest_Path   : String;
      Minimum_Entries : Natural;
      Purpose         : String := "structural baseline";
      Section         : String := "body";
      Quiet           : Boolean := False);
   --  Check a manifest with path, target_lines, max_lines,
   --  min_headroom_lines, max_bytes, split_prefix, min_split_bodies, and
   --  usecase fields.
   --  @param Errors Error counter incremented for each structural failure.
   --  @param Root Project root the manifest paths are resolved against.
   --  @param Manifest_Path Manifest to read.
   --  @param Minimum_Entries Fewest entries the manifest may hold; a manifest
   --         that has quietly emptied is a passing check that measures nothing.
   --  @param Purpose Name for the check in diagnostics.
   --  @param Section Manifest section to read.
   --  @param Quiet Suppress diagnostics when True.

   procedure Check_Test_Source_Budgets
     (Errors          : in out Natural;
      Root            : String;
      Manifest_Path   : String;
      Test_Source_Dir : String;
      File_Pattern    : String;
      Minimum_Entries : Natural;
      Purpose         : String := "test source budget";
      Quiet           : Boolean := False);
   --  Check a manifest with prefix, parent_max_lines, subunit_max_lines, and
   --  usecase fields. The longest matching prefix selects the applicable
   --  budget. Files whose simple name contains "-test_" or "-check_" are
   --  treated as subunits.
   --  @param Errors Error counter incremented for each budget violation.
   --  @param Root Project root the paths are resolved against.
   --  @param Manifest_Path Manifest to read.
   --  @param Test_Source_Dir Directory holding the test sources to measure.
   --  @param File_Pattern Which files in that directory to measure.
   --  @param Minimum_Entries Fewest entries the manifest may hold.
   --  @param Purpose Name for the check in diagnostics.
   --  @param Quiet Suppress diagnostics when True.

   procedure Check_Large_Source_Budget_Coverage
     (Errors          : in out Natural;
      Root            : String;
      Source_Dir      : String;
      Minimum_Lines   : Natural;
      Manifests       : Coverage_Manifest_List;
      Purpose         : String := "large source budget coverage";
      Quiet           : Boolean := False);
   --  Require every .adb/.ads source file under Source_Dir with at least
   --  Minimum_Lines lines to appear in one of the configured manifests.
   --  @param Errors Error counter incremented for each uncovered source file.
   --  @param Root Project root the paths are resolved against.
   --  @param Source_Dir Directory to walk.
   --  @param Minimum_Lines Size at which a file must be covered by a manifest;
   --         below it a file is left alone.
   --  @param Manifests Manifest sections that between them must cover the
   --         files found, built with Coverage_Manifest_Entry.
   --  @param Purpose Name for the check in diagnostics.
   --  @param Quiet Suppress diagnostics when True.

private
   subtype Unbounded_String is Ada.Strings.Unbounded.Unbounded_String;

   type Coverage_Manifest is record
      Manifest_Path : Unbounded_String;
      Section       : Unbounded_String;
   end record;
end Project_Tools.Source_Budgets;
