with Ada.Strings.Unbounded;

with Project_Tools.Files;

package Project_Tools.AUnit_Checks is
   subtype Unbounded_String is Ada.Strings.Unbounded.Unbounded_String;
   subtype Text_List is Project_Tools.Files.Name_List;

   type Suite_Metrics is record
      Section_Count      : Natural := 0;
      Registration_Count : Natural := 0;
      Assertion_Count    : Natural := 0;
      Test_Body_Count    : Natural := 0;
      Registered_Text    : Unbounded_String;
   end record;

   function Spec_Name (Body_Name : String) return String;
   --  @param Body_Name Ada body file name ending in .adb.
   --  @return Matching Ada spec file name ending in .ads.

   function Registration_Count (Text : String) return Natural;
   --  @param Text Ada source text to inspect.
   --  @return Number of Register_Routine occurrences.

   function Assertion_Count (Text : String) return Natural;
   --  @param Text Ada source text to inspect.
   --  @return Number of Assert occurrences.

   function Test_Body_Count (Text : String) return Natural;
   --  @param Text Ada source text to inspect.
   --  @return Number of local Test_ or AUnit_Test_ procedure declarations.

   function Collect_Suite_Metrics
     (Directory : String;
      Pattern   : String) return Suite_Metrics;
   --  Aggregate AUnit metrics for every ordinary file matching Pattern.
   --  @param Directory Directory to scan.
   --  @param Pattern Ada.Directories search pattern, for example "*.adb".
   --  @return Counts accumulated from matching source files.

   procedure Check_Section_Suite
     (Errors               : in out Natural;
      Body_Path            : String;
      Spec_Path            : String;
      Display_Name         : String;
      Required_Spec_Tokens : Text_List;
      Required_Body_Tokens : Text_List;
      Forbidden_Body_Tokens : Text_List;
      Max_Registrations    : Natural;
      Metrics              : in out Suite_Metrics;
      Quiet                : Boolean := False);
   --  Check common split AUnit section-suite source structure.
   --  @param Errors Error counter incremented for each structural failure.
   --  @param Body_Path Section-suite body path.
   --  @param Spec_Path Section-suite spec path.
   --  @param Display_Name Human-readable section-suite name for diagnostics.
   --  @param Required_Spec_Tokens Tokens that must occur in the spec.
   --  @param Required_Body_Tokens Tokens that must occur in the body.
   --  @param Forbidden_Body_Tokens Tokens that must not occur in the body.
   --  @param Max_Registrations Maximum allowed Register_Routine occurrences.
   --  @param Metrics Accumulated suite metrics updated from the body.
   --  @param Quiet Suppress diagnostics when True.

   procedure Require_Registered_Test_Packages
     (Test_Dir                 : String;
      Spec_Pattern             : String;
      Suite_Path               : String;
      Documentation_Path       : String;
      Documented_Stem_Prefix   : String;
      Suite_Add_Prefix         : String := "Result.Add_Test (new ";
      Suite_Add_Suffix         : String := ".Test_Case)";
      Registration_Token       : String := "Register_Routine";
      Required_Stem_Suffix     : String := "_tests";
      Quiet                    : Boolean := False);
   --  Require split AUnit test packages to be registered and documented.
   --  @param Test_Dir Directory containing test package specs and bodies.
   --  @param Spec_Pattern Ada.Directories pattern for test package specs.
   --  @param Suite_Path Suite body that withs and adds every package.
   --  @param Documentation_Path Markdown or text inventory file.
   --  @param Documented_Stem_Prefix Prefix used to recognize documented stems.
   --  @param Suite_Add_Prefix Text before the package name in suite add calls.
   --  @param Suite_Add_Suffix Text after the package name in suite add calls.
   --  @param Registration_Token Token proving the body registers routines.
   --  @param Required_Stem_Suffix Suffix required before stale docs are checked.
   --  @param Quiet Suppress diagnostics when True.
end Project_Tools.AUnit_Checks;
