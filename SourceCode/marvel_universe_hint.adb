with Ada.Text_IO, Ada.Integer_Text_IO, Ada.Float_Text_IO, GNAT.Regpat, Ada.Numerics.Elementary_Functions;
use Ada.Text_IO, Ada.Integer_Text_IO, Ada.Float_Text_IO, GNAT.Regpat, Ada.Numerics.Elementary_Functions;

procedure Marvel_Universe_Hint is

  Input_File_Name : constant String := "porgat.txt";
  Input_File : File_Type;

  Buffer : String (1 .. 100); -- This should be sufficient for us.
  Last : Natural;

  N_Vertices : Positive;
  N_Characters : Positive;

  type String_Access is access String;
  type Vertex_Name_Array is array (Positive range <>) of String_Access;
  type Vertex_Name_Array_Access is access Vertex_Name_Array;

  Vertex_Names : Vertex_Name_Array_Access;

  type Edge_Matrix is array (Positive range <>, Positive range <>) of Boolean;
  type Edge_Matrix_Access is access Edge_Matrix;

  Edges : Edge_Matrix_Access;

  type Count_Vector is array (Positive range <>) of Natural;

  procedure Print_Statistics (Counts : Count_Vector; Title : String) is
    Minimum_Index : Positive := Counts'First;
    Minimum : Natural := Counts (Counts'First);
    Maximum_Index : Positive := Counts'First;
    Maximum : Natural := Counts (Counts'First);
    N : Natural := 0;
    Sum : Float := 0.0;
    Sum_Squares : Float := 0.0;
  begin
    for I in Counts'Range loop
      if Counts (I) < Minimum then
        Minimum_Index := I;
        Minimum := Counts (I);
      end if;
      if Counts (I) > Maximum then
        Maximum_Index := I;
        Maximum := Counts (I);
      end if;
      declare
        X : Float := Float (Counts (I));
      begin
        N := N + 1;
        Sum := Sum + X;
        Sum_Squares := Sum_Squares + X * X;
      end;
    end loop;
    Put_Line ("The minimum " & Title & " is " &
              Natural'Image (Minimum) & " (" &
              Vertex_Names (Minimum_Index).all & ").");
    Put_Line ("The maximum " & Title & " is " &
              Natural'Image (Maximum) & " (" &
              Vertex_Names (Maximum_Index).all & ").");
    Put ("The average " & Title & " is ");
    Put (Sum / (Float (N)), Fore => 1, Aft => 2, Exp => 0);
    Put_Line (".");
    Put ("The standard deviation of the " & Title & " is ");
    Put (Sqrt ((Sum_Squares - (Sum * Sum) / Float (N)) / Float (N - 1)),
         Fore => 1, Aft => 2, Exp => 0);
    Put_Line (".");
  end Print_Statistics;

begin

  -- Open the input file.
  Open (Input_File, In_File, Input_File_Name);
  Put_Line ("File " & Input_File_Name & " opened for input.");

  -- Read and parse the *Vertices line.
  declare
    Matches : Match_Array (0 .. 2);
    Vertices_Regexp : constant string := "^\*Vertices (\d+) (\d+)$";
  begin
    Get_Line (Input_File, Buffer, Last);
    Match (Compile (Vertices_Regexp), Buffer (1 .. Last), Matches);
    if Matches (0) = No_Match then
      Put_Line ("*Vertices line was not found.");
      return;
    end if;
    N_Vertices := Positive'Value (Buffer (Matches (1).First .. Matches (1).Last));
    N_Characters := Positive'Value (Buffer (Matches (2).First .. Matches (2).Last));
  end;
  Put_Line ("Number of vertices = " & Positive'Image (N_Vertices));
  Put_Line ("Number of characters = " & Positive'Image (N_Characters));
  if N_Characters > N_Vertices then
    Put_Line ("The number of characters must not exceed the number of vertices.");
    return;
  end if;

  -- Create the array of vertex names and the edge matrix. For the edge matrix
  -- we only store the upper right quadrant and initialize it to false;
  Put_Line ("Creating the vertex name vector and edge matrix.");
  -- We don't need to initialize the array of vertex names. (1) It's an array
  -- of access types, which are automatically initialized to null. (2) We
  -- set the values before they are used anyway.
  Vertex_Names := new Vertex_Name_Array (1 .. N_Vertices);
  -- We would like to create and initialize the edge matrix with the following
  -- statement, but it creates the contents on the stack and then copies it to
  -- newly created object. This overflows the stack with the default stack size
  -- and I didn't want to change the stack size.
  --Edges := new Edge_Matrix'(1 .. N_Characters => (N_Characters + 1 .. N_Vertices => False));
  Edges := new Edge_Matrix (1 .. N_Characters, N_Characters + 1 .. N_Vertices);
  Edges.all := (others => (others => False));

  -- Read and parse the vertex name lines and build the array of vertex names.
  declare
    Matches : Match_Array (0 .. 2);
    Vertex_Regexp : constant String := "^(\d+) \""(.*)\""$";
    Vertex_Pattern_Matcher : Pattern_Matcher := Compile (Vertex_Regexp);
  begin
    Put_Line ("Reading the vertex names.");
    for I in Vertex_Names'range loop
      Get_Line (Input_File, Buffer, Last);
      Match (Vertex_Pattern_Matcher, Buffer (1 .. Last), Matches);
      if Matches (0) = No_Match then
        Put_Line (Buffer (1 .. Last));
        Put_Line ("Failed to match vertex name regular expression.");
        return;
      end if;
      Vertex_Names (I) := new String'(Buffer (Matches (2).First .. Matches (2).Last));
    end loop;
  end;

--  for I in Vertex_Names'Range loop
--    Put_Line (Positive'Image (I) & " : " & Vertex_Names (I).all);
--  end loop;

  -- Read and parse the (trivial) *Edgeslist line.
  declare
    Matches : Match_Array (0 .. 0);
    Edgeslist_Regexp : constant String := "^\*Edgeslist$";
  begin
    Get_Line (Input_File, Buffer, Last);
    Match (Compile (Edgeslist_Regexp), Buffer (1 .. Last), Matches);
    if Matches (0) = No_Match then
      Put_Line ("*Edgelist line not found.");
      return;
    end if;
  end;

  -- Read and parse the edge lines and build the edge matrix.
  -- Since these are just space separated integers, we can use the standard
  -- IO routines. Note that we also specified the valid ranges for the Source
  -- and Target variables.
  declare
    Source : Positive range 1 .. N_Characters;
    Target : Positive range N_Characters + 1 .. N_Vertices;
  begin
    Put_Line ("Reading the edge matrix.");
    while not End_Of_File (Input_File) loop
      Get (Input_File, Source);
      while not End_Of_line (Input_File) loop
        Get (Input_File, Target);
        Edges (Source, Target) := True;
      end loop;
    end loop;
  end;

--  for I in Edges'Range(1) loop
--    Put (Positive'Image (I));
--    for J in Edges'Range(2) loop
--      if Edges (I, J) then
--        Put (" " & Positive'Image (J));
--      end if;
--    end loop;
--    New_Line;
--  end loop;

  -- Close the input file.
  Close (Input_File);

  -- Print the results.

  -- Print the number of characters and the number of comic books.
  Put_Line ("The number of characters is " &
            Positive'Image (N_Characters) & ".");
  Put_Line ("The number of comic books is " &
            Positive'Image (N_Vertices - N_Characters) & ".");

  -- Gather the character and comic book statistics and print them.
  declare
    Character_Counts : Count_Vector (Edges'Range (1)) := (others => 0);
    Comic_Book_Counts : Count_Vector (Edges'Range (2)) := (others => 0);
  begin
    for I in Edges'Range (1) loop
      for J in Edges'Range (2) loop
        if Edges (I, J) then
          Character_Counts (I) := Character_Counts (I) + 1;
          Comic_Book_Counts (J) := Comic_Book_Counts (J) + 1;
        end if;
      end loop;
    end loop;
    Print_Statistics (Character_Counts, "comic books per character");
    Print_Statistics (Comic_Book_Counts, "characters per comic book");
  end;

  -- Your code to do the other processing will go here.

end Marvel_Universe_Hint;

