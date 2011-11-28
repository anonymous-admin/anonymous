-module(directory_test).
-include_lib("eunit/include/eunit.hrl").

create_directories_test_() ->
    [?_assert(directory:create_directories("parent", ["a","b","c","hitch.txt"]) =:= "parent\\a\\b\\c"),
     ?_assert(directory:create_directories("parent", ["a","b","c","d","e","hitch.txt"]) =:= "parent\\a\\b\\c\\d\\e"),
     ?_assert(directory:create_directories("parent", ["a","ff","hitch.txt"]) =:= "parent\\a\\ff")].

make_directories_test_() ->
    [?_assert(directory:make_directories("parent",[["second","ssecond","2.docx"],["first","ffirst","1.txt"]]) =:= "parent\\first\\ffirst")].

handle_directories_test_() ->
    [?_assert(file:set_cwd("C:/parent") =:= ok),
     ?_assert(file:get_cwd() =:= ok),
     ?_assert(directory:handle_directories("C:/parent", List) =:= ok].
