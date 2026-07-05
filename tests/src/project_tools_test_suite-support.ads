--  Shared fixtures and helpers for the Project_Tools_Test_Suite domain test
--  child packages (extracted from the former single-file suite).
package Project_Tools_Test_Suite.Support is

   --  Scratch directory used by the file/process/manifest fixtures.
   Root : constant String := "/tmp/project_tools_tests";

   procedure Delete_Tree_If_Present (Path : String);
   --  Delete Path (recursively) if it exists; a no-op otherwise.

   procedure Write_File (Path : String; Content : String);
   --  Create or replace the file at Path with Content.

   procedure Expect_Program_Error
     (Action  : not null access procedure;
      Message : String);
   --  Invoke Action and fail the current AUnit test with Message unless Action
   --  raises Program_Error (the failure signal used by the Require_* helpers).

end Project_Tools_Test_Suite.Support;
