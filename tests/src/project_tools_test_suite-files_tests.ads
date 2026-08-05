with AUnit;
with AUnit.Simple_Test_Cases;

--  Files Tests extracted from the former single-file suite.
package Project_Tools_Test_Suite.Files_Tests is

   type Text_Helper_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Text_Helper_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Text_Helper_Test);

   type File_Helper_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : File_Helper_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out File_Helper_Test);

   type File_Failure_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : File_Failure_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out File_Failure_Test);

   type JSON_Helper_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : JSON_Helper_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out JSON_Helper_Test);

   type Gcov_Helper_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Gcov_Helper_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Gcov_Helper_Test);

   type Ada_Source_Query_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Ada_Source_Query_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Ada_Source_Query_Test);

end Project_Tools_Test_Suite.Files_Tests;
