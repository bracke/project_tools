with Ada.Command_Line;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Project_Tools.Files;
with Project_Tools.Text;
with Project_Tools.TOML;

package body Project_Tools.Generated_Docs is
   procedure Error
     (Errors  : in out Natural;
      Message : String;
      Quiet   : Boolean)
   is
   begin
      Errors := Errors + 1;
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      if not Quiet then
         Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, "error: " & Message);
      end if;
   end Error;

   function Read_File (Path : String) return String is
     (Ada.Strings.Unbounded.To_String (Project_Tools.Text.Read_Text_File (Path)));

   function Equivalent_Text
     (Stored    : String;
      Generated : String)
      return Boolean
   is
   begin
      if Stored = Generated then
         return True;
      elsif Stored'Length > 0
        and then Stored (Stored'Last) = ASCII.LF
        and then Stored (Stored'First .. Stored'Last - 1) = Generated
      then
         return True;
      elsif Generated'Length > 0
        and then Generated (Generated'Last) = ASCII.LF
        and then Generated (Generated'First .. Generated'Last - 1) = Stored
      then
         return True;
      else
         return False;
      end if;
   end Equivalent_Text;

   procedure Require_Current
     (Errors    : in out Natural;
      Stored    : String;
      Generated : String;
      Message   : String;
      Quiet     : Boolean := False)
   is
   begin
      if not Equivalent_Text (Stored, Generated) then
         Error (Errors, Message, Quiet);
      end if;
   end Require_Current;

   procedure Check_Docs_Manifest
     (Errors                  : in out Natural;
      Root                    : String;
      Manifest_Path           : String;
      Checker_Source_Path     : String;
      Required_Command_Prefix : String;
      Minimum_Entries         : Natural;
      Quiet                   : Boolean := False)
   is
      Manifest : constant String := Read_File (Root & "/" & Manifest_Path);
      Checker  : constant String := Read_File (Root & "/" & Checker_Source_Path);
      Count    : Natural := 0;

      procedure Check_Entry (Entry_Pos : Positive) is
         Path : constant String :=
           Project_Tools.TOML.String_Value_After
             (Manifest, "path = ", Entry_Pos);
         Command : constant String :=
           Project_Tools.TOML.String_Value_After
             (Manifest, "command = ", Entry_Pos);
         Owner : constant String :=
           Project_Tools.TOML.String_Value_After
             (Manifest, "owner = ", Entry_Pos);
         Source : constant String :=
           Project_Tools.TOML.String_Value_After
             (Manifest, "source = ", Entry_Pos);
      begin
         if Path = "" or else Command = "" or else Owner = ""
           or else Source = ""
         then
            Error (Errors, "generated-docs manifest entry is incomplete", Quiet);
         elsif not Project_Tools.Files.File_Exists (Root & "/" & Path) then
            Error (Errors, "missing required file: " & Path, Quiet);
         else
            if not Project_Tools.Text.Contains
              (Command, Required_Command_Prefix)
            then
               Error
                 (Errors,
                  "generated-docs command must use required checker: " & Path,
                  Quiet);
            end if;

            if Project_Tools.Text.Contains (Command, "--")
              and then not Project_Tools.Text.Contains
                (Checker,
                 Command
                   (Ada.Strings.Fixed.Index (Command, "--") .. Command'Last))
            then
               Error
                 (Errors,
                  "generated-docs command is not exposed by checker: "
                  & Command, Quiet);
            end if;

            Count := Count + 1;
         end if;
      end Check_Entry;

      procedure Check_Entries is new Project_Tools.TOML.Iterate_Section
        (Check_Entry);
   begin
      Check_Entries (Manifest, "doc");

      if Count < Minimum_Entries then
         Error
           (Errors, "generated-docs manifest must cover generated docs", Quiet);
      end if;
   end Check_Docs_Manifest;
end Project_Tools.Generated_Docs;
