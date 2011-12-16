%% Author: Johan

-module(dynamic_supervisor).
-behaviour(supervisor).
% Supervisor exports
-export([start_link/0, init/1]).
% Exports for intermodule use 
-export([start_torrent/1, start_tracker/2, start_peer/3]). 
-include("defs.hrl").

% Supervisor functionality

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, [{debug, [trace]}]).

init(_Args) ->
    {ok,{{one_for_one,3,1}, []}}.

% Starts the given tracker as a process, with the Tracker and Torrent records
% as arguments. Interval for timeout is set to 3000 first time, this changes
% after the init call in the tracker process.

start_tracker(Tracker, Torrent) ->
    Id = list_to_atom(Tracker#tracker_info.url),
    TrackerChild = {Id, {tracker_interactor, start_link, [[Tracker, 3000, Torrent]]},
			 transient, brutal_kill, worker, [tracker_interactor]},
    supervisor:start_child(dynamic_supervisor, TrackerChild).

% Starts a torrent process, with the Torrent record as argument.

start_torrent(Torrent) ->
    Id = Torrent#torrent.id,
    TorrentChild = {Id, {torrent, start_link, [[Id, Torrent]]},
			 transient, brutal_kill, worker, [torrent]},
    supervisor:start_child(dynamic_supervisor, TorrentChild).

% Starts a peer process, with the given Torrent record, Ip and Port
% as arguments.

start_peer(Torrent, Ip, Port) ->
    Id = list_to_atom(Ip),
    case whereis(Id) of
	undefined ->
	    PeerChild = {Id, {peers_interactor, start_link, [[Torrent, Ip, Port]]},
			 transient, brutal_kill, worker, [peers_interactor]},
	    supervisor:start_child(dynamic_supervisor, PeerChild);
	_         -> false
    end.
