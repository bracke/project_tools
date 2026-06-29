with Ada.Command_Line;
with Ada.Directories;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;

with Project_Tools.Text;

package body Project_Tools.Tree_Checks is
   use type Ada.Directories.File_Kind;
   use type Ada.Directories.File_Size;
   procedure Error (Errors : in out Natural; Message : String; Quiet : Boolean) is
   begin
      Errors := Errors + 1;
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      if not Quiet then
         Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, "error: " & Message);
      end if;
   end Error;

   procedure Check_No_Generated_Python
     (Errors : in out Natural;
      Dir    : String;
      Quiet  : Boolean := False)
   is
      Search : Ada.Directories.Search_Type;
      Dir_Entry : Ada.Directories.Directory_Entry_Type;
   begin
      Ada.Directories.Start_Search
        (Search    => Search,
         Directory => Dir,
         Pattern   => "*",
         Filter    => [Ada.Directories.Directory => True, Ada.Directories.Ordinary_File => True, others => False]);
      while Ada.Directories.More_Entries (Search) loop
         Ada.Directories.Get_Next_Entry (Search, Dir_Entry);
         declare
            Name : constant String := Ada.Directories.Simple_Name (Dir_Entry);
            Full : constant String := Ada.Directories.Full_Name (Dir_Entry);
         begin
            if Name /= "." and then Name /= ".." then
               if Name = "__pycache__" or else Project_Tools.Text.Contains (Name, ".pyc") then
                  Error (Errors, "generated Python artifact must not be packaged: " & Full, Quiet);
               elsif Project_Tools.Text.Contains (Name, ".py") then
                  Error (Errors, "Python script must not be packaged in release tooling: " & Full, Quiet);
               elsif Ada.Directories.Kind (Dir_Entry) = Ada.Directories.Directory then
                  Check_No_Generated_Python (Errors, Full, Quiet);
               end if;
            end if;
         end;
      end loop;
      Ada.Directories.End_Search (Search);
   exception
      when others =>
         if Ada.Directories.More_Entries (Search) then
            Ada.Directories.End_Search (Search);
         end if;
   end Check_No_Generated_Python;

   procedure Check_No_Forbidden_Tokens
     (Errors           : in out Natural;
      Dir              : String;
      Forbidden_Tokens : Text_List;
      Purpose          : String;
      Exempt_Path_Token : String := "";
      Quiet            : Boolean := False)
   is
      Search : Ada.Directories.Search_Type;
      Dir_Entry : Ada.Directories.Directory_Entry_Type;
   begin
      Ada.Directories.Start_Search
        (Search    => Search,
         Directory => Dir,
         Pattern   => "*",
         Filter    => [Ada.Directories.Directory => True, Ada.Directories.Ordinary_File => True, others => False]);
      while Ada.Directories.More_Entries (Search) loop
         Ada.Directories.Get_Next_Entry (Search, Dir_Entry);
         declare
            Name : constant String := Ada.Directories.Simple_Name (Dir_Entry);
            Full : constant String := Ada.Directories.Full_Name (Dir_Entry);
         begin
            if Name /= "." and then Name /= ".." then
               if Ada.Directories.Kind (Dir_Entry) = Ada.Directories.Directory then
                  Check_No_Forbidden_Tokens (Errors, Full, Forbidden_Tokens, Purpose, Exempt_Path_Token, Quiet);
               else
                  declare
                     Text : constant String := To_String (Project_Tools.Text.Read_Text_File (Full));
                  begin
                     for Token of Forbidden_Tokens loop
                        declare
                           Pattern : constant String := To_String (Token);
                        begin
                           if Project_Tools.Text.Contains (Name, Pattern)
                             or else
                               (Project_Tools.Text.Contains (Text, Pattern)
                                and then
                                  (Exempt_Path_Token = ""
                                   or else not Project_Tools.Text.Contains (Full, Exempt_Path_Token)))
                           then
                              Error
                                (Errors,
                                 Purpose & " must not contain forbidden token '" & Pattern & "': " & Full,
                                 Quiet);
                           end if;
                        end;
                     end loop;
                  end;
               end if;
            end if;
         end;
      end loop;
      Ada.Directories.End_Search (Search);
   exception
      when others =>
         if Ada.Directories.More_Entries (Search) then
            Ada.Directories.End_Search (Search);
         end if;
         Error (Errors, "could not scan " & Purpose & ": " & Dir, Quiet);
   end Check_No_Forbidden_Tokens;

   procedure Require_No_Nonempty_Stderr
     (Dir   : String;
      Quiet : Boolean := False)
   is
      Errors : Natural := 0;

      procedure Scan (Path : String) is
         Search : Ada.Directories.Search_Type;
         Open   : Boolean := False;
      begin
         if not Ada.Directories.Exists (Path)
           or else Ada.Directories.Kind (Path) /= Ada.Directories.Directory
         then
            return;
         end if;

         Ada.Directories.Start_Search (Search, Path, "*");
         Open := True;
         while Ada.Directories.More_Entries (Search) loop
            declare
               Item : Ada.Directories.Directory_Entry_Type;
            begin
               Ada.Directories.Get_Next_Entry (Search, Item);
               declare
                  Name : constant String := Ada.Directories.Simple_Name (Item);
                  Full : constant String := Ada.Directories.Full_Name (Item);
               begin
                  if Name /= "." and then Name /= ".." then
                     if Ada.Directories.Kind (Item) = Ada.Directories.Directory then
                        Scan (Full);
                     elsif Project_Tools.Text.Contains (Name, ".stderr")
                       and then Ada.Directories.Size (Full) > 0
                     then
                        Error (Errors, "generated stderr log is non-empty: " & Full, Quiet);
                     end if;
                  end if;
               end;
            end;
         end loop;
         Ada.Directories.End_Search (Search);
      exception
         when others =>
            if Open then
               begin
                  Ada.Directories.End_Search (Search);
               exception
                  when others =>
                     null;
               end;
            end if;
            raise;
      end Scan;
   begin
      Scan (Dir);
      if Errors > 0 then
         raise Program_Error;
      end if;
   end Require_No_Nonempty_Stderr;
end Project_Tools.Tree_Checks;
