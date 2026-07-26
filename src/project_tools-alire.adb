package body Project_Tools.Alire is
   function Noninteractive_Update_Args return GNAT.OS_Lib.Argument_List is
   begin
      return
        [1 => new String'("--non-interactive"),
         2 => new String'("update")];
   end Noninteractive_Update_Args;

   function Noninteractive_Build_Args return GNAT.OS_Lib.Argument_List is
   begin
      return
        [1 => new String'("--non-interactive"),
         2 => new String'("build")];
   end Noninteractive_Build_Args;

   function Noninteractive_Exec_Args
     (Args : GNAT.OS_Lib.Argument_List)
      return GNAT.OS_Lib.Argument_List
   is
      Result : GNAT.OS_Lib.Argument_List (1 .. Args'Length + 3);
   begin
      Result (1) := new String'("--non-interactive");
      Result (2) := new String'("exec");
      Result (3) := new String'("--");

      for Index in Args'Range loop
         Result (Index - Args'First + 4) := new String'(Args (Index).all);
      end loop;

      return Result;
   end Noninteractive_Exec_Args;
end Project_Tools.Alire;
