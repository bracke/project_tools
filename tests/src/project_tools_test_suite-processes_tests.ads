with AUnit;
with AUnit.Simple_Test_Cases;

--  Processes Tests extracted from the former single-file suite.
package Project_Tools_Test_Suite.Processes_Tests is

   type Process_Helper_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Process_Helper_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Process_Helper_Test);

   type Process_Failure_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Process_Failure_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Process_Failure_Test);

   type Process_Output_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Process_Output_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Process_Output_Test);

   type Promoted_Helpers_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Promoted_Helpers_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Promoted_Helpers_Test);

end Project_Tools_Test_Suite.Processes_Tests;
