% Accomplish a given Task and return the Cost
solve_task(Task,Cost) :-
    my_agent(A), get_agent_position(A,P),
    format("Starting task: ~w from position ~w~n", [Task, P]),
    get_agent_energy(A, Energy),
    format("Starting bfs ~n"),
    find_all_stations(Stations),
    format("Stations: ~w~n", [Stations]),
    (
        can_reach_target(Task, P, Path, PathCost),
        Energy >= PathCost,
        format("Energy available: ~w, Cost to target: ~w~n", [Energy, PathCost]),
        agent_do_moves(A, Path), length(Path, Cost),
        format("Task completed directly. Path: ~w, Cost: ~w~n", [Path, Cost])
    ;
        format("Energy insufficient to reach target or target unreachable. Energy: ~w~n", [Energy]),
        \+ can_reach_target(Task, P, _, _),
        find_best_charging_station(Task, P, Energy, ChargePath, TargetPath, Cost),
        format("Path to charging station: ~w~n", [ChargePath]),
        agent_do_moves(A, ChargePath),
        agent_topup_energy(A),
        agent_do_moves(A, TargetPath)
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
    length(Path, Cost),
    my_agent(A),
    get_agent_energy(A, Energy),
    Energy>=Cost,
    format("Path to target found: ~w, Cost: ~w~n", [Path, Cost]).

find_best_charging_station(Task, StartPos, EnergyAvailable, ChargePath, TargetPath, Cost) :-
    format("Finding best charging station from position ~w with energy ~w~n", [StartPos, EnergyAvailable]),
    find_all_charging_stations(StartPos, EnergyAvailable, Stations),
    format("Charging stations found: ~w~n", [Stations]),
    Stations \= [],
    select_best_station(Task, Stations, StartPos, EnergyAvailable, ChargePath, TargetPath, Cost).

select_best_station(Task, Stations, _, EnergyAvailable, BestChargePath, BestTargetPath, BestCost) :-
    format("Selecting best charging station from: ~w~n", [Stations]),
    findall([Cost, ChargePath, TargetPath], (member([Station, ChargePath, StationCost], Stations), EnergyAvailable>=StationCost, heuristic(Task, Station, F), solve_task_astar(Task, [[F, Station, []]], [], TargetPath), length(TargetPath, TargetCost),
        Cost is StationCost+TargetCost), Costs),
    sort(Costs, [[BestCost, BestChargingPath, BestTargetPath]|_]),
    format("Best charging station chosen. Cost: ~w, Charge path: ~w, Target path: ~w~n", [BestCost, BestChargePath, BestTargetPath]).

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

% Calculate the path required to achieve a Task
solve_task_dfs(Task,[P|Ps],Path) :-
    achieved(Task,P), reverse([P|Ps],Path)
    ;
    map_adjacent(P,Q,empty), \+ member(Q,Ps),
    solve_task_dfs(Task,[Q,P|Ps],Path).

solve_task_bfs(Task, [[Pos|Path]|_], _, RPath) :-
	achieved(Task, Pos),
	reverse([Pos|Path], [_|RPath]).

solve_task_bfs(Task, [[Pos|Path]|Rest], Visited, Solution) :-
	findall([NewPos, Pos|Path], (map_adjacent(Pos, NewPos, empty), \+ member(NewPos, Visited), \+ member([NewPos|_], Rest)), Children),
	append(Rest, Children, N),
	solve_task_bfs(Task,N, [Pos|Visited], Solution).

% True if the Task is achieved with the agent at Pos
achieved(Task,Pos) :- 
    Task=find(Obj), map_adjacent(Pos,_,Obj)
    ;
    Task=go(Pos).
