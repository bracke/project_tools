package Project_Tools.Source_Budgets is
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
end Project_Tools.Source_Budgets;
