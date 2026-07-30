package Project_Tools.Generated_Docs is
   function Equivalent_Text
     (Stored    : String;
      Generated : String)
      return Boolean;
   --  Compare generated text while tolerating exactly one trailing newline
   --  difference.
   --  @param Stored Text as it stands in the repository.
   --  @param Generated Text as the generator produces it now.
   --  @return True when they agree, ignoring one trailing newline.

   procedure Require_Current
     (Errors    : in out Natural;
      Stored    : String;
      Generated : String;
      Message   : String;
      Quiet     : Boolean := False);
   --  Increment Errors when Stored is stale relative to Generated.
   --  @param Errors Error counter incremented when the stored text is stale.
   --  @param Stored Text as it stands in the repository.
   --  @param Generated Text as the generator produces it now.
   --  @param Message Description of what drifted, for the diagnostic.
   --  @param Quiet Suppress diagnostics when True.

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
   --  @param Errors Error counter incremented for each metadata failure.
   --  @param Root Project root the paths are resolved against.
   --  @param Manifest_Path Manifest describing the generated documents.
   --  @param Checker_Source_Path Checker whose switches must expose the
   --         commands the manifest names.
   --  @param Required_Command_Prefix Prefix every such command must carry.
   --  @param Minimum_Entries Fewest entries the manifest may hold.
   --  @param Quiet Suppress diagnostics when True.
end Project_Tools.Generated_Docs;
