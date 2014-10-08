-- Sample Program used to learn basics of how Ada works

with ada.text_io;   -- Tell compiler to use i/o library
use  ada.text_io;   -- Use library routines w/o fully qualified names

--with Ada.Text_IO, Ada.Integer_Text_IO, Ada.Float_Text_IO, GNAT.Regpat, Ada.Numerics.Elementary_Functions;
--use Ada.Text_IO, Ada.Integer_Text_IO, Ada.Float_Text_IO, GNAT.Regpat, Ada.Numerics.Elementary_Functions;

procedure sample is

  --Declaration of Edge Matrix
  type Edge_Matrix is array (Positive range <>, Positive range <>) of Boolean;
  type Edge_Matrix_Access is access Edge_Matrix;

  Edges : Edge_Matrix_Access;


begin
     -- example of printing lines (statements followed by newline)
     Put_Line("Hello World!");
     Put_Line("line2");


  Edges := new Edge_Matrix (1 .. 100, 1 .. 100);
  Edges.all := (others => (others => False));
  
  Edges (1,1) := true;


  declare
	--lineToprint : string := Integer'Image (0);
	--lineToprint : string := Boolean'Image (false) ;

	BoolValue : string := Boolean'Image (Edges (1,1) );

  begin
     Put_Line("Printing boolValue:");
     --Put_Line(lineToprint);

	--Print value of Edges(1,1), should be false
	Put_Line(BoolValue);

	--Change value of Edges(1,1) to true and print
	--Edges (1,1) := True;
	--BoolValue := Boolean'Image ( Edges (1,1) );
	--Put_Line(BoolValue);

	Put_Line("Print only if Edges (1,1) is false");
	if (Edges (1,1) = Edges (1,2)) then -- & (Edges (1,2) = false) then
		Put_Line("Hello");
	else
		Put_Line("Edge(1,1) was true");

	end if;


  end;

  --Put_Line( Integer'Image (1) );
  --Put_Line( Integer'Image ( Edges (1,1) ) );
  --put(Boolean'Image (Edges (1,1) ) );

  --Edges (1, 1) = True;

  --put(Edges (1,1)); 

	For_Loop:
	for I in Integer range 1 .. 5 loop
		Put_Line(Integer'Image (I) );
	end loop For_Loop;


end sample;
