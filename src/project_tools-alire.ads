with GNAT.OS_Lib;

package Project_Tools.Alire is
   --  Argument lists for driving alr from a check program, with the switches
   --  that stop it asking questions. A gate that blocks on a prompt is a gate
   --  that hangs a CI run rather than failing it.

   function Noninteractive_Update_Args return GNAT.OS_Lib.Argument_List;
   --  @return Arguments for "alr update" that will not prompt.

   function Noninteractive_Build_Args return GNAT.OS_Lib.Argument_List;
   --  @return Arguments for "alr build" that will not prompt.

   function Noninteractive_Exec_Args
     (Args : GNAT.OS_Lib.Argument_List)
      return GNAT.OS_Lib.Argument_List;
   --  @param Args The command and its arguments to run under "alr exec".
   --  @return Args preceded by the exec switches that will not prompt.
end Project_Tools.Alire;
