with Ada.Strings.Unbounded;
with GNAT.OS_Lib;

package Project_Tools.Processes is
   subtype Unbounded_String is Ada.Strings.Unbounded.Unbounded_String;

   function Locate_Command (Name : String) return String;
   --  @param Name Executable name to find on PATH.
   --  @return Absolute executable path, or an empty string when not found.

   function Has_Argument (Name : String) return Boolean;
   --  @param Name Command-line argument to find.
   --  @return True when the current process was invoked with Name.

   procedure Require_Command
     (Name    : String;
      Message : String;
      Quiet   : Boolean := False);
   --  Require Name to resolve on PATH or fail the current tool.
   --  @param Name Executable name to find on PATH.
   --  @param Message Diagnostic message to emit when Name is missing.
   --  @param Quiet Suppress diagnostics when True.

   function Run_Status
     (Label   : String;
      Dir     : String;
      Program : String;
      Args    : GNAT.OS_Lib.Argument_List;
      Quiet   : Boolean := False) return Integer;
   --  Run Program in Dir, restore the caller directory, and return the exit status.
   --  @param Label Human-readable command label for diagnostics.
   --  @param Dir Working directory for the child process.
   --  @param Program Executable to run.
   --  @param Args Argument list passed to Program.
   --  @param Quiet Suppress informational output when True.
   --  @return Child process exit status.

   procedure Run
     (Label   : String;
      Dir     : String;
      Program : String;
      Args    : GNAT.OS_Lib.Argument_List;
      Quiet   : Boolean := False);
   --  @param Label Human-readable command label for diagnostics.
   --  @param Dir Working directory for the child process.
   --  @param Program Executable to run.
   --  @param Args Argument list passed to Program.
   --  @param Quiet Suppress informational output when True.

   function Run_Status
     (Label   : String;
      Dir     : String;
      Program : String;
      Args    : GNAT.OS_Lib.Argument_List;
      Output  : out Unbounded_String;
      Quiet   : Boolean := False) return Integer;
   --  As Run_Status above, but also capture the child's standard output.
   --  Overload that preserves the existing output-less Run_Status; the child's
   --  standard error is left on the inherited stream (only stdout is captured).
   --  @param Label Human-readable command label for diagnostics.
   --  @param Dir Working directory for the child process.
   --  @param Program Executable to run.
   --  @param Args Argument list passed to Program.
   --  @param Output Receives the child's captured standard output.
   --  @param Quiet Suppress informational output when True.
   --  @return Child process exit status.

   procedure Run
     (Label   : String;
      Dir     : String;
      Program : String;
      Args    : GNAT.OS_Lib.Argument_List;
      Output  : out Unbounded_String;
      Quiet   : Boolean := False);
   --  As Run above, but also capture the child's standard output into Output.
   --  Overload that preserves the existing output-less Run; fails the current
   --  tool (sets failure status and raises Program_Error) on a non-zero exit,
   --  after populating Output with whatever was captured.
   --  @param Label Human-readable command label for diagnostics.
   --  @param Dir Working directory for the child process.
   --  @param Program Executable to run.
   --  @param Args Argument list passed to Program.
   --  @param Output Receives the child's captured standard output.
   --  @param Quiet Suppress informational output when True.

   function Command_Output
     (Command    : String;
      Arguments  : GNAT.OS_Lib.Argument_List;
      Input      : String := "";
      Status     : access Integer := null;
      Err_To_Out : Boolean := False) return String;
   --  Run Command with Arguments and capture its output.
   --  This helper is intended for tests and workflow probes that need to feed
   --  standard input and capture the resulting output without invoking a shell.
   --  @param Command Executable to run.
   --  @param Arguments Argument list passed to Command.
   --  @param Input Standard input for the child process.
   --  @param Status Child status receiver.
   --  @param Err_To_Out Whether standard error is merged into output.
   --  @return Captured command output.

   --  POSIX shell helpers. Unlike the Program/Args helpers above, these run
   --  commands through /bin/sh and are POSIX-oriented.

   function Shell_Quote (Value : String) return String;
   --  @param Value Raw string to embed in a POSIX shell command.
   --  @return Value wrapped in single quotes with embedded quotes escaped.

   function Run_Shell (Command : String) return Integer;
   --  Run Command through /bin/sh -c in the current directory.
   --  @param Command POSIX shell command line.
   --  @return Child exit status, or 1 when the shell could not be spawned.

   function Run_Shell_In_Directory
     (Directory   : String;
      Command     : String;
      Quiet       : Boolean := False;
      Output_File : String := "") return Integer;
   --  Run Command through /bin/sh after changing into Directory.
   --  @param Directory Working directory entered before Command runs.
   --  @param Command POSIX shell command line.
   --  @param Quiet Redirect output to /dev/null when True and Output_File empty.
   --  @param Output_File When non-empty, redirect stdout and stderr to this file.
   --  @return Child exit status, or 1 when the shell could not be spawned.

   function Shell_Output (Command : String) return String;
   --  Capture the standard output of a POSIX shell command (stderr discarded).
   --  @param Command POSIX shell command line.
   --  @return Captured stdout with normalized line-feed separators, or an empty
   --          string when Command exits non-zero or cannot be run.

   function Shell_Output_Trimmed (Command : String) return String;
   --  As Shell_Output, but return only the first output line, whitespace-trimmed.
   --  @param Command POSIX shell command line.
   --  @return The first output line trimmed of surrounding whitespace.
end Project_Tools.Processes;
