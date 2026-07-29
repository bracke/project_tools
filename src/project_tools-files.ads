with Ada.Strings.Unbounded;

package Project_Tools.Files is
   subtype Unbounded_String is Ada.Strings.Unbounded.Unbounded_String;
   type Name_List is array (Positive range <>) of Unbounded_String;
   type Path_List is array (Positive range <>) of Unbounded_String;

   function Exists (Path : String) return Boolean;
   --  @param Path Filesystem path to test.
   --  @return True when Path exists.

   function File_Exists (Path : String) return Boolean;
   --  @param Path Filesystem path to test.
   --  @return True when Path names an ordinary file.

   function Directory_Exists (Path : String) return Boolean;
   --  @param Path Filesystem path to test.
   --  @return True when Path names a directory.

   function File_Contains (Path : String; Pattern : String) return Boolean;
   --  @param Path Text file path to inspect.
   --  @param Pattern Substring to find.
   --  @return True when Pattern occurs in the file.

   function Read_Raw_File (Path : String) return String;

   --  A writable temporary directory for scratch files: the first non-empty of
   --  TMPDIR, TMP, TEMP, else "/tmp". Portable across Unix (where /tmp is the
   --  default) and Windows (where TEMP/TMP are set but /tmp does not exist).
   function Temp_Dir return String;
   --  @param Path File path to read byte-for-byte.
   --  @return Raw file contents as a String.

   function File_Starts_With_File (Path : String; Prefix_Path : String) return Boolean;
   --  @param Path File whose prefix is checked.
   --  @param Prefix_Path File containing the required prefix.
   --  @return True when Path starts with Prefix_Path contents.

   procedure Require_Contains
     (Path    : String;
      Pattern : String;
      Message : String;
      Quiet   : Boolean := False);
   --  Require Pattern to occur in Path or fail the current tool.
   --  @param Path Text file path to inspect.
   --  @param Pattern Substring that must occur.
   --  @param Message Diagnostic prefix to emit on failure.
   --  @param Quiet Suppress diagnostics when True.

   procedure Require_File
     (Path    : String;
      Message : String;
      Quiet   : Boolean := False);
   --  Require Path to name an ordinary file or fail the current tool.
   --  @param Path Filesystem path to inspect.
   --  @param Message Diagnostic prefix to emit on failure.
   --  @param Quiet Suppress diagnostics when True.

   procedure Require_Directory
     (Path    : String;
      Message : String;
      Quiet   : Boolean := False);
   --  Require Path to name a directory or fail the current tool.
   --  @param Path Filesystem path to inspect.
   --  @param Message Diagnostic prefix to emit on failure.
   --  @param Quiet Suppress diagnostics when True.

   procedure Require_Files
     (Paths   : Path_List;
      Message : String;
      Quiet   : Boolean := False);
   --  Require every path in Paths to name an ordinary file or fail the current tool.
   --  @param Paths Filesystem paths to inspect.
   --  @param Message Diagnostic prefix to emit on failure.
   --  @param Quiet Suppress diagnostics when True.

   procedure Require_Directories
     (Paths   : Path_List;
      Message : String;
      Quiet   : Boolean := False);
   --  Require every path in Paths to name a directory or fail the current tool.
   --  @param Paths Filesystem paths to inspect.
   --  @param Message Diagnostic prefix to emit on failure.
   --  @param Quiet Suppress diagnostics when True.

   procedure Require_File_Starts_With_File
     (Path        : String;
      Prefix_Path : String;
      Message     : String;
      Quiet       : Boolean := False);
   --  Require Path to start with Prefix_Path contents or fail the current tool.
   --  @param Path File whose prefix is checked.
   --  @param Prefix_Path File containing the required prefix.
   --  @param Message Diagnostic prefix to emit on failure.
   --  @param Quiet Suppress diagnostics when True.

   procedure Copy_Filtered_Tree
     (Source_Dir      : String;
      Target_Dir      : String;
      Skip_Entries    : Name_List;
      Skip_Files      : Name_List;
      Failure_Message : String := "failed to copy source tree";
      Quiet           : Boolean := False);
   --  Recursively copy a source tree while applying caller-provided skip name lists.
   --  @param Source_Dir Source directory to copy from.
   --  @param Target_Dir Target directory to create/populate.
   --  @param Skip_Entries Simple directory entry names to skip before recursion.
   --  @param Skip_Files Simple ordinary file names to skip.
   --  @param Failure_Message Diagnostic prefix to emit on copy failure.
   --  @param Quiet Suppress diagnostics when True.

   function List_Tree
     (Root         : String;
      Name_Pattern : String := "*";
      Skip_Entries : Name_List := [1 .. 0 => <>])
      return Path_List;
   --  Recursively collect the ordinary files under Root whose simple name
   --  matches the glob Name_Pattern (for example "*.ads"), skipping any
   --  subdirectory whose simple name appears in Skip_Entries; "." and ".." are
   --  always skipped. Each path is Root joined with the entry path, so a
   --  relative Root yields relative paths. The walk is depth-first in the order
   --  Ada.Directories reports entries, recursing into a subdirectory as soon as
   --  it is encountered -- matching the hand-rolled scanners this replaces.
   --  @param Root the directory to walk (relative or absolute)
   --  @param Name_Pattern glob matched against each file's simple name
   --  @param Skip_Entries simple names of subdirectories to skip
   --  @return the matching file paths, Root-relative when Root is relative

   procedure Copy_Release_Source_Tree
     (Source_Dir      : String;
      Target_Dir      : String;
      Skip_Entries    : Name_List;
      Skip_Files      : Name_List;
      Quiet           : Boolean := False);
   --  Copy a release source tree using caller-provided skip name lists.
   --  @param Source_Dir Source directory to copy from.
   --  @param Target_Dir Target directory to create/populate.
   --  @param Skip_Entries Simple directory entry names to skip before recursion.
   --  @param Skip_Files Simple ordinary file names to skip.
   --  @param Quiet Suppress diagnostics when True.

   procedure Delete_Tree (Path : String);
   --  Recursively delete Path when it exists.
   --  @param Path File or directory tree to remove.

   procedure Delete_File_If_Present (Path : String);
   --  Delete Path when it exists and names an ordinary file; missing paths and
   --  directories are left untouched.
   --  @param Path Ordinary file to remove if present.

   procedure Write_Text_File (Path : String; Content : String);
   --  Create or replace a text file with Content.
   --  @param Path File to create or replace.
   --  @param Content Text to write.

   procedure Write_Raw_File (Path : String; Content : String);
   --  Create or replace a file with byte-for-byte Content.
   --  @param Path File to create or replace.
   --  @param Content Raw bytes represented as String characters.

   procedure Append_Text_File (Path : String; Content : String);
   --  @param Path File to open in append mode.
   --  @param Content Text to append.

   function Join (Left : String; Right : String) return String;
   --  Join two path segments with a single '/' separator.
   --  @param Left Left path segment.
   --  @param Right Right path segment.
   --  @return Left and Right joined with '/', or Right when Left is empty, or
   --          Left & Right when Left already ends in '/'.

   function Has_Line (Path : String; Line : String) return Boolean;
   --  @param Path Text file path to inspect.
   --  @param Line Exact line to find (compared without its terminator).
   --  @return True when Path contains a line equal to Line.

   function Line_Contains (Path : String; Pattern : String) return Boolean;
   --  Whether any single line of Path contains Pattern as a substring. Unlike
   --  File_Contains (a whole-file match), Pattern is matched within one line, so
   --  a Pattern spanning a line boundary never matches -- the semantics the
   --  hand-rolled per-line source scanners rely on. A missing or unreadable
   --  file, or a Pattern absent from every line, yields False.
   --  @param Path Text file path to inspect.
   --  @param Pattern Substring to search for within each individual line.
   --  @return True when some line of Path contains Pattern.

   function Value_Of (Path : String; Key : String) return String;
   --  Read the value of a "Key=value" line from a simple key/value text file.
   --  @param Path Text file path to inspect.
   --  @param Key Key whose "Key=" prefixed line is read.
   --  @return The text following the first "Key=" line, or an empty string.

   function Find_File (Directory : String; Name : String) return String;
   --  Recursively search Directory for an ordinary file named Name.
   --  @param Directory Root directory to search.
   --  @param Name Simple file name to match.
   --  @return The lexicographically smallest matching path, or an empty string
   --          when no match exists.

   function Find_Root_Upward
     (Start_Directory : String;
      Marker_File     : String) return String;
   --  Walk upward from Start_Directory until Marker_File is found.
   --  @param Start_Directory Directory where the search begins.
   --  @param Marker_File File name or relative path that identifies the root.
   --  @return Full path of the first directory containing Marker_File, or an
   --          empty string when no matching ancestor exists.

   function Any_File_Contains
     (Root    : String;
      Pattern : String)
      return Boolean;
   --  Whether any ordinary file under Root (searched recursively) contains
   --  Pattern. A missing Root yields False. Useful for architecture/wiring
   --  assertions that must survive code moving between files.
   --  @param Root Directory to search recursively.
   --  @param Pattern Literal substring to look for.
   --  @return True when some file under Root contains Pattern.
end Project_Tools.Files;
