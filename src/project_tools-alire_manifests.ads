with Ada.Strings.Unbounded;

package Project_Tools.Alire_Manifests is
   subtype Unbounded_String is Ada.Strings.Unbounded.Unbounded_String;
   type String_List is array (Positive range <>) of Unbounded_String;

   procedure Require_Workspace_Pin
     (Manifest      : String;
      Crate         : String;
      Relative_Path : String;
      Quiet         : Boolean := False);
   --  Require an Alire development manifest to pin a crate to a local workspace path.
   --  @param Manifest Manifest file path to inspect.
   --  @param Crate Crate name that must be pinned.
   --  @param Relative_Path Expected local pin path.
   --  @param Quiet Suppress diagnostics when True.

   procedure Require_No_Local_Pins
     (Manifest : String;
      Quiet    : Boolean := False);
   --  Require an Alire release manifest to contain no local path pins.
   --  @param Manifest Manifest file path to inspect.
   --  @param Quiet Suppress diagnostics when True.

   procedure Require_Release_Dependency
     (Manifest : String;
      Crate    : String;
      Quiet    : Boolean := False);
   --  Require an Alire release manifest to depend on Crate using a wildcard version.
   --  @param Manifest Manifest file path to inspect.
   --  @param Crate Dependency crate name that must be present.
   --  @param Quiet Suppress diagnostics when True.

   procedure Require_Release_Dependencies
     (Manifest     : String;
      Dependencies : String_List;
      Quiet        : Boolean := False);
   --  Require an Alire release manifest to depend on each crate in Dependencies.
   --  @param Manifest Manifest file path to inspect.
   --  @param Dependencies Dependency crate names that must be present.
   --  @param Quiet Suppress diagnostics when True.

   procedure Require_Pin_Free_Crate_Manifest
     (Manifest : String;
      Name     : String;
      Quiet    : Boolean := False);
   --  Require an Alire crate manifest to name a crate and contain no local path pins.
   --  @param Manifest Manifest file path to inspect.
   --  @param Name Expected crate name.
   --  @param Quiet Suppress diagnostics when True.

   procedure Require_Staged_Crate_Source
     (Crate_Dir : String;
      Name      : String;
      GPR_File  : String;
      Quiet     : Boolean := False);
   --  Require a staged release crate to have pin-free manifest and standard source files.
   --  @param Crate_Dir Staged crate directory to inspect.
   --  @param Name Expected Alire crate name.
   --  @param GPR_File Expected project file name.
   --  @param Quiet Suppress diagnostics when True.

   procedure Require_Build_Overlay
     (Overlay       : String;
      Template      : String;
      Dependencies  : String_List;
      Quiet         : Boolean := False);
   --  Require a build overlay to preserve a release template prefix and contain dependency pins.
   --  @param Overlay Build overlay file path to inspect.
   --  @param Template Release template file whose content must prefix Overlay.
   --  @param Dependencies Required local pin fragments.
   --  @param Quiet Suppress diagnostics when True.

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
end Project_Tools.Alire_Manifests;
