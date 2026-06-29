with Project_Tools.Alire_Manifests.Staging;
with Project_Tools.Alire_Manifests.Validation;

package body Project_Tools.Alire_Manifests is
   procedure Require_Workspace_Pin
     (Manifest      : String;
      Crate         : String;
      Relative_Path : String;
      Quiet         : Boolean := False) is
   begin
      Project_Tools.Alire_Manifests.Validation.Require_Workspace_Pin (Manifest, Crate, Relative_Path, Quiet);
   end Require_Workspace_Pin;

   procedure Require_No_Local_Pins
     (Manifest : String;
      Quiet    : Boolean := False) is
   begin
      Project_Tools.Alire_Manifests.Validation.Require_No_Local_Pins (Manifest, Quiet);
   end Require_No_Local_Pins;

   procedure Require_Release_Dependency
     (Manifest : String;
      Crate    : String;
      Quiet    : Boolean := False) is
   begin
      Project_Tools.Alire_Manifests.Validation.Require_Release_Dependency (Manifest, Crate, Quiet);
   end Require_Release_Dependency;

   procedure Require_Release_Dependencies
     (Manifest     : String;
      Dependencies : String_List;
      Quiet        : Boolean := False) is
   begin
      Project_Tools.Alire_Manifests.Validation.Require_Release_Dependencies (Manifest, Dependencies, Quiet);
   end Require_Release_Dependencies;

   procedure Require_Pin_Free_Crate_Manifest
     (Manifest : String;
      Name     : String;
      Quiet    : Boolean := False) is
   begin
      Project_Tools.Alire_Manifests.Validation.Require_Pin_Free_Crate_Manifest (Manifest, Name, Quiet);
   end Require_Pin_Free_Crate_Manifest;

   procedure Require_Staged_Crate_Source
     (Crate_Dir : String;
      Name      : String;
      GPR_File  : String;
      Quiet     : Boolean := False) is
   begin
      Project_Tools.Alire_Manifests.Validation.Require_Staged_Crate_Source (Crate_Dir, Name, GPR_File, Quiet);
   end Require_Staged_Crate_Source;

   procedure Require_Build_Overlay
     (Overlay      : String;
      Template     : String;
      Dependencies : String_List;
      Quiet        : Boolean := False) is
   begin
      Project_Tools.Alire_Manifests.Validation.Require_Build_Overlay (Overlay, Template, Dependencies, Quiet);
   end Require_Build_Overlay;

   procedure Write_Build_Manifest_Overlay
     (Template : String;
      Target   : String;
      Pins     : String;
      Quiet    : Boolean := False) is
   begin
      Project_Tools.Alire_Manifests.Staging.Write_Build_Manifest_Overlay (Template, Target, Pins, Quiet);
   end Write_Build_Manifest_Overlay;

   procedure Copy_Release_Manifest
     (Template : String;
      Target   : String;
      Quiet    : Boolean := False) is
   begin
      Project_Tools.Alire_Manifests.Staging.Copy_Release_Manifest (Template, Target, Quiet);
   end Copy_Release_Manifest;

   procedure Activate_Build_Manifest
     (Crate_Dir : String;
      Quiet     : Boolean := False) is
   begin
      Project_Tools.Alire_Manifests.Staging.Activate_Build_Manifest (Crate_Dir, Quiet);
   end Activate_Build_Manifest;

   procedure Restore_Publish_Manifest
     (Crate_Dir : String) is
   begin
      Project_Tools.Alire_Manifests.Staging.Restore_Publish_Manifest (Crate_Dir);
   end Restore_Publish_Manifest;

   procedure Copy_Dependency_Manifest
     (Source_Dir : String;
      Target_Dir : String;
      Quiet      : Boolean := False) is
   begin
      Project_Tools.Alire_Manifests.Staging.Copy_Dependency_Manifest (Source_Dir, Target_Dir, Quiet);
   end Copy_Dependency_Manifest;
end Project_Tools.Alire_Manifests;
