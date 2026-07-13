with Ada.Command_Line;
with Ada.Containers.Vectors;
with Ada.Directories;
with Ada.Streams;
with Ada.Strings.Unbounded;
with Ada.Streams.Stream_IO;
with Ada.Text_IO;

with GNAT.OS_Lib;
with GNAT.Regexp;

with Project_Tools.Text;

package body Project_Tools.Files is
   use type Ada.Directories.File_Kind;
   function Exists (Path : String) return Boolean is
   begin
      return Ada.Directories.Exists (Path);
   end Exists;

   function File_Exists (Path : String) return Boolean is
   begin
      return Ada.Directories.Exists (Path)
        and then Ada.Directories.Kind (Path) = Ada.Directories.Ordinary_File;
   exception
      when others =>
         return False;
   end File_Exists;

   function Directory_Exists (Path : String) return Boolean is
   begin
      return Ada.Directories.Exists (Path)
        and then Ada.Directories.Kind (Path) = Ada.Directories.Directory;
   exception
      when others =>
         return False;
   end Directory_Exists;

   function File_Contains (Path : String; Pattern : String) return Boolean is
   begin
      return Project_Tools.Text.Contains
        (Ada.Strings.Unbounded.To_String (Project_Tools.Text.Read_Text_File (Path)), Pattern);
   end File_Contains;

   function Line_Contains (Path : String; Pattern : String) return Boolean is
      File_Item : Ada.Text_IO.File_Type;
   begin
      if not Exists (Path) then
         return False;
      end if;

      Ada.Text_IO.Open (File_Item, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File_Item) loop
         if Project_Tools.Text.Contains
              (Ada.Text_IO.Get_Line (File_Item), Pattern)
         then
            Ada.Text_IO.Close (File_Item);
            return True;
         end if;
      end loop;
      Ada.Text_IO.Close (File_Item);
      return False;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File_Item) then
            Ada.Text_IO.Close (File_Item);
         end if;
         return False;
   end Line_Contains;

   function Read_Raw_File (Path : String) return String is
      use Ada.Streams;

      File : Ada.Streams.Stream_IO.File_Type;
   begin
      Ada.Streams.Stream_IO.Open (File, Ada.Streams.Stream_IO.In_File, Path);
      declare
         File_Size : constant Stream_Element_Offset :=
           Stream_Element_Offset (Ada.Streams.Stream_IO.Size (File));
      begin
         if File_Size = 0 then
            Ada.Streams.Stream_IO.Close (File);
            return "";
         end if;

         declare
            Data      : Stream_Element_Array (1 .. File_Size);
            Last      : Stream_Element_Offset;
            Result    : String (1 .. Natural (File_Size));
            Out_Index : Natural := Result'First;
         begin
            Ada.Streams.Stream_IO.Read (File, Data, Last);
            Ada.Streams.Stream_IO.Close (File);

            for Index in Data'First .. Last loop
               Result (Out_Index) := Character'Val (Data (Index));
               Out_Index := Out_Index + 1;
            end loop;

            return Result (Result'First .. Out_Index - 1);
         end;
      end;
   exception
      when others =>
         if Ada.Streams.Stream_IO.Is_Open (File) then
            Ada.Streams.Stream_IO.Close (File);
         end if;
         raise;
   end Read_Raw_File;

   function File_Starts_With_File (Path : String; Prefix_Path : String) return Boolean is
      Text   : constant String := Read_Raw_File (Path);
      Prefix : constant String := Read_Raw_File (Prefix_Path);
   begin
      if Text'Length < Prefix'Length then
         return False;
      elsif Prefix'Length = 0 then
         return True;
      else
         return Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix;
      end if;
   exception
      when others =>
         return False;
   end File_Starts_With_File;


   procedure Fail_Requirement
     (Path    : String;
      Message : String;
      Quiet   : Boolean) is
   begin
      if not Quiet then
         Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, Message & ": " & Path);
      end if;
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      raise Program_Error;
   end Fail_Requirement;

   procedure Require_Contains
     (Path    : String;
      Pattern : String;
      Message : String;
      Quiet   : Boolean := False) is
   begin
      if not File_Contains (Path, Pattern) then
         Fail_Requirement (Path, Message, Quiet);
      end if;
   end Require_Contains;

   procedure Require_File
     (Path    : String;
      Message : String;
      Quiet   : Boolean := False) is
   begin
      if not File_Exists (Path) then
         Fail_Requirement (Path, Message, Quiet);
      end if;
   end Require_File;

   procedure Require_Directory
     (Path    : String;
      Message : String;
      Quiet   : Boolean := False) is
   begin
      if not Directory_Exists (Path) then
         Fail_Requirement (Path, Message, Quiet);
      end if;
   end Require_Directory;

   procedure Require_Files
     (Paths   : Path_List;
      Message : String;
      Quiet   : Boolean := False) is
   begin
      for Path of Paths loop
         Require_File (Ada.Strings.Unbounded.To_String (Path), Message, Quiet);
      end loop;
   end Require_Files;

   procedure Require_Directories
     (Paths   : Path_List;
      Message : String;
      Quiet   : Boolean := False) is
   begin
      for Path of Paths loop
         Require_Directory (Ada.Strings.Unbounded.To_String (Path), Message, Quiet);
      end loop;
   end Require_Directories;

   procedure Require_File_Starts_With_File
     (Path        : String;
      Prefix_Path : String;
      Message     : String;
      Quiet       : Boolean := False) is
   begin
      Require_File (Path, Message, Quiet);
      Require_File (Prefix_Path, Message, Quiet);
      if not File_Starts_With_File (Path, Prefix_Path) then
         Fail_Requirement (Path, Message, Quiet);
      end if;
   end Require_File_Starts_With_File;


   function Contains_Name (Names : Name_List; Name : String) return Boolean is
   begin
      for Item of Names loop
         if Ada.Strings.Unbounded.To_String (Item) = Name then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Name;

   procedure Copy_Filtered_Tree
     (Source_Dir      : String;
      Target_Dir      : String;
      Skip_Entries    : Name_List;
      Skip_Files      : Name_List;
      Failure_Message : String := "failed to copy source tree";
      Quiet           : Boolean := False)
   is
      Search      : Ada.Directories.Search_Type;
      Search_Open : Boolean := False;
      Dir_Entry   : Ada.Directories.Directory_Entry_Type;
   begin
      Ada.Directories.Create_Path (Target_Dir);
      Ada.Directories.Start_Search (Search, Source_Dir, "");
      Search_Open := True;

      while Ada.Directories.More_Entries (Search) loop
         Ada.Directories.Get_Next_Entry (Search, Dir_Entry);

         declare
            Name   : constant String := Ada.Directories.Simple_Name (Dir_Entry);
            Source : constant String := Source_Dir & "/" & Name;
            Target : constant String := Target_Dir & "/" & Name;
            Kind   : constant Ada.Directories.File_Kind := Ada.Directories.Kind (Dir_Entry);
         begin
            if Name = "." or else Name = ".." or else Contains_Name (Skip_Entries, Name) then
               null;
            elsif Kind = Ada.Directories.Directory then
               Copy_Filtered_Tree
                 (Source, Target, Skip_Entries, Skip_Files, Failure_Message, Quiet);
            elsif Kind = Ada.Directories.Ordinary_File
              and then not Contains_Name (Skip_Files, Name)
            then
               Ada.Directories.Copy_File
                 (Source_Name => Source,
                  Target_Name => Target,
                  Form        => "mode=overwrite");
            end if;
         end;
      end loop;

      Ada.Directories.End_Search (Search);
   exception
      when Program_Error =>
         raise;
      when others =>
         if Search_Open then
            Ada.Directories.End_Search (Search);
         end if;
         Fail_Requirement (Source_Dir, Failure_Message, Quiet);
   end Copy_Filtered_Tree;

   procedure Copy_Release_Source_Tree
     (Source_Dir      : String;
      Target_Dir      : String;
      Skip_Entries    : Name_List;
      Skip_Files      : Name_List;
      Quiet           : Boolean := False) is
   begin
      Copy_Filtered_Tree
        (Source_Dir      => Source_Dir,
         Target_Dir      => Target_Dir,
         Skip_Entries    => Skip_Entries,
         Skip_Files      => Skip_Files,
         Failure_Message => "failed to copy release source from",
         Quiet           => Quiet);
   end Copy_Release_Source_Tree;

   procedure Delete_Tree (Path : String) is
      --  Ada.Directories.Delete_Tree walks INTO a symbolic link that points at a
      --  directory, because Kind follows the link. A tree containing a link back
      --  to one of its own ancestors therefore recurses without end -- on Windows
      --  it grinds on until the path passes MAX_PATH and raises Use_Error, and on
      --  any platform it risks deleting whatever the link points at, which may
      --  sit entirely outside the tree.
      --
      --  So walk the tree by hand: a link is removed, never followed.

      procedure Remove_Link (Target : String);

      procedure Remove_Link (Target : String) is
      begin
         --  A link to a directory is a directory entry on Windows and a file
         --  entry on POSIX, and only one of the two calls will take it.
         Ada.Directories.Delete_File (Target);
      exception
         when others =>
            begin
               Ada.Directories.Delete_Directory (Target);
            exception
               when others =>
                  null;
            end;
      end Remove_Link;

   begin
      if GNAT.OS_Lib.Is_Symbolic_Link (Path) then
         --  Checked before Exists: a dangling link does not "exist", but it is
         --  still there to be removed.
         Remove_Link (Path);
         return;
      end if;

      if not Ada.Directories.Exists (Path) then
         return;
      end if;

      if Ada.Directories.Kind (Path) /= Ada.Directories.Directory then
         Ada.Directories.Delete_File (Path);
         return;
      end if;

      declare
         Search : Ada.Directories.Search_Type;
         Item   : Ada.Directories.Directory_Entry_Type;
      begin
         Ada.Directories.Start_Search
           (Search, Path, "",
            [Ada.Directories.Directory => True,
             Ada.Directories.Ordinary_File => True,
             Ada.Directories.Special_File => True]);

         while Ada.Directories.More_Entries (Search) loop
            Ada.Directories.Get_Next_Entry (Search, Item);

            declare
               Name : constant String := Ada.Directories.Simple_Name (Item);
            begin
               if Name /= "." and then Name /= ".." then
                  Delete_Tree (Ada.Directories.Full_Name (Item));
               end if;
            end;
         end loop;

         Ada.Directories.End_Search (Search);
      end;

      Ada.Directories.Delete_Directory (Path);
   end Delete_Tree;

   procedure Delete_File_If_Present (Path : String) is
   begin
      if Ada.Directories.Exists (Path)
        and then Ada.Directories.Kind (Path) = Ada.Directories.Ordinary_File
      then
         Ada.Directories.Delete_File (Path);
      end if;
   end Delete_File_If_Present;

   procedure Write_Text_File (Path : String; Content : String) is
      File : Ada.Text_IO.File_Type;
   begin
      Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put (File, Content);
      Ada.Text_IO.Close (File);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Write_Text_File;

   procedure Write_Raw_File (Path : String; Content : String) is
      use Ada.Streams;

      File : Ada.Streams.Stream_IO.File_Type;
   begin
      Ada.Streams.Stream_IO.Create (File, Ada.Streams.Stream_IO.Out_File, Path);
      if Content'Length > 0 then
         declare
            Data      : Stream_Element_Array
              (1 .. Stream_Element_Offset (Content'Length));
            Out_Index : Stream_Element_Offset := Data'First;
         begin
            for Item of Content loop
               Data (Out_Index) := Stream_Element (Character'Pos (Item));
               Out_Index := Out_Index + 1;
            end loop;
            Ada.Streams.Stream_IO.Write (File, Data);
         end;
      end if;
      Ada.Streams.Stream_IO.Close (File);
   exception
      when others =>
         if Ada.Streams.Stream_IO.Is_Open (File) then
            Ada.Streams.Stream_IO.Close (File);
         end if;
         raise;
   end Write_Raw_File;

   procedure Append_Text_File (Path : String; Content : String) is
      File : Ada.Text_IO.File_Type;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.Append_File, Path);
      Ada.Text_IO.Put (File, Content);
      Ada.Text_IO.Close (File);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Append_Text_File;

   function Join (Left : String; Right : String) return String is
   begin
      if Left'Length = 0 then
         return Right;
      elsif Left (Left'Last) = '/' then
         return Left & Right;
      else
         return Left & "/" & Right;
      end if;
   end Join;

   function Has_Line (Path : String; Line : String) return Boolean is
      File : Ada.Text_IO.File_Type;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         if Ada.Text_IO.Get_Line (File) = Line then
            Ada.Text_IO.Close (File);
            return True;
         end if;
      end loop;
      Ada.Text_IO.Close (File);
      return False;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return False;
   end Has_Line;

   function Value_Of (Path : String; Key : String) return String is
      File   : Ada.Text_IO.File_Type;
      Prefix : constant String := Key & "=";
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Line : constant String := Ada.Text_IO.Get_Line (File);
         begin
            if Line'Length >= Prefix'Length
              and then Line (Line'First .. Line'First + Prefix'Length - 1) = Prefix
            then
               Ada.Text_IO.Close (File);
               return Line (Line'First + Prefix'Length .. Line'Last);
            end if;
         end;
      end loop;
      Ada.Text_IO.Close (File);
      return "";
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return "";
   end Value_Of;

   function Find_File (Directory : String; Name : String) return String is
      use Ada.Strings.Unbounded;
      Found : Unbounded_String;

      procedure Consider (Path : String) is
      begin
         if Length (Found) = 0 or else Path < To_String (Found) then
            Found := To_Unbounded_String (Path);
         end if;
      end Consider;

      procedure Search (Dir : String) is
         Search_Obj : Ada.Directories.Search_Type;
      begin
         Ada.Directories.Start_Search
           (Search_Obj, Dir, "",
            [Ada.Directories.Ordinary_File => True,
             Ada.Directories.Directory     => True,
             others                        => False]);
         while Ada.Directories.More_Entries (Search_Obj) loop
            declare
               Item : Ada.Directories.Directory_Entry_Type;
            begin
               Ada.Directories.Get_Next_Entry (Search_Obj, Item);
               declare
                  Simple : constant String := Ada.Directories.Simple_Name (Item);
                  Full   : constant String := Join (Dir, Simple);
               begin
                  if Simple /= "." and then Simple /= ".." then
                     case Ada.Directories.Kind (Item) is
                        when Ada.Directories.Ordinary_File =>
                           if Simple = Name then
                              Consider (Full);
                           end if;
                        when Ada.Directories.Directory =>
                           Search (Full);
                        when others =>
                           null;
                     end case;
                  end if;
               end;
            end;
         end loop;
         Ada.Directories.End_Search (Search_Obj);
      exception
         when others =>
            if Ada.Directories.More_Entries (Search_Obj) then
               Ada.Directories.End_Search (Search_Obj);
            end if;
            raise;
      end Search;
   begin
      Search (Directory);
      return To_String (Found);
   end Find_File;

   function Find_Root_Upward
     (Start_Directory : String;
      Marker_File     : String) return String
   is
      Current : Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String
          (Ada.Directories.Full_Name (Start_Directory));
   begin
      loop
         declare
            Here : constant String := Ada.Strings.Unbounded.To_String (Current);
         begin
            if File_Exists (Join (Here, Marker_File)) then
               return Here;
            end if;

            declare
               Parent : constant String :=
                 Ada.Directories.Containing_Directory (Here);
            begin
               exit when Parent = Here or else Parent'Length = 0;
               Current := Ada.Strings.Unbounded.To_Unbounded_String (Parent);
            end;
         end;
      end loop;

      return "";
   exception
      when others =>
         return "";
   end Find_Root_Upward;

   package Path_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Ada.Strings.Unbounded.Unbounded_String,
      "="          => Ada.Strings.Unbounded."=");

   function List_Tree
     (Root         : String;
      Name_Pattern : String := "*";
      Skip_Entries : Name_List := (1 .. 0 => <>))
      return Path_List
   is
      Matcher   : constant GNAT.Regexp.Regexp :=
        GNAT.Regexp.Compile (Name_Pattern, Glob => True);
      Collected : Path_Vectors.Vector;

      procedure Walk (Directory : String) is
         Search : Ada.Directories.Search_Type;
         Item   : Ada.Directories.Directory_Entry_Type;
      begin
         if not Ada.Directories.Exists (Directory) then
            return;
         end if;
         Ada.Directories.Start_Search (Search, Directory, "");
         while Ada.Directories.More_Entries (Search) loop
            Ada.Directories.Get_Next_Entry (Search, Item);
            declare
               Name : constant String := Ada.Directories.Simple_Name (Item);
               Path : constant String := Directory & "/" & Name;
               Kind : constant Ada.Directories.File_Kind :=
                 Ada.Directories.Kind (Item);
            begin
               if Name = "." or else Name = ".."
                 or else Contains_Name (Skip_Entries, Name)
               then
                  null;
               elsif Kind = Ada.Directories.Directory then
                  Walk (Path);
               elsif Kind = Ada.Directories.Ordinary_File
                 and then GNAT.Regexp.Match (Name, Matcher)
               then
                  Collected.Append
                    (Ada.Strings.Unbounded.To_Unbounded_String (Path));
               end if;
            end;
         end loop;
         Ada.Directories.End_Search (Search);
      end Walk;
   begin
      Walk (Root);
      return Result : Path_List (1 .. Natural (Collected.Length)) do
         for Index in Result'Range loop
            Result (Index) := Collected (Index);
         end loop;
      end return;
   end List_Tree;
end Project_Tools.Files;
