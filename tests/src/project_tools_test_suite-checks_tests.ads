with AUnit;
with AUnit.Simple_Test_Cases;

--  Checks Tests extracted from the former single-file suite.
package Project_Tools_Test_Suite.Checks_Tests is

   type Alire_Manifest_Failure_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Alire_Manifest_Failure_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Alire_Manifest_Failure_Test);

   type Release_Checks_Fail_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Release_Checks_Fail_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Release_Checks_Fail_Test);

   type Release_Checks_Git_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Release_Checks_Git_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Release_Checks_Git_Test);

   type AUnit_Check_Helper_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : AUnit_Check_Helper_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out AUnit_Check_Helper_Test);

   type Tree_Check_Helper_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Tree_Check_Helper_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Tree_Check_Helper_Test);

   type Security_Corpus_Helper_Test is new AUnit.Simple_Test_Cases.Test_Case with null record;
   overriding function Name (Item : Security_Corpus_Helper_Test) return AUnit.Message_String;
   overriding procedure Run_Test (Item : in out Security_Corpus_Helper_Test);

end Project_Tools_Test_Suite.Checks_Tests;
