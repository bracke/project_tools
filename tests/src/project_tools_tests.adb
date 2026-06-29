with Ada.Command_Line;

with AUnit;
with AUnit.Run;
with AUnit.Reporter.Text;

with Project_Tools_Test_Suite;

procedure Project_Tools_Tests is
   use type AUnit.Status;

   function Run is new AUnit.Run.Test_Runner_With_Status (Project_Tools_Test_Suite.Suite);

   Reporter : AUnit.Reporter.Text.Text_Reporter;
   Status   : AUnit.Status;
begin
   Status := Run (Reporter);
   if Status = AUnit.Failure then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Project_Tools_Tests;
