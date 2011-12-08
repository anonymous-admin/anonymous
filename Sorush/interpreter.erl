-module(interpreter).
-export([create_record/1, get_tracker_response_info/1]).
-compile(export_all).
-behaviour(gen_server).
-include("defs.hrl").

init(Data)->
    create_record(Data),
    {ok,Data}.

handle_cast({torrent_info},Data)->
    gen_server:cast(logger,{notify,torrent_info,Data}),
    {noreply,Data}.
handle_call(_State,_From,_Data)->
    Reply = ok,
    {reply,Reply,_Data}.

create_record(FileName) ->
    Parsed_info = read_file(FileName),
    Info_hash_tracker = get_info_hash_tracker(Parsed_info),
    Info_hash_handshake = get_info_hash_handshake(Parsed_info),
    Announce = get_announce(Parsed_info),
    Creation_date = get_creation_date(Parsed_info),
    Comment = get_comment(Parsed_info),
    Created_by = get_created_by(Parsed_info),
    Encoding = get_encoding(Parsed_info),
    Files = get_files(Parsed_info),
    Filename = get_filename(Parsed_info),
    Piece_length = get_piece_length(Parsed_info),
    Number_of_pieces = get_number_of_pieces(Parsed_info),
    File_length = get_file_length(Parsed_info),
    Pieces = get_pieces(Parsed_info),
    Bitfield = get_bitfield(Parsed_info),
    TrackerInfo = tracker_info_record(Announce, Info_hash_tracker, File_length),
    #torrent{id = Info_hash_handshake, info_hash_tracker = Info_hash_tracker, 
	     announce = Announce, creation_date = Creation_date, comment = Comment, 
	     created_by = Created_by, encoding = Encoding, files = Files,
	     filename = Filename, piece_length = Piece_length, 
	     number_of_pieces = Number_of_pieces,file_length = File_length, 
	     pieces = Pieces, bitfield = Bitfield, trackers = TrackerInfo, 
	     downloaded = 0, max_peers = 50 }.


tracker_info_record([], _, _)->
    [];
tracker_info_record([H|T], Info_hash, File_length)->
    [#tracker_info{url = H,
	 info_hash = Info_hash, peer_id = "-AZ4004-znmphhbrij37",
	 port = 6881, uploaded = 0, downloaded = 0, left = File_length, 
	 event = started, num_want = 50, interval = 1000}|tracker_info_record(T, Info_hash, File_length)].
    

read_file(FileName) ->
  {ok, FileContents} = file:read_file(FileName),
  {{dict, Info}, _Remainder} = parser:decode(FileContents),
  {info, Info}.

get_info_hash_tracker({info, Info}) ->
    Information = dict:fetch(<<"info">>, Info),
    BencodedInfo = binary_to_list(parser:encode(Information)),
    hash_gen(encoder_tracker(BencodedInfo),2).

get_info_hash_handshake({info, Info}) ->
    Information = dict:fetch(<<"info">>, Info),
    encoder_handshake(parser:encode(Information)).

get_announce({info, Info}) ->
    Info_keys = dict:fetch_keys(Info),
    case lists:member(<<"announce-list">>, Info_keys) of
	true ->
	    {list, Announce_list} = dict:fetch(<<"announce-list">>, Info),
	    check_tcp(to_string(Announce_list));
	false ->
	    check_tcp([binary_to_list(dict:fetch(<<"announce">>, Info))])
    end.

get_creation_date({info, Info}) ->
    case dict:find(<<"creation date">>, Info) of
	{ok, Creation_date} ->
	    Creation_date;
	error ->
	    novalue
    end.

get_comment({info, Info}) ->
    case dict:find(<<"comment">>, Info) of
	{ok, Comment} ->
	    binary_to_list(Comment);
	error ->
	    novalue
    end.

get_created_by({info, Info}) ->
    case dict:find(<<"created by">>, Info) of
	{ok, Created_by} ->
	    binary_to_list(Created_by);
	error ->
	    novalue
    end.

get_encoding({info, Info}) ->
    case dict:find(<<"encoding">>, Info) of
	{ok, Encoding} ->
	    binary_to_list(Encoding);
	error ->
	    novalue
    end.

get_files({info, Info}) ->
    {list, Files_dict} = get_info_dec(<<"files">>, Info),
    files_interpreter(Files_dict).

get_filename({info, Info}) ->
    Name = get_info_dec(<<"name">>, Info),
    binary_to_list(Name).
    
get_piece_length({info, Info}) ->
    get_info_dec(<<"piece length">>, Info).

get_number_of_pieces({info, Info}) ->
    PieceHashes = get_info_dec(<<"pieces">>, Info),
    HashLength = 20,
    round(length(binary_to_list(PieceHashes)) / HashLength).

get_file_length({info, Info}) ->
    get_piece_length({info, Info}) * get_number_of_pieces({info, Info}).

get_pieces({info, Info}) ->
    get_info_dec(<<"pieces">>, Info).

get_bitfield({info, Info}) ->
    NumberOfPieces = get_number_of_pieces({info, Info}),
    create_bitfield_binary(NumberOfPieces).

get_tracker_response_info({{dict,Response},_}) ->
    Interval = dict:fetch(<<"interval">>,Response),
    Seeds = dict:fetch(<<"complete">>,Response),
    Leechers = dict:fetch(<<"incomplete">>,Response),
    {list,Peers_dict} = dict:fetch(<<"peers">>,Response),
    [Interval,Seeds,Leechers,peers_interpreter(Peers_dict)].
    
peers_interpreter([]) ->
    [];
peers_interpreter([H|T]) ->
    {dict, Info} = H,
    IP = dict:fetch(<<"ip">>, Info),
    Peer_id = dict:fetch(<<"peer id">>, Info),
    Port = dict:fetch(<<"port">>, Info),
    [[IP,Port,Peer_id]|peers_interpreter(T)].

files_interpreter([]) ->    
    [];
files_interpreter([H|T]) ->
    {dict, Info} = H,
    Length = dict:fetch(<<"length">>, Info),
    {list, Path} = dict:fetch(<<"path">>, Info),
    [[Path, Length]|files_interpreter(T)].

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

encoder_tracker(Data)->
    crypto:start(),
    Info_hash = [ hd(integer_to_list(N, 16)) || << N:4 >> <= crypto:sha(Data) ],
    Info_hash.

encoder_handshake(Data)->
    crypto:start(),
    Info_hash = crypto:sha(Data),
    Info_hash.

hash_gen(List, Num) when Num < length(List)->
    {A, B} = lists:split(Num,List),
    hash_gen(A ++ [37] ++ B, Num+3 );
hash_gen(List, _) ->
    [37] ++ List.

to_string([]) ->
    [];
to_string([H|T]) ->
    {list,B} = H,
    [binary_to_list(hd(B))] ++ to_string(T).

get_info_dec(Name, Info) ->
    {dict,{dict, Info_dec}} = {dict, dict:fetch(<<"info">>, Info)},
    dict:fetch(Name, Info_dec).

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
