%% Author: Johan

-module(dynamic_supervisor).
-behaviour(supervisor).
-export([start_link/0, init/1, start_torrent/1, start_tracker/2, start_peer/3]). 
-include("defs.hrl").

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, [{debug, [trace]}]).

init(_Args) ->
    {ok,{{one_for_one,3,1}, []}}.

start_tracker(Tracker, Torrent) ->
    Id = list_to_atom(Tracker#tracker_info.url),
    TrackerChild = {Id, {tracker_interactor, start_link, [[Tracker, 3000, Torrent]]},
			 transient, 2000, worker, [tracker_interactor]},
    supervisor:start_child(dynamic_supervisor, TrackerChild).

start_torrent(Torrent) ->
    Id = Torrent#torrent.id,
    TorrentChild = {Id, {torrent, start_link, [[Id, Torrent]]},
			 transient, 2000, worker, [torrent]},
    supervisor:start_child(dynamic_supervisor, TorrentChild).

start_peer(Torrent, Ip, Port) ->
    Id = list_to_atom(Ip),
    case whereis(Id) of
	undefined ->
	    PeerChild = {Id, {peers_interactor, start_link, [[Torrent, Ip, Port]]},
			 transient, 2000, worker, [peers_interactor]},
	    supervisor:start_child(dynamic_supervisor, PeerChild);
	_         -> false
    end.
