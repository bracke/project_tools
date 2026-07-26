with Ada.Command_Line;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;

with Project_Tools.Text;

package body Project_Tools.Security_Corpus is
   use type Ada.Directories.File_Size;
   procedure Error (Errors : in out Natural; Message : String; Quiet : Boolean) is
   begin
      Errors := Errors + 1;
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      if not Quiet then
         Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, "error: " & Message);
      end if;
   end Error;

   function Is_Listed (Name : String; Items : Text_List) return Boolean is
   begin
      for Item of Items loop
         if Name = To_String (Item) then
            return True;
         end if;
      end loop;
      return False;
   end Is_Listed;

   function Contains_Forbidden_Token (Data : String; Tokens : Text_List) return Boolean is
   begin
      for Token of Tokens loop
         if Project_Tools.Text.Contains (Data, To_String (Token)) then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Forbidden_Token;

   procedure Check_Category
     (Errors                  : in out Natural;
      Corpus                  : String;
      Name                    : String;
      Forbidden_Secret_Tokens : Text_List;
      Max_Entry_Size          : Ada.Directories.File_Size;
      Quiet                   : Boolean)
   is
      Search : Ada.Directories.Search_Type;
      Dir_Entry : Ada.Directories.Directory_Entry_Type;
      Count  : Natural := 0;
      Path   : constant String := Corpus & "/" & Name;
   begin
      if not Project_Tools.Files.Directory_Exists (Path) then
         Error (Errors, "missing security corpus category: " & Name, Quiet);
         return;
      end if;

      Ada.Directories.Start_Search
        (Search    => Search,
         Directory => Path,
         Pattern   => "*",
         Filter    => [Ada.Directories.Ordinary_File => True, others => False]);
      while Ada.Directories.More_Entries (Search) loop
         Ada.Directories.Get_Next_Entry (Search, Dir_Entry);
         declare
            File_Path : constant String := Ada.Directories.Full_Name (Dir_Entry);
            Data      : constant String := To_String (Project_Tools.Text.Read_Text_File (File_Path));
            Size      : constant Ada.Directories.File_Size := Ada.Directories.Size (File_Path);
         begin
            Count := Count + 1;
            if Size = 0 then
               Error (Errors, "empty security corpus entry: " & File_Path, Quiet);
            elsif Size > Max_Entry_Size then
               Error (Errors, "oversized security corpus entry: " & File_Path, Quiet);
            end if;
            if Contains_Forbidden_Token (Data, Forbidden_Secret_Tokens) then
               Error (Errors, "possible secret material in security corpus entry: " & File_Path, Quiet);
            end if;
         end;
      end loop;
      Ada.Directories.End_Search (Search);

      if Count = 0 then
         Error (Errors, "empty security corpus category: " & Name, Quiet);
      end if;
   exception
      when others =>
         if Ada.Directories.More_Entries (Search) then
            Ada.Directories.End_Search (Search);
         end if;
         Error (Errors, "could not scan security corpus category: " & Name, Quiet);
   end Check_Category;

   procedure Check_Corpus
     (Errors                   : in out Natural;
      Corpus                   : String;
      Required_Categories      : Text_List;
      Forbidden_Secret_Tokens  : Text_List;
      Required_README_Tokens   : Text_List;
      Max_Entry_Size           : Ada.Directories.File_Size;
      Quiet                    : Boolean := False)
   is
   begin
      if not Project_Tools.Files.Directory_Exists (Corpus) then
         Error (Errors, "missing corpus directory: " & Corpus, Quiet);
         return;
      end if;

      for Category of Required_Categories loop
         Check_Category
           (Errors, Corpus, To_String (Category), Forbidden_Secret_Tokens, Max_Entry_Size, Quiet);
      end loop;

      declare
         Search : Ada.Directories.Search_Type;
         Dir_Entry : Ada.Directories.Directory_Entry_Type;
      begin
         Ada.Directories.Start_Search
           (Search    => Search,
            Directory => Corpus,
            Pattern   => "*",
            Filter    => [Ada.Directories.Directory => True, others => False]);
         while Ada.Directories.More_Entries (Search) loop
            Ada.Directories.Get_Next_Entry (Search, Dir_Entry);
            declare
               Name : constant String := Ada.Directories.Simple_Name (Dir_Entry);
            begin
               if Name /= "." and then Name /= ".." and then not Is_Listed (Name, Required_Categories) then
                  Error (Errors, "unexpected security corpus category: " & Name, Quiet);
               end if;
            end;
         end loop;
         Ada.Directories.End_Search (Search);
      end;

      declare
         Readme : constant String := To_String (Project_Tools.Text.Read_Text_File (Corpus & "/README.md"));
      begin
         for Token of Required_README_Tokens loop
            declare
               Pattern : constant String := To_String (Token);
            begin
               if not Project_Tools.Text.Contains (Readme, Pattern) then
                  Error (Errors, "security corpus README missing required token: " & Pattern, Quiet);
               end if;
            end;
         end loop;
      end;
   end Check_Corpus;
end Project_Tools.Security_Corpus;
