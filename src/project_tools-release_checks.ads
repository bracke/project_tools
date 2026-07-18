with GNAT.OS_Lib;
with Project_Tools.Files;
with Project_Tools.Processes;

package Project_Tools.Release_Checks is
   type Checker is tagged private;

   function Create (Root : String) return Checker;

   procedure Require_File
     (Check         : Checker;
      Relative_Path : String;
      Quiet         : Boolean := False);

   procedure Require_Directory
     (Check         : Checker;
      Relative_Path : String;
      Quiet         : Boolean := False);

   procedure Require_Text
     (Check         : Checker;
      Relative_Path : String;
      Text          : String;
      Quiet         : Boolean := False);

   procedure Require_Absolute_File
     (Path  : String;
      Quiet : Boolean := False);

   procedure Require_Absolute_Directory
     (Path  : String;
      Quiet : Boolean := False);

   procedure Require_Clean_Git_Worktree
     (Label : String;
      Path  : String;
      Quiet : Boolean := False);
   --  Require Path to be a Git worktree with no porcelain status output.
   --  @param Label Human-readable repository name for diagnostics.
   --  @param Path Path to the Git worktree to inspect.
   --  @param Quiet Suppress diagnostics when True.

   function Nonempty_Stderr_Files
     (Dirs : Project_Tools.Files.Path_List)
      return String;
   --  Return newline-separated nonempty `.stderr` files below Dirs.

   function Ada_Build_Processes
     (Path_Token : String := "")
      return String;
   --  Return visible Alire/GPR/GNAT process diagnostics, optionally filtered
   --  by a path token.

   procedure Wait_For_Workspace_Build_Lock
     (Lock_Path       : String;
      Timeout_Seconds : Natural;
      Quiet           : Boolean := False);
   --  Wait until Lock_Path disappears, failing after Timeout_Seconds.
   --  @param Lock_Path Workspace-level lock file path.
   --  @param Timeout_Seconds Maximum seconds to wait; zero means fail fast.
   --  @param Quiet Suppress diagnostics when True.

   procedure Create_Workspace_Build_Lock
     (Lock_Path : String;
      Owner     : String;
      Quiet     : Boolean := False);
   --  Create Lock_Path with Owner text or fail if a lock already exists.

   procedure Remove_Workspace_Build_Lock
     (Lock_Path : String;
      Quiet     : Boolean := False);
   --  Remove a lock file created by this process. Missing files are ignored.

   procedure Require_GPR_Main_Inventory
     (Project_File                   : String;
      Documentation_File             : String;
      Source_Directory               : String;
      Alternate_Stem_Prefix          : String := "";
      Alternate_Source_Directory     : String := "";
      Alternate_Documentation_File   : String := "";
      Runner_File                    : String := "";
      Runner_Token_Prefix            : String := "";
      Runner_Token_Suffix            : String := "";
      Quiet                          : Boolean := False);
   --  Require every .adb main listed in a GPR file to have a source and docs.
   --  @param Project_File GPR file containing quoted .adb main names.
   --  @param Documentation_File File that must mention every executable stem.
   --  @param Source_Directory Directory for ordinary main sources.
   --  @param Alternate_Stem_Prefix Stem prefix for alternate-source mains.
   --  @param Alternate_Source_Directory Directory for alternate-source mains.
   --  @param Alternate_Documentation_File Extra docs file for alternate mains.
   --  @param Runner_File File that must mention alternate mains, if provided.
   --  @param Runner_Token_Prefix Prefix before the alternate stem in Runner_File.
   --  @param Runner_Token_Suffix Suffix after the alternate stem in Runner_File.
   --  @param Quiet Suppress diagnostics when True.

   procedure Require_Program_Output_Matches_Fenced_Text
     (Expected_File : String;
      Fence_Label   : String;
      Dir           : String;
      Program       : String;
      Args          : GNAT.OS_Lib.Argument_List;
      Label         : String;
      Quiet         : Boolean := False);
   --  Run Program and require stdout to exactly match the first fenced block
   --  labelled Fence_Label in Expected_File, for example ```text.
   --  @param Expected_File Markdown/text file containing the expected block.
   --  @param Fence_Label Fence info string without backticks, for example "text".
   --  @param Dir Working directory for the child process.
   --  @param Program Executable to run.
   --  @param Args Arguments passed to Program.
   --  @param Label Human-readable command label for diagnostics.
   --  @param Quiet Suppress informational diagnostics when True.

   procedure Run
     (Label   : String;
      Dir     : String;
      Program : String;
      Args    : GNAT.OS_Lib.Argument_List;
      Quiet   : Boolean := False) renames Project_Tools.Processes.Run;

   procedure Fail (Message : String; Quiet : Boolean := False);
   --  Report a release-check failure: emit Message, set the failure exit
   --  status, and raise Program_Error so the current tool unwinds. Use for
   --  bespoke conditional checks that do not map to a Require_* helper.
   --  @param Message Diagnostic to emit on standard error.
   --  @param Quiet Suppress the diagnostic when True.

private
   type Checker is tagged record
      Root : String (1 .. 4096);
      Last : Natural := 0;
   end record;
end Project_Tools.Release_Checks;
