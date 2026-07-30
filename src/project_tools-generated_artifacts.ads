package Project_Tools.Generated_Artifacts is
   type Hash_Function is not null access function (Text : String) return String;
   --  A named access type (not an anonymous one) so that callers building a
   --  String_List with 'new String''(...)' do not trip -gnatw_a.
   type Constant_String_Access is access constant String;
   type String_List is array (Positive range <>) of Constant_String_Access;

   procedure Check_Data_Manifest
     (Errors          : in out Natural;
      Root            : String;
      Manifest_Path   : String;
      Expected_Count  : Natural;
      Hash            : Hash_Function;
      Allowed_Kinds   : String_List := [];
      Max_Shard_Lines : Natural := 0;
      Quiet           : Boolean := False);
   --  Validate generated/native artifact metadata, marker, line count, and
   --  hash snapshot. When Allowed_Kinds is nonempty, every kind must match
   --  one of those values. When Max_Shard_Lines is nonzero, `*-shard` kinds
   --  must stay within that line cap and have a non-shard parent artifact with
   --  matching owner, source, and marker metadata.
   --  @param Errors Error counter incremented for each manifest failure.
   --  @param Root Project root the manifest paths are resolved against.
   --  @param Manifest_Path Manifest to validate.
   --  @param Expected_Count Entries the manifest must hold; a manifest that has
   --         quietly emptied would otherwise pass while measuring nothing.
   --  @param Hash Hash applied to each artifact, so the snapshot in the
   --         manifest can be compared against the file as it stands.
   --  @param Allowed_Kinds Kinds an entry may declare; empty allows any.
   --  @param Max_Shard_Lines Line cap for *-shard kinds; zero disables it.
   --  @param Quiet Suppress diagnostics when True.

   procedure Print_Data_Manifest
     (Root          : String;
      Manifest_Path : String;
      Header        : String;
      Hash          : Hash_Function);
   --  Print a refreshed generated/native artifact manifest, preserving
   --  metadata fields from the existing manifest and recomputing line/hash.
   --  @param Root Project root the manifest paths are resolved against.
   --  @param Manifest_Path Manifest to refresh; it is read, not written.
   --  @param Header Header line to print above the entries.
   --  @param Hash Hash applied to each artifact when recomputing the snapshot.
end Project_Tools.Generated_Artifacts;
