with Ada.Command_Line;
with Ada.Directories;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Text_IO;

with GNAT.Expect;

with Project_Tools.Files;
with Project_Tools.Text;

package body Project_Tools.Processes is
   use type GNAT.OS_Lib.String_Access;
   use type GNAT.OS_Lib.File_Descriptor;

   procedure Free_Args (Args : in out GNAT.OS_Lib.Argument_List) is
   begin
      for Arg of Args loop
         if Arg /= null then
            GNAT.OS_Lib.Free (Arg);
         end if;
      end loop;
   end Free_Args;
   function Locate_Command (Name : String) return String is
      Path : GNAT.OS_Lib.String_Access := GNAT.OS_Lib.Locate_Exec_On_Path (Name);
   begin
      if Path = null then
         return "";
      end if;
      declare
         Result : constant String := Path.all;
      begin
         GNAT.OS_Lib.Free (Path);
         return Result;
      end;
   exception
      when others =>
         if Path /= null then
            GNAT.OS_Lib.Free (Path);
         end if;
         raise;
   end Locate_Command;

   function Has_Argument (Name : String) return Boolean is
   begin
      for Index in 1 .. Ada.Command_Line.Argument_Count loop
         if Ada.Command_Line.Argument (Index) = Name then
            return True;
         end if;
      end loop;

      return False;
   end Has_Argument;

   procedure Require_Command
     (Name    : String;
      Message : String;
      Quiet   : Boolean := False)
   is
   begin
      if Locate_Command (Name) = "" then
         if not Quiet then
            Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, Message);
         end if;
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
         raise Program_Error;
      end if;
   end Require_Command;

   function Run_Status
     (Label   : String;
      Dir     : String;
      Program : String;
      Args    : GNAT.OS_Lib.Argument_List;
      Quiet   : Boolean := False) return Integer
   is
      Previous : constant String := Ada.Directories.Current_Directory;
      Status   : Integer;
   begin
      if not Quiet then
         Ada.Text_IO.New_Line;
         Ada.Text_IO.Put_Line ("==> " & Label);
      end if;

      Ada.Directories.Set_Directory (Dir);
      Status := GNAT.OS_Lib.Spawn (Program, Args);
      Ada.Directories.Set_Directory (Previous);
      return Status;
   exception
      when others =>
         if Ada.Directories.Current_Directory /= Previous then
            Ada.Directories.Set_Directory (Previous);
         end if;
         raise;
   end Run_Status;

   procedure Run
     (Label   : String;
      Dir     : String;
      Program : String;
      Args    : GNAT.OS_Lib.Argument_List;
      Quiet   : Boolean := False)
   is
      Status : constant Integer := Run_Status (Label, Dir, Program, Args, Quiet);
   begin
      if Status /= 0 then
         if not Quiet then
            Ada.Text_IO.Put_Line
              (Ada.Text_IO.Standard_Error,
               Label & " failed with status" & Integer'Image (Status));
         end if;
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
         raise Program_Error;
      end if;
   end Run;

   function Run_Status
     (Label   : String;
      Dir     : String;
      Program : String;
      Args    : GNAT.OS_Lib.Argument_List;
      Output  : out Unbounded_String;
      Quiet   : Boolean := False) return Integer
   is
      Previous  : constant String := Ada.Directories.Current_Directory;
      Temp_Dir  : constant String := Project_Tools.Files.Temp_Dir;
      Max_Temp_Attempts : constant := 50_000;
      FD        : GNAT.OS_Lib.File_Descriptor;
      Temp_Name : GNAT.OS_Lib.String_Access;
      Status    : Integer;

      function Temp_Path return String is
      begin
         if Temp_Name = null then
            return "";
         elsif Temp_Name.all'Length > 0 and then Temp_Name.all (Temp_Name.all'First) = '/' then
            return Temp_Name.all;
         else
            return Temp_Dir & "/" & Temp_Name.all;
         end if;
      end Temp_Path;

      procedure Cleanup is
         Deleted : Boolean;
      begin
         if Temp_Name /= null then
            GNAT.OS_Lib.Delete_File (Temp_Path, Deleted);
            GNAT.OS_Lib.Free (Temp_Name);
         end if;
      end Cleanup;
   begin
      Output := Ada.Strings.Unbounded.Null_Unbounded_String;

      if not Quiet then
         Ada.Text_IO.New_Line;
         Ada.Text_IO.Put_Line ("==> " & Label);
      end if;

      --  GNAT.OS_Lib.Create_Temp_Output_File derives a candidate name from a
      --  process-global counter and returns Invalid_FD (without retrying) when
      --  that candidate already exists; the counter still advances. A /tmp
      --  littered with stale GNAT-TEMP-*.TMP files -- e.g. leaked by processes
      --  killed before cleanup -- therefore makes the first call(s) fail until
      --  the counter steps past them. Retry until a free slot is found rather
      --  than treating the first collision as fatal.
      for Attempt in 1 .. Max_Temp_Attempts loop
         Ada.Directories.Set_Directory (Temp_Dir);
         GNAT.OS_Lib.Create_Temp_Output_File (FD, Temp_Name);
         Ada.Directories.Set_Directory (Previous);
         exit when FD /= GNAT.OS_Lib.Invalid_FD and then Temp_Name /= null;
      end loop;
      if FD = GNAT.OS_Lib.Invalid_FD or else Temp_Name = null then
         raise Program_Error with "could not create temporary output file";
      end if;

      Ada.Directories.Set_Directory (Dir);
      GNAT.OS_Lib.Spawn
        (Program_Name           => Program,
         Args                   => Args,
         Output_File_Descriptor => FD,
         Return_Code            => Status,
         Err_To_Out             => False);
      Ada.Directories.Set_Directory (Previous);

      GNAT.OS_Lib.Close (FD);
      Output :=
        Ada.Strings.Unbounded.To_Unbounded_String
          (Project_Tools.Files.Read_Raw_File (Temp_Path));
      Cleanup;
      return Status;
   exception
      when others =>
         if Ada.Directories.Current_Directory /= Previous then
            Ada.Directories.Set_Directory (Previous);
         end if;
         Cleanup;
         raise;
   end Run_Status;

   procedure Run
     (Label   : String;
      Dir     : String;
      Program : String;
      Args    : GNAT.OS_Lib.Argument_List;
      Output  : out Unbounded_String;
      Quiet   : Boolean := False)
   is
      Status : constant Integer :=
        Run_Status (Label, Dir, Program, Args, Output, Quiet);
   begin
      if Status /= 0 then
         if not Quiet then
            Ada.Text_IO.Put_Line
              (Ada.Text_IO.Standard_Error,
               Label & " failed with status" & Integer'Image (Status));
         end if;
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
         raise Program_Error;
      end if;
   end Run;

   function Command_Output
     (Command    : String;
      Arguments  : GNAT.OS_Lib.Argument_List;
      Input      : String := "";
      Status     : access Integer := null;
      Err_To_Out : Boolean := False) return String is
   begin
      return
        GNAT.Expect.Get_Command_Output
          (Command    => Command,
           Arguments  => Arguments,
           Input      => Input,
           Status     => Status,
           Err_To_Out => Err_To_Out);
   end Command_Output;

   function Shell_Quote (Value : String) return String is
      use Ada.Strings.Unbounded;
      Result : Unbounded_String := To_Unbounded_String ("'");
   begin
      for Ch of Value loop
         if Ch = ''' then
            Append (Result, "'\''");
         else
            Append (Result, Ch);
         end if;
      end loop;
      Append (Result, "'");
      return To_String (Result);
   end Shell_Quote;

   function Run_Shell (Command : String) return Integer is
      Shell  : constant String :=
        (if Ada.Directories.Exists ("/bin/sh") then "/bin/sh" else "sh");
      Args   : GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("-c"), new String'(Command)];
      Status : Integer;
   begin
      Status := GNAT.OS_Lib.Spawn (Program_Name => Shell, Args => Args);
      Free_Args (Args);
      return Status;
   exception
      when others =>
         Free_Args (Args);
         return 1;
   end Run_Shell;

   function Run_Shell_In_Directory
     (Directory   : String;
      Command     : String;
      Quiet       : Boolean := False;
      Output_File : String := "") return Integer
   is
      Redirect : constant String :=
        (if Output_File'Length > 0
         then " >" & Shell_Quote (Output_File) & " 2>&1"
         elsif Quiet
         then " >/dev/null"
         else "");
   begin
      return Run_Shell
        ("cd " & Shell_Quote (Directory) & " && " & Command & Redirect);
   end Run_Shell_In_Directory;

   function Shell_Output (Command : String) return String is
      FD     : GNAT.OS_Lib.File_Descriptor;
      Name   : GNAT.OS_Lib.String_Access;
      Status : Integer;

      procedure Cleanup is
         Deleted : Boolean;
      begin
         if Name /= null then
            GNAT.OS_Lib.Delete_File (Name.all, Deleted);
            GNAT.OS_Lib.Free (Name);
         end if;
      end Cleanup;
   begin
      GNAT.OS_Lib.Create_Temp_Output_File (FD, Name);
      if FD = GNAT.OS_Lib.Invalid_FD or else Name = null then
         return "";
      end if;
      GNAT.OS_Lib.Close (FD);

      Status :=
        Run_Shell
          ("(" & Command & ") > " & Shell_Quote (Name.all) & " 2>/dev/null");
      if Status /= 0 then
         Cleanup;
         return "";
      end if;

      declare
         Text : constant String :=
           Ada.Strings.Unbounded.To_String
             (Project_Tools.Text.Read_Text_File (Name.all));
      begin
         Cleanup;
         return Text;
      end;
   exception
      when others =>
         Cleanup;
         return "";
   end Shell_Output;

   function Shell_Output_Trimmed (Command : String) return String is
      Text : constant String := Shell_Output (Command);
   begin
      for I in Text'Range loop
         if Text (I) = ASCII.LF or else Text (I) = ASCII.CR then
            if I = Text'First then
               return "";
            end if;
            return Ada.Strings.Fixed.Trim
              (Text (Text'First .. I - 1), Ada.Strings.Both);
         end if;
      end loop;
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Shell_Output_Trimmed;
end Project_Tools.Processes;
