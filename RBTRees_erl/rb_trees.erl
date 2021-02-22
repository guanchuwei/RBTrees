%%%-------------------------------------------------------------------
%%% @author Administrator
%%% @copyright (C) 2021, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 一月 2021 14:43
%%%-------------------------------------------------------------------
-module(rb_trees).
-author("ChuWei").

-include("common.hrl").

%% API
-export([
    left_rotate/1
    , build_tree/0
    , insert/3
    , lookup/2
%%    , insert_test/3
    , right_rotate/1
    , empty/0
    , test_gb/1
    , test_rb/1
    , test_lookup_rb/2
    , test_lookup_gb/2
    , to_list/1
]).

-record(rb_node, {
    key = null
    ,val = null
    ,color = black
    ,left = null
    ,right = null

}).

test_lookup_rb(Key, RbTree) ->
    ?gcw("==================开始 ~w", [lib_time:unixtime(ms)]),
    T = lookup(Key, RbTree),
    ?gcw("==================结束 ~w", [lib_time:unixtime(ms)]),
    T.

test_lookup_gb(Key, GbTree) ->
    ?gcw("==================开始 ~w", [lib_time:unixtime(ms)]),
    T = gb_trees:lookup(Key, GbTree),
    ?gcw("==================结束 ~w", [lib_time:unixtime(ms)]),
    T.

test_gb(Num) ->
    ST = gb_trees:empty(),
    Start = lib_time:unixtime(ms),
    T =do_test(Num, ST),
    End = lib_time:unixtime(ms),
    ?gcw("==================开始 ~w", [Start]),
    ?gcw("==================结束 ~w", [End]),
    End - Start.

do_test(Num, ST) when Num =< 0 -> ST;
do_test(Num, ST) ->
    do_test(Num - 1, gb_trees:insert(Num, Num, ST)).

test_rb(Num) ->
    ST = empty(),
    Start = lib_time:unixtime(ms),
    T = do_test_rb(Num, ST),
    End = lib_time:unixtime(ms),
    ?gcw("==================开始 ~w", [Start]),
    ?gcw("==================结束 ~w", [End]),
    End - Start.

do_test_rb(Num, ST) when Num =< 0 -> ST;
do_test_rb(Num, ST) ->
    do_test_rb(Num - 1, insert(Num, Num, ST)).


%% 左旋
%%       p                           pr
%%      / \                         /  \
%%     pl  pr          =>          p    rr
%%        / \                     / \
%%       rl  rr                  pl  rl

left_rotate(NodeP) ->
    #rb_node{right = Pr} = NodeP,
    case Pr of
        #rb_node{left = Rl} ->
            NodeP1 = NodeP#rb_node{right = Rl},
            Pr1 = Pr#rb_node{left = NodeP1},
            Pr1;
        _ ->
            %% 右孩子为空
            NodeP
    end.


%% 右旋
%%       p                           pl
%%      / \                         /  \
%%     pl  pr          =>          rl    p
%%    / \                               / \
%%  rl  rr                             rr  pr
right_rotate(NodeP) ->
    #rb_node{left = Pl} = NodeP,
    case Pl of
        #rb_node{right = Rr} ->
            NodeP1 = NodeP#rb_node{left = Rr},
            Pl1 = Pl#rb_node{right = NodeP1},
            Pl1;
        _ ->
            %% 左孩子为空
            NodeP
    end.

build_tree() ->
    RR = #rb_node{key = 8, val = 8},
    Rl = #rb_node{key = 6, val = 6},
    Pr = #rb_node{key = 7, val = 7, left = Rl, right = RR},
    Pl = #rb_node{key = 4, val = 4},
    P = #rb_node{key = 5, val = 5, right = Pr, left = Pl},
    P.

%%%% 插入操作
%%%% 根节点
%%insert_test(K, V, Trees = #rb_node{key = null}) ->
%%    Trees#rb_node{key = K, val = V};
%%%% 左子树
%%insert_test(K, V, Trees = #rb_node{key = Key, left = Left}) when K < Key ->
%%    case Left of
%%        #rb_node{} ->
%%            T = #rb_node{} = insert_test(K, V, Left),
%%            Trees#rb_node{left = T};
%%        _ ->
%%            Trees#rb_node{left = #rb_node{key = K, val = V}}
%%    end;
%%%% 右子树
%%insert_test(K, V, Trees = #rb_node{key = Key, right = Right}) when K > Key ->
%%    case Right of
%%        #rb_node{} ->
%%            T = #rb_node{} = insert_test(K, V, Right),
%%            Trees#rb_node{right = T};
%%        _ -> Trees#rb_node{right = #rb_node{key = K, val = V}}
%%    end;
%%%% 相同key值
%%insert_test(_K, V, Trees = #rb_node{}) ->
%%    Trees#rb_node{val = V}.


insert(K, V, Root = #rb_node{}) ->
    Node = #rb_node{key = K, val = V, color = red},
    case insert_1(Node, Root, null) of
        {skip, Node1} ->
            Node1#rb_node{color = black};
        Node1 -> Node1#rb_node{color = black}
    end. %% 根节点一定是黑色

%% Node 插入节点; Trees 父节点; GrandNode 祖父节点
insert_1(N = #rb_node{}, #rb_node{key = null}, _GrandNode) -> N; %% 根节点
insert_1(N = #rb_node{key = K}, Father = #rb_node{key = Key, left = Left, color = FatherColor}, GrandNode) when K < Key ->
    case insert_1(N, Left, Father) of
        %% 递归返回节点
        {skip, Node = #rb_node{}} -> Node;
        Node = #rb_node{color = black} -> Father#rb_node{left = Node};
        %% 返回来的节点是红色，向上递归检查
        Node = #rb_node{} ->
            case GrandNode of
                null -> %% 根节点了
                    Father#rb_node{left = Node};
                _ ->
                    case FatherColor of
                        red -> %% 父亲节点是红色
                            #rb_node{left = GrandLeft, right = GrandRight} = GrandNode,
                            UncleNode = ?IF(GrandRight =:= null orelse (GrandLeft =/= null andalso GrandLeft#rb_node.key =:= Father#rb_node.key), GrandRight, GrandLeft),
                            if
                            %% 父亲是祖父节点的左节点  左倾一条直线变色右旋  自下而上 ： 红 - 红 - 黑
                            %% 先将父亲节点染黑，新增节点和祖父节点变红，然后右旋
                                GrandLeft#rb_node.key =:= Father#rb_node.key andalso (UncleNode =:= null orelse UncleNode#rb_node.color =:= black) ->
                                    NFNode = Father#rb_node{color = black, left = Node},
                                    NewGrandNode = GrandNode#rb_node{color = red, left = NFNode},
                                    {skip, right_rotate(NewGrandNode)};
                            %% 父亲是祖父节点的右节点  这种情况需要以父亲节点右旋，达到一条直线，然后再进行变色左旋    自下而上 ： 红 - 红 - 黑
                            %% 将插入节点染黑，祖父节点染红，然后以父亲节点右旋 再按插入节点左旋     红（祖父） - 黑 (插入) - 红(父亲)
                                GrandRight#rb_node.key =:= Father#rb_node.key andalso (UncleNode =:= null orelse UncleNode#rb_node.color =:= black) ->
                                    BlackNode = Node#rb_node{color = black},
                                    NewF = Father#rb_node{left = BlackNode},
                                    TempNode = right_rotate(NewF),
                                    NewGrandNode = GrandNode#rb_node{right = TempNode, color = red},
                                    {skip, left_rotate(NewGrandNode)};
                            %% 其他情况，叔叔节点是红色
                                true ->
                                    NFNode = Father#rb_node{left = Node, color = black},
                                    NUNode = UncleNode#rb_node{color = black},
                                    NewGrandNode = ?IF(GrandLeft#rb_node.key =:= Father#rb_node.key, GrandNode#rb_node{color = red, left = NFNode, right = NUNode}, GrandNode#rb_node{color = red, left = NUNode, right = NFNode}),
                                    {skip, NewGrandNode}
                            end;
                        black -> %% 父亲节点是黑色
                            Father#rb_node{left = Node}
                    end
            end;
        _Else -> _Else
    end;
insert_1(N = #rb_node{key = K}, Father = #rb_node{key = Key, right = Right, color = FatherColor}, GrandNode) when K > Key ->
    case insert_1(N, Right, Father) of
        %% 递归返回节点
        {skip, Node = #rb_node{}} -> Node;
        Node = #rb_node{color = black} -> Father#rb_node{right = Node};
        %% 返回来的节点是红色，向上递归检查
        Node = #rb_node{} ->
            case GrandNode of
                null -> %% 根节点了
                    Father#rb_node{right = Node};
                _ ->
                    case FatherColor of
                        red -> %% 父亲节点是红色
                            #rb_node{left = GrandLeft, right = GrandRight} = GrandNode,
                            UncleNode = ?IF(GrandLeft =:= null orelse (GrandRight =/= null andalso GrandRight#rb_node.key =:= Father#rb_node.key), GrandLeft, GrandRight),
                            if
                                GrandRight#rb_node.key =:= Father#rb_node.key andalso (UncleNode =:= null orelse UncleNode#rb_node.color =:= black) ->
                                    NFNode = Father#rb_node{color = black, right = Node},
                                    NewGrandNode = GrandNode#rb_node{color = red, right = NFNode},
                                    {skip, left_rotate(NewGrandNode)};
                                GrandLeft#rb_node.key =:= Father#rb_node.key andalso (UncleNode =:= null orelse UncleNode#rb_node.color =:= black) ->
                                    BlackNode = Node#rb_node{color = black},
                                    NewF = Father#rb_node{right = BlackNode},
                                    TempNode = left_rotate(NewF),
                                    NewGrandNode = GrandNode#rb_node{left = TempNode, color = red},
                                    {skip, right_rotate(NewGrandNode)};
                            %% 其他情况，叔叔节点是红色
                                true ->
                                    NFNode = Father#rb_node{right = Node, color = black},
                                    NUNode = UncleNode#rb_node{color = black},
                                    NewGrandNode = ?IF(GrandLeft#rb_node.key =:= Father#rb_node.key, GrandNode#rb_node{color = red, left = NFNode, right = NUNode}, GrandNode#rb_node{color = red, left = NUNode, right = NFNode}),
                                    {skip, NewGrandNode}
                            end;
                        black -> %% 父亲节点是黑色
                            Father#rb_node{right = Node}
                    end
            end;
        _Else ->
            _Else
    end;
insert_1(Node, null, _) -> Node;
insert_1(_Node = #rb_node{key = Key}, _, _) -> erlang:error({key_exists, Key}).


%% 查找
lookup(Key, #rb_node{val = Val, key = Key}) -> {ok, Val};
lookup(Key, #rb_node{key = K, left = Left}) when Key < K -> lookup(Key, Left);
lookup(Key, #rb_node{key = K, right = Right}) when Key > K -> lookup(Key, Right);
lookup(_Key, null) -> false.


%% 新建
empty() ->
    #rb_node{}.


to_list(RbTree) ->
    to_list(RbTree, []).

to_list(#rb_node{key = Key, left = Left, right = Right}, L) ->
    to_list(Left, [Key | to_list(Right, L)]);
to_list(null, L) ->
    L.


