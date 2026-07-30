package Project_Tools.Coverage_Ratchets is
   procedure Check_Category_Ratchets
     (Errors          : in out Natural;
      Root            : String;
      Coverage_Path   : String;
      Manifest_Path   : String;
      Coverage_Key    : String;
      Minimum_Entries : Natural;
      Purpose         : String := "coverage category ratchet";
      Quiet           : Boolean := False);
   --  Check a [[category]] manifest with category, max_count, and usecase
   --  fields against repeated quoted Coverage_Key values in Coverage_Path.
   --  @param Errors Error counter incremented for each ratchet violation.
   --  @param Root Project root the paths are resolved against.
   --  @param Coverage_Path File the counts are taken from.
   --  @param Manifest_Path Manifest holding the per-category caps.
   --  @param Coverage_Key Quoted key counted in Coverage_Path.
   --  @param Minimum_Entries Fewest categories the manifest may hold.
   --  @param Purpose Name for the check in diagnostics.
   --  @param Quiet Suppress diagnostics when True.
end Project_Tools.Coverage_Ratchets;
