%%Author: Johan and Massih

-module(torrent).
-export([init/1,start_link/1,handle_call/3,handle_cast/2,terminate/2]).
-behaviour(gen_server).
-include("defs.hrl").

init(Torrent_info) ->
    Dict = dict:new(),
    {NewDict, Entries} = spawn_trackers(Torrent_info#torrent.trackers, Dict, 1),
    {ok, {NewDict, Entries}}.

terminate(_Reason, {Dict, Entries}) ->
    ok.

start_link(Trackers) ->
    gen_server:start_link(?MODULE,Trackers,[]).

handle_cast(_Operation, {Dict, Entries}) ->
    ok.

handle_call(Operation, _From, {Dict, Entries}) ->
    notify_trackers(Dict, Operation, Entries),
    {reply, ok, {Dict, Entries}}.

spawn_trackers([], Dict, Entries) ->
    {Dict, Entries};
spawn_trackers([H|T], Dict, Entries) -> 
    {_, Pid} = tracker_supevisor:start_tracker([H]),
    Result = gen_server:call(Pid, info_to_send(H,"started")),
    [_Seeders,_Leechers,Interval,_Peers] = Result,
    gen_server:cast(logger, Result),
    LoopId = spawn_link(fun() -> interval_loop(H, Pid, "") end),
    NewDict = dict:store(Entries, {Pid, H, LoopId}, Dict),
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

notify_trackers(Dict, Event, 0) -> ok;
notify_trackers(Dict, Event, Entries) ->
    {_, _, LoopId} = dict:find(Dict, Entries), 
    LoopId ! {event, Event},
    notify_trackers(Dict, Event, Entries-1).
		 
    
