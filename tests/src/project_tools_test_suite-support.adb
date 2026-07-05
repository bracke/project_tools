with Ada.Command_Line;
with Ada.Directories;

with AUnit.Assertions;

with Project_Tools.Files;

package body Project_Tools_Test_Suite.Support is

   procedure Delete_Tree_If_Present (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_Tree (Path);
      end if;
   end Delete_Tree_If_Present;

   procedure Write_File (Path : String; Content : String) is
   begin
      Project_Tools.Files.Write_Text_File (Path, Content);
   end Write_File;

   procedure Expect_Program_Error
     (Action  : not null access procedure;
      Message : String) is
   begin
      Action.all;
      AUnit.Assertions.Assert (False, Message);
   exception
      when Program_Error =>
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end Expect_Program_Error;

end Project_Tools_Test_Suite.Support;
