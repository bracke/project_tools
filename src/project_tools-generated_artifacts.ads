package Project_Tools.Generated_Artifacts is
   type Hash_Function is not null access function (Text : String) return String;
   type String_List is array (Positive range <>) of access constant String;

   procedure Check_Data_Manifest
     (Errors          : in out Natural;
      Root            : String;
      Manifest_Path   : String;
      Expected_Count  : Natural;
      Hash            : Hash_Function;
      Allowed_Kinds   : String_List := [];
      Quiet           : Boolean := False);
   --  Validate generated/native artifact metadata, marker, line count, and
   --  hash snapshot. When Allowed_Kinds is nonempty, every kind must match
   --  one of those values.

   procedure Print_Data_Manifest
     (Root          : String;
      Manifest_Path : String;
      Header        : String;
      Hash          : Hash_Function);
   --  Print a refreshed generated/native artifact manifest, preserving
   --  metadata fields from the existing manifest and recomputing line/hash.
end Project_Tools.Generated_Artifacts;
