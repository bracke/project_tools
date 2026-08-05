package Project_Tools.Gcov is
   type Coverage_Summary is private;

   function Summary
     (Lines_Covered : Natural;
      Lines_Total   : Natural) return Coverage_Summary;
   --  @param Lines_Covered Executable lines reported covered.
   --  @param Lines_Total Executable lines reported total.
   --  @return Immutable coverage summary.

   function Parse_Lines_Executed_Output
     (Output : String) return Coverage_Summary;
   --  Parse gcov output containing one or more
   --  "Lines executed:NN.NN% of NNN" lines and return the summed executable
   --  line totals. Malformed lines are ignored.
   --  @param Output Captured gcov standard output.
   --  @return Summed line coverage summary.

   function Parse_Lines_Executed_Output
     (Output      : String;
      File_Prefix : String) return Coverage_Summary;
   --  Parse gcov output and sum only files whose latest "File '...'" line
   --  starts with File_Prefix. An empty prefix accepts every file.
   --  @param Output Captured gcov standard output.
   --  @param File_Prefix Required source path prefix, or empty to accept all.
   --  @return Filtered summed line coverage summary.

   function Covered_Lines (Item : Coverage_Summary) return Natural;
   --  @param Item Coverage summary to inspect.
   --  @return Covered executable line count.

   function Total_Lines (Item : Coverage_Summary) return Natural;
   --  @param Item Coverage summary to inspect.
   --  @return Total executable line count.

   function Percent_Basis_Points (Item : Coverage_Summary) return Natural;
   --  @param Item Coverage summary to inspect.
   --  @return Coverage percentage in basis points, so 75.34% is 7534.

   function Percent_Image (Item : Coverage_Summary) return String;
   --  @param Item Coverage summary to inspect.
   --  @return Deterministic percentage image with two decimal places.

   procedure Require_Minimum_Line_Coverage
     (Errors                 : in out Natural;
      Item                   : Coverage_Summary;
      Minimum_Basis_Points   : Natural;
      Minimum_Executable_Lines : Natural;
      Purpose                : String := "line coverage";
      Quiet                  : Boolean := False);
   --  Validate line coverage and minimum executable-line evidence.
   --  @param Errors Error counter incremented for each violation.
   --  @param Item Coverage summary to validate.
   --  @param Minimum_Basis_Points Required coverage in basis points.
   --  @param Minimum_Executable_Lines Required total executable lines.
   --  @param Purpose Name for diagnostics.
   --  @param Quiet Suppress diagnostics when True.

private
   type Coverage_Summary is record
      Lines_Covered : Natural := 0;
      Lines_Total   : Natural := 0;
   end record;
end Project_Tools.Gcov;
