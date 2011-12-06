-module(server_util).

-compile([export_all]).

start(ServerName, {Module, Function, Args}) ->
		   case whereis(ServerName) of
		     undefined ->
		       Pid = spawn(Module, Function, Args),
		       register(ServerName, Pid);
		     _ ->
		       ok
		   end.

stop(ServerName) ->
			 case whereis(ServerName) of
			     undefined ->
				 ok;
			     _ ->
				 ServerName!shutdown
			 end.
