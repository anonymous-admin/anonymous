%% Author: Johan and Massih

-module(torrent).
-export([init/1,start_link/1,handle_call/3,handle_cast/2,terminate/2]).
-export([handle_info/2, code_change/3]).
-behaviour(gen_server).
-include("defs.hrl").

init([Id, Torrent_info]) ->
    gen_server:cast(msg_controller, {subscribe, Id, [{torrent_status, Id}, 
						     {downloaded, Id},
						     {left, Id}]}),
    Dict = dict:new(),
    Dynamics = {Torrent_info#torrent.downloaded, Torrent_info#torrent.left, "started", Torrent_info#torrent.max_peers},
    spawn(fun() -> spawn_trackers(Torrent_info#torrent.trackers, Dict, 1, Torrent_info) end),
    {ok, {Id, Dict, 0, Dynamics}}.

terminate(_Reason, {Id, _Dict, _Entries, _Dynamics}) ->
    gen_server:cast(Id, stop).

start_link([Id, Torrent_info]) ->
    gen_server:start_link({local, Id}, ?MODULE, [Id, Torrent_info], []).

handle_cast(stop, _Data) ->
    {stop, normal, _Data};

handle_cast({trackerinfo, {NewDict, NewEntries}}, {Id, _Dict, _Entries, Dynamics}) ->
    {noreply, {Id, NewDict, NewEntries, Dynamics}}; 

handle_cast({notify, Tag, {Id, Value}}, {Id, Dict, Entries, {Downloaded, Left, Event, Max_peers}}) ->
    case Tag of 
	downloaded     -> Dynamics = {Value, Left, Event, Max_peers};
        left           -> Dynamics = {Downloaded, Value, Event, Max_peers};
	max_peers      -> Dynamics = {Downloaded, Left, Event, Value};
        torrent_status -> 
	    case Value of 
		paused    -> Dynamics = {Downloaded, Left, "stopped", Max_peers};
		completed -> Dynamics = {Downloaded, Left, "completed", Max_peers};
		resumed   -> Dynamics = {Downloaded, Left, "", Max_peers};
		deleted   -> 
		    Dynamics = {Downloaded, Left, "", Max_peers},
		    kill_trackers(Dict, Entries),
		    terminate([], {Id, [], [], []})
	    end
    end,
    {noreply, {Id, Dict, Entries, Dynamics}}.

handle_call(get_dynamics, _From, {Id, Dict, Entries, Dynamics}) ->
    {reply, Dynamics, {Id, Dict, Entries, Dynamics}}.

%% Starts each tracker trough the dynamic supervisor, sends started to them.
%% Gets the interval for said tracker, and updates the record with new interval,
%% sends the information to the blackboard, spawns the interval loop for said tracker
%% with the empty flag. Store the information in the dict.
%% Loop until all trackers are spawned.
%% 
%% H = tracker record
%% Dict = new dict which get filled with....
%% Entries = number of entries
%% Id = torrent id

spawn_trackers([], Dict, Entries, Torrent_info) ->
    gen_server:cast(Torrent_info#torrent.id, {trackerinfo, {Dict, Entries}});
spawn_trackers([H|T], Dict, Entries, Torrent_info) -> 
    {_, Pid} = dynamic_supervisor:start_tracker(H, Torrent_info),
    NewDict = dict:store(Entries, {Pid, H}, Dict),
    spawn_trackers(T, NewDict, Entries+1, Torrent_info).

kill_trackers(_, 0) ->
    ok;
kill_trackers(Dict, Entries) ->
    {ok, {Pid, _}} = dict:find(Entries),
    gen_server:cast(Pid, stop),
    kill_trackers(Dict, Entries-1).

handle_info(_, _) ->
    ok.

code_change(_, _, _) ->
    ok.
		 
    
