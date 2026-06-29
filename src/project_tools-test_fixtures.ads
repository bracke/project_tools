package Project_Tools.Test_Fixtures is

   --  Generic temporary-directory test fixtures, shared by the version and
   --  versionlib AUnit test suites so the fixture lifecycle lives in one place.

   function Fresh_Temp_Dir (Name : String) return String;
   --  Create and return a unique temporary directory for a test case.
   --  @param Name Short label embedded in the directory name.
   --  @return Path to a freshly created, unique temporary directory.

   procedure Cleanup (Path : String);
   --  Recursively delete Path if it exists; never raises for a missing path
   --  and retries briefly to tolerate transient filesystem locks.
   --  @param Path Directory tree to remove.

   procedure Make_Directory (Path : String);
   --  Create Path (and parents) if it does not already exist.
   --  @param Path Directory to create.

   procedure Write_Text_File (Path : String; Content : String);
   --  Create or replace Path with byte-for-byte Content, creating parent
   --  directories as needed (fixture-write semantics).
   --  @param Path File to create or replace.
   --  @param Content Raw bytes to write.

   function Read_Text_File (Path : String) return String;
   --  Read Path as text, joining lines with line feeds and without a trailing
   --  line feed (fixture-content semantics).
   --  @param Path File to read.
   --  @return File contents, or propagates the I/O exception on open failure.

end Project_Tools.Test_Fixtures;
