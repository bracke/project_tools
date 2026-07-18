with Ada.Strings.Unbounded;

package Project_Tools.Source_Budgets is
   type Coverage_Manifest is private;
   type Coverage_Manifest_List is array (Positive range <>) of Coverage_Manifest;

   function Coverage_Manifest_Entry
     (Manifest_Path : String;
      Section       : String)
      return Coverage_Manifest;
   --  Describe one manifest section that owns source budget coverage.

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

private
   subtype Unbounded_String is Ada.Strings.Unbounded.Unbounded_String;

   type Coverage_Manifest is record
      Manifest_Path : Unbounded_String;
      Section       : Unbounded_String;
   end record;
end Project_Tools.Source_Budgets;
