% Accomplish a given Task and return the Cost
solve_task(Task,Cost) :-
    my_agent(A), get_agent_position(A,P),
    get_agent_energy(A, Energy),
    (
        can_reach_target(Task, P, Path, PathCost),
        (
            Energy >= PathCost,
            format("Energy available: ~w, Cost to target: ~w~n", [Energy, PathCost]),
            agent_do_moves(A, Path), length(Path, Cost)
        ;
            find_best_charging_station(Task, P, Energy, Station, ChargePath, TargetPath, Cost),
            agent_do_moves(A, ChargePath),
            agent_topup_energy(A, Station),
            agent_do_moves(A, TargetPath)
        )
        ;
        format("Target unreachable. Energy: ~w~n", [Energy]),
        fail
    ).
    %solve_task_dfs(Task,[P],[P|Path]), !,
    %solve_task_bfs(Task, [[P]], [], Pathbfs),
    %heuristic(Task, P, F), solve_task_astar(Task, [[F, P, []]], [], Path),
    %agent_do_moves(A,Path), length(Path,Cost).

find_all_stations(Stations) :-
    ailp_grid_size(N),
    findall(c(ID)-p(X, Y), (between(1, N, X), between(1, N, Y), lookup_pos(p(X, Y), c(ID))), Stations).

can_reach_target(Task, StartPos, Path, Cost) :-
    heuristic(Task, StartPos, F),
    solve_task_astar(Task, [[F, StartPos, []]], [], Path),
    length(Path, Cost).

find_best_charging_station(Task, StartPos, EnergyAvailable, Station, ChargePath, TargetPath, Cost) :-
    find_all_stations(Stations),
    Stations \= [],
    get_best_station(Task, Stations, StartPos, EnergyAvailable, Station, ChargePath, TargetPath, Cost).

get_best_station(Task, Stations, StartPos, EnergyAvailable, BestStation, BestChargePath, BestTargetPath, BestCost) :-
    findall([Cost, Object, ChargePath, TargetPath], (member(Object-_, Stations), heuristic(find(Object), StartPos, F), solve_task_astar(find(Object), [[F, StartPos, []]], [], ChargePath), length(ChargePath, ChargeCost), EnergyAvailable>=ChargeCost, format("This costs ~w and we have ~w ~n", [ChargeCost, EnergyAvailable]),
        get_final_position(ChargePath, AgentStationPos), heuristic(Task, AgentStationPos, F1), solve_task_astar(Task, [[F1, AgentStationPos, []]], [], TargetPath), length(TargetPath, TargetCost),
    Cost is ChargeCost+TargetCost), Costs),
    sort(Costs, [[BestCost, BestStation, BestChargePath, BestTargetPath]|_]).

get_final_position([Pos], Pos).
get_final_position([_|Rest], Pos) :- get_final_position(Rest, Pos).

% Although achieved theoretically does this, this is a failsafe
solve_task_astar(find(Object), [[_, Pos|Path]|_],_, Solution) :-
    map_adjacent(Pos, _, Object), reverse([Pos|Path], Solution).

solve_task_astar(Task, [[_, Pos|Path]|_],_, RPath) :-
	achieved(Task, Pos),
	reverse([Pos|Path], [_|[_|RPath]]).

solve_task_astar(Task, [[_, Pos|Path]|Rest], Visited, Solution) :-
	findall([F1, NewPos, Pos|Path], (
		map_adjacent(Pos, NewPos, empty), \+ member(NewPos, Visited), \+ member([_, NewPos|_], Rest),
		length([NewPos, Pos|Path], G), heuristic(Task, NewPos, H), F1 is G+H
	), Children),
	append(Rest, Children, N),
	sort(N, S),
	solve_task_astar(Task, S, [Pos|Visited], Solution).

heuristic(go(TargetPos), Pos, H) :-
    map_distance(Pos, TargetPos, H).

heuristic(find(_), _, 0).

% True if the Task is achieved with the agent at Pos
achieved(Task,Pos) :- 
    Task=find(Obj), map_adjacent(Pos,_,Obj)
    ;
    Task=go(Pos).
