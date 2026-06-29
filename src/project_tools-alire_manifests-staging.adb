with Ada.Directories;

with Project_Tools.Files;

package body Project_Tools.Alire_Manifests.Staging is
   procedure Copy_Release_Manifest
     (Template : String;
      Target   : String;
      Quiet    : Boolean := False) is
   begin
      Ada.Directories.Copy_File
        (Source_Name => Template,
         Target_Name => Target,
         Form        => "mode=overwrite");
   exception
      when others =>
         Project_Tools.Files.Require_File
           (Template,
            "failed to write release manifest",
            Quiet);
         Project_Tools.Files.Require_Contains
           (Template,
            "__project_tools_copy_release_manifest_failure_marker__",
            "failed to write release manifest",
            Quiet);
   end Copy_Release_Manifest;

   procedure Write_Build_Manifest_Overlay
     (Template : String;
      Target   : String;
      Pins     : String;
      Quiet    : Boolean := False) is
   begin
      Copy_Release_Manifest (Template, Target, Quiet);
      Project_Tools.Files.Append_Text_File (Target, ASCII.LF & Pins);
   end Write_Build_Manifest_Overlay;

   procedure Activate_Build_Manifest
     (Crate_Dir : String;
      Quiet     : Boolean := False) is
      Publish_Manifest : constant String := Crate_Dir & "/alire.toml";
      Build_Manifest   : constant String := Crate_Dir & "/alire.build.toml";
      Saved_Manifest   : constant String := Crate_Dir & "/alire.publish.toml";
   begin
      Project_Tools.Files.Require_File
        (Build_Manifest, "staged release build missing build-only manifest overlay", Quiet);
      Ada.Directories.Copy_File (Publish_Manifest, Saved_Manifest, "mode=overwrite");
      Ada.Directories.Copy_File (Build_Manifest, Publish_Manifest, "mode=overwrite");
   end Activate_Build_Manifest;

   procedure Restore_Publish_Manifest
     (Crate_Dir : String) is
      Publish_Manifest : constant String := Crate_Dir & "/alire.toml";
      Saved_Manifest   : constant String := Crate_Dir & "/alire.publish.toml";
   begin
      if Ada.Directories.Exists (Saved_Manifest) then
         Ada.Directories.Copy_File (Saved_Manifest, Publish_Manifest, "mode=overwrite");
         Ada.Directories.Delete_File (Saved_Manifest);
      end if;
   end Restore_Publish_Manifest;

   procedure Copy_Dependency_Manifest
     (Source_Dir : String;
      Target_Dir : String;
      Quiet      : Boolean := False) is
   begin
      Ada.Directories.Copy_File
        (Source_Name => Source_Dir & "/alire.toml",
         Target_Name => Target_Dir & "/alire.toml",
         Form        => "mode=overwrite");
   exception
      when others =>
         Project_Tools.Files.Require_File
           (Source_Dir & "/alire.toml",
            "failed to copy dependency manifest into " & Target_Dir,
            Quiet);
         Project_Tools.Files.Require_Contains
           (Source_Dir & "/alire.toml",
            "__project_tools_copy_manifest_failure_marker__",
            "failed to copy dependency manifest into " & Target_Dir,
            Quiet);
   end Copy_Dependency_Manifest;
end Project_Tools.Alire_Manifests.Staging;
