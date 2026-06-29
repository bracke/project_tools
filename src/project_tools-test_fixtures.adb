with Ada.Calendar;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Exceptions;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Project_Tools.Files;

package body Project_Tools.Test_Fixtures is

   use Ada.Strings.Unbounded;

   Counter : Natural := 0;

   function Next_Id return String is
   begin
      Counter := Counter + 1;
      declare
         Image : constant String := Natural'Image (Counter);
      begin
         return Image (Image'First + 1 .. Image'Last);
      end;
   end Next_Id;

   function Temp_Base return String is
   begin
      if Ada.Environment_Variables.Exists ("TMPDIR") then
         return Ada.Environment_Variables.Value ("TMPDIR");
      elsif Ada.Environment_Variables.Exists ("TEMP") then
         return Ada.Environment_Variables.Value ("TEMP");
      elsif Ada.Environment_Variables.Exists ("TMP") then
         return Ada.Environment_Variables.Value ("TMP");
      else
         return "/tmp";
      end if;
   end Temp_Base;

   procedure Make_Directory (Path : String) is
   begin
      if not Ada.Directories.Exists (Path) then
         Ada.Directories.Create_Path (Path);
      end if;
   end Make_Directory;

   procedure Cleanup (Path : String) is
      Max_Attempts : constant Positive := 3;
      Last_Message : Unbounded_String;
   begin
      for Attempt in 1 .. Max_Attempts loop
         begin
            if Ada.Directories.Exists (Path) then
               Ada.Directories.Delete_Tree (Path);
            end if;
            return;
         exception
            when E : others =>
               Last_Message := To_Unbounded_String
                 (Ada.Exceptions.Exception_Message (E));
               if Attempt < Max_Attempts then
                  delay 0.02;
               end if;
         end;
      end loop;

      if Ada.Environment_Variables.Exists ("VERSION_TEST_VERBOSE_CLEANUP")
        and then Ada.Environment_Variables.Value
          ("VERSION_TEST_VERBOSE_CLEANUP") = "1"
      then
         Ada.Text_IO.Put_Line
           ("[WARN] cleanup failed: " & To_String (Last_Message));
      end if;
   end Cleanup;

   function Fresh_Temp_Dir (Name : String) return String is
      Now_Value   : constant Duration :=
        Ada.Calendar.Seconds (Ada.Calendar.Clock);
      Suffix_Time : constant String := Duration'Image (Now_Value);
      Clean_Time  : Unbounded_String;
   begin
      for C of Suffix_Time loop
         if C in '0' .. '9' then
            Append (Clean_Time, C);
         end if;
      end loop;

      declare
         Dir : constant String :=
           Project_Tools.Files.Join
             (Temp_Base,
              "version_test_" & Name & "_" & To_String (Clean_Time) & "_"
              & Next_Id);
      begin
         Cleanup (Dir);
         Ada.Directories.Create_Directory (Dir);
         return Dir;
      end;
   end Fresh_Temp_Dir;

   procedure Write_Text_File (Path : String; Content : String) is
      Parent : constant String := Ada.Directories.Containing_Directory (Path);
   begin
      if Parent'Length > 0 and then not Ada.Directories.Exists (Parent) then
         Ada.Directories.Create_Path (Parent);
      end if;
      Project_Tools.Files.Write_Raw_File (Path, Content);
   end Write_Text_File;

   function Read_Text_File (Path : String) return String is
      File   : Ada.Text_IO.File_Type;
      Result : Unbounded_String;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         Append (Result, Ada.Text_IO.Get_Line (File));
         if not Ada.Text_IO.End_Of_File (File) then
            Append (Result, Character'Val (10));
         end if;
      end loop;
      Ada.Text_IO.Close (File);
      return To_String (Result);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Read_Text_File;

end Project_Tools.Test_Fixtures;
