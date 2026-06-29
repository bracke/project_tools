with Ada.Strings.Unbounded;

with Project_Tools.Files;

package body Project_Tools.Alire_Manifests.Validation is
   procedure Require_Workspace_Pin
     (Manifest      : String;
      Crate         : String;
      Relative_Path : String;
      Quiet         : Boolean := False) is
   begin
      Project_Tools.Files.Require_Contains
        (Manifest,
         "[[pins]]",
         "development manifest must keep intentional local pin sections",
         Quiet);
      Project_Tools.Files.Require_Contains
        (Manifest,
         Crate & " = { path",
         "development manifest missing intentional local pin for " & Crate,
         Quiet);
      Project_Tools.Files.Require_Contains
        (Manifest,
         Relative_Path,
         "development manifest local pin for " & Crate & " must use the documented sibling path",
         Quiet);
   end Require_Workspace_Pin;

   procedure Require_No_Local_Pins
     (Manifest : String;
      Quiet    : Boolean := False) is
   begin
      Project_Tools.Files.Require_File (Manifest, "release manifest template missing", Quiet);
      if Project_Tools.Files.File_Contains (Manifest, "[[pins]]")
        or else Project_Tools.Files.File_Contains (Manifest, "path =")
        or else Project_Tools.Files.File_Contains (Manifest, "path=")
        or else Project_Tools.Files.File_Contains (Manifest, "path='")
      then
         Project_Tools.Files.Require_Contains
           (Manifest,
            "__project_tools_no_local_pins_marker__",
            "release manifest template must not contain local pins",
            Quiet);
      end if;
   end Require_No_Local_Pins;

   procedure Require_Release_Dependency
     (Manifest : String;
      Crate    : String;
      Quiet    : Boolean := False) is
   begin
      Project_Tools.Files.Require_Contains
        (Manifest,
         Crate & " = ""*""",
         "release manifest template missing dependency on " & Crate,
         Quiet);
   end Require_Release_Dependency;

   procedure Require_Release_Dependencies
     (Manifest     : String;
      Dependencies : Project_Tools.Alire_Manifests.String_List;
      Quiet        : Boolean := False) is
   begin
      for Dependency of Dependencies loop
         Require_Release_Dependency
           (Manifest, Ada.Strings.Unbounded.To_String (Dependency), Quiet);
      end loop;
   end Require_Release_Dependencies;

   procedure Require_Pin_Free_Crate_Manifest
     (Manifest : String;
      Name     : String;
      Quiet    : Boolean := False) is
   begin
      Require_No_Local_Pins (Manifest, Quiet);
      Project_Tools.Files.Require_Contains
        (Manifest,
         "name = """ & Name & """",
         "manifest has wrong crate name",
         Quiet);
   end Require_Pin_Free_Crate_Manifest;

   procedure Require_Staged_Crate_Source
     (Crate_Dir : String;
      Name      : String;
      GPR_File  : String;
      Quiet     : Boolean := False)
   is
      Manifest : constant String := Crate_Dir & "/alire.toml";
   begin
      Require_Pin_Free_Crate_Manifest (Manifest, Name, Quiet);
      Project_Tools.Files.Require_File
        (Crate_Dir & "/" & GPR_File, "staged release source missing project file", Quiet);
      Project_Tools.Files.Require_Directory
        (Crate_Dir & "/src", "staged release source missing src directory", Quiet);
      Project_Tools.Files.Require_File
        (Crate_Dir & "/README.md", "staged release source missing README.md", Quiet);
      Project_Tools.Files.Require_File
        (Crate_Dir & "/LICENSE", "staged release source missing LICENSE", Quiet);
   end Require_Staged_Crate_Source;

   procedure Require_Build_Overlay
     (Overlay      : String;
      Template     : String;
      Dependencies : Project_Tools.Alire_Manifests.String_List;
      Quiet        : Boolean := False) is
   begin
      Project_Tools.Files.Require_File_Starts_With_File
        (Overlay,
         Template,
         "staged release build overlay must preserve release template prefix",
         Quiet);
      Project_Tools.Files.Require_Contains
        (Overlay,
         "[[pins]]",
         "staged release build overlay missing local pin section",
         Quiet);
      for Dependency of Dependencies loop
         Project_Tools.Files.Require_Contains
           (Overlay,
            Ada.Strings.Unbounded.To_String (Dependency),
            "staged release build overlay missing expected local pin",
            Quiet);
      end loop;
   end Require_Build_Overlay;
end Project_Tools.Alire_Manifests.Validation;
