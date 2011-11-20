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

-module(torrentdata).
-export([start_link/0, start_link/1, stop/0]).
-export([init/1, terminate/2, handle_call/3, handle_cast/2]).
-export([create_record/5, insert/1, update/1, 
         lookup/1, delete/1]).
-behaviour(gen_server).

-include("defs.hrl").

%% Behaviour

start_link() ->
    start_link().

start_link(_Args) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, _Args, []).

stop() ->
    gen_server:cast(?MODULE, close).

init(_Args) ->
    {ok, null}.

terminate(_Reason, _LoopData) ->
    gen_server:cast(?MODULE, {stop, []}).

handle_cast({Operation, Value}, _LoopData) ->
    do_operation(Operation, Value),
    {noreply, _LoopData}.

handle_cast({stop, _Value}, _LoopData) ->
    {stop, normal, _LoopData};

handle_cast(init, _LoopData) ->
    dets:open_file(?DATAFILE, [{type, set}]),
    {noreply, _LoopData};

handle_cast(close, _LoopData) ->
    dets:sync(?DATAFILE),
    dets:close(?DATAFILE),
    {noreply, _LoopData};

handle_cast({insert, Record}, _LoopData) ->
    dets:
    Bool = dets:insert_new(?DATAFILE, {Record#torrent.id, Record}),
    case Bool of
	true  -> Reply = {ok, inserted};
	false -> Reply = {error, no_unique_key}
    end,
    {noreply, _Loopdata};

handle_cast({update, Record}, _LoopData) ->
    case dets:lookup(?DATAFILE, Record#torrent.id) of
	[] -> Reply = {error, no_existing_record};
        _  -> Reply = dets:insert(?DATAFILE, 
				  {Record#torrent.id, Record})
    end,
    {noreply, _LoopData};

handle_cast({delete, Key}, _LoopData) ->
    Reply = dets:delete(?DATAFILE, Key),
    {noreply, _LoopData};

handle_cast({lookup, Key}, _LoopData) ->
    case dets:lookup(?DATAFILE, Key) of
	[] -> Reply = {error, no_existing_record};
	[Record] -> Reply = Record
    end,
    gen_server:cast(logger, {torrent_record, Reply}),
    {noreply, _LoopData}.

%%--------------------------------------------------------------------
%% @author Johan Wikström Schützer
%% @doc torrentdata.erl
%% @spec Used by insert/2, update/2, lookup/2 and delete/2. Used to
%%       simplify and compress code, contains operations needed in 
%%       all functions mentioned above. Not exported so not for 
%%       external use.
%% @end
%%--------------------------------------------------------------------
do_operation(Item, Operation) ->
    case server_active() of
	true ->
	    gen_server:cast(?MODULE, init),
	    Reply = gen_server:call(?MODULE, {Operation, Item}),
	    gen_server:cast(?MODULE, close),
	    Reply;
	false -> blackboard ! {error, torrentdata_not_active}
    end.

%%--------------------------------------------------------------------
%% @author Johan Wikström Schützer
%% @doc torrentdata.erl
%% @spec Creates a record with the given arguments;
%%       Id, Size, Percent, Pieces, PiecesFinished.
%%       See the 'torrent' record definition for information
%%       on what values are expected.
%% @end
%%--------------------------------------------------------------------
create_record(Id, Size, Percent, Pieces, Pieces_finished) ->
    #torrent{id=Id, size=Size, percent=Percent,
             pieces=Pieces, pieces_finished=Pieces_finished}.

%%--------------------------------------------------------------------
%% @author Johan Wikström Schützer
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
