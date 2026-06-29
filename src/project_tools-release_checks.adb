with Ada.Command_Line;
with Ada.Text_IO;

with Project_Tools.Files;
with Project_Tools.Processes;

package body Project_Tools.Release_Checks is
   function Create (Root : String) return Checker is
      Result : Checker;
   begin
      if Root'Length > Result.Root'Length then
         raise Constraint_Error;
      end if;
      Result.Root (1 .. Root'Length) := Root;
      Result.Last := Root'Length;
      return Result;
   end Create;

   function Root_Path (Check : Checker) return String is
   begin
      return Check.Root (1 .. Check.Last);
   end Root_Path;

   function Join (Check : Checker; Relative_Path : String) return String is
   begin
      return Root_Path (Check) & "/" & Relative_Path;
   end Join;

   procedure Require_File
     (Check         : Checker;
      Relative_Path : String;
      Quiet         : Boolean := False)
   is
   begin
      Project_Tools.Files.Require_File
        (Join (Check, Relative_Path),
         "required release file missing: " & Relative_Path,
         Quiet);
   end Require_File;

   procedure Require_Directory
     (Check         : Checker;
      Relative_Path : String;
      Quiet         : Boolean := False)
   is
   begin
      Project_Tools.Files.Require_Directory
        (Join (Check, Relative_Path),
         "required release directory missing: " & Relative_Path,
         Quiet);
   end Require_Directory;

   procedure Require_Text
     (Check         : Checker;
      Relative_Path : String;
      Text          : String;
      Quiet         : Boolean := False)
   is
   begin
      Project_Tools.Files.Require_Contains
        (Join (Check, Relative_Path),
         Text,
         Relative_Path & " must contain: " & Text,
         Quiet);
   end Require_Text;

   procedure Require_Absolute_File
     (Path  : String;
      Quiet : Boolean := False)
   is
   begin
      Project_Tools.Files.Require_File
        (Path, "required installed file missing", Quiet);
   end Require_Absolute_File;

   procedure Require_Absolute_Directory
     (Path  : String;
      Quiet : Boolean := False)
   is
   begin
      Project_Tools.Files.Require_Directory
        (Path, "required installed directory missing", Quiet);
   end Require_Absolute_Directory;

   procedure Fail (Message : String; Quiet : Boolean := False) is
   begin
      if not Quiet then
         Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, Message);
      end if;
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      raise Program_Error;
   end Fail;
end Project_Tools.Release_Checks;
