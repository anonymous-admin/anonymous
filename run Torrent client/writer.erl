-module(writer).
-export([write_pieces/6,write_Lpiece/5,write_files/7,write_file/5]).
-record (files_data,{filename,path,size,passed_bytes}).
-include("defs.hrl").

   
   write_files(DefPath,Bin_Piece,Piece_index,PieceSize,Files_dict,N,false)-> % it is not the last piece
         %% io:format("in the write files function ~n"),
         %% io:format("DefPath: ~p~n",[DefPath]),
         %% io:format("Bin_Piece: ~p~n",[Bin_Piece]),
         %% io:format("Piece_index: ~p~n",[Piece_index]),
         %% io:format("PieceSize: ~p~n",[PieceSize]),
         %% io:format("Files_dict: ~p~n",[Files_dict]),
         %% io:format("N: ~p~n",[N]),
         write_pieces(DefPath,Bin_Piece,Piece_index,PieceSize,Files_dict,N); 
   write_files(DefPath,Bin_Piece,Piece_index,PieceSize,Files_dict,_N,true)-> % it is the last piece
         write_Lpiece(DefPath,Bin_Piece,Piece_index,PieceSize,Files_dict)% Piece size has to be a normal one even here!!!!!           
  .
 
   write_Lpiece(DefPath,Bin_Piece,Piece_index,PieceSize,Files_dict)-> % The starting position has to be based on a normal piece even here!!!!!!!
        %%  this is the last piece
          {ok,Rec} = dict:find(dict:size(Files_dict),Files_dict),
           Path = Rec#files_data.path,
           Name = Rec#files_data.filename,
          {ok,Io} = file:open(DefPath++"/"++ Path ++ "/"++Name,[read,write,raw]),
          file:pwrite(Io,Piece_index * PieceSize,Bin_Piece),
          file:close(Io).

   write_pieces(DefPath,Bin_Piece,Piece_index,PieceSize,Files_dict,N)->
	%%  io:format("in the write_pieces~n"),
        %%  io:format("DefPath: ~p~n",[DefPath]),
        %%  io:format("Bin_Piece: ~p~n",[Bin_Piece]),
        %%  io:format("Piece_index: ~p~n",[Piece_index]),
        %%  io:format("PieceSize: ~p~n",[PieceSize]),
        %%  io:format("Files_dict: ~p~n",[Files_dict]),
        %%  io:format("N: ~p~n",[N]),
        %%  this is not the last piece
	  Start_Position = Piece_index * PieceSize,
    %      io:format("Start_position: ~p~n",[Start_Position]),
	  {ok,Rec} = dict:find(N,Files_dict),
    %      io:format("FileRec: ~p~n",[Rec]),
 
	   case  Start_Position =< ((Rec#files_data.passed_bytes + Rec#files_data.size) - 1) of

             %% if this is the right file to write to.
	       
             true ->
%		io:format("this is the right file to write to ~n"),
      		 case ((Start_Position + PieceSize)=<(Rec#files_data.passed_bytes + Rec#files_data.size))  of 
                    %% if the file can include the whole piece 
                    true ->
%			io:format("file can include the whole piece ~n"),
			 Path = Rec#files_data.path,
			 Name = Rec#files_data.filename,
			 {ok,Io} = file:open(DefPath++"/"++ Path ++ "/"++Name,[read,write,raw]),
                         file:pwrite(Io,Start_Position,Bin_Piece),
 %                        io:format("in the write_pieces: piece was written ~n"),
                         file:close(Io)  
                     	  ;
                    %% if the file can include some of the piece
                    false ->
                           Allowed = ((Rec#files_data.passed_bytes + Rec#files_data.size) - Start_Position),
  %                         io:format("allowed bytes:  ~p~n",[Allowed]),
                           case Allowed /= PieceSize-1 of
                             true ->				   
                                Part1 = binary:part(Bin_Piece,0,Allowed),
%				io:format("before part2"),
                                Part2 = binary:part(Bin_Piece,Allowed,PieceSize-Allowed),
%			        io:format("after part2"),
			        Path = Rec#files_data.path,
				Name = Rec#files_data.filename,
				{ok,Io} = file:open(DefPath++"/"++ Path ++ "/"++Name,[read,write,raw]),                                
                                file:pwrite(Io,Start_Position,Part1),
                                file:close(Io), 
                                write_pieces(DefPath,Part2,0,PieceSize,Files_dict,N+1);		 
			     false ->
                                Part1 = binary:part(Bin_Piece,0,Allowed),
                                Part2 = binary:last(Bin_Piece),
			        Path = Rec#files_data.path,
				Name = Rec#files_data.filename,
				{ok,Io} = file:open(DefPath++"/"++ Path ++ "/"++Name,[read,write,raw]),  
                                file:pwrite(Io,Start_Position,Part1),
                                file:close(Io), 
                                write_pieces(DefPath,Part2,0,PieceSize,Files_dict,N+1) 
			   end
			 
                 end;
             %% if this is not the right file to write to.
             false ->
%		io:format("this is not the write file to write to"),
		write_pieces(DefPath,Bin_Piece,Piece_index,PieceSize,Files_dict,N+1)	  
	   end 	.


   write_file(DefPath,Bin_Piece,Piece_index,PieceSize,FileName)->
  %   io:format("in the writefile: ~n"),
     Start_Position = Piece_index * PieceSize, 
 %    io:format("Start_Position: ~p~n",[Start_Position]),
 %    io:format("DefPath: ~p~n" , [DefPath]),
 %    io:format("Bin_Piece: ~p~n", [Bin_Piece]),
     %% io:format("Piece_index: ~p~n",[PieceSize]),
     %% io:format("PieceSize: ~p~n",[PieceSize]),
     %% io:format("FileName: ~p~n",[FileName]),
	
     {ok,Io} = file:open(DefPath++"/"++FileName,[read,write,raw]),
     file:pwrite(Io,Start_Position,Bin_Piece),
 %    io:format("Piece was written: ~n"),
     file:close(Io).
	 
