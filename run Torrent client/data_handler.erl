-module(data_handler).
-export([handle_blocks/4,test/2,write_temp/2]).
-compile([export_all]).
-include("defs.hrl").
  test (Rec,Pid)->
    spawn(data_handler,handle_blocks,[Rec,dict:new(),Pid,true]).
  % A major function that plays the core role of putting the data together and writing them in the file. 
  handle_blocks(DataRec,FilesDict,Pid,true)-> % it is multiple

   receive 

    make_dict ->
	  {Files,_} = DataRec#torrent.files,
          Files_Dict = record_operation:files_dict(DataRec#torrent.filename,Files,FilesDict,1),
	  handle_blocks(DataRec,Files_Dict,Pid,true);	 
    {set_blocks,Default_path,[[Index,Begin,Block]|Tail]} -> 
    %  io:format("data_handler got set_block ~n"),
    %  io:format("in datahandler, Index: ~p~n", [Index]),
    %  io:format("in datahandler, Begin: ~p~n", [Begin]),
    %  io:format("in datahandler, Block: ~p~n", [Block]),
    %  io:format("in datahandler, Tail: ~p~n", [Tail]),
          write_temp(Default_path,[[Index,Begin,Block]|Tail]),
            Piece = get_allBlocks(Default_path,Index), % file is deleted afterwads
	 %  io:format("in datahandler, assembled Piece: ~p~n", [Piece]),
	 %  io:format("after get_all blocks: index:  ~p~n" , [Index]),
            Pieces = binary:bin_to_list(record_operation:get_pieces(DataRec)),
	 %  io:format("in datahandler, Pieces from record: ~p~n", [Pieces]),
          %% check hash value 
         case  check_hash(Piece,Index,Pieces) of
          % io:format("in datahandler in check_hash ~n"),
           false ->
           io:format("Piece is invalid~n"),
           handle_blocks(DataRec,FilesDict,Pid,true);
           %% The piece is ready to be written to file
           true ->
            io:format("piece is valid~n"),
             PieceLength = record_operation:get_Piece_Length(DataRec),
             Key = record_operation: findN(FilesDict,1,PieceLength*Index),
              case  is_LastPiece(DataRec,Index) of 
                   % it is not the last piece    
                   false ->
                      writer:write_files(Default_path,Piece,Index,PieceLength,FilesDict,Key,false),
                %     io:format("in datahandler: was written~n"),
                      Pid ! {ready_piece ,Index} ,
		      handle_blocks(DataRec,FilesDict,Pid,true);
		                 

                   % it is the last piece
                   true ->
                    writer:write_files(Default_path,Piece,Index,PieceLength,FilesDict,Key,true),
              %      io:format("was written"),
                     Pid ! {ready_piece ,Index} ,
		     handle_blocks(DataRec,FilesDict,Pid,true)

              end

          end ;
    {get_block,{Default_path,[Peid,Index,Begin,Length]}} ->  
       %    io:format("datahandler got get_block"),
       %    io:format("Peid: ~p~n, Index: ~p~n  Begin: ~p~n Length:  ~p~n",[Peid,Index,Begin,Length]),
           PieceLength = record_operation:get_Piece_Length(DataRec),
      %     io:format("PieceLength: ~p~n ",[PieceLength]),
           LPFlag =  data_handler:is_LastPiece(DataRec,Index),
      %     io:format("LPFlag: ~p~n" , [LPFlag]),
           Block = reader:read_files(Default_path,Begin,Length,Index,PieceLength,FilesDict,1,LPFlag),
         % io:format("this is the block: ~p~n",[Block]),
           Pid !  {block,[Peid,Index,Begin,Block]},
	   handle_blocks(DataRec,FilesDict,Pid,true)
            ; 
     stop ->
         stopped
 end ; 



 handle_blocks(DataRec,FilesDict,Pid,false)-> % it is single

   receive 

    {set_blocks,Default_path,[[Index,Begin,Block]|Tail]} -> 
      write_temp(Default_path,[[Index,Begin,Block]|Tail]),
           Piece = get_allBlocks(Default_path,Index), % file is deleted afterwads
         %%  io:format("after get_all blocks: index:  ~p~n" , [Index]),
           Pieces = binary:bin_to_list(record_operation:get_pieces(DataRec)),
         %% check hash value 
         case  check_hash(Piece,Index,Pieces) of

           false ->
                io:format("in data_handler: Piece is invalid~n"),
                handle_blocks(DataRec,FilesDict,Pid,false);
           %% The piece is ready to be written to file
           true ->
                   FileName = record_operation:get_FileName(DataRec),
                   PieceLength = record_operation:get_Piece_Length(DataRec),
		   writer:write_file(Default_path,Piece,Index,PieceLength,FileName),
	%%	   io:format("in  data_handler, piece was written~n"),

		   Pid ! {ready_piece ,Index} ,
	%%	    io:format("in data_handler: read_piece was sent to pid: ~p~n", [Pid]),

		   handle_blocks(DataRec,FilesDict,Pid,false)

          end ;
        {get_block,{Default_path,[Peid,Index,Begin,Length]}} ->
	   FileName = record_operation:get_FileName(DataRec),
           PieceLength = record_operation:get_Piece_Length(DataRec),
    %       io:format("datahandler got get_block"),
    %       io:format("Peid: ~p~n, Index: ~p~n  Begin: ~p~n Length:  ~p~n",[Peid,Index,Begin,Length]),
           Block =  reader:read_file(Default_path,Begin,Length,Index,PieceLength,FileName),
	   Pid !  {block,[Peid,Index,Begin,Block]},
	   handle_blocks(DataRec,FilesDict,Pid,false)
            ;   

        stop ->
        stopped
 end .


  write_temp(Dir,[[Ind,Begin,Block]])->
    Add = lists:concat([temp,Ind,'.',txt]),
    {ok, Io} = file:open(Dir++"/"++Add,[read,write,raw]),
    file:pwrite(Io, Begin, Block ),
    file:close(Io);    

  %% writes each block of data to its pre-defined order.
  write_temp(Dir,[[Ind,Begin,Block]|Tail])->
  %  io:format("in data_handler, tail: ~p~n",[Tail]),
  %  io:format("in data_handler,in write_temp: index is : ~p~n begin is :~p~n block length : ~p~n",[Ind,Begin,byte_size(Block)]),
    Add = lists:concat([temp,Ind,'.',txt]),
    {ok, Io} = file:open(Dir++"/"++Add,[read,write,raw]),
    {ok, Io} = file:open(Dir++"/"++"temp.txt",[read,write,raw]),
    file:pwrite(Io, Begin, Block ),
    file:close(Io),
    write_temp(Dir,Tail)
    .

  %% gets a block size and a file name and checks if the content
  %% of the file has the same size with piece size.
  %% is_complete(Dir,PieceSize)->
  %%   directory:set_wdir(Dir),
  %%   {ok,Bin} = file:read_file("temp.txt"),
  %%   Binsize = byte_size(Bin),
  %%   case PieceSize == Binsize of

  %%     true  ->
  %% 	    true;
  %%     false ->

  %%           false
  %%   end .


  %% retrieves the data stored in the temp.txt file and deletes the file.
  get_allBlocks(Dir,Index)-> 
    Add = lists:concat([Dir,'/',temp,Index,'.',txt]),
    {ok,Bin} = file:read_file(Add),
    file:delete(Add),
 %   io:format("in get_allblocks, after temp is deleted"),
    Bin
  .
  
  %% checks the SHA1 hash value of the returned data 
  %% to see if the data has the same hash value with what 
  %% has been declared in the torrent file.
  check_hash(Bin,Index,String)->
    crypto:start(),
    ShaValue1 = binary:bin_to_list(crypto:sha(Bin)),
  %  io:format("datahandler: before aithmatic operation ~n"),
  %  io:format("Bin: ~p~n",[Bin]),
  %  io:format("Index: ~p~n",[Index]), 
    ShaValue2 = lists:sublist(String,((Index*20)+1),20),
    io:format("ShaValue1: ~p , ShaValue2: ~p ~n" , [ShaValue1,ShaValue2]),
   case ShaValue1 == ShaValue2 of
      true -> 
      true;
      false ->
      false
   end
    .
  is_LastPiece(Rec,Index)->
     PieceNum = record_operation:get_PieceNum(Rec),
      case PieceNum-1 == Index of
        true ->
          true;
        false ->
          false
      end .

