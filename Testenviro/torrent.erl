%%Author: Johan and Massih

-module(torrent).
-export([init/1,start_link/1,handle_call/3,handle_cast/2,terminate/2]).
-behaviour(gen_server).
-include("defs.hrl").

init(Torrent_info) ->
    %%REGISTER AND SUBSCRIBE
    Dict = dict:new(),
    {NewDict, Entries} = spawn_trackers(Torrent_info#torrent.trackers, Dict, 1),
    {ok, {NewDict, Entries}}.

terminate(_Reason, {_Dict, _Entries}) ->
    ok.

start_link([Id, Torrent_info]) ->
    gen_server:start_link({local, Id}, ?MODULE,Torrent_info,[]).

handle_cast(_Operation, {_Dict, _Entries}) ->
    ok.

handle_call(Operation, _From, {Dict, Entries}) ->
    notify_trackers(Dict, Operation, Entries),
    {reply, ok, {Dict, Entries}}.

spawn_trackers([], Dict, Entries) ->
    {Dict, Entries};
spawn_trackers([H|T], Dict, Entries) -> 
    {_, Pid} = dynamic_supevisor:start_tracker([H]),
    Result = gen_server:call(Pid, info_to_send(H,"started")),
    [_Seeders,_Leechers,Interval,_Peers] = Result,
    NewH = H#tracker_info{interval=Interval},
    gen_server:cast(logger, Result),
    LoopId = spawn_link(fun() -> interval_loop(NewH, Pid, "") end),
    NewDict = dict:store(Entries, {Pid, NewH, LoopId}, Dict),
    spawn_trackers(T, NewDict, Entries+1).

interval_loop(Tracker, Pid, Event) ->
    receive
	{event, pause} -> 
	    NewTracker = gen_server:call(logger, {get_tracker, Tracker#tracker_info.url}),
	    gen_server:call(Pid, info_to_send(NewTracker,"pause")),
            interval_loop(Tracker, Pid, "pause");
	{event, completed} -> 
	    NewTracker = gen_server:call(logger, {get_tracker, Tracker#tracker_info.url}),
	    gen_server:call(Pid, info_to_send(NewTracker,"completed")),
            interval_loop(Tracker, Pid, "completed")
    after Tracker#tracker_info.interval ->
	    NewTracker = gen_server:call(logger, {get_tracker, Tracker#tracker_info.url}),
	    gen_server:call(Pid, info_to_send(NewTracker,Event))
    end,
    interval_loop(NewTracker, Pid, Event).

info_to_send(Tracker, Event) ->
    {tracker_request_info, 
     {Tracker#torrent.downloaded, 
     (Tracker#torrent.size-Tracker#torrent.downloaded),
     Event, Tracker#torrent.max_peers}}.

notify_trackers(_Dict, _Event, 0) -> ok;
notify_trackers(Dict, Event, Entries) ->
    {_, _, LoopId} = dict:find(Dict, Entries), 
    LoopId ! {event, Event},
    notify_trackers(Dict, Event, Entries-1).
		 
    
