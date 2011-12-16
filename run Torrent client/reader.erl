-module(reader).
-export([read_files/8,read_file/6]).
-record (files_data,{filename,path,size,passed_bytes}).
 read_files(DefPath,Begin,Block_length,Piece_index, PieceSize, Files_dict, N,false)-> %  it is not the last piece
     %    io:format("in the read_files function ~n"),
      %  io:format("DefPath: ~p~n",[DefPath]),
   %      io:format("Block_length: ~p~n",[Block_length]),
    %     io:format("Piece_index: ~p~n",[Piece_index]),
    %     io:format("PieceSize: ~p~n",[PieceSize]),
     %   io:format("Files_dict: ~p~n",[Files_dict]),
     %    io:format("N: ~p~n",[N]),
       BlockList = read_pieces(DefPath,Begin,Block_length,Piece_index,PieceSize,Files_dict,N,[]),
       list_to_binary(BlockList)
       ; 
 read_files(DefPath,Begin,Block_Length,Piece_index,PieceSize,Files_dict,_N,true)-> % it is the last piece
    BlockList = read_Lpiece(DefPath,Begin,Block_Length,Piece_index,PieceSize,Files_dict),% Piece size has to be a normal one even here!!!!! 
    list_to_binary(BlockList)
  .

 read_pieces(DefPath,Begin,Block_length,Piece_index,PieceSize,Files_dict,N,List)->
     %% 	io:format("in the read_pieces~n"),
     %% %    io:format("DefPath: ~p~n",[DefPath]),
     %%     io:format("Block_length: ~p~n",[Block_length]),
     %%     io:format("Piece_index: ~p~n",[Piece_index]),
     %%     io:format("PieceSize: ~p~n",[PieceSize]),
     %% %    io:format("Files_dict: ~p~n",[Files_dict]),
     %%     io:format("N: ~p~n",[N]),
        %% this is not the last piece
	  Start_Position = (Piece_index * PieceSize)+Begin,
     %%     io:format("Start_position: ~p~n",[Start_Position]),
	  {ok,Rec} = dict:find(N,Files_dict),
    %%       io:format("FileRec: ~p~n",[Rec]),
 
	   case  Start_Position =< ((Rec#files_data.passed_bytes + Rec#files_data.size) - 1) of

             %% if this is the right file to read from.
	       
             true ->
%%		io:format("this is the right file to read from ~n"),
      		 case ((Start_Position + PieceSize)=<(Rec#files_data.passed_bytes + Rec#files_data.size))  of 
                    %% if the file can include the whole piece 
                    true ->
	%%		io:format("file can include the whole piece ~n"),
			 Path = Rec#files_data.path,
	%%		 io:format("Path: ~p~n",[Path]),
			 Name = Rec#files_data.filename,
	%%		 io:format("Name: ~p~n",[Name]),
			 {ok,Io} = file:open(DefPath++"/"++ Path ++ "/"++Name,[read,write,raw]),
	%%		 io:format("io:  ~p~n",[Io]),
                         {Er, Block} = file:pread(Io,Start_Position,Block_length),
		%	 io:format("Er: ~p , Block: ~p~n",[Er,Block]),
		%	 io:format("block:  ~p~n",[Block]),
                %         io:format("in the read_pieces: piece was read and is: ~p ~n",[Block]),
                         file:close(Io),
                         List++[Block]  
                     	  ;
                    %% if the file can include some of the piece
                    false ->

                       case (Start_Position + Block_length) =< (Rec#files_data.passed_bytes + Rec#files_data.size) of 
			  true ->
          %%                io:format("The whole block is included in this file"),
			  Path = Rec#files_data.path,
				Name = Rec#files_data.filename,
				{ok,Io} = file:open(DefPath++"/"++ Path ++ "/"++Name,[read,write,raw]),                                
                                {ok,Block} = file:pread(Io,Start_Position,Block_length),
                                file:close(Io),
                                Block 
			        ; 
                          false ->
	%%		   io:format("some of the block is included in this file"),
                           Allowed = ((Rec#files_data.passed_bytes + Rec#files_data.size) - Start_Position),
         %%                  io:format("allowed bytes:  ~p~n",[Allowed]),				   
			        Path = Rec#files_data.path,
				Name = Rec#files_data.filename,
				{ok,Io} = file:open(DefPath++"/"++ Path ++ "/"++Name,[read,write,raw]),                                
                                {Er,Block} = file:pread(Io,Start_Position,Allowed),
	%%		        io:format("Er: ~p" , [Er]),
                                file:close(Io), 
                                read_pieces(DefPath,0 ,Block_length-Allowed ,0,PieceSize,Files_dict,N+1,List ++ Block)		 
			   
			 end
                 end;
             %% if this is not the right file to write to.
             false ->
	%%	io:format("this is not the right file to read from"),
		read_pieces(DefPath,Begin,Block_length,Piece_index,PieceSize,Files_dict,N+1,List)	  
	   end 	. 


 read_Lpiece(DefPath,Begin,Block_length,Piece_index,PieceSize,Files_dict)-> % The starting position has to be based on a normal piece even here!!!!!!!
        %%  this is the last piece
          {ok,Rec} = dict:find(dict:size(Files_dict),Files_dict),
          Path = Rec#files_data.path,
          Name = Rec#files_data.filename,
          {ok,Io} = file:open(DefPath++"/"++ Path ++ "/"++Name,[read,write,raw]),
          io:format("in read_Lpiece, Block_length:  ~p~n" , [Block_length]),
          {ok, Block} = file:pread(Io,(Piece_index * PieceSize)+ Begin,Block_length),
        %  io:format("block was read and is: ~p~n",[Block]),
          file:close(Io),
          Block
   .
 

 read_file(DefPath,Begin,Block_length,Piece_index,PieceSize,FileName)->
 %%    io:format("in the read_file: ~n"),
     Start_Position = (Piece_index * PieceSize)+Begin, 
     %% io:format("Start_Position: ~p~n",[Start_Position]),
     %% io:format("DefPath: ~p~n" , [DefPath]),
     %% io:format("Block_length: ~p~n", [Block_length]),
     %% io:format("Piece_index: ~p~n",[Piece_index]),
     %% io:format("PieceSize: ~p~n",[PieceSize]),
     %% io:format("FileName: ~p~n",[FileName]),
     {ok,Io} = file:open(DefPath++"/"++FileName,[read,write,raw]),
     {ok,Block} = file:pread(Io,Start_Position,Block_length),
     %% io:format("Piece was read: ~n"),
     %% io:format("Piece Is: ~p~n",[Block]),
     file:close(Io),
     Block .
