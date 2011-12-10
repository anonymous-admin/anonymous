-module(data_handler).
-export([handle_blocks/4]).
-record(torrent,{filename ,files,number_of_pieces}).
 
  % A major function that plays the core role. %% should be spawned with an empty dict from main
  %%%%% This process has to get linked to the main one and if it terminates abnormaly, it should be started with the
  %%%%%% last dict it has passed.
  handle_blocks(DataRec,FilesDict,Pid,true)-> % it is multiple

   receive 

    make_dict ->
          Files_Dict = record_operation:files_dict(DataRec#torrent.files,FilesDict,1),
	  handle_blocks(DataRec,Files_Dict,Pid,true);	 
    {set_block,Default_path,Index,Begin,Binary} ->
      write_temp(Default_path,Begin,Binary),
       case is_ready(Default_path,DataRec,Index) of 
         % The piece is full
         true ->
           Piece = get_allBlocks(Default_path), % file is deleted afterwads
          %% check hash value 
         case  check_hash(Piece,Index,record_operation:get_pieces(DataRec)) of

           false ->
           io:format("Piece is invalid");

           %% The piece is ready to be written to file
           true ->
             PieceLength = record_operation:get_Piece_Length(DataRec),
             Key = record_operation: findN(FilesDict,1,PieceLength*Index),
              case  is_LastPiece(DataRec,Index) of 
                   % it is not the last piece    
                   false ->
                      writer:write_files(Piece,Index,PieceLength,FilesDict,Key,false),
                      Pid ! {ready_piece ,Index} ,
		      handle_blocks(DataRec,FilesDict,Pid,true);
		                 

                   % it is the last piece
                   true ->
                    writer:write_files(Piece,Index,PieceLength,FilesDict,Key,true),
                     Pid ! {ready_piece ,Index} ,
		     handle_blocks(DataRec,FilesDict,Pid,true)

              end

          end ;


        % Piece is not ready
         false -> 
         handle_blocks(DataRec,FilesDict,Pid,true)
       end
 end ; 



 handle_blocks(DataRec,FilesDict,Pid,false)-> % it is single

   receive 

    {data,Default_path,Index,Begin,Binary} -> % msg style may change!!!!!!
      write_temp(Default_path,Begin,Binary),
       case is_ready(Default_path,DataRec,Index) of 
         % The piece is full
         true ->
           Piece = get_allBlocks(Default_path), % file is deleted afterwads
         %% check hash value 
         case  check_hash(Piece,Index,record_operation:get_pieces(DataRec)) of

           false ->
                io:format("Piece is invalid");

           %% The piece is ready to be written to file
           true ->
                   FileName = record_operation:get_FileName(DataRec),
                   PieceLength = record_operation:get_Piece_Length(DataRec),
		   writer:write_file(Piece,Index,PieceLength,FileName),
		   Pid ! {ready_piece ,Index} ,
		   handle_blocks(DataRec,FilesDict,Pid,false)

          end ;


        % Piece is not ready
         false ->
      	           handle_blocks(DataRec,FilesDict,Pid,false)
       end
 end .





  %% writes each block of data to its pre-defined order.
  write_temp(Dir,Begin,Bin)->
    directory:set_wdir(Dir),
    {ok, Io} = file:open("temp.txt",[read,write,raw]),
    file:pwrite(Io, Begin, Bin ),
    file:close(Io)
    .

   %% gets a block size and a file name and checks if the content
   %% of the file has the same size with piece size.
  is_complete(Dir,PieceSize)->
    directory:set_wdir(Dir),
    {ok,Bin} = file:read_file("temp.txt"),
    Binsize = byte_size(Bin),
    case PieceSize == Binsize of

      true  ->
	    true;
      false ->

            false
    end .


  %% retrieves the data stored in the temp.txt file and deletes the file.
  get_allBlocks(Dir)-> 
    directory:set_wdir(Dir),
    {ok,Bin} = file:read_file("temp.txt"),
    file:delete("temp.txt"),
    Bin
  .
  
  %% checks the SHA1 hash value of the returned data 
  %% to see if the data has the same hash value with what 
  %% has been declared in the torrent file.
  check_hash(Bin,Index,String)->
    ShaValue1 = binary:bin_to_list(crypto:sha(Bin)),
    ShaValue2 = lists:sublist(String,(Index*20)+1,(Index*20)+20),
    
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

  is_ready(Default_path,Rec,Index)->
     case is_LastPiece(record_operation:get_PieceNum(Rec)-1, Index) of
          true  ->
            is_complete(Default_path,record_operation:get_LPiece_Length(Rec));
          false ->
            is_complete(Default_path,record_operation:get_Piece_Length(Rec))
     end .
