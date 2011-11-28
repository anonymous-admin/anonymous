%%%-------------------------------------------------------------------
%%% @author Johan Wikstr�m Sch�tzer
%%% @copyright (C) 2011 Johan Wikstr�m Sch�tzer
%%% @doc torrentdata.erl
%%%
%%% @end
%%% Created  : 10 Nov 2011 by Johan Wikstr�m Sch�tzer
%%% Modified : 18 Nov 2011 by Johan Wikstr�m Sch�tzer
%%%            Notes: From simple server to gen_server 
%%%
%%%            SEE defs.hrl FOR INFO ON EXPECTED MESSAGES
%%% 
%%%-------------------------------------------------------------------

-module(torrentdata).
-export([start_link/0, start_link/1, stop/0]).
-export([init/1, terminate/2, handle_cast/2, handle_call/3]).
-export([create_record/5]).
-behaviour(gen_server).

-include("defs.hrl").

%% Behaviour

start_link() ->
    start_link([]).

start_link(_Args) ->
    gen_server:start_link({local, torrentdata}, ?MODULE, _Args, []).

stop() ->
    gen_server:cast(torrentdata, close).

init(_Args) ->
    {ok, null}.

terminate(_Reason, _LoopData) ->
    gen_server:cast(torrentdata, stop).

handle_cast(stop, _LoopData) ->
    {stop, normal, _LoopData}.

handle_call({Operation, Item}, _From, _LoopData) ->
    case server_active() of
	true ->
	    dets:open_file(?DATAFILE, [{type, set}]),
	    case Operation of
		insert -> Reply = insert(Item);
		update -> Reply = update(Item);
		lookup -> Reply = lookup(Item);
		delete -> Reply = delete(Item);
		_      -> Reply = {error, invalid_operation}
	    end,
	    dets:sync(?DATAFILE),
	    dets:close(?DATAFILE),
	    {reply, Reply, _LoopData};
	false -> {reply, {error, torrentdata_not_active}, _LoopData}
    end.

insert(Record) ->
    dets:insert_new(?DATAFILE, {Record#torrent.id, Record}).

update(Record) ->
    case dets:lookup(?DATAFILE, Record#torrent.id) of
	[] -> {error, no_existing_record};
        _  -> dets:insert(?DATAFILE, {Record#torrent.id, Record})
    end.

lookup(Key) ->
    List = dets:lookup(?DATAFILE, Key),
    case List of
	[] -> {error, no_existing_record};
	[Record] -> Record
    end.

delete(Key) ->
    dets:delete(?DATAFILE, Key).

%%--------------------------------------------------------------------
%% @author Johan Wikstr�m Sch�tzer
%% @doc torrentdata.erl
%% @spec Creates a record with the given arguments;
%%       Id, Size, Percent, Pieces, PiecesFinished.
%%       See the 'torrent' record definition for information
%%       on what values are expected.
%% @end
%%--------------------------------------------------------------------
create_record(Id, Size, Downloaded, Percent, Pieces, Pieces_finished,
	      Trackers, Max_Peers) ->
    #torrent{id=Id, size=Size, downloaded=Downloaded, percent=Percent,
             pieces=Pieces, pieces_finished=Pieces_finished,
	     trackers=Trackers, max_peers=Max_Peers}.

%%--------------------------------------------------------------------
%% @author Johan Wikstr�m Sch�tzer
%% @doc torrentdata.erl
%% @spec Checks if the server is active or not. 
%%       Returns true or false.
%% @end
%%--------------------------------------------------------------------
server_active() ->
    case whereis(?MODULE) of
	undefined -> false;
	_         -> true
    end.
