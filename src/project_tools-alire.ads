with GNAT.OS_Lib;

package Project_Tools.Alire is
   function Noninteractive_Update_Args return GNAT.OS_Lib.Argument_List;
   function Noninteractive_Build_Args return GNAT.OS_Lib.Argument_List;
   function Noninteractive_Exec_Args
     (Args : GNAT.OS_Lib.Argument_List)
      return GNAT.OS_Lib.Argument_List;
end Project_Tools.Alire;
