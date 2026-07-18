package Project_Tools.Generated_Docs is
   function Equivalent_Text
     (Stored    : String;
      Generated : String)
      return Boolean;
   --  Compare generated text while tolerating exactly one trailing newline
   --  difference.

   procedure Require_Current
     (Errors    : in out Natural;
      Stored    : String;
      Generated : String;
      Message   : String;
      Quiet     : Boolean := False);
   --  Increment Errors when Stored is stale relative to Generated.

   procedure Check_Docs_Manifest
     (Errors                  : in out Natural;
      Root                    : String;
      Manifest_Path           : String;
      Checker_Source_Path     : String;
      Required_Command_Prefix : String;
      Minimum_Entries         : Natural;
      Quiet                   : Boolean := False);
   --  Validate generated-doc metadata and that command switches are exposed by
   --  the checker source.
end Project_Tools.Generated_Docs;
