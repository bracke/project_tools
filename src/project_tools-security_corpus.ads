with Ada.Directories;
with Project_Tools.Files;

package Project_Tools.Security_Corpus is
   subtype Text_List is Project_Tools.Files.Name_List;

   procedure Check_Corpus
     (Errors                   : in out Natural;
      Corpus                   : String;
      Required_Categories      : Text_List;
      Forbidden_Secret_Tokens  : Text_List;
      Required_README_Tokens   : Text_List;
      Max_Entry_Size           : Ada.Directories.File_Size;
      Quiet                    : Boolean := False);
   --  Check a deterministic security/adversarial corpus directory layout.
   --  @param Errors Error counter incremented for each corpus violation.
   --  @param Corpus Root corpus directory.
   --  @param Required_Categories Category directory names required below Corpus.
   --  @param Forbidden_Secret_Tokens Tokens that indicate accidental secret material.
   --  @param Required_README_Tokens Tokens that must appear in Corpus/README.md.
   --  @param Max_Entry_Size Maximum allowed ordinary-file corpus entry size.
   --  @param Quiet Suppress diagnostics when True.
end Project_Tools.Security_Corpus;
