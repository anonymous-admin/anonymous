%%%-------------------------------------------------------------------
%%% @author Johan Wikstr�m Sch�tzer
%%% @copyright (C) 2011 Johan Wikstr�m Sch�tzer
%%% @doc torrentdata.erl
%%%
%%% @end
%%% Created : 18 Nov 2011 by Johan Wikstr�m Sch�tzer
%%%-------------------------------------------------------------------

%%--------------------------------------------------------------------
%% @author Johan Wikstr�m Sch�tzer
%% @doc defs.hrl
%% @spec Definition of the record 'torrent'.
%%       The 'Id' will be used as a key when calling the lookup/2
%%       function. Should be a unique atom. 'Size' is the size of 
%%       the content file(s) of the torrent in bytes (integer) 
%%       (the gui should recalculate it to KB or MB. 
%%       'Percent' is the percentage of the finished download 
%%       (integer 0-100). 'Pieces' is the amount of pieces in the 
%%       torrent and 'Pieces_finished' are the amount of finished 
%%       pieces (both integers).
%% @end
%%--------------------------------------------------------------------	
-record(torrent, {
   id, 
   info_hash_tracker, 
   announce, 
   creation_date, 
   comment, 
   created_by, 
   encoding, files,
   filename, 
   piece_length, 
   number_of_pieces,
   file_length,
   pieces,
   bitfield,
   trackers,
   downloaded,
   size,
   max_peers
  }).

-record(tracker_info,
	{url,
	 info_hash,
	 peer_id,
	 port,
	 uploaded,
	 downloaded,
	 left,
	 event,
	 num_want,
	 interval}).

%%--------------------------------------------------------------------
%% @author Johan Wikstr�m Sch�tzer
%% @doc defs.hrl
%% @spec Defenition of the file which the DETS table in 
%%       torrentdata.erl is saved to.
-define(DATAFILE, databasefile). 
