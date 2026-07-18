package Project_Tools.Generated_Artifacts is
   type Hash_Function is not null access function (Text : String) return String;

   procedure Check_Data_Manifest
     (Errors          : in out Natural;
      Root            : String;
      Manifest_Path   : String;
      Expected_Count  : Natural;
      Hash            : Hash_Function;
      Quiet           : Boolean := False);
   --  Validate generated/native artifact metadata, marker, line count, and
   --  hash snapshot.

   procedure Print_Data_Manifest
     (Root          : String;
      Manifest_Path : String;
      Header        : String;
      Hash          : Hash_Function);
   --  Print a refreshed generated/native artifact manifest, preserving
   --  metadata fields from the existing manifest and recomputing line/hash.
end Project_Tools.Generated_Artifacts;
