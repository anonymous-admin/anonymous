%%%-------------------------------------------------------------------
%%% @author Johan Wikström Schützer
%%% @copyright (C) 2011 Johan Wikström Schützer
%%% @doc torrentdata.erl
%%%
%%% @end
%%% Created  : 10 Nov 2011 by Johan Wikström Schützer
%%% Modified : 18 Nov 2011 by Johan Wikström Schützer
%%%            Notes: From simple server to gen_server
%%%            01 Dec 2011 by Johan Wikström Schützer
%%%            Notes: From operation dependent to independent
%%%            05 Dec 2011 by Johan Wikström Schützer
%%%            Notes: Added blackboard notification
%%%            15 Dec 2011 by Johan Wikström Schützer
%%%            Notes: Fixed bug about sending records to 
%%%                   the msg_controller, didn't send 
%%%                   records but tuple.
%%%
%%%-------------------------------------------------------------------

-module(database).
-export([start_link/0, start_link/1, stop/0]).
-export([init/1, terminate/2, handle_cast/2]).
-export([handle_call/3, handle_info/2, code_change/3]).
-behaviour(gen_server).

-include("defs.hrl").

%% Behaviour

start_link() ->
    start_link([]).

start_link(_Args) ->
    gen_server:start_link({local, database}, ?MODULE, _Args, []).

stop() ->
    gen_server:cast(database, stop).

init(_Args) ->
    dets:open_file(?DATAFILE, [{type, set}]),
    dets:to_ets(?DATAFILE, ets:new(database_table, [set, named_table])),
    case whereis(msg_controller) of
	undefined -> false;
	_         -> gen_server:cast(msg_controller, {subscribe, database, [{torrent_info,-1}, {torrent_status,-1}]}),
	             spawn(fun() -> notify_blackboard() end)
    end,
    {ok, _Args}.

terminate(_Reason, _LoopData) ->
    gen_server:cast(database, stop).

%% Call handling

handle_cast(stop, _LoopData) ->
    {stop, normal, _LoopData};

handle_cast({notify, torrent_info, {TorrentId, Record}}, _LoopData) ->
    case ((TorrentId /= -1) and server_active()) of
	true ->
	    insert(TorrentId, Record),
	    spawn(fun() -> dump_table() end);
	false -> false
    end,
    {noreply, _LoopData};

handle_cast({notify, torrent_status, {TorrentId, deleted}}, _LoopData) ->
    delete(TorrentId),    
    {noreply, _LoopData};

handle_cast({notify, Tag, {TorrentId, Value}}, _LoopData) ->
    update(TorrentId, Tag, Value),
    {noreply, _LoopData}.
		
%% Private functions
		
%% Insert the given record with its Id as key

insert(TorrentId, Record) ->
    ets:insert_new(database_table, {TorrentId, Record}).

%% Updates a given field in a record with the given Id
%% with the given value.

update(TorrentId, Tag, Value) ->
    case ets:lookup(database_table, TorrentId) of
	[] -> {error, no_existing_record};
        [{TorrentId, Record}] -> 
	    case Tag of
		id ->
		    ets:insert(database_table, {TorrentId, Record#torrent{id = Value}});
		info_hash_tracker ->
		    ets:insert(database_table, {TorrentId, Record#torrent{info_hash_tracker = Value}});
		announce ->
		    ets:insert(database_table, {TorrentId, Record#torrent{announce = Value}});
		creation_date ->
		    ets:insert(database_table, {TorrentId, Record#torrent{creation_date = Value}});
		comment ->
		    ets:insert(database_table, {TorrentId, Record#torrent{comment = Value}});
		created_by ->
		    ets:insert(database_table, {TorrentId, Record#torrent{created_by = Value}});
		encoding ->
		    ets:insert(database_table, {TorrentId, Record#torrent{encoding = Value}});
		files ->
		    ets:insert(database_table, {TorrentId, Record#torrent{files = Value}});
		filename ->
		    ets:insert(database_table, {TorrentId, Record#torrent{filename = Value}});
		piece_length ->
		    ets:insert(database_table, {TorrentId, Record#torrent{piece_length = Value}});
		number_of_pieces ->
		    ets:insert(database_table, {TorrentId, Record#torrent{number_of_pieces = Value}});
		file_length ->
		    ets:insert(database_table, {TorrentId, Record#torrent{file_length = Value}});
		bitfield -> 
		    ets:insert(database_table, {TorrentId, Record#torrent{bitfield = Value}});
		trackers ->
		    ets:insert(database_table, {TorrentId, Record#torrent{trackers = Value}});
		downloaded ->
		    ets:insert(database_table, {TorrentId, Record#torrent{downloaded = Value}});
		size ->
		    ets:insert(database_table, {TorrentId, Record#torrent{size = Value}});
		max_peers ->
		    ets:insert(database_table, {TorrentId, Record#torrent{max_peers = Value}})
	    end
    end.

%% Deletes an entry from the table

delete(TorrentId) ->
    timer:sleep(2000),
    ets:delete(database_table, TorrentId),
    spawn(fun() -> dump_table() end).

%% Checks if the server is active or not. 
%% Returns true or false.

server_active() ->
    case whereis(database) of
	undefined -> false;
	_         -> true
    end.

%% Dumps the table to the defined file.
%% This is for ensuring that the data is
%% saved in case of crash.

dump_table() ->
    dets:open_file(?DATAFILE, [{type, set}]),
    ets:to_dets(database_table, ?DATAFILE),
    dets:sync(?DATAFILE),
    dets:close(?DATAFILE).

notify_blackboard() ->
    notify_blackboard(ets:tab2list(database_table)).

notify_blackboard([]) -> ok;
notify_blackboard([H|T]) ->
    {Id, Record} = H,
    dynamic_supervisor:start_torrent(Record),
    gen_server:cast(msg_controller, {notify, torrent_info, {Id, Record}}),
    notify_blackboard(T).

handle_info(_,_) ->
    ok.

handle_call(_,_,_) ->
    ok.

code_change(_,_,_) ->
    ok.
