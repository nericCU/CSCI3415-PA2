-- Sample Program used to learn basics of how Ada works

with ada.text_io;   -- Tell compiler to use i/o library
use  ada.text_io;   -- Use library routines w/o fully qualified names

procedure sample is
begin
     -- example of printing a statement
     put("Hello World!");
     put("line2?");
end sample;
