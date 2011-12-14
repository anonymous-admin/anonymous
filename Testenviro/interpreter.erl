%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @copyright (C) 2011 Sorush Arefipour
%% @doc    interpreter.erl
%% @end
%% Created : 18 Nov 2011 by Sorush Arefipour
%%--------------------------------------------------------------------
-module(interpreter).
-author('Sorush Arefipour').
-export([create_record/1, get_tracker_response_info/1,
	 init/1, handle_cast/2, handle_call/3]).
-compile(export_all).
-behaviour(gen_server).
-include("defs.hrl").

%% ************************************************************************************************************
%% ********************************************** External functions ******************************************
%% ************************************************************************************************************

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   Used by the supervisor to start the process 
%% @end
%%--------------------------------------------------------------------
start_link() ->
    start_link([]).

start_link(_Args) ->
    gen_server:start_link({local, interpreter}, ?MODULE, _Args, []).

%% ************************************************************************************************************
%% ******************************************** Gen_server functions ********************************************
%% ************************************************************************************************************

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   
%% @end
%%--------------------------------------------------------------------
init(_Args)->
    gen_server:cast(msg_controller, {subscribe, interpreter, [{torrent_filepath, -1}]}),
    {ok,null}.

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   
%% Start the torrent process so it gets the torrent_info message.
%% @end
%%--------------------------------------------------------------------
handle_cast({notify, torrent_filepath, {_Id, Filepath}}, _Data)->
    Record = create_record(Filepath),
    dynamic_supervisor:start_torrent(Record),
    gen_server:cast(msg_controller, {notify, torrent_info, {Record#torrent.id, Record}}),
    {noreply,_Data}.

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec    
%% @end
%%--------------------------------------------------------------------
handle_call(_State,_From,_Data)->
    Reply = ok,
    {reply,Reply,_Data}.

%% ************************************************************************************************************
%% ********************************************** External functions ********************************************
%% ************************************************************************************************************

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   Function gets the directory as argument of a torrent file
%%         and make a record of all information in the torrent file. 
%% @end
%%--------------------------------------------------------------------
create_record(FileName) ->
    Parsed_info = read_file(FileName),
    Info_hash_tracker = get_info_hash_tracker(Parsed_info),
    Info_hash_handshake = get_info_hash_handshake(Parsed_info),
    Announce = get_announce(Parsed_info),
    Creation_date = get_creation_date(Parsed_info),
    Comment = get_comment(Parsed_info),
    Created_by = get_created_by(Parsed_info),
    Encoding = get_encoding(Parsed_info),
    Files = get_files(Parsed_info, 0),
    Filename = get_filename(Parsed_info),
    Piece_length = get_piece_length(Parsed_info),
    Number_of_pieces = get_number_of_pieces(Parsed_info),
    File_length = get_file_length(Parsed_info),
    Pieces = get_pieces(Parsed_info),
    Bitfield = get_bitfield(Parsed_info),
    TrackerInfo = tracker_info_record(Announce, Info_hash_tracker, File_length),
    #torrent{id = list_to_atom(binary_to_list(Info_hash_handshake)), info_hash_tracker = Info_hash_tracker, 
	     announce = Announce, creation_date = Creation_date, comment = Comment, 
	     created_by = Created_by, encoding = Encoding, files = Files,
	     filename = Filename, piece_length = Piece_length, 
	     number_of_pieces = Number_of_pieces,file_length = File_length, 
	     pieces = Pieces, bitfield = Bitfield, trackers = TrackerInfo, 
	     downloaded = "0", max_peers = "50", size = integer_to_list(File_length), left = integer_to_list(File_length) }.

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   It takes a list of announce, info hash and file length and 
%%         creates a record per each announce and put all of records 
%%         in a list.
%% @end
%%--------------------------------------------------------------------
tracker_info_record([], _, _)->
    [];
tracker_info_record([H|T], Info_hash, File_length)->
    [#tracker_info{url = H,
	 info_hash = Info_hash, peer_id = "-AZ4004-znmphhbrij37",
	 port = "6881", uploaded = "0", downloaded = "0", left = integer_to_list(File_length), 
	 event = started, num_want = "50", interval = "1000"}|tracker_info_record(T, Info_hash, File_length)].
    

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   It take string of directory as argument and read the content
%%         of it and passes the content to parser to be parsed.
%% @end
%%--------------------------------------------------------------------
read_file(FileName) ->
  {ok, FileContents} = file:read_file(FileName),
  {{dict, Info}, _Remainder} = parser:decode(FileContents),
  {info, Info}.

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   It gets the parsed information and after fetching info 
%%         dictonary from it, it calculate the info hash that is being
%%         used for communicating with tracker.
%% @end
%%--------------------------------------------------------------------
get_info_hash_tracker({info, Info}) ->
    Information = dict:fetch(<<"info">>, Info),
    BencodedInfo = binary_to_list(parser:encode(Information)),
    hash_gen(encoder_tracker(BencodedInfo),2).

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   It gets the parsed information and after fetching info 
%%         dictonary from it, it calculate the info hash that is being
%%         used for handshaking.  
%% @end
%%--------------------------------------------------------------------
get_info_hash_handshake({info, Info}) ->
    Information = dict:fetch(<<"info">>, Info),
    encoder_handshake(parser:encode(Information)).

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   The function gets the parsed information as argument and check 
%%         if the torrent has one announce or list of announces and return
%%         a list of tracker or trackers
%% @end
%%--------------------------------------------------------------------
get_announce({info, Info}) ->
    Info_keys = dict:fetch_keys(Info),
    case lists:member(<<"announce-list">>, Info_keys) of
	true ->
	    {list, Announce_list} = dict:fetch(<<"announce-list">>, Info),
	    check_tcp(to_string(Announce_list));
	false ->
	    check_tcp([binary_to_list(dict:fetch(<<"announce">>, Info))])
    end.

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   The function gets the parsed information as argument and 
%%         and returns the creation date while checking if field is not
%%         empty, and if it is, it will return novalue.
%% @end
%%--------------------------------------------------------------------
get_creation_date({info, Info}) ->
    case dict:find(<<"creation date">>, Info) of
	{ok, Creation_date} ->
	    Creation_date;
	error ->
	    novalue
    end.

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   The function gets the parsed information as argument and 
%%         and returns the comment while checking if field is not
%%         empty, and if it is, it will return novalue.
%% @end
%%--------------------------------------------------------------------
get_comment({info, Info}) ->
    case dict:find(<<"comment">>, Info) of
	{ok, Comment} ->
	    binary_to_list(Comment);
	error ->
	    novalue
    end.

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   The function gets the parsed information as argument and 
%%         and returns the created by while checking if field is not
%%         empty, and if it is, it will return novalue.
%% @end
%%--------------------------------------------------------------------
get_created_by({info, Info}) ->
    case dict:find(<<"created by">>, Info) of
	{ok, Created_by} ->
	    binary_to_list(Created_by);
	error ->
	    novalue
    end.

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   The function gets the parsed information as argument and 
%%         and returns the encoding while checking if field is not
%%         empty, and if it is, it will return novalue.
%% @end
%%--------------------------------------------------------------------
get_encoding({info, Info}) ->
    case dict:find(<<"encoding">>, Info) of
	{ok, Encoding} ->
	    binary_to_list(Encoding);
	error ->
	    novalue
    end.

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   The function gets the parsed information as argument and 
%%         and returns the creation date while checking if field is not
%%         empty, and if it is, it will return novalue.
%% @end
%%--------------------------------------------------------------------
get_files({info, Info},FileSize) ->
    Info_dec_keys = get_info_dec_keys(Info),
    case lists:member(<<"files">>, Info_dec_keys) of
	true ->
	    {list, Files_dict} = get_info_dec(<<"files">>, Info),
	    files_interpreter(Files_dict,FileSize,[]);
	false ->
	    Path = get_info_dec(<<"name">>, Info),
	    Length = get_info_dec(<<"length">>, Info),
	    {[[[Path],Length]],Length}
    end.

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   The function gets the parsed information as argument and 
%%         and returns the name of the file.
%% @end
%%--------------------------------------------------------------------
get_filename({info, Info}) ->
    Name = get_info_dec(<<"name">>, Info),
    binary_to_list(Name).

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   The function gets the parsed information as argument and 
%%         fetches length of each piece in info dictionary.
%% @end
%%--------------------------------------------------------------------    
get_piece_length({info, Info}) ->
    get_info_dec(<<"piece length">>, Info).

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   The function gets the parsed information as argument and
%%         after feching the pieces from info dictionary it calculates
%%         number of pieces.
%% @end
%%--------------------------------------------------------------------
get_number_of_pieces({info, Info}) ->
    PieceHashes = get_info_dec(<<"pieces">>, Info),
    HashLength = 20,
    round(length(binary_to_list(PieceHashes)) / HashLength).

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   It take string of directory as argument and calculate size of 
%%         file by multipying piece length and number of pieces.
%% @end
%%--------------------------------------------------------------------
get_file_length({info, Info}) ->
    {_, Length} = get_files({info, Info}, 0),
    Length.

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   It take string of directory as argument and get the content
%%         pieces field.
%% @end
%%--------------------------------------------------------------------
get_pieces({info, Info}) ->
    get_info_dec(<<"pieces">>, Info).

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   It take string of directory as argument and generate bitfield
%%         of the torrent file.
%% @end
%%--------------------------------------------------------------------
get_bitfield({info, Info}) ->
    NumberOfPieces = get_number_of_pieces({info, Info}),
    create_bitfield_binary(NumberOfPieces).

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   It gets reponse of th tracker and returns interval, compelete,
%%         incomplete, and list of peers with their IPs and Ports by 
%%         calling the function peers_compact().
%% @end
%%--------------------------------------------------------------------
get_tracker_response_info({{dict,Response},_}) ->
    Interval = dict:fetch(<<"interval">>,Response),
    Seeds = dict:fetch(<<"complete">>,Response),
    Leechers = dict:fetch(<<"incomplete">>,Response),
    PeersList = dict:fetch(<<"peers">>,Response),
%    {list,Peers_dict} = dict:fetch(<<"peers">>,Response),
    [Interval,Seeds,Leechers,peers_compact(binary_to_list(PeersList))].


%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   The funcion gets a list as its argument and returns a list of 
%%         IPs and Ports to get_tracker_reponse_info().
%% @end
%%--------------------------------------------------------------------
peers_compact([])->
    [];
peers_compact([M1,M2,M3,M4,M5,M6|T]) ->
    IP = lists:concat([M1,'.',M2,'.',M3,'.',M4]),
    <<Port:16>> = list_to_binary([M5,M6]), 
    [[IP,Port]|peers_compact(T)].

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   It takes a list as argument and put all names and size in
%%         in a list and call the the function again recursively for
%%         all other files.
%% @end
%%--------------------------------------------------------------------
files_interpreter([],FileSize,Acc) ->    
    {Acc,FileSize};
files_interpreter([H|T],FileSize,Acc) ->
    {dict, Info} = H,
    Length = dict:fetch(<<"length">>, Info),
    Size = FileSize + Length,
    {list, Path} = dict:fetch(<<"path">>, Info),
    files_interpreter(T,Size,  Acc ++ [[Path, Length]]).

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   It gets a list of announce and return the udp tracker in
%%         a list. 
%% @end
%%--------------------------------------------------------------------
check_udp([])->
    [];
check_udp([H|T]) ->
    [H1|_] = H,
    case H1 == 117 of
	true ->
	    [H] ++ check_udp(T);
	false ->
	    check_udp(T)
    end.

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   It gets a list of announce and return the tcp tracker in
%%         a list.
%% @end
%%--------------------------------------------------------------------
check_tcp([])->
    [];
check_tcp([H|T]) ->
    [H1|_] = H,
    case H1 == 104 of
	true ->
	    [H] ++ check_tcp(T);
	false ->
	    check_tcp(T)
    end.

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   It takes the data of info dictionary and encode it for
%%         tracker infohash.
%% @end
%%--------------------------------------------------------------------
encoder_tracker(Data)->
    crypto:start(),
    Info_hash = [ hd(integer_to_list(N, 16)) || << N:4 >> <= crypto:sha(Data) ],
    Info_hash.

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   It takes the data of info dictionary and encode it for 
%%         handshake infohash.     
%% @end
%%--------------------------------------------------------------------
encoder_handshake(Data)->
    crypto:start(),
    Info_hash = crypto:sha(Data),
    Info_hash.

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   It takes string of infohash and put % between each two 
%%         character.
%% @end
%%--------------------------------------------------------------------
hash_gen(List, Num) when Num < length(List)->
    {A, B} = lists:split(Num,List),
    hash_gen(A ++ [37] ++ B, Num+3 );
hash_gen(List, _) ->
    [37] ++ List.

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   It take list and binary and make them list and put all of them
%%         in a list.
%% @end
%%--------------------------------------------------------------------
to_string([]) ->
    [];
to_string([H|T]) ->
    {list,B} = H,
    [binary_to_list(hd(B))] ++ to_string(T).

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   Function takes a key and data as arguments and fetches the
%%         information according to given tag name.
%% @end
%%--------------------------------------------------------------------
get_info_dec(Name, Info) ->
    {dict,{dict, Info_dec}} = {dict, dict:fetch(<<"info">>, Info)},
    dict:fetch(Name, Info_dec).

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   It gets content of torrent file and returns keys name of 
%%         info dictionary of the torrent file.
%% @end
%%--------------------------------------------------------------------
get_info_dec_keys(Info) ->
    {dict,{dict, Info_dec}} = {dict, dict:fetch(<<"info">>, Info)},
     dict:fetch_keys(Info_dec).

%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    interpreter.erl
%% @spec   It gets number of pieces and generate bitfield accordingly 
%% @end
%%--------------------------------------------------------------------
create_bitfield_binary(0) ->
    <<>>;
create_bitfield_binary(NumberOfPieces) ->
  LeaderLength = (8 - NumberOfPieces rem 8) rem 8,
  create_bitfield_binary(<<>>, LeaderLength, NumberOfPieces).
create_bitfield_binary(Binary, 0, 0) ->
    Binary;
create_bitfield_binary(Binary, 0, NumberOfPieces) ->
    NewBinary = <<Binary/bitstring, 1:1>>,
    create_bitfield_binary(NewBinary, 0, NumberOfPieces - 1);
create_bitfield_binary(Binary, LeaderLength, NumberOfPieces) ->
    NewBinary = <<Binary/bitstring, 0:1>>,
    create_bitfield_binary(NewBinary, LeaderLength - 1, NumberOfPieces).
