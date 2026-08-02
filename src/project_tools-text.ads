with Ada.Strings.Unbounded;

package Project_Tools.Text is
   function Contains (Text : String; Pattern : String) return Boolean
     with SPARK_Mode => On;
   --  @param Text Text to search.
   --  @param Pattern Pattern to find.
   --  @return True when Pattern occurs in Text.

   function Count (Text : String; Pattern : String) return Natural
     with SPARK_Mode => On;
   --  @param Text Text to search.
   --  @param Pattern Pattern to count.
   --  @return Number of non-overlapping Pattern occurrences in Text.

   function Index (Text : String; Pattern : String) return Natural
     with SPARK_Mode => On;
   --  @param Text Text to search.
   --  @param Pattern Pattern to find.
   --  @return Index of the first occurrence of Pattern in Text, or 0 when
   --          Pattern is absent or empty.

   function Index_From (Text : String; Pattern : String; From : Positive) return Natural;
   --  @param Text Text to search.
   --  @param Pattern Pattern to find.
   --  @param From Index in Text at which to begin searching.
   --  @return Index of the first occurrence of Pattern at or after From, or 0
   --          when Pattern is absent or From is past the end of Text.

   function Starts_With (Value : String; Prefix : String) return Boolean
     with SPARK_Mode => On;
   --  @param Value String to test.
   --  @param Prefix Required leading substring.
   --  @return True when Value begins with Prefix.

   function Ends_With (Value : String; Suffix : String) return Boolean
     with SPARK_Mode => On;
   --  @param Value String to test.
   --  @param Suffix Required trailing substring.
   --  @return True when Value ends with Suffix.

   function Line_Value
     (Text      : String;
      Key       : String;
      Separator : String := " =")
      return String;
   --  Return the value from the first line beginning with Key & Separator.
   --  A single blank after the separator is skipped. This is for simple
   --  generated/catalog text checks, not for structured formats such as TOML.
   --  @param Text Text containing line-feed separated key/value lines.
   --  @param Key Key that must appear at the start of a line.
   --  @param Separator Text between Key and the value.
   --  @return The remainder of the matching line, or "" when absent.

   function Read_Text_File (Path : String) return Ada.Strings.Unbounded.Unbounded_String;
   --  @param Path File path to read.
   --  @return File contents with line-feed separators, or an empty string on read failure.
end Project_Tools.Text;
