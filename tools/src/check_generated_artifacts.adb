with Ada.Command_Line;
with Ada.Directories;
with Ada.Text_IO;

with GNAT.OS_Lib;

with Project_Tools.Files;
with Project_Tools.Processes;

--  Ada port of the former tools/check_generated_artifacts.sh helper.
--
--  Usage: check_generated_artifacts PASS_MESSAGE GENERATE_COMMAND PATH...
--
--  Creates a temporary output directory, runs GENERATE_COMMAND through the
--  shell with the temporary directory passed as its single positional argument
--  ($1), then byte-compares each PATH against its regenerated counterpart under
--  the temporary directory. Any mismatch prints a diff-like report to stderr
--  and exits 1; otherwise PASS_MESSAGE is printed and the program exits 0.
procedure Check_Generated_Artifacts is
   use Ada.Text_IO;
   use type GNAT.OS_Lib.String_Access;

   procedure Put_Line_Diff (Expected : String; Generated : String) is
   --  Emit a small diff-like report of the first differing lines to stderr.
   --  @param Expected Committed artifact contents.
   --  @param Generated Regenerated artifact contents.
      E_Start : Natural := Expected'First;
      G_Start : Natural := Generated'First;

      function Next_LF (Text : String; From : Natural) return Natural is
      begin
         for I in From .. Text'Last loop
            if Text (I) = ASCII.LF then
               return I;
            end if;
         end loop;
         return Text'Last + 1;
      end Next_LF;

      Shown : Natural := 0;
   begin
      while (E_Start <= Expected'Last or else G_Start <= Generated'Last)
        and then Shown < 40
      loop
         declare
            E_End : constant Natural :=
              (if E_Start <= Expected'Last then Next_LF (Expected, E_Start) else E_Start - 1);
            G_End : constant Natural :=
              (if G_Start <= Generated'Last then Next_LF (Generated, G_Start) else G_Start - 1);
            E_Line : constant String :=
              (if E_Start <= Expected'Last then Expected (E_Start .. E_End - 1) else "");
            G_Line : constant String :=
              (if G_Start <= Generated'Last then Generated (G_Start .. G_End - 1) else "");
            Have_E : constant Boolean := E_Start <= Expected'Last;
            Have_G : constant Boolean := G_Start <= Generated'Last;
         begin
            if Have_E /= Have_G or else E_Line /= G_Line then
               if Have_E then
                  Put_Line (Standard_Error, "-" & E_Line);
               end if;
               if Have_G then
                  Put_Line (Standard_Error, "+" & G_Line);
               end if;
               Shown := Shown + 1;
            end if;
            E_Start := (if Have_E then E_End + 1 else E_Start);
            G_Start := (if Have_G then G_End + 1 else G_Start);
         end;
      end loop;
   end Put_Line_Diff;

   function Make_Temp_Directory return String is
   --  @return A freshly created empty temporary directory path.
      FD      : GNAT.OS_Lib.File_Descriptor;
      Name    : GNAT.OS_Lib.String_Access;
      Deleted : Boolean;
   begin
      GNAT.OS_Lib.Create_Temp_File (FD, Name);
      if Name = null then
         raise Program_Error with "could not allocate a temporary output path";
      end if;
      GNAT.OS_Lib.Close (FD);
      GNAT.OS_Lib.Delete_File (Name.all, Deleted);
      declare
         Dir : constant String := Name.all;
      begin
         GNAT.OS_Lib.Free (Name);
         Ada.Directories.Create_Directory (Dir);
         return Dir;
      end;
   end Make_Temp_Directory;

begin
   if Ada.Command_Line.Argument_Count < 3 then
      Put_Line
        (Standard_Error,
         "usage: check_generated_artifacts PASS_MESSAGE GENERATE_COMMAND PATH...");
      Ada.Command_Line.Set_Exit_Status (2);
      return;
   end if;

   declare
      Pass_Message     : constant String := Ada.Command_Line.Argument (1);
      Generate_Command : constant String := Ada.Command_Line.Argument (2);
      Temp_Dir         : constant String := Make_Temp_Directory;
      Shell            : constant String :=
        (if Project_Tools.Processes.Locate_Command ("sh") /= ""
         then Project_Tools.Processes.Locate_Command ("sh")
         else "/bin/sh");
      Args : GNAT.OS_Lib.Argument_List :=
        [new String'("-c"),
         new String'(Generate_Command),
         new String'("generated-check"),
         new String'(Temp_Dir)];
      Mismatch : Boolean := False;
   begin
      begin
         --  Run GENERATE_COMMAND with the temporary directory as its positional
         --  argument ($1), mirroring the former "sh -c CMD label TMP" behavior.
         Project_Tools.Processes.Run
           (Label   => "generate artifacts",
            Dir     => Ada.Directories.Current_Directory,
            Program => Shell,
            Args    => Args,
            Quiet   => True);

         for Index in 3 .. Ada.Command_Line.Argument_Count loop
            declare
               Path      : constant String := Ada.Command_Line.Argument (Index);
               Generated : constant String := Project_Tools.Files.Join (Temp_Dir, Path);
            begin
               if not Project_Tools.Files.File_Exists (Generated) then
                  Put_Line
                    (Standard_Error,
                     "generated artifact missing: " & Path);
                  Mismatch := True;
               else
                  declare
                     Committed_Text : constant String :=
                       Project_Tools.Files.Read_Raw_File (Path);
                     Generated_Text : constant String :=
                       Project_Tools.Files.Read_Raw_File (Generated);
                  begin
                     if Committed_Text /= Generated_Text then
                        Put_Line
                          (Standard_Error, "generated artifact differs: " & Path);
                        Put_Line_Diff (Committed_Text, Generated_Text);
                        Mismatch := True;
                     end if;
                  end;
               end if;
            end;
         end loop;
      exception
         when others =>
            for Arg of Args loop
               GNAT.OS_Lib.Free (Arg);
            end loop;
            Project_Tools.Files.Delete_Tree (Temp_Dir);
            raise;
      end;

      for Arg of Args loop
         GNAT.OS_Lib.Free (Arg);
      end loop;
      Project_Tools.Files.Delete_Tree (Temp_Dir);

      if Mismatch then
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      else
         Put_Line (Pass_Message);
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
      end if;
   end;
end Check_Generated_Artifacts;
