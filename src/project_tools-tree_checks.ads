with Project_Tools.Files;

package Project_Tools.Tree_Checks is
   subtype Text_List is Project_Tools.Files.Name_List;

   procedure Check_No_Generated_Python
     (Errors : in out Natural;
      Dir    : String;
      Quiet  : Boolean := False);
   --  Recursively reject Python source/cache artifacts under Dir.
   --  @param Errors Error counter incremented for each forbidden artifact.
   --  @param Dir Directory tree to inspect.
   --  @param Quiet Suppress diagnostics when True.

   procedure Check_No_Forbidden_Tokens
     (Errors           : in out Natural;
      Dir              : String;
      Forbidden_Tokens : Text_List;
      Purpose          : String;
      Exempt_Path_Token : String := "";
      Quiet            : Boolean := False);
   --  Recursively reject forbidden text tokens in ordinary files below Dir.
   --  @param Errors Error counter incremented for each forbidden occurrence.
   --  @param Dir Directory tree to inspect.
   --  @param Forbidden_Tokens Tokens that must not occur in file names or contents.
   --  @param Purpose Human-readable tree purpose for diagnostics.
   --  @param Exempt_Path_Token Optional path substring exempted from content-token failures.
   --  @param Quiet Suppress diagnostics when True.

   procedure Require_No_Nonempty_Stderr
     (Dir   : String;
      Quiet : Boolean := False);
   --  Recursively reject non-empty generated .stderr logs below Dir.
   --  @param Dir Directory tree to inspect. Missing or non-directory paths are ignored.
   --  @param Quiet Suppress diagnostics when True.
end Project_Tools.Tree_Checks;
