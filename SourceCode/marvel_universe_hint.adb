-- marvel_universe_hint.adb
-- CSCI3415-PA2: Analysis of Marvel Universe using the Ada Programming Language
-- Created by: (Professor) Douglas Milton
-- Modified by: Team 7- Eric Nguyen, Raphael O'Flynn, Gabriella Ramirez, Paul Rodriquez, Kyle Ryan
-- Last Modified: October-13-2014

with Ada.Text_IO, Ada.Integer_Text_IO, Ada.Float_Text_IO, GNAT.Regpat, Ada.Numerics.Elementary_Functions;
use Ada.Text_IO, Ada.Integer_Text_IO, Ada.Float_Text_IO, GNAT.Regpat, Ada.Numerics.Elementary_Functions;

procedure Marvel_Universe_Hint is

  --Declaration of input file
  Input_File_Name : constant String := "porgat.txt";
  Input_File : File_Type;

  --Declaration of Buffer String used to read input file
  Buffer : String (1 .. 100); -- This should be sufficient for us.
  Last : Natural; -- Used for determining the last element of a string
  
  --Declaration of variables to keep track of Number of Vertices and Number of Characters
  N_Vertices : Positive;
  N_Characters : Positive;

  --Declaration of Vertex Name Array
  type String_Access is access String;
  type Vertex_Name_Array is array (Positive range <>) of String_Access;
  type Vertex_Name_Array_Access is access Vertex_Name_Array;

  --forward declaration
  Vertex_Names : Vertex_Name_Array_Access;

  --Declaration of Edge Matrix
  type Edge_Matrix is array (Positive range <>, Positive range <>) of Boolean;
  type Edge_Matrix_Access is access Edge_Matrix;	

   --forward declaration
  Edges : Edge_Matrix_Access;

  --Declaration of Vector used to keep count of
  type Count_Vector is array (Positive range <>) of Natural;

  --Declaration of Collaboration Matrix
  type Collaboration_Matrix is array (Positive range <>, Positive range <>) of Natural;
  type Collaboration_Matrix_Access is access Collaboration_Matrix;

   --forward declaration
  Collaborations : Collaboration_Matrix_Access;

  --Implementation of Print_Statistics
  --Pre: takes a array of positive integers and a string
  --Post: displays minimum, maximum and standard deviation
  --Notes:
  procedure Print_Statistics (Counts : Count_Vector; Title : String) is
  
	--declaration 
    Minimum_Index : Positive := Counts'First;
    Minimum : Natural := Counts (Counts'First);
    Maximum_Index : Positive := Counts'First;
    Maximum : Natural := Counts (Counts'First);
    N : Natural := 0;
    Sum : Float := 0.0;
    Sum_Squares : Float := 0.0;
  begin
  
	-- finds max and min value within the array and their position within the array.
    for I in Counts'Range loop
      if Counts (I) < Minimum then
        Minimum_Index := I;
        Minimum := Counts (I);
      end if;
      if Counts (I) > Maximum then
        Maximum_Index := I;
        Maximum := Counts (I);
      end if;
	  
	  --sub-procedure
      declare
        X : Float := Float (Counts (I));
      begin
        N := N + 1;				--calculates number of iterations within count array
        Sum := Sum + X;				--calculates the sum of the values within count array
        Sum_Squares := Sum_Squares + X * X;	--calculates the squared sum of the values within count array
      end; --end sub-procedure
    end loop;
	
	--displays results
    Put_Line ("The minimum " & Title & " is " &
              Natural'Image (Minimum) & " (" &
              Vertex_Names (Minimum_Index).all & ").");  --maps Minimum_Index to Vertex_Names to display character or comic book name
    Put_Line ("The maximum " & Title & " is " &
              Natural'Image (Maximum) & " (" &
              Vertex_Names (Maximum_Index).all & ").");	 --maps Maximum_Index to Vertex_Names to display character or comic book name
	--Calculates and displays average and standard deviation from sub-procedure.
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
  --sub-procedure
  declare
    Matches : Match_Array (0 .. 2);
    Vertices_Regexp : constant string := "^\*Vertices (\d+) (\d+)$";    --regular expression to parse first line 
  begin
    Get_Line (Input_File, Buffer, Last);    --reads first line of Input_File
    Match (Compile (Vertices_Regexp), Buffer (1 .. Last), Matches);
    if Matches (0) = No_Match then    --exits if first line does not match *Vertices # #
      Put_Line ("*Vertices line was not found.");
      return;
    end if;
    N_Vertices := Positive'Value (Buffer (Matches (1).First .. Matches (1).Last));    --set value to number of vertices (character + comic books) from first line
    N_Characters := Positive'Value (Buffer (Matches (2).First .. Matches (2).Last));    --set value to number of character from first line
  end; --end sub-procedure
  
  Put_Line ("Number of vertices = " & Positive'Image (N_Vertices));    --displays number of vertices (character + comic books) 
  Put_Line ("Number of characters = " & Positive'Image (N_Characters));    --displays number of character
  --error checking for number of vertices (character + comic books) to be less than number of character
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
  --sub-procedure
  declare
    Matches : Match_Array (0 .. 2);
    Vertex_Regexp : constant String := "^(\d+) \""(.*)\""$";			--regular expression to parse a line (keeping name only)
    Vertex_Pattern_Matcher : Pattern_Matcher := Compile (Vertex_Regexp);	--compiles the regular expression
  begin 
    Put_Line ("Reading the vertex names.");
    for I in Vertex_Names'range loop							--loops through all the characters and comic books (N_Vertices)
      Get_Line (Input_File, Buffer, Last);						--read line from Input_File move into buffer
      Match (Vertex_Pattern_Matcher, Buffer (1 .. Last), Matches);			--parse buffer using regular expression
      if Matches (0) = No_Match then							--error checking (did not match regular expression requirement)
        Put_Line (Buffer (1 .. Last));
        Put_Line ("Failed to match vertex name regular expression.");
        return;
      end if;
      Vertex_Names (I) := new String'(Buffer (Matches (2).First .. Matches (2).Last));	--adds buffer to Vertex_Names (array of strings)
    end loop;
  end; --end sub-procedure

  --Used to output Vertex_Name index and Commic Names
  --for I in Vertex_Names'Range loop
    --Put_Line (Positive'Image (I) & " : " & Vertex_Names (I).all);
  --end loop;

  -- Read and parse the (trivial) *Edgeslist line.
  --sub-procedure
  --Note: does nothing unless *Edgeslist line isn't there
  declare
    Matches : Match_Array (0 .. 0);
    Edgeslist_Regexp : constant String := "^\*Edgeslist$";			--regular expression to parse *Edgeslist line
  begin
    Get_Line (Input_File, Buffer, Last);					--read line from Input_File move into buffer
    Match (Compile (Edgeslist_Regexp), Buffer (1 .. Last), Matches);
    if Matches (0) = No_Match then
      Put_Line ("*Edgelist line not found.");
      return;
    end if;
  end; --end sub-procedure

  -- Read and parse the edge lines and build the edge matrix.
  -- Since these are just space separated integers, we can use the standard
  -- IO routines. Note that we also specified the valid ranges for the Source
  -- and Target variables.
  --sub-procedure
  declare
    --Characters
    Source : Positive range 1 .. N_Characters;				--declaring an integer in the range of (1 to the number of characters) 
	--Comic books
    Target : Positive range N_Characters + 1 .. N_Vertices;		--declaring an integer in the range of (number of characters to the number vertices) 
  begin
    Put_Line ("Reading the edge matrix.");
    while not End_Of_File (Input_File) loop		--loop through remaining lines
      Get (Input_File, Source);
      while not End_Of_line (Input_File) loop		--loops through each line individually
        Get (Input_File, Target);
        Edges (Source, Target) := True;			--sets the matrix location to true (character, comic book)
      end loop;
    end loop;
  end; --end sub-procedure

  --used to print Edge list. Characters index along with their associated Commic index
  --for I in Edges'Range(1) loop
    --Put (Positive'Image (I));
    --for J in Edges'Range(2) loop
      --if Edges (I, J) then
        --Put (" " & Positive'Image (J));
      --end if;
    --end loop;
    --New_Line;
  --end loop;

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
    Character_Counts : Count_Vector (Edges'Range (1)) := (others => 0);		--declares a vector of positive numbers with the range of (edge's column size)
    Comic_Book_Counts : Count_Vector (Edges'Range (2)) := (others => 0);	--declares a vector of positive numbers with the range of (edge's row size)
  begin
    for I in Edges'Range (1) loop		--loops through every character
      for J in Edges'Range (2) loop		--loops through every comic book
        if Edges (I, J) then			--if the character was in the comic book (Edges (character, comic book) is true) then...
          Character_Counts (I) := Character_Counts (I) + 1;			--increments Character_Counts (number of comic books character(I) has been in) 
          Comic_Book_Counts (J) := Comic_Book_Counts (J) + 1;			--increments Comic_Book_Counts (number of characters in comic books(I)) 
        end if;
      end loop;
    end loop;
    Print_Statistics (Character_Counts, "comic books per character");		--calls Print_Statistics for character
    Print_Statistics (Comic_Book_Counts, "characters per comic book");		--calls Print_Statistics for comic books
  end; --end sub-procedure

-- Here is the code for "Total Number of Collaborations"

  --Definition of Edges
  --Edges := new Edge_Matrix (1 .. N_Characters, N_Characters + 1 .. N_Vertices);
  --Edges.all := (others => (others => False));

  --Declaration of Collaboration Matrix
  --type Collaboration_Matrix is array (Positive range <>, Positive range <>) of Natural;
  --type Collaboration_Matrix_Access is access Collaboration_Matrix;
   --forward declaration
  --Collaborations : Collaboration_Matrix_Access;

  --declare
    Collaborations := new Collaboration_Matrix (1 .. N_Characters, 1 .. N_Characters);
    Collaborations.all := (others => (others => 0));


  --begin
--    for j in Integer range 6487..19428 loop
--      for i in Integer range 1 .. 6200 loop --N_Characters loop      
      --for i in Integer range 1 .. 6485 loop --N_Characters loop
--        if Edges (i, j) = Edges ( i+1 , j) then
--          if Edges (i, j) = true then
		--used to print value of i
--            	Put_Line( Integer'Image(i) );
		--subtract 6486 to get index back in range
		--Collaborations (i-6485, i-6484) := Collaborations (i-6485, i-6484) + 1;		
		--Collaborations (i-6485, i-6484) := Collaborations (i-6485, i-6484) + 1;
--          end if;
--        end if;
--      end loop;
--    end loop;

  --end;


      --for J in Integer range 6487 .. 6490 loop --19428 loop
      --J will go from 6487 to 19428
      --for J in Integer range N_Characters + 1 .. N_Vertices loop
			--if J > 19429 then
        		  --Put_Line (Integer'Image (J) );
       			 --end if;
      --end loop commic_books_loop;

    commic_books_loop:
      for commicBook in Edges'Range(2) loop  -- values 6487 through 19428
        characters_loop:	
          for Hero in Edges'Range(1) loop  --values 1 through 6286
		if Edges (Hero, commicBook) = true then
			if Hero < N_Characters then  --stop before going over # of Characters (6486)
				if Edges (Hero, commicBook) = Edges (Hero +1, commicBook) then
					--Put_Line(Boolean'Image( Edges(Hero, commicBook) ) );
					Collaborations ( Hero, Hero+1) := Collaborations ( Hero, Hero+1) + 1;
				end if;
			end if;
		end if;
          end loop characters_loop;      
      end loop commic_books_loop;


	--if commicBook < 7000 then
	--	Put_Line( Boolean'Image ( Edges(1, commicBook) ) );
	--end if;


  --used to print Edge list. Characters index along with their associated Commic index
  --for M in Edges'Range(1) loop    --1 through 6486
    --Put (Positive'Image (M));
    --for bookname in Edges'Range(2) loop  --6487 through 19428
      --if Edges (M, N) then
        --Put (" " & Positive'Image (N));
      --end if;
	--if bookname <= 6500 then
	  --Put_Line(Integer'Image (bookname) );
	--end if;
    --end loop;
    --New_Line;
  --end loop;


  -- Here is the code for "Number of Collaborating Pairs"





  -- Here is the code for "Mean Number of Collaborations Per Character"








end Marvel_Universe_Hint;


