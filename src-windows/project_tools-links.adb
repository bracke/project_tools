with Interfaces.C.Strings;

package body Project_Tools.Links is

   use type Interfaces.C.unsigned_long;
   use type Interfaces.C.Strings.chars_ptr;

   --  GNAT.OS_Lib.Is_Symbolic_Link is lstat-based, and mingw has no lstat: it
   --  answers False for every path here, links included. Ask Windows directly.

   Invalid_Attributes : constant Interfaces.C.unsigned_long := 16#FFFF_FFFF#;
   Attribute_Reparse  : constant Interfaces.C.unsigned_long := 16#0000_0400#;
   --  FILE_ATTRIBUTE_REPARSE_POINT covers symbolic links and directory
   --  junctions alike, which is what a tree walk must refuse to follow.

   function Get_File_Attributes
     (Name : Interfaces.C.Strings.chars_ptr)
      return Interfaces.C.unsigned_long
     with Import, Convention => Stdcall,
          External_Name => "GetFileAttributesA";

   function Is_Link (Path : String) return Boolean is
      C_Path     : Interfaces.C.Strings.chars_ptr :=
        Interfaces.C.Strings.New_String (Path);
      Attributes : Interfaces.C.unsigned_long;
   begin
      Attributes := Get_File_Attributes (C_Path);
      Interfaces.C.Strings.Free (C_Path);

      if Attributes = Invalid_Attributes then
         return False;
      end if;

      return (Attributes and Attribute_Reparse) /= 0;

   exception
      when others =>
         if C_Path /= Interfaces.C.Strings.Null_Ptr then
            Interfaces.C.Strings.Free (C_Path);
         end if;
         return False;
   end Is_Link;

end Project_Tools.Links;
