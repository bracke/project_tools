with GNAT.OS_Lib;

package Project_Tools.Alire is
   --  Argument lists for driving alr from a check program, with the switches
   --  that stop it asking questions. A gate that blocks on a prompt is a gate
   --  that hangs a CI run rather than failing it.

   function Noninteractive_Update_Args return GNAT.OS_Lib.Argument_List;
   --  @return Arguments for "alr update" that will not prompt.

   function Noninteractive_Build_Args return GNAT.OS_Lib.Argument_List;
   --  @return Arguments for "alr build" that will not prompt.

   function Noninteractive_Exec_Args
     (Args : GNAT.OS_Lib.Argument_List)
      return GNAT.OS_Lib.Argument_List;
   --  @param Args The command and its arguments to run under "alr exec".
   --  @return Args preceded by the exec switches that will not prompt.

   procedure Run_Build
     (Directory    : String;
      Release_Mode : Boolean := False;
      Label        : String := "alr build");
   --  Run a noninteractive Alire build in Directory. When alr was installed
   --  by getada, run it with a scrubbed environment that preserves only the
   --  derived Alire home and PATH, avoiding host-local Alire state drift in
   --  repeatable workflow checks.
   --  @param Directory Crate directory where alr should run.
   --  @param Release_Mode Use --release and release profiles when True.
   --  @param Label Human-readable command label for diagnostics.
end Project_Tools.Alire;
