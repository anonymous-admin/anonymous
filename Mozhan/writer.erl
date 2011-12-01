-module(writer).
-export([write_files/6,test/0]).
-record (files_data,{filename,path,size,passed_bytes}).

 test()-> % not complete!
  %% please note that a parent directory must be set first.
  Rec1 = #files_data{filename = "1.txt" , path = "a\\b\\c" , size = 5 , passed_bytes = 0},
  Rec2 = #files_data{filename = "2.txt" , path = "a\\b\\c" , size = 20 , passed_bytes = 20},
  Dic1 = dict:new(),
  Dic2 = dict:store(1,Rec1,Dic1),
  Dic3 = dict:store(2,Rec2,Dic2),
  write_files(<<1,2,3>>,1,3,1,Dic3,1)
 .
   write_files(Bin_Piece,Piece_index,PieceSize,PieceSize,Files_dict,N)->
        %%  this is the last piece
          {ok,Rec} = dict:find(dict:size(Files_dict),Files_dict),
          directory:set_wdir(Rec#files_data.path),
          {ok,Io} = file:open(Rec#files_data.filename,[read,write,raw]),
          file:pwrite(Io,Piece_index * PieceSize,Bin_Piece),
          file:close(Io)  
	  ;
   write_files(Bin_Piece,Piece_index,PieceSize,LPiece_length,Files_dict,N)->
        %% this is not the last piece
	  Start_Position = Piece_index * PieceSize,
	  {ok,Rec} = dict:find(N,Files_dict),
	   case  Start_Position =< ((Rec#files_data.passed_bytes + Rec#files_data.size) - 1) of
             %% if this is the right file to write to.
             true ->
      		 case ((Start_Position + PieceSize)=<((Rec#files_data.passed_bytes + Rec#files_data.size)-1))  of 
                    %% if the file can include the whole piece 
                    true ->
		         directory:set_wdir(Rec#files_data.path),
                         {ok,Io} = file:open(Rec#files_data.filename,[read,write,raw]),
                         file:pwrite(Io,Start_Position,Bin_Piece),
                         file:close(Io)  
                     	  ;
                    %% if the file can include some of the piece
                    false ->
                         Allowed = (((Rec#files_data.passed_bytes + Rec#files_data.size)-1) - Start_Position),
                           case Allowed /= PieceSize-1 of
                             true ->				   
                                Part1 = binary:part(Bin_Piece,0,Allowed-1),
                                Part2 = binary:part(Bin_Piece,Allowed,PieceSize-1),
		         	directory:set_wdir(Rec#files_data.path),
                                {ok,Io} = file:open(Rec#files_data.filename,[read,write,raw]),
                                file:pwrite(Io,Start_Position,Part1),
                                file:close(Io), 
                                write_files(Part2,Piece_index,PieceSize,LPiece_length,Files_dict,N+1);		 
			     false ->
                                Part1 = binary:part(Bin_Piece,0,Allowed-1),
                                Part2 = binary:last(Bin_Piece),
		         	directory:set_wdir(Rec#files_data.path),
                                {ok,Io} = file:open(Rec#files_data.filename,[read,write,raw]),
                                file:pwrite(Io,Start_Position,Part1),
                                file:close(Io), 
                                write_files(Part2,Piece_index,PieceSize,LPiece_length,Files_dict,N+1) 
			   end
			 
                 end;
             %% if this is not the right file to write to.
             false ->
		write_files(Bin_Piece,Piece_index,PieceSize,LPiece_length,Files_dict,N+1)	  
	   end 	.


   write_file(Bin_Piece,Piece_index,PieceSize,FileName)->
     Start_Position = Piece_index * PieceSize,
     {ok,Io} = file:open(FileName,[read,write,raw]),
     file:pwrite(Io,Start_Position,Bin_Piece),
     file:close(Io) ;
	 
