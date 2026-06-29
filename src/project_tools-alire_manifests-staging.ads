package Project_Tools.Alire_Manifests.Staging is
   procedure Write_Build_Manifest_Overlay
     (Template : String;
      Target   : String;
      Pins     : String;
      Quiet    : Boolean := False);
   --  Copy a release manifest template to a build overlay and append local pin text.
   --  @param Template Source release manifest template file.
   --  @param Target Target build overlay manifest file path.
   --  @param Pins Local pin TOML text to append after the template.
   --  @param Quiet Suppress diagnostics when True.

   procedure Copy_Release_Manifest
     (Template : String;
      Target   : String;
      Quiet    : Boolean := False);
   --  Copy a release manifest template to Target, overwriting an existing file.
   --  @param Template Source release manifest template file.
   --  @param Target Target manifest file path.
   --  @param Quiet Suppress diagnostics when True.

   procedure Activate_Build_Manifest
     (Crate_Dir : String;
      Quiet     : Boolean := False);
   --  Save alire.toml as alire.publish.toml and activate alire.build.toml.
   --  @param Crate_Dir Crate directory containing alire.toml and alire.build.toml.
   --  @param Quiet Suppress diagnostics when True.

   procedure Restore_Publish_Manifest
     (Crate_Dir : String);
   --  Restore alire.publish.toml to alire.toml when a saved publish manifest exists.
   --  @param Crate_Dir Crate directory to restore.

   procedure Copy_Dependency_Manifest
     (Source_Dir : String;
      Target_Dir : String;
      Quiet      : Boolean := False);
   --  Copy alire.toml from Source_Dir to Target_Dir, overwriting an existing target.
   --  @param Source_Dir Directory containing the source alire.toml.
   --  @param Target_Dir Directory that receives alire.toml.
   --  @param Quiet Suppress diagnostics when True.
end Project_Tools.Alire_Manifests.Staging;
