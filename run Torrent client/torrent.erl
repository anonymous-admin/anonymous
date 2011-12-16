%% Author: Johan and Massih

-module(torrent).
% Gen server behaviour
-export([init/1,start_link/1,handle_call/3,handle_cast/2,terminate/2]).
% Unused gen_server functions.
-export([handle_info/2, code_change/3]).
-behaviour(gen_server).
-include("defs.hrl").

% Sets the dynamics and spawns the trackers for this torrent.
% Dynamics: Values for downloaded, left, message tag for the tracker and max peers.
%           These are continously retreived by the tracker processes, to be sent to the 
%           trackers. They should change over the course of runtime, so its implemented
%           here as part of the loopdata. The rest of the loopdata is the id of this
%           torrent, a dict containing referenses to each tracker and the number of trackers.

init([Id, Torrent_info]) ->
    gen_server:cast(msg_controller, {subscribe, Id, [{torrent_status, Id}, 
						     {downloaded, Id},
						     {left, Id}]}),
    Dict = dict:new(),
    Dynamics = {Torrent_info#torrent.downloaded, Torrent_info#torrent.left, "started", Torrent_info#torrent.max_peers},
    spawn(fun() -> spawn_trackers(Torrent_info#torrent.trackers, Dict, 0, Torrent_info) end),
    {ok, {Id, Dict, 0, Dynamics}}.

terminate(_Reason, {Id, _Dict, _Entries, _Dynamics}) ->
    gen_server:cast(Id, stop).

start_link([Id, Torrent_info]) ->
    gen_server:start_link({local, Id}, ?MODULE, [Id, Torrent_info], []).

handle_cast(stop, _Data) ->
    {stop, normal, _Data};

% Updates the tracker dict and the number of entries in it.

handle_cast({trackerinfo, {NewDict, NewEntries}}, {Id, _Dict, _Entries, Dynamics}) ->
    {noreply, {Id, NewDict, NewEntries, Dynamics}}; 

% Updates the dynamic values in the loopdata. If it gets torrent_status deleted, it will
% kill this process. In the other parts of the applications messagesending, the status
% of the related torrent is checked. If it is killed, all its related tracker and 
% peers processes should terminate.

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
		    %spawn(fun() -> kill_trackers(Dict) end),
		    supervisor:terminate_child(dynamic_supervisor, Id),
		    terminate([], {Id, [], [], []})
	    end
    end,
    {noreply, {Id, Dict, Entries, Dynamics}};

% Used internally, updates the tracker event.

handle_cast({set_dynamics_event, NewEvent}, {Id, Dict, Entries, {Downloaded, Left, _Event, Max_peers}}) ->
    {noreply, {Id, Dict, Entries, {Downloaded, Left, NewEvent, Max_peers}}}.

% Called by the traacker processes, returns the dynamic data.

handle_call(get_dynamics, _From, {Id, Dict, Entries, Dynamics}) ->
    {reply, Dynamics, {Id, Dict, Entries, Dynamics}}.

%% Starts each tracker trough the dynamic supervisor.
%% Sets its own dynamic with the event "", which is the default event
%% to send to the tracker. In the tracker process we make sure that
%% the first info sent to the tracker is with the event "started".
%% Updates the dict of trackers and proceeds recursively on the
%% given list of tracker records.

spawn_trackers([], Dict, Entries, Torrent_info) ->
    gen_server:cast(Torrent_info#torrent.id, {trackerinfo, {Dict, Entries}});
spawn_trackers([H|T], Dict, Entries, Torrent_info) -> 
    {_, Pid} = dynamic_supervisor:start_tracker(H, Torrent_info),
    %gen_server:cast(Pid, {tracker_request_info,{H#tracker_info{event="started"}, Torrent_info}}),
    gen_server:cast(self(), {set_dynamics_event, ""}),
    NewDict = dict:store(Entries+1, {Pid, H}, Dict),
    spawn_trackers(T, NewDict, Entries+1, Torrent_info).

%% Old function for killing trackers. Not used anymore.
%% This function would kill the trackers, but instead
%% the trackers check for their torrents status, and if it
%% is dead, they terminate.

kill_trackers(Dict) ->
    kill_trackers(dict:fetch_keys(Dict), Dict).
kill_trackers([], _Dict) ->
    ok;
kill_trackers([H|T], Dict) ->
    Id = list_to_atom(H#tracker_info.url),
    supervisor:terminate_child(dynamic_supervisor, Id),
    supervisor:delete_child(dynamic_supervisor, Id),
    kill_trackers(T, Dict).

% Unused gen_server functions.

handle_info(_, _) ->
    ok.

code_change(_, _, _) ->
    ok.
		 
    
