package Project_Tools.Links is

   --  Is this path a symbolic link (or, on Windows, any reparse point)?
   --
   --  The body is selected per platform by the project file (Source_Dirs =
   --  "src-" & <host OS>). It cannot be answered portably: GNAT.OS_Lib's
   --  Is_Symbolic_Link is implemented with lstat, which mingw does not have, so
   --  on Windows it quietly answers False for every path -- including links.
   --  Windows must be asked through GetFileAttributes instead.
   --
   --  Anything that walks a directory tree needs this: a link to a directory
   --  looks exactly like a directory to Ada.Directories, so a tree holding a
   --  link back to one of its own ancestors recurses without end.

   function Is_Link (Path : String) return Boolean;
   --  @param Path the path to test
   --  @return True when Path is a symbolic link or reparse point

end Project_Tools.Links;
