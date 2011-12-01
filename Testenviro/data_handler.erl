-module(data_handler).
-export([is_complete/2,write_temp/3,get_data/1,check_hash/3,is_ready/3]).
-record(torrent,{filename = "parent", files = [[["second","ssecond","2.docx"],123],[["first","ffirst","1.txt"],456]],number_of_pieces}).

 
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

    end.


  %% retrieves the data stored in the temp.txt file and deletes the file.
  get_data(Dir)-> 
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
  is_LastPiece(LP_index,LP_index)->
    true;
  is_LastPiece(LP_index,Index)->
    false.

  is_ready(Default_path,Rec,Index)->
     case is_LastPiece(record_operation:get_PieceNum(Rec)-1, Index) of
          true  ->
            is_complete(Default_path,record_operation:get_LPiece_Length(Rec));
          false ->
            is_complete(Default_path,record_operation:get_Piece_Length(Rec))
     end .
