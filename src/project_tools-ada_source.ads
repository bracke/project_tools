package Project_Tools.Ada_Source is
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
end Project_Tools.Ada_Source;
