with Ada.Command_Line;
with Ada.Directories;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Project_Tools.Files;
with Project_Tools.Text;
with Project_Tools.TOML;

package body Project_Tools.Source_Budgets is
   use type Ada.Directories.File_Size;

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

   function Line_Count (Text : String) return Natural is
      Count : Natural := 0;
   begin
      for Ch of Text loop
         if Ch = ASCII.LF then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Line_Count;

   function Count_Files_With_Prefix
     (Root   : String;
      Prefix : String)
      return Natural
   is
      Slash : Natural := 0;
   begin
      for Index in reverse Prefix'Range loop
         if Prefix (Index) = '/' then
            Slash := Index;
            exit;
         end if;
      end loop;

      if Slash = 0 then
         return 0;
      end if;

      declare
         Dir       : constant String :=
           Root & "/" & Prefix (Prefix'First .. Slash - 1);
         Stem      : constant String := Prefix (Slash + 1 .. Prefix'Last);
         Search    : Ada.Directories.Search_Type;
         Dir_Entry : Ada.Directories.Directory_Entry_Type;
         Count     : Natural := 0;
      begin
         Ada.Directories.Start_Search
           (Search,
            Directory => Dir,
            Pattern   => Stem & "*.adb",
            Filter    => [Ada.Directories.Ordinary_File => True,
                          others => False]);
         while Ada.Directories.More_Entries (Search) loop
            Ada.Directories.Get_Next_Entry (Search, Dir_Entry);
            declare
               Name : constant String := Ada.Directories.Simple_Name (Dir_Entry);
            begin
               if Project_Tools.Text.Starts_With (Name, Stem)
                 and then Project_Tools.Text.Ends_With (Name, ".adb")
               then
                  Count := Count + 1;
               end if;
            end;
         end loop;
         Ada.Directories.End_Search (Search);
         return Count;
      exception
         when Ada.Directories.Name_Error | Ada.Directories.Use_Error =>
            if Ada.Directories.More_Entries (Search) then
               Ada.Directories.End_Search (Search);
            end if;
            return 0;
      end;
   end Count_Files_With_Prefix;

   procedure Check_Line_Byte_Budget
     (Errors             : in out Natural;
      Root               : String;
      Relative_Path      : String;
      Label              : String;
      Target_Lines       : Natural;
      Max_Lines          : Natural;
      Min_Headroom_Lines : Natural;
      Max_Bytes          : Natural;
      Quiet              : Boolean := False)
   is
      Full_Path : constant String := Root & "/" & Relative_Path;
   begin
      if Relative_Path = "" or else Target_Lines = 0 or else Max_Lines = 0
        or else Min_Headroom_Lines = 0 or else Max_Bytes = 0
      then
         Error (Errors, Label & " budget entry is incomplete", Quiet);
      elsif Target_Lines > Max_Lines then
         Error
           (Errors, Label & " target_lines exceeds max_lines for " & Relative_Path,
            Quiet);
      elsif Max_Lines - Target_Lines < Min_Headroom_Lines then
         Error
           (Errors, Label & " target_lines is too close to max_lines for "
            & Relative_Path, Quiet);
      elsif not Project_Tools.Files.File_Exists (Full_Path) then
         Error (Errors, "missing required file: " & Relative_Path, Quiet);
      else
         declare
            Source_Text : constant String :=
              Ada.Strings.Unbounded.To_String
                (Project_Tools.Text.Read_Text_File (Full_Path));
            Lines       : constant Natural := Line_Count (Source_Text);
         begin
            if Lines > Max_Lines then
               Error
                 (Errors, Label & " hard line budget exceeded for "
                  & Relative_Path, Quiet);
            elsif Lines > Target_Lines then
               Error
                 (Errors, Label & " line ratchet exceeded for " & Relative_Path,
                  Quiet);
            end if;

            if Ada.Directories.Size (Full_Path)
              > Ada.Directories.File_Size (Max_Bytes)
            then
               Error
                 (Errors, Label & " byte budget exceeded for " & Relative_Path,
                  Quiet);
            end if;
         end;
      end if;
   end Check_Line_Byte_Budget;

   procedure Check_Structural_Baseline
     (Errors          : in out Natural;
      Root            : String;
      Manifest_Path   : String;
      Minimum_Entries : Natural;
      Purpose         : String := "structural baseline";
      Section         : String := "body";
      Quiet           : Boolean := False)
   is
      Manifest : constant String :=
        Ada.Strings.Unbounded.To_String
          (Project_Tools.Text.Read_Text_File (Root & "/" & Manifest_Path));
      Count    : Natural := 0;

      procedure Check_Entry (Entry_Pos : Positive) is
         Path : constant String :=
           Project_Tools.TOML.String_Value_After
             (Manifest, "path = ", Entry_Pos);
         Prefix : constant String :=
           Project_Tools.TOML.String_Value_After
             (Manifest, "split_prefix = ", Entry_Pos);
         Target_Lines : constant Natural :=
           Project_Tools.TOML.Natural_Value_After
             (Manifest, "target_lines = ", Entry_Pos);
         Max_Lines : constant Natural :=
           Project_Tools.TOML.Natural_Value_After
             (Manifest, "max_lines = ", Entry_Pos);
         Min_Headroom_Lines : constant Natural :=
           Project_Tools.TOML.Natural_Value_After
             (Manifest, "min_headroom_lines = ", Entry_Pos);
         Max_Bytes : constant Natural :=
           Project_Tools.TOML.Natural_Value_After
             (Manifest, "max_bytes = ", Entry_Pos);
         Min_Splits : constant Natural :=
           Project_Tools.TOML.Natural_Value_After
             (Manifest, "min_split_bodies = ", Entry_Pos);
         Usecase : constant String :=
           Project_Tools.TOML.String_Value_After
             (Manifest, "usecase = ", Entry_Pos);
      begin
         if Usecase = "" or else (Min_Splits > 0 and then Prefix = "") then
            Error (Errors, Purpose & " entry is incomplete", Quiet);
         else
            Check_Line_Byte_Budget
              (Errors, Root, Path, Purpose, Target_Lines, Max_Lines,
               Min_Headroom_Lines, Max_Bytes, Quiet);

            if Min_Splits > 0
              and then Count_Files_With_Prefix (Root, Prefix) < Min_Splits
            then
               Error
                 (Errors, Purpose & " split inventory too small for " & Path,
                  Quiet);
            end if;

            Count := Count + 1;
         end if;
      end Check_Entry;

      procedure Check_Entries is new Project_Tools.TOML.Iterate_Section
        (Check_Entry);
   begin
      Check_Entries (Manifest, Section);

      if Count < Minimum_Entries then
         Error
           (Errors, Purpose & " manifest covers too few entries", Quiet);
      end if;
   end Check_Structural_Baseline;
end Project_Tools.Source_Budgets;
