with GNAT.OS_Lib;
with Project_Tools.Processes;

package Project_Tools.Release_Checks is
   type Checker is tagged private;

   function Create (Root : String) return Checker;

   procedure Require_File
     (Check         : Checker;
      Relative_Path : String;
      Quiet         : Boolean := False);

   procedure Require_Directory
     (Check         : Checker;
      Relative_Path : String;
      Quiet         : Boolean := False);

   procedure Require_Text
     (Check         : Checker;
      Relative_Path : String;
      Text          : String;
      Quiet         : Boolean := False);

   procedure Require_Absolute_File
     (Path  : String;
      Quiet : Boolean := False);

   procedure Require_Absolute_Directory
     (Path  : String;
      Quiet : Boolean := False);

   procedure Run
     (Label   : String;
      Dir     : String;
      Program : String;
      Args    : GNAT.OS_Lib.Argument_List;
      Quiet   : Boolean := False) renames Project_Tools.Processes.Run;

   procedure Fail (Message : String; Quiet : Boolean := False);
   --  Report a release-check failure: emit Message, set the failure exit
   --  status, and raise Program_Error so the current tool unwinds. Use for
   --  bespoke conditional checks that do not map to a Require_* helper.
   --  @param Message Diagnostic to emit on standard error.
   --  @param Quiet Suppress the diagnostic when True.

private
   type Checker is tagged record
      Root : String (1 .. 4096);
      Last : Natural := 0;
   end record;
end Project_Tools.Release_Checks;
