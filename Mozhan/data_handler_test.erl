-module(data_handler_test).
-include_lib("eunit/include/eunit.hrl").
-record (torrent,{filename,files,number_of_pieces,piece_length}).



write_temp_test_() ->
    ?_assert(directory:create_directories("parent", ["a","b","c","hitch.txt"]) =:= "parent\\a\\b\\c"),

make_directories_test_() ->
    io:format("~p~n", [pwd()]),
    ?_assert(directory:make_directories("parent",[["second","ssecond","2.docx"],["first","ffirst","1.txt"]]) =:= "parent\\first\\ffirst").

handle_directories_test_() ->
    [?_assert(file:set_cwd("C:/testenviro/parent") =:= ok),
     ?_assert(file:get_cwd() =:= {ok, "C:/testenviro/parent"),
     ?_assert(directory:handle_directories("C:/testenviro/parent", #torrent{}) =:= ok)].
