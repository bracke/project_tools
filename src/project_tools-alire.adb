with Ada.Command_Line;
with Ada.Environment_Variables;
with Ada.Text_IO;

with Project_Tools.Processes;

package body Project_Tools.Alire is
   function Noninteractive_Update_Args return GNAT.OS_Lib.Argument_List is
   begin
      return
        [1 => new String'("--non-interactive"),
         2 => new String'("update")];
   end Noninteractive_Update_Args;

   function Noninteractive_Build_Args return GNAT.OS_Lib.Argument_List is
   begin
      return
        [1 => new String'("--non-interactive"),
         2 => new String'("build")];
   end Noninteractive_Build_Args;

   function Noninteractive_Exec_Args
     (Args : GNAT.OS_Lib.Argument_List)
      return GNAT.OS_Lib.Argument_List
   is
      Result : GNAT.OS_Lib.Argument_List (1 .. Args'Length + 3);
   begin
      Result (1) := new String'("--non-interactive");
      Result (2) := new String'("exec");
      Result (3) := new String'("--");

      for Index in Args'Range loop
         Result (Index - Args'First + 4) := new String'(Args (Index).all);
      end loop;

      return Result;
   end Noninteractive_Exec_Args;

   procedure Run_Build
     (Directory    : String;
      Release_Mode : Boolean := False;
      Label        : String := "alr build")
   is
      package Env_Vars renames Ada.Environment_Variables;

      Alr : constant String := Project_Tools.Processes.Locate_Command ("alr");
      Env : constant String := Project_Tools.Processes.Locate_Command ("env");

      function Derived_Home return String is
         Marker : constant String := "/.getada/bin/alr";
      begin
         if Alr'Length > Marker'Length
           and then Alr (Alr'Last - Marker'Length + 1 .. Alr'Last) = Marker
         then
            return Alr (Alr'First .. Alr'Last - Marker'Length);
         else
            return "";
         end if;
      end Derived_Home;

      function Value_Or_Empty (Name : String) return String is
      begin
         if Env_Vars.Exists (Name) then
            return Env_Vars.Value (Name);
         else
            return "";
         end if;
      end Value_Or_Empty;

      Alr_Args : constant GNAT.OS_Lib.Argument_List :=
        (if Release_Mode
         then [new String'("--non-interactive"),
               new String'("build"),
               new String'("--release"),
               new String'("--profiles=*=release")]
         else Noninteractive_Build_Args);
      Home : constant String := Derived_Home;
      Path : constant String := Value_Or_Empty ("PATH");

      procedure Fail (Message : String) is
      begin
         Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, Message);
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
         raise Program_Error;
      end Fail;
   begin
      if Alr = "" then
         Fail ("alr executable not found");
      end if;

      if Env /= "" and then Home /= "" then
         declare
            Args : GNAT.OS_Lib.Argument_List (1 .. Alr_Args'Length + 6);
         begin
            Args (1) := new String'("-i");
            Args (2) := new String'("HOME=" & Home);
            Args (3) := new String'("XDG_DATA_HOME=" & Home & "/.local/share");
            Args (4) := new String'("XDG_CONFIG_HOME=" & Home & "/.config");
            Args (5) := new String'("PATH=" & Path);
            Args (6) := new String'(Alr);

            for Index in Alr_Args'Range loop
               Args (Index - Alr_Args'First + 7) := new String'(Alr_Args (Index).all);
            end loop;

            if Project_Tools.Processes.Run_Status (Label, Directory, Env, Args) /= 0 then
               Fail (Label & " failed in " & Directory);
            end if;
         end;
      elsif Project_Tools.Processes.Run_Status (Label, Directory, Alr, Alr_Args) /= 0 then
         Fail (Label & " failed in " & Directory);
      end if;
   end Run_Build;
end Project_Tools.Alire;
