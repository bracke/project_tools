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
end Project_Tools.AUnit_Checks;
