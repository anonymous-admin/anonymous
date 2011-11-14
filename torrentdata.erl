%%%-------------------------------------------------------------------
%%% @author Johan Wikström Schützer
%%% @copyright (C) 2011 Johan Wikström Schützer
%%% @doc torrentdata.erl
%%%
%%% @end
%%% Created : 10 Nov 2011 by Johan Wikström Schützer
%%%-------------------------------------------------------------------

-module(torrentdata).
-export([start/0, create_record/5, stop/0, insert/2, update/2, lookup/2, delete/2]).

%%--------------------------------------------------------------------
%% @author Johan Wikström Schützer
%% @doc torrentdata.erl
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
-record(torrent,
       {id,
	size,
	percent,
	pieces,
	pieces_finished}).

%%--------------------------------------------------------------------
%% @author Johan Wikström Schützer
%% @doc torrentdata.erl
%% @spec Starts this server, should only be used once (at startup) 
%%       or, if it is connected to a supervising process, it should 
%%       be restarted in case of crash).
%% @end
%%--------------------------------------------------------------------	
start() ->
    case server_active() of
	true  -> {error, already_started};
	false -> register(torrentdata_process, 
			  spawn(fun() -> loop() end))
    end.

%%--------------------------------------------------------------------
%% @author Johan Wikström Schützer
%% @doc torrentdata.erl
%% @spec Stops this server. Should only be used once, at normal
%%       termination of the application.
%% @end
%%--------------------------------------------------------------------
stop() ->
    case server_active() of
	true  -> 
	    torrentdata_process ! {close, true};
	false -> {error, already_stopped}
    end.    

%%--------------------------------------------------------------------
%% @author Johan Wikström Schützer
%% @doc torrentdata.erl
%% @spec Inserts a torrent record into the table. Takes a torrent
%%       record and caller pid as arguments (use create_record/5 to 
%%       create a record correctly).
%% @end
%%--------------------------------------------------------------------
insert(Record, From) ->
    do_operation(Record, From, insert).

%%--------------------------------------------------------------------
%% @author Johan Wikström Schützer
%% @doc torrentdata.erl
%% @spec Updates an existin torrent record into the table. 
%%       Takes a torrent record and caller pid as arguments 
%%       (use create_record/5 to create a record correctly).
%% @end
%%--------------------------------------------------------------------
update(Record, From) ->
    do_operation(Record, From, update).

%%--------------------------------------------------------------------
%% @author Johan Wikström Schützer
%% @doc torrentdata.erl
%% @spec Returns a torrent record. Takes the Key and the caller Pid
%%       as arguments. Make sure that the Key is correct (see the
%%       function create_record/5 for more information). 
%% @end
%%--------------------------------------------------------------------
lookup(Key, From) ->
    do_operation(Key, From, lookup).

%%--------------------------------------------------------------------
%% @author Johan Wikström Schützer
%% @doc torrentdata.erl
%% @spec Deletes a torrent record. Takes Key and caller Pid as
%%       arguments.
%% @end
%%--------------------------------------------------------------------
delete(Key, From) ->
    do_operation(Key, From, delete).

%%--------------------------------------------------------------------
%% @author Johan Wikström Schützer
%% @doc torrentdata.erl
%% @spec Used by insert/2, update/2, lookup/2 and delete/2. Used to
%%       simplify and compress code, contains operations needed in 
%%       all functions mentioned above. Not exported so not for 
%%       external use.
%% @end
%%--------------------------------------------------------------------
do_operation(Item, From, Operation) ->
    case server_active() of
	true ->
	    torrentdata_process ! {init},
	    torrentdata_process ! {Operation, Item, From},
	    torrentdata_process ! {close, false},
	    receive_reply();
	false -> {error, server_not_active}
    end.

%%--------------------------------------------------------------------
%% @author Johan Wikström Schützer
%% @doc torrentdata.erl
%% @spec The server loop. Handles all the messages passed from the
%%       other functions in this module. This loop is started by the
%%       start/0 function, so this is not to be used directly.
%% @end
%%--------------------------------------------------------------------
loop() ->
    receive
	{init} ->
	    dets:open_file(torrentdata, [{type, set}]),
	    loop();
	{insert, Record, From} ->
	    Bool = dets:insert_new(torrentdata, {Record#torrent.id, Record}),
	    case Bool of
		true  -> reply(From, {ok, inserted});
		false -> reply(From, {error, no_unique_key})
            end,
	    loop();
	{update, Record, From} ->
            case dets:lookup(torrentdata, Record#torrent.id) of
		[] -> Reply = {error, no_existing_record};
                _  -> Reply = dets:insert(torrentdata, 
					 {Record#torrent.id, Record})
            end,
	    reply(From, Reply),
	    loop();
	{lookup, Key, From} ->
            [Record] = dets:lookup(torrentdata, Key),
	    reply(From, Record),
	    loop();
        {delete, Key, From} ->
	    Reply = dets:delete(torrentdata, Key),
	    reply(From, Reply),
	    loop();
        {close, Shall_stop} ->
	    dets:sync(torrentdata),
	    dets:close(torrentdata),
	    case Shall_stop of
		true  -> {ok, stopped};
                false -> loop()
            end
    end.

%%--------------------------------------------------------------------
%% @author Johan Wikström Schützer
%% @doc torrentdata.erl
%% @spec A simple reply function. Used in the loop to given the caller
%%       confirmation messages.
%% @end
%%--------------------------------------------------------------------
reply(Pid, Reply) ->
    Pid ! {reply, Reply}.

%%--------------------------------------------------------------------
%% @author Johan Wikström Schützer
%% @doc torrentdata.erl
%% @spec A simple receive reply function. Used in every caller
%%       caller
%% @end
%%--------------------------------------------------------------------
receive_reply() ->
    receive
	{reply, Reply} ->
	    Reply
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
    case whereis(torrentdata_process) of
	undefined -> false;
	_         -> true
    end.
