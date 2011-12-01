%%%-------------------------------------------------------------------
%%% @author Johan Wikström Schützer
%%% @copyright (C) 2011 Johan Wikström Schützer
%%% @doc torrentdata.erl
%%%
%%% @end
%%% Created  : 10 Nov 2011 by Johan Wikström Schützer
%%% Modified : 18 Nov 2011 by Johan Wikström Schützer
%%%            Notes: From simple server to gen_server 
%%%
%%%            SEE defs.hrl FOR INFO ON EXPECTED MESSAGES
%%% 
%%%-------------------------------------------------------------------

-module(database).
-export([start_link/0, start_link/1, stop/0]).
-export([init/1, terminate/2, handle_cast/2, handle_call/3]).
%-export([create_record/8]).
-behaviour(gen_server).

-include("defs.hrl").

%% Behaviour

start_link() ->
    start_link([]).

start_link(_Args) ->
    gen_server:start_link({local, database}, ?MODULE, _Args, []).
%    blackboard ! {subscribe, database, [torrentinfo, torrentstatus]}.

stop() ->
    gen_server:cast(database, stop).

init(_Args) ->
    dets:open_file(?DATAFILE, [{type, set}]),
    dets:to_ets(?DATAFILE, ets:new(database_table, [set, named_table])),
    {ok, null}.

terminate(_Reason, _LoopData) ->
    gen_server:cast(database, stop).

handle_cast(stop, _LoopData) ->
    {stop, normal, _LoopData}.

handle_call({Operation, Item}, _From, _LoopData) ->
    case server_active() of
	true ->
	    case Operation of
		insert -> Reply = insert(Item);
		update -> Reply = update(Item);
		lookup -> Reply = lookup(Item);
		delete -> Reply = delete(Item);
		_      -> Reply = {error, invalid_operation}
	    end,
	    spawn(fun() -> dump_table() end),
	    {reply, Reply, _LoopData};
	false -> {reply, {error, database_not_active}, _LoopData}
    end.

insert(Record) ->
    ets:insert_new(database_table, {Record#torrent.id, Record}).

update(Record) ->
    case ets:lookup(database_table, Record#torrent.id) of
	[] -> {error, no_existing_record};
        _  -> ets:insert(database_table, {Record#torrent.id, Record})
    end.

lookup(Key) ->
    List = ets:lookup(database_table, Key),
    case List of
	[] -> {error, no_existing_record};
	[Record] -> Record
    end.

delete(Key) ->
    ets:delete(database_table, Key).

%%--------------------------------------------------------------------
%% @author Johan Wikström Schützer
%% @doc torrentdata.erl
%% @spec Creates a record with the given arguments;
%%       Id, Size, Percent, Pieces, PiecesFinished.
%%       See the 'torrent' record definition for information
%%       on what values are expected.
%% @end
%%--------------------------------------------------------------------
%create_record(Id, Size, Downloaded, Percent, Pieces, Pieces_finished,
%	      Trackers, Max_Peers) ->
%    #torrent{id=Id, size=Size, downloaded=Downloaded, percent=Percent,
%             pieces=Pieces, pieces_finished=Pieces_finished,
%	     trackers=Trackers, max_peers=Max_Peers}.

%%--------------------------------------------------------------------
%% @author Johan Wikström Schützer
%% @doc torrentdata.erl
%% @spec Checks if the server is active or not. 
%%       Returns true or false.
%% @end
%%--------------------------------------------------------------------
server_active() ->
    case whereis(database) of
	undefined -> false;
	_         -> true
    end.

dump_table() ->
    dets:open_file(?DATAFILE, [{type, set}]),
    ets:to_dets(database_table, ?DATAFILE),
    dets:sync(?DATAFILE),
    dets:close(?DATAFILE).
