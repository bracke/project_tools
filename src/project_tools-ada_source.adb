with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;

with Project_Tools.Text;

package body Project_Tools.Ada_Source is
   function Is_Identifier_Character (Char : Character) return Boolean is
   begin
      return
        (Char >= 'A' and then Char <= 'Z')
        or else (Char >= 'a' and then Char <= 'z')
        or else (Char >= '0' and then Char <= '9')
        or else Char = '_';
   end Is_Identifier_Character;

   function First_Token (Text : String) return String is
      Stop : Natural := Text'First;
   begin
      while Stop <= Text'Last and then Is_Identifier_Character (Text (Stop)) loop
         Stop := Stop + 1;
      end loop;

      if Stop = Text'First then
         return "";
      else
         return Text (Text'First .. Stop - 1);
      end if;
   end First_Token;

   function Is_Single_Identifier (Text : String) return Boolean is
   begin
      if Text = "" then
         return False;
      end if;

      for Char of Text loop
         if not Is_Identifier_Character (Char) then
            return False;
         end if;
      end loop;

      return True;
   end Is_Single_Identifier;

   function Token_After (Text : String; Prefix : String) return String is
   begin
      if not Project_Tools.Text.Starts_With (Text, Prefix) then
         return "";
      else
         return First_Token
           (Ada.Strings.Fixed.Trim
              (Text (Text'First + Prefix'Length .. Text'Last),
               Ada.Strings.Both));
      end if;
   end Token_After;

   function Is_Ada_Reserved_Word (Name : String) return Boolean is
      Lower : constant String := Ada.Characters.Handling.To_Lower (Name);
   begin
      return
        Lower = "abort" or else Lower = "abs" or else Lower = "abstract"
        or else Lower = "accept" or else Lower = "access" or else Lower = "aliased"
        or else Lower = "all" or else Lower = "and" or else Lower = "array"
        or else Lower = "at" or else Lower = "begin" or else Lower = "body"
        or else Lower = "case" or else Lower = "constant" or else Lower = "declare"
        or else Lower = "delay" or else Lower = "delta" or else Lower = "digits"
        or else Lower = "do" or else Lower = "else" or else Lower = "elsif"
        or else Lower = "end" or else Lower = "entry" or else Lower = "exception"
        or else Lower = "exit" or else Lower = "for" or else Lower = "function"
        or else Lower = "generic" or else Lower = "goto" or else Lower = "if"
        or else Lower = "in" or else Lower = "interface" or else Lower = "is"
        or else Lower = "limited" or else Lower = "loop" or else Lower = "mod"
        or else Lower = "new" or else Lower = "not" or else Lower = "null"
        or else Lower = "of" or else Lower = "or" or else Lower = "others"
        or else Lower = "out" or else Lower = "overriding" or else Lower = "package"
        or else Lower = "pragma" or else Lower = "private" or else Lower = "procedure"
        or else Lower = "protected" or else Lower = "raise" or else Lower = "range"
        or else Lower = "record" or else Lower = "rem" or else Lower = "renames"
        or else Lower = "requeue" or else Lower = "return" or else Lower = "reverse"
        or else Lower = "select" or else Lower = "separate" or else Lower = "some"
        or else Lower = "subtype" or else Lower = "synchronized" or else Lower = "tagged"
        or else Lower = "task" or else Lower = "terminate" or else Lower = "then"
        or else Lower = "type" or else Lower = "until" or else Lower = "use"
        or else Lower = "when" or else Lower = "while" or else Lower = "with"
        or else Lower = "xor";
   end Is_Ada_Reserved_Word;
end Project_Tools.Ada_Source;
