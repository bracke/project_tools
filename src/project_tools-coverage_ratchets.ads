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
end Project_Tools.Coverage_Ratchets;
