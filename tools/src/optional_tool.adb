with Ada.Command_Line;
with Ada.Environment_Variables;
with Ada.Text_IO;

with Project_Tools.Processes;

--  Ada port of the former tools/optional_tool.sh helper.
--
--  Usage: optional_tool <tool> <label>
--
--  Resolves <tool> on PATH. When the tool is present the program exits 0.
--  When the tool is missing the behavior depends on strict mode, which is
--  enabled when any of the environment variables BACKUP_COMPLETION_STRICT or
--  PROJECT_TOOLS_OPTIONAL_STRICT equals "1", or CI equals "true":
--    * strict mode  -> print "<label> failed: <tool> not found" to stderr,
--                      exit with status 1.
--    * lenient mode -> print "<label> skipped: <tool> not found" to stdout,
--                      exit with status 0.
procedure Optional_Tool is
   use Ada.Text_IO;

   function Env_Equals (Name : String; Expected : String) return Boolean is
   --  @param Name Environment variable to inspect.
   --  @param Expected Value the variable must hold to count as set.
   --  @return True when Name is defined and equals Expected exactly.
   begin
      return Ada.Environment_Variables.Exists (Name)
        and then Ada.Environment_Variables.Value (Name) = Expected;
   end Env_Equals;

   function Strict_Mode return Boolean is
   --  @return True when any recognized strict-mode environment variable is set.
   begin
      return Env_Equals ("BACKUP_COMPLETION_STRICT", "1")
        or else Env_Equals ("PROJECT_TOOLS_OPTIONAL_STRICT", "1")
        or else Env_Equals ("CI", "true");
   end Strict_Mode;

begin
   if Ada.Command_Line.Argument_Count /= 2 then
      Put_Line (Standard_Error, "usage: optional_tool <tool> <label>");
      Ada.Command_Line.Set_Exit_Status (2);
      return;
   end if;

   declare
      Tool  : constant String := Ada.Command_Line.Argument (1);
      Label : constant String := Ada.Command_Line.Argument (2);
   begin
      if Project_Tools.Processes.Locate_Command (Tool) /= "" then
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
         return;
      end if;

      if Strict_Mode then
         Put_Line (Standard_Error, Label & " failed: " & Tool & " not found");
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      else
         Put_Line (Label & " skipped: " & Tool & " not found");
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
      end if;
   end;
end Optional_Tool;
