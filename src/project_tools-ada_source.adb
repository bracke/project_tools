with Ada.Command_Line;
with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;

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

   function Trim (Text : String) return String is
     (Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both));

   function Lower (Text : String) return String is
     (Ada.Characters.Handling.To_Lower (Text));

   function Code_Prefix (Line : String) return String is
      Comment : constant Natural := Ada.Strings.Fixed.Index (Line, "--");
   begin
      if Comment = 0 then
         return Line;
      elsif Comment = Line'First then
         return "";
      else
         return Line (Line'First .. Comment - 1);
      end if;
   end Code_Prefix;

   procedure Fail
     (Errors  : in out Natural;
      Message : String;
      Quiet   : Boolean)
   is
   begin
      Errors := Errors + 1;
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      if not Quiet then
         Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, "error: " & Message);
      end if;
   end Fail;

   procedure For_Each_Code_Token
     (Line  : String;
      Visit : not null access procedure (Token : String))
   is
      Index : Natural := Line'First;
   begin
      while Index <= Line'Last loop
         if Index < Line'Last
           and then Line (Index) = '-'
           and then Line (Index + 1) = '-'
         then
            return;
         elsif Line (Index) = '"' then
            Index := Index + 1;
            while Index <= Line'Last loop
               if Line (Index) = '"' then
                  if Index < Line'Last and then Line (Index + 1) = '"' then
                     Index := Index + 2;
                  else
                     Index := Index + 1;
                     exit;
                  end if;
               else
                  Index := Index + 1;
               end if;
            end loop;
         elsif Is_Identifier_Character (Line (Index)) then
            declare
               First : constant Positive := Index;
            begin
               while Index <= Line'Last
                 and then Is_Identifier_Character (Line (Index))
               loop
                  Index := Index + 1;
               end loop;

               Visit (Lower (Line (First .. Index - 1)));
            end;
         elsif Index < Line'Last
           and then Line (Index) = '='
           and then Line (Index + 1) = '>'
         then
            Visit ("=>");
            Index := Index + 2;
         else
            Index := Index + 1;
         end if;
      end loop;
   end For_Each_Code_Token;

   procedure Scan_Broad_Exception_Handlers
     (Source_Path : String;
      Visit       : not null access procedure
        (Line_Number : Positive;
         Source_Line : String))
   is
      File                 : Ada.Text_IO.File_Type;
      Buffer               : String (1 .. 4096);
      Last                 : Natural;
      Current_Line         : Positive := 1;
      In_Exception_Handler : Boolean := False;
      Exception_Case_Depth : Natural := 0;
      Choice_Open          : Boolean := False;
      Choice_Has_Others    : Boolean := False;
      Choice_Case_Depth    : Natural := 0;
      Choice_Line_Number   : Positive := 1;
      Choice_Source_Line   : Unbounded_String;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Source_Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         Ada.Text_IO.Get_Line (File, Buffer, Last);
         declare
            Line               : constant String := Buffer (1 .. Last);
            Token_Count        : Natural := 0;
            First_Token_Text   : Unbounded_String;
            Second_Token_Text  : Unbounded_String;
            Saw_End_Case       : Boolean := False;
            Saw_Case           : Boolean := False;
            Saw_Case_Is        : Boolean := False;
            Broad_Handler_Line : Boolean := False;

            procedure Note_Token (Token : String) is
            begin
               Token_Count := Token_Count + 1;
               if Token_Count = 1 then
                  First_Token_Text := To_Unbounded_String (Token);
               elsif Token_Count = 2 then
                  Second_Token_Text := To_Unbounded_String (Token);
               end if;

               if In_Exception_Handler then
                  if Token = "when" then
                     Choice_Open := True;
                     Choice_Has_Others := False;
                     Choice_Case_Depth := Exception_Case_Depth;
                     Choice_Line_Number := Current_Line;
                     Choice_Source_Line := To_Unbounded_String (Line);
                  elsif Choice_Open and then Token = "others" then
                     Choice_Has_Others := True;
                  elsif Choice_Open and then Token = "=>" then
                     if Choice_Has_Others and then Choice_Case_Depth = 0 then
                        Broad_Handler_Line := True;
                     end if;
                     Choice_Open := False;
                  elsif Choice_Open and then Token = ";" then
                     Choice_Open := False;
                  end if;
               end if;

               if Token_Count = 2
                 and then To_String (First_Token_Text) = "end"
                 and then Token = "case"
               then
                  Saw_End_Case := True;
               elsif Token = "case" and then not Saw_End_Case then
                  Saw_Case := True;
               elsif Token = "is" and then Saw_Case then
                  Saw_Case_Is := True;
               end if;
            end Note_Token;

            function Is_Exception_Line return Boolean is
              (Token_Count = 1 and then To_String (First_Token_Text) = "exception");

            function Ends_Case_Statement return Boolean is
              (To_String (First_Token_Text) = "end"
               and then To_String (Second_Token_Text) = "case");

            function Starts_Case_Statement return Boolean is
              (Saw_Case_Is and then not Saw_End_Case);

            function Ends_Exception_Section return Boolean is
              (To_String (First_Token_Text) = "end"
               and then To_String (Second_Token_Text) /= "if"
               and then To_String (Second_Token_Text) /= "loop"
               and then To_String (Second_Token_Text) /= "case"
               and then To_String (Second_Token_Text) /= "record"
               and then To_String (Second_Token_Text) /= "select");
         begin
            For_Each_Code_Token (Line, Note_Token'Access);

            if Broad_Handler_Line then
               Visit (Choice_Line_Number, To_String (Choice_Source_Line));
            end if;

            if Is_Exception_Line then
               In_Exception_Handler := True;
               Exception_Case_Depth := 0;
               Choice_Open := False;
            elsif In_Exception_Handler and then Ends_Case_Statement then
               if Exception_Case_Depth > 0 then
                  Exception_Case_Depth := Exception_Case_Depth - 1;
               end if;
            elsif In_Exception_Handler and then Starts_Case_Statement then
               Exception_Case_Depth := Exception_Case_Depth + 1;
            elsif In_Exception_Handler and then Ends_Exception_Section then
               In_Exception_Handler := False;
               Exception_Case_Depth := 0;
               Choice_Open := False;
            end if;
         end;

         if Current_Line < Positive'Last then
            Current_Line := Current_Line + 1;
         end if;
      end loop;

      Ada.Text_IO.Close (File);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;

         raise;
   end Scan_Broad_Exception_Handlers;

   procedure Require_No_Code_Tokens
     (Source_Path      : String;
      Forbidden_Tokens : String_List;
      Quiet            : Boolean := False)
   is
      File   : Ada.Text_IO.File_Type;
      Buffer : String (1 .. 4096);
      Last   : Natural;
      Errors : Natural := 0;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Source_Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         Ada.Text_IO.Get_Line (File, Buffer, Last);
         declare
            Code : constant String := Code_Prefix (Buffer (1 .. Last));
         begin
            for Token of Forbidden_Tokens loop
               declare
                  Pattern : constant String := To_String (Token);
               begin
                  if Project_Tools.Text.Contains (Code, Pattern) then
                     Fail
                       (Errors,
                        Source_Path & " contains forbidden code token " & Pattern,
                        Quiet);
                  end if;
               end;
            end loop;
         end;
      end loop;

      Ada.Text_IO.Close (File);
      if Errors > 0 then
         raise Program_Error;
      end if;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;

         if Errors > 0 then
            raise Program_Error;
         end if;

         raise;
   end Require_No_Code_Tokens;

   function First_Source_File_Containing
     (Root          : String;
      Pattern       : String;
      Allowed_Files : Project_Tools.Files.Path_List := [1 .. 0 => <>])
      return String
   is
      function Is_Allowed (Path : String) return Boolean is
      begin
         for Allowed of Allowed_Files loop
            if Path = To_String (Allowed) then
               return True;
            end if;
         end loop;
         return False;
      end Is_Allowed;

      function First_In (Name_Pattern : String) return String is
         Sources : constant Project_Tools.Files.Path_List :=
           Project_Tools.Files.List_Tree (Root, Name_Pattern);
      begin
         for Path of Sources loop
            declare
               Name : constant String := To_String (Path);
            begin
               if Project_Tools.Files.File_Contains (Name, Pattern)
                 and then not Is_Allowed (Name)
               then
                  return Name;
               end if;
            end;
         end loop;
         return "";
      end First_In;

      Found : constant String := First_In ("*.ads");
   begin
      if Found /= "" then
         return Found;
      else
         return First_In ("*.adb");
      end if;
   end First_Source_File_Containing;

   procedure Require_No_Code_Tokens_In_Tree
     (Root             : String;
      Forbidden_Tokens : String_List;
      Quiet            : Boolean := False)
   is
      procedure Check (Name_Pattern : String) is
         Sources : constant Project_Tools.Files.Path_List :=
           Project_Tools.Files.List_Tree (Root, Name_Pattern);
      begin
         for Path of Sources loop
            Require_No_Code_Tokens
              (To_String (Path), Forbidden_Tokens, Quiet => Quiet);
         end loop;
      end Check;
   begin
      Check ("*.ads");
      Check ("*.adb");
   end Require_No_Code_Tokens_In_Tree;

   procedure Require_Unique_String_Returns
     (Source_Path   : String;
      Function_Name : String;
      Allow_Empty   : Boolean := False;
      Quiet         : Boolean := False)
   is
      File        : Ada.Text_IO.File_Type;
      Buffer      : String (1 .. 4096);
      Last        : Natural;
      In_Function : Boolean := False;
      Seen        : Unbounded_String;
      Errors      : Natural := 0;

      function Quoted_Return (Code : String) return String is
         Return_Word  : constant String := "return";
         Return_Index : constant Natural := Ada.Strings.Fixed.Index (Code, "return");
         First        : Natural := 0;
         Last_Quote   : Natural := 0;
      begin
         if Return_Index = 0 then
            return "";
         end if;

         for I in Return_Index + Return_Word'Length .. Code'Last loop
            if Code (I) = '"' then
               First := I;
               exit;
            end if;
         end loop;

         if First = 0 then
            return "";
         end if;

         for I in First + 1 .. Code'Last loop
            if Code (I) = '"' then
               Last_Quote := I;
               exit;
            end if;
         end loop;

         if Last_Quote = 0 then
            return "";
         else
            return Code (First + 1 .. Last_Quote - 1);
         end if;
      end Quoted_Return;

      function Seen_Line (Value : String) return String is
        (ASCII.LF & Value & ASCII.LF);
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Source_Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         Ada.Text_IO.Get_Line (File, Buffer, Last);
         declare
            Code : constant String := Trim (Code_Prefix (Buffer (1 .. Last)));
         begin
            if not In_Function then
               In_Function :=
                 Project_Tools.Text.Starts_With
                   (Lower (Code), "function " & Lower (Function_Name));
            elsif Project_Tools.Text.Starts_With
              (Lower (Code), "end " & Lower (Function_Name))
            then
               In_Function := False;
            else
               declare
                  Value : constant String := Quoted_Return (Code);
               begin
                  if Value /= "" or else Project_Tools.Text.Contains (Code, "return """"") then
                     if Value = "" and then Allow_Empty then
                        null;
                     elsif Project_Tools.Text.Contains (To_String (Seen), Seen_Line (Value)) then
                        Fail
                          (Errors,
                           Source_Path & " has duplicate string return in "
                           & Function_Name & ": " & Value,
                           Quiet);
                     else
                        Append (Seen, Seen_Line (Value));
                     end if;
                  end if;
               end;
            end if;
         end;
      end loop;

      Ada.Text_IO.Close (File);
      if Errors > 0 then
         raise Program_Error;
      end if;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;

         if Errors > 0 then
            raise Program_Error;
         end if;

         raise;
   end Require_Unique_String_Returns;

   procedure Require_Only_Allowed_With_Clauses
     (Source_Path : String;
      Prefix      : String;
      Allowed     : String_List;
      Quiet       : Boolean := False)
   is
      File   : Ada.Text_IO.File_Type;
      Buffer : String (1 .. 4096);
      Last   : Natural;
      Errors : Natural := 0;

      function Starts_With_CI (Value : String; Prefix_Text : String) return Boolean is
      begin
         return Value'Length >= Prefix_Text'Length
           and then Lower (Value (Value'First .. Value'First + Prefix_Text'Length - 1))
             = Lower (Prefix_Text);
      end Starts_With_CI;

      function Allowed_Unit (Unit_Name : String) return Boolean is
      begin
         for Item of Allowed loop
            if Lower (Unit_Name) = Lower (To_String (Item)) then
               return True;
            end if;
         end loop;
         return False;
      end Allowed_Unit;

      function With_Payload (Line : String) return String is
         T : constant String := Trim (Line);
      begin
         if Starts_With_CI (T, "limited private with ") then
            return T (T'First + 21 .. T'Last);
         elsif Starts_With_CI (T, "limited with ") then
            return T (T'First + 13 .. T'Last);
         elsif Starts_With_CI (T, "private with ") then
            return T (T'First + 13 .. T'Last);
         elsif Starts_With_CI (T, "with ") then
            return T (T'First + 5 .. T'Last);
         else
            return "";
         end if;
      end With_Payload;

      procedure Error (Message : String) is
      begin
         Fail (Errors, Message, Quiet);
      end Error;

      procedure Check_Unit (Unit_Name : String) is
         Name : constant String := Trim (Unit_Name);
      begin
         if Name /= ""
           and then Starts_With_CI (Name, Prefix)
           and then not Allowed_Unit (Name)
         then
            Error (Source_Path & " imports disallowed unit " & Name);
         end if;
      end Check_Unit;

      procedure Check_With_Clause (Clause : String) is
         Text  : constant String := Trim (Clause);
         Semi  : constant Natural := Ada.Strings.Fixed.Index (Text, ";");
         Last_Unit : constant Natural :=
           (if Semi = 0 then Text'Last else Semi - 1);
         Start : Positive := Text'First;
      begin
         if Text = "" then
            return;
         end if;

         for I in Text'First .. Last_Unit loop
            if Text (I) = ',' then
               Check_Unit (Text (Start .. I - 1));
               Start := I + 1;
            end if;
         end loop;

         if Start <= Last_Unit then
            Check_Unit (Text (Start .. Last_Unit));
         end if;
      end Check_With_Clause;

   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Source_Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         Ada.Text_IO.Get_Line (File, Buffer, Last);
         declare
            Payload : constant String := With_Payload (Code_Prefix (Buffer (1 .. Last)));
         begin
            if Payload /= "" then
               declare
                  Clause : Unbounded_String := To_Unbounded_String (Payload);
               begin
                  while not Project_Tools.Text.Contains (To_String (Clause), ";")
                    and then not Ada.Text_IO.End_Of_File (File)
                  loop
                     Ada.Text_IO.Get_Line (File, Buffer, Last);
                     Append (Clause, " ");
                     Append (Clause, Trim (Code_Prefix (Buffer (1 .. Last))));
                  end loop;

                  Check_With_Clause (To_String (Clause));
               end;
            end if;
         end;
      end loop;

      Ada.Text_IO.Close (File);
      if Errors > 0 then
         raise Program_Error;
      end if;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;

         if Errors > 0 then
            raise Program_Error;
         end if;

         raise;
   end Require_Only_Allowed_With_Clauses;

   procedure Require_Public_GNATdoc_Tags
     (Spec_Path       : String;
      Stop_At_Private : Boolean := True;
      Tags_Before     : Boolean := True;
      Quiet           : Boolean := False)
   is
      File        : Ada.Text_IO.File_Type;
      Buffer      : String (1 .. 4096);
      Last        : Natural;
      Pending     : Unbounded_String;
      Has_Pending : Boolean := False;
      Preceding   : Unbounded_String;
      Errors      : Natural := 0;

      procedure Error (Message : String) is
      begin
         Errors := Errors + 1;
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
         if not Quiet then
            Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, "error: " & Message);
         end if;
      end Error;

      function Trim (Text : String) return String is
        (Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both));

      function Starts_With_Subprogram (Line : String) return Boolean is
         T : constant String := Trim (Line);
      begin
         return Project_Tools.Text.Starts_With (T, "function ")
           or else Project_Tools.Text.Starts_With (T, "procedure ");
      end Starts_With_Subprogram;

      function Paren_Balance (Text : String) return Integer is
         Result : Integer := 0;
      begin
         for C of Text loop
            if C = '(' then
               Result := Result + 1;
            elsif C = ')' then
               Result := Result - 1;
            end if;
         end loop;

         return Result;
      end Paren_Balance;

      function Next_Line (Line : out Unbounded_String) return Boolean is
      begin
         if Has_Pending then
            Line := Pending;
            Has_Pending := False;
            return True;
         end if;

         if Ada.Text_IO.End_Of_File (File) then
            return False;
         end if;

         Ada.Text_IO.Get_Line (File, Buffer, Last);
         Line := To_Unbounded_String (Buffer (1 .. Last));
         return True;
      end Next_Line;

      function Subprogram_Name (Declaration : String) return String is
         Function_Prefix  : constant String := "function ";
         Procedure_Prefix : constant String := "procedure ";
         T          : constant String := Trim (Declaration);
         Name_First : Positive := T'First;
         Name_Last  : Natural := 0;
      begin
         if Project_Tools.Text.Starts_With (T, Function_Prefix) then
            Name_First := T'First + Function_Prefix'Length;
         elsif Project_Tools.Text.Starts_With (T, Procedure_Prefix) then
            Name_First := T'First + Procedure_Prefix'Length;
         end if;

         for I in Name_First .. T'Last loop
            if T (I) = ' ' or else T (I) = '(' then
               Name_Last := I - 1;
               exit;
            end if;
         end loop;

         if Name_Last = 0 then
            Name_Last := T'Last;
         end if;

         return T (Name_First .. Name_Last);
      end Subprogram_Name;

      procedure Check_Param_Group
        (Subprogram : String;
         Comments   : String;
         Group      : String)
      is
         Colon : constant Natural := Ada.Strings.Fixed.Index (Group, ":");
      begin
         if Colon = 0 then
            return;
         end if;

         declare
            Names : constant String := Group (Group'First .. Colon - 1);
            Start : Positive := Names'First;
         begin
            for I in Names'Range loop
               if Names (I) = ',' then
                  declare
                     Name : constant String := Trim (Names (Start .. I - 1));
                  begin
                     if Name'Length > 0
                       and then not Project_Tools.Text.Contains (Comments, "@param " & Name)
                     then
                        Error ("public GNATdoc missing @param " & Name & " for " & Subprogram);
                     end if;
                  end;
                  Start := I + 1;
               end if;
            end loop;

            declare
               Name : constant String := Trim (Names (Start .. Names'Last));
            begin
               if Name'Length > 0
                 and then not Project_Tools.Text.Contains (Comments, "@param " & Name)
               then
                  Error ("public GNATdoc missing @param " & Name & " for " & Subprogram);
               end if;
            end;
         end;
      end Check_Param_Group;

      procedure Check_Declaration (Declaration : String; Comments : String) is
         Name        : constant String := Subprogram_Name (Declaration);
         Open_Paren  : constant Natural := Ada.Strings.Fixed.Index (Declaration, "(");
         Close_Paren : Natural := 0;
      begin
         if Project_Tools.Text.Starts_With (Trim (Declaration), "function ")
           and then not Project_Tools.Text.Contains (Comments, "@return")
         then
            Error ("public GNATdoc missing @return for " & Name);
         end if;

         if Open_Paren = 0 then
            return;
         end if;

         for I in reverse Open_Paren + 1 .. Declaration'Last loop
            if Declaration (I) = ')' then
               Close_Paren := I;
               exit;
            end if;
         end loop;

         if Close_Paren = 0 then
            Error ("public GNATdoc checker could not parse parameters for " & Name);
            return;
         end if;

         declare
            Params : constant String := Declaration (Open_Paren + 1 .. Close_Paren - 1);
            Start  : Positive := Params'First;
         begin
            for I in Params'Range loop
               if Params (I) = ';' then
                  Check_Param_Group (Name, Comments, Params (Start .. I - 1));
                  Start := I + 1;
               end if;
            end loop;

            Check_Param_Group (Name, Comments, Params (Start .. Params'Last));
         end;
      end Check_Declaration;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Spec_Path);
      while not Ada.Text_IO.End_Of_File (File) or else Has_Pending loop
         declare
            Line : Unbounded_String;
         begin
            exit when not Next_Line (Line);

            declare
               Text : constant String := To_String (Line);
            begin
               exit when Stop_At_Private and then Trim (Text) = "private";

               if Starts_With_Subprogram (Text) then
                  declare
                     Declaration : Unbounded_String := Line;
                     Comments    : Unbounded_String;
                     Comment_Line : Unbounded_String;
                     Balance     : Integer := Paren_Balance (Text);
                  begin
                     while Balance /= 0
                       or else not Project_Tools.Text.Ends_With (Trim (To_String (Declaration)), ";")
                     loop
                        exit when not Next_Line (Comment_Line);
                        Append (Declaration, " ");
                        declare
                           More : constant String := Trim (To_String (Comment_Line));
                        begin
                           Append (Declaration, More);
                           Balance := Balance + Paren_Balance (More);
                        end;
                     end loop;

                     if Tags_Before then
                        Comments := Preceding;
                     else
                        while Next_Line (Comment_Line) loop
                           declare
                              Comment_Text : constant String := Trim (To_String (Comment_Line));
                           begin
                              if Project_Tools.Text.Starts_With (Comment_Text, "--") then
                                 Append (Comments, Comment_Text);
                                 Append (Comments, " ");
                              else
                                 Pending := Comment_Line;
                                 Has_Pending := True;
                                 exit;
                              end if;
                           end;
                        end loop;
                     end if;

                     Check_Declaration (To_String (Declaration), To_String (Comments));
                     Preceding := Null_Unbounded_String;
                  end;
               elsif Project_Tools.Text.Starts_With (Trim (Text), "--") then
                  if Tags_Before then
                     Append (Preceding, Trim (Text));
                     Append (Preceding, " ");
                  end if;
               elsif Trim (Text) /= "" then
                  Preceding := Null_Unbounded_String;
               end if;
            end;
         end;
      end loop;

      Ada.Text_IO.Close (File);

      if Errors > 0 then
         raise Program_Error;
      end if;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;

         if Errors > 0 then
            raise Program_Error;
         end if;

         raise;
   end Require_Public_GNATdoc_Tags;
end Project_Tools.Ada_Source;
