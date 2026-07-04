with Ada.Strings.Unbounded;

package Project_Tools.Ada_Source is
   type String_List is
     array (Positive range <>) of Ada.Strings.Unbounded.Unbounded_String;

   function Is_Identifier_Character (Char : Character) return Boolean;
   --  @param Char Character to classify.
   --  @return True when Char may appear in an Ada identifier (ASCII letter,
   --          digit, or underscore).

   function First_Token (Text : String) return String;
   --  @param Text Text to scan from its first character.
   --  @return The leading run of identifier characters, or "" when Text does
   --          not start with an identifier character.

   function Is_Single_Identifier (Text : String) return Boolean;
   --  @param Text Text to test.
   --  @return True when Text is non-empty and consists solely of identifier
   --          characters.

   function Token_After (Text : String; Prefix : String) return String;
   --  @param Text Text to scan.
   --  @param Prefix Required leading substring.
   --  @return The first identifier token after Prefix (leading whitespace
   --          trimmed), or "" when Text does not start with Prefix.

   function Is_Ada_Reserved_Word (Name : String) return Boolean;
   --  @param Name Candidate word, compared case-insensitively.
   --  @return True when Name is an Ada 2022 reserved word.

   procedure Require_Public_GNATdoc_Tags
     (Spec_Path       : String;
      Stop_At_Private : Boolean := True;
      Tags_Before     : Boolean := True;
      Quiet           : Boolean := False);
   --  Require public subprogram declarations in Spec_Path to have GNATdoc
   --  tags for their public profile. The default associates the doc comment
   --  block that immediately precedes each declaration (the house convention
   --  used by the files and guikit specs); set Tags_Before to False for specs
   --  that place the comment block after the declaration instead.
   --  @param Spec_Path Ada package spec to scan.
   --  @param Stop_At_Private Stop scanning when a private section is reached.
   --  @param Tags_Before Associate the preceding comment block when True,
   --         otherwise the trailing comment block.
   --  @param Quiet Suppress diagnostics when True.

   procedure Require_Only_Allowed_With_Clauses
     (Source_Path : String;
      Prefix      : String;
      Allowed     : String_List;
      Quiet       : Boolean := False);
   --  Require every `with` clause whose unit starts with Prefix to be listed
   --  exactly in Allowed. Comments are ignored; limited/private with clauses
   --  and comma-separated with clauses are parsed.
   --  @param Source_Path Ada source file to inspect.
   --  @param Prefix Package prefix to restrict, for example "I18N.".
   --  @param Allowed Exact unit names allowed under Prefix.
   --  @param Quiet Suppress diagnostics when True.

   procedure Require_No_Code_Tokens
     (Source_Path      : String;
      Forbidden_Tokens : String_List;
      Quiet            : Boolean := False);
   --  Require Ada source code, with line comments stripped, to contain none of
   --  the forbidden tokens.
   --  @param Source_Path Ada source file to inspect.
   --  @param Forbidden_Tokens Tokens that must not appear outside comments.
   --  @param Quiet Suppress diagnostics when True.

   procedure Require_Unique_String_Returns
     (Source_Path   : String;
      Function_Name : String;
      Allow_Empty   : Boolean := False;
      Quiet         : Boolean := False);
   --  Require string literals returned directly by Function_Name to be unique.
   --  This is intended for simple mapping functions implemented as case
   --  statements with `return "literal";` arms.
   --  @param Source_Path Ada source file to inspect.
   --  @param Function_Name Function body to scan.
   --  @param Allow_Empty Permit repeated empty-string returns when True.
   --  @param Quiet Suppress diagnostics when True.
end Project_Tools.Ada_Source;
