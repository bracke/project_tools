package body Project_Tools.Links is

   --  No way to ask; assume nothing is a link.

   function Is_Link (Path : String) return Boolean is
      pragma Unreferenced (Path);
   begin
      return False;
   end Is_Link;

end Project_Tools.Links;
