with Ada.Command_Line;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Project_Tools.Files;
with Project_Tools.Text;
with Project_Tools.TOML;

package body Project_Tools.Generated_Artifacts is
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

   procedure Check_Data_Manifest
     (Errors          : in out Natural;
      Root            : String;
      Manifest_Path   : String;
      Expected_Count  : Natural;
      Hash            : Hash_Function;
      Allowed_Kinds   : String_List := [];
      Max_Shard_Lines : Natural := 0;
      Quiet           : Boolean := False)
   is
      Manifest : constant String := Read_File (Root & "/" & Manifest_Path);
      Count    : Natural := 0;

      function Is_Allowed_Kind (Kind : String) return Boolean is
      begin
         if Allowed_Kinds'Length = 0 then
            return True;
         end if;

         for Allowed of Allowed_Kinds loop
            if Allowed /= null and then Kind = Allowed.all then
               return True;
            end if;
         end loop;

         return False;
      end Is_Allowed_Kind;

      function Is_Shard_Kind (Kind : String) return Boolean is
         Suffix : constant String := "-shard";
      begin
         return Kind'Length > Suffix'Length
           and then Kind (Kind'Last - Suffix'Length + 1 .. Kind'Last) =
             Suffix;
      end Is_Shard_Kind;

      function Parent_Kind (Kind : String) return String is
         Suffix : constant String := "-shard";
      begin
         if Is_Shard_Kind (Kind) then
            return Kind (Kind'First .. Kind'Last - Suffix'Length);
         else
            return Kind;
         end if;
      end Parent_Kind;

      function Has_Shared_Metadata_Parent
        (Kind   : String;
         Owner  : String;
         Source : String;
         Marker : String)
         return Boolean
      is
         Parent : constant String := Parent_Kind (Kind);
         Found  : Boolean := False;

         procedure Check_Parent (Entry_Pos : Positive) is
            Entry_Kind : constant String :=
              Project_Tools.TOML.String_Value_After
                (Manifest, "kind = ", Entry_Pos);
            Entry_Owner : constant String :=
              Project_Tools.TOML.String_Value_After
                (Manifest, "owner = ", Entry_Pos);
            Entry_Source : constant String :=
              Project_Tools.TOML.String_Value_After
                (Manifest, "source = ", Entry_Pos);
            Entry_Marker : constant String :=
              Project_Tools.TOML.String_Value_After
                (Manifest, "marker = ", Entry_Pos);
         begin
            if Entry_Kind = Parent
              and then Entry_Owner = Owner
              and then Entry_Source = Source
              and then Entry_Marker = Marker
            then
               Found := True;
            end if;
         end Check_Parent;

         procedure Check_Parents is new Project_Tools.TOML.Iterate_Section
           (Check_Parent);
      begin
         Check_Parents (Manifest, "artifact");
         return Found;
      end Has_Shared_Metadata_Parent;

      procedure Check_Entry (Entry_Pos : Positive) is
         Path : constant String :=
           Project_Tools.TOML.String_Value_After
             (Manifest, "path = ", Entry_Pos);
         Kind : constant String :=
           Project_Tools.TOML.String_Value_After
             (Manifest, "kind = ", Entry_Pos);
         Owner : constant String :=
           Project_Tools.TOML.String_Value_After
             (Manifest, "owner = ", Entry_Pos);
         Source : constant String :=
           Project_Tools.TOML.String_Value_After
             (Manifest, "source = ", Entry_Pos);
         Currentness : constant String :=
           Project_Tools.TOML.String_Value_After
             (Manifest, "currentness = ", Entry_Pos);
         Coverage : constant String :=
           Project_Tools.TOML.String_Value_After
             (Manifest, "coverage = ", Entry_Pos);
         Marker : constant String :=
           Project_Tools.TOML.String_Value_After
             (Manifest, "marker = ", Entry_Pos);
         Expected_Lines : constant Natural :=
           Project_Tools.TOML.Natural_Value_After
             (Manifest, "line_count = ", Entry_Pos);
         SHA256 : constant String :=
           Project_Tools.TOML.String_Value_After
             (Manifest, "sha256 = ", Entry_Pos);
      begin
         if Path = "" or else Kind = "" or else Owner = "" or else Source = ""
           or else Currentness = "" or else Coverage = "" or else Marker = ""
           or else Expected_Lines = 0 or else SHA256 = ""
         then
            Error (Errors, "generated-data manifest entry is incomplete", Quiet);
         elsif not Is_Allowed_Kind (Kind) then
            Error
              (Errors, "generated-data manifest kind is not allowed: " & Kind,
               Quiet);
         elsif Max_Shard_Lines > 0
           and then Is_Shard_Kind (Kind)
           and then Expected_Lines > Max_Shard_Lines
         then
            Error
              (Errors,
               "generated-data shard line budget exceeded for " & Path,
               Quiet);
         elsif Max_Shard_Lines > 0
           and then Is_Shard_Kind (Kind)
           and then not Has_Shared_Metadata_Parent
             (Kind, Owner, Source, Marker)
         then
            Error
              (Errors,
               "generated-data shard lacks matching parent artifact for "
               & Path,
               Quiet);
         elsif not Project_Tools.Files.File_Exists (Root & "/" & Path) then
            Error (Errors, "missing required file: " & Path, Quiet);
         else
            declare
               Source_Text : constant String := Read_File (Root & "/" & Path);
            begin
               if not Project_Tools.Text.Contains (Source_Text, Marker) then
                  Error
                    (Errors, "generated-data marker missing from " & Path,
                     Quiet);
               end if;
               if Line_Count (Source_Text) /= Expected_Lines then
                  Error
                    (Errors, "generated-data line count changed for " & Path,
                     Quiet);
               end if;
               if Hash (Source_Text) /= SHA256 then
                  Error
                    (Errors,
                     "generated-data SHA-256 snapshot changed for " & Path,
                     Quiet);
               end if;
            end;
            Count := Count + 1;
         end if;
      end Check_Entry;

      procedure Check_Entries is new Project_Tools.TOML.Iterate_Section
        (Check_Entry);
   begin
      Check_Entries (Manifest, "artifact");

      if Count /= Expected_Count then
         Error
           (Errors, "generated-data manifest artifact count is wrong", Quiet);
      end if;
   end Check_Data_Manifest;

   procedure Print_Data_Manifest
     (Root          : String;
      Manifest_Path : String;
      Header        : String;
      Hash          : Hash_Function)
   is
      Manifest : constant String := Read_File (Root & "/" & Manifest_Path);
      First    : Boolean := True;

      procedure Print_Entry (Entry_Pos : Positive) is
         Path : constant String :=
           Project_Tools.TOML.String_Value_After
             (Manifest, "path = ", Entry_Pos);
         Kind : constant String :=
           Project_Tools.TOML.String_Value_After
             (Manifest, "kind = ", Entry_Pos);
         Owner : constant String :=
           Project_Tools.TOML.String_Value_After
             (Manifest, "owner = ", Entry_Pos);
         Source : constant String :=
           Project_Tools.TOML.String_Value_After
             (Manifest, "source = ", Entry_Pos);
         Currentness : constant String :=
           Project_Tools.TOML.String_Value_After
             (Manifest, "currentness = ", Entry_Pos);
         Coverage : constant String :=
           Project_Tools.TOML.String_Value_After
             (Manifest, "coverage = ", Entry_Pos);
         Marker : constant String :=
           Project_Tools.TOML.String_Value_After
             (Manifest, "marker = ", Entry_Pos);
      begin
         if Path /= "" then
            declare
               Source_Text : constant String := Read_File (Root & "/" & Path);
            begin
               if First then
                  First := False;
               else
                  Ada.Text_IO.New_Line;
               end if;

               Ada.Text_IO.Put_Line ("[[artifact]]");
               Ada.Text_IO.Put_Line ("path = """ & Path & """");
               Ada.Text_IO.Put_Line ("kind = """ & Kind & """");
               Ada.Text_IO.Put_Line ("owner = """ & Owner & """");
               Ada.Text_IO.Put_Line ("source = """ & Source & """");
               Ada.Text_IO.Put_Line ("coverage = """ & Coverage & """");
               Ada.Text_IO.Put_Line ("currentness = """ & Currentness & """");
               Ada.Text_IO.Put_Line ("marker = """ & Marker & """");
               declare
                  Lines_Image : constant String :=
                    Natural'Image (Line_Count (Source_Text));
               begin
                  Ada.Text_IO.Put_Line
                    ("line_count = "
                     & Lines_Image (Lines_Image'First + 1 .. Lines_Image'Last));
               end;
               Ada.Text_IO.Put_Line
                 ("sha256 = """ & Hash (Source_Text) & """");
            end;
         end if;
      end Print_Entry;

      procedure Print_Entries is new Project_Tools.TOML.Iterate_Section
        (Print_Entry);
   begin
      if Header /= "" then
         Ada.Text_IO.Put (Header);
         if Header (Header'Last) /= ASCII.LF then
            Ada.Text_IO.New_Line;
         end if;
         Ada.Text_IO.New_Line;
      end if;

      Print_Entries (Manifest, "artifact");
   end Print_Data_Manifest;
end Project_Tools.Generated_Artifacts;
