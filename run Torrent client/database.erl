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
%% Export for intermodule use, used by static supervisor
-export([start_link/0, start_link/1, stop/0]).
%% Gen_server functions, used for message passing and init
-export([init/1, terminate/2, handle_cast/2]).
%% Unused exports
-export([handle_call/3, handle_info/2, code_change/3]).
-behaviour(gen_server).

-include("defs.hrl").

%% Gen_server behaviour functions

start_link() ->
    start_link([]).

start_link(_Args) ->
    gen_server:start_link({local, database}, ?MODULE, _Args, []).

stop() ->
    gen_server:cast(database, stop).

%% Inits the process. If the msg_controller process is alive, this process
%% sends the subscribe message.
init(_Args) ->
    dets:open_file(?DATAFILE, [{type, set}]),
    dets:to_ets(?DATAFILE, ets:new(database_table, [set, named_table])),
    case whereis(msg_controller) of
	undefined -> false;
	_         -> gen_server:cast(msg_controller, {subscribe, database, [{torrent_info,-1}, {torrent_status,-1}, {default_path,-1},
									    {downloaded, -1}, {uploaded, -1}]}),
	             spawn(fun() -> notify_blackboard() end)
    end,
    {ok, _Args}.

terminate(_Reason, _LoopData) ->
    gen_server:cast(database, stop).

%% Message handling


%% Stops the process
handle_cast(stop, _LoopData) ->
    {stop, normal, _LoopData};

%% Handles torrent_info. Saves the torrent record to the database
%% if the torrent id is valid.
handle_cast({notify, torrent_info, {TorrentId, Record}}, _LoopData) ->
    case ((TorrentId /= -1) and server_active()) of
	true ->
	    insert(TorrentId, Record),
	    spawn(fun() -> dump_table() end);
	false -> false
    end,
    {noreply, _LoopData};

%% Handles the torrent_status message, if the value is deleted.
%% Deletes the corresponding torrent from the database.
handle_cast({notify, torrent_status, {TorrentId, deleted}}, _LoopData) ->
    delete(TorrentId),    
    {noreply, _LoopData};

%% Handles the default_path message. Saves the default path to
%% the database.
handle_cast({notify, default_path, {_TorrentId, Value}}, _LoopData) ->
    put_default_path(Value),    
    {noreply, _LoopData};

%% Takes care of all other notifications. This process only subcribes
%% to torrent related data.
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
		downloaded ->
		    ets:insert(database_table, {TorrentId, Record#torrent{downloaded = Value}});
		uploaded   ->
		    ets:insert(database_table, {TorrentId, Record#torrent{uploaded = Value}});
		_          -> ok
	    end
    end.

%% Deletes an entry from the table

delete(TorrentId) ->
    timer:sleep(2000),
    ets:delete(database_table, TorrentId),
    spawn(fun() -> dump_table() end).

%% Puts the default path in the database

put_default_path(Path) ->
    ets:insert(database_table, {default_path, Path}),
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

%% Called upon init. Sends any data in the database to the msg_controller.
%% The whole purpose of the database is executed here; to restart any torrent
%% that was alive during previous application termination.

notify_blackboard() ->
    notify_blackboard(ets:tab2list(database_table)).

notify_blackboard([]) -> ok;
notify_blackboard([H|T]) ->
    {Id, Value} = H,
    case Id of
	default_path ->
	    gen_server:cast(msg_controller, {notify, default_path, {-1, Value}});
	_            ->
	    dynamic_supervisor:start_torrent(Value),
	    gen_server:cast(msg_controller, {notify, torrent_info, {Id, Value}})
    end,
    notify_blackboard(T).

%% Unused gen_server functions.

handle_info(_,_) ->
    ok.

handle_call(_,_,_) ->
    ok.

code_change(_,_,_) ->
    ok.
