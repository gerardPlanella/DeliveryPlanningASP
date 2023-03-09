#const t=40.
possible_time(1..t).
node(1).
node(2).
node(3).
node(4).
node(5).
node(6).
edge(1,2).
edge(2,3).
edge(3,4).
edge(4,5).
edge(2,6).
edge(3,6).
delivery_point(4).
delivery_point_demand(4,2).
delivery_point(5).
delivery_point_demand(5,2).
charging_point(2).
charging_point(6).
warehouse(1).
warehouse_load(1,10).
truck(1).
truck_at(1, 1).
truck_load(1, 0).
truck_capacity(1, 1).
truck_charge_level(1, 2).
truck_charge_capacity(1, 10).
truck(2).
truck_at(2, 2).
truck_load(2, 0).
truck_capacity(2, 1).
truck_charge_level(2, 2).
truck_charge_capacity(2, 10).
{ time(T) : possible_time(T) }.
:- not time(1).
:- possible_time(T), possible_time(T+1), not time(T), time(T+1).

% Store the last time step
max_time(MaxTime) :- MaxTime = #max { T : time(T) }.

action(wait).
action(load(I)) :- warehouse(I).
action(unload(I)) :- delivery_point(I).
action(charge(I)) :- charging_point(I).
edge(X,Y) :- edge(Y,X).
action(move(I,N)) :- edge(I,N).
1 { do(T,TR,A) : action(A) } 1 :- time(T), truck(TR).


:- do(T,TR,move(X,_)), state(T,truck_at(TR,Z)), Z!=X.
:- do(T,TR,load(X)), state(T,truck_at(TR,Z)), Z!=X.
:- do(T,TR,unload(X)), state(T,truck_at(TR,Z)), Z!=X.
:- do(T,TR,charge(X)), state(T,truck_at(TR,Z)), Z!=X.  


% Initial states.
state(1,truck_at(TR,P)) :- truck_at(TR,P).

% State if the truck moved.
state(T+1,truck_at(TR,Y)) :- do(T,TR,move(X,Y)), state(T,truck_at(TR,X)). 
state(T+1,truck_charge_level(TR,L-1)) :-  state(T,truck_charge_level(TR,L)), do(T,TR,move(_,_)).

% State if the truck didn't move.
state(T+1,truck_at(TR,P)) :- do(T,TR,_), state(T,truck_at(TR,P)), not do(T,TR,move(_,_)).
state(T+1,truck_charge_level(TR,L)) :-  state(T,truck_charge_level(TR,L)), do(T,TR,_),
  not do(T,TR,move(_,_)), not do(T,TR,charge(_)).


:- do(T,ID,charge(_)), state(T,truck_charge_level(ID,L)),truck_charge_capacity(ID,C), L==C.
state(T+1,truck_charge_level(ID,L+1)) :- do(T,ID,charge(_)), state(T,truck_charge_level(ID,L)).

 


% load

% Intial states.
state(1,truck_load(TR,L)) :- truck_load(TR,L).
state(1,warehouse_load(ID,L)) :- warehouse_load(ID,L).
state(1,delivery_point_demand(ID,D)) :- delivery_point_demand(ID,D).
  
% truck must have space left.
:- do(T,TR,load(_)), state(T,truck_load(TR,L)),truck_capacity(TR,L).
% warehouse must have items.
:- do(T,TR,load(I)), state(T,warehouse_load(I,0)).

% check if truck capacity check is needed here, I think is not needed.
state(T+1,truck_load(ID,L+1)) :- do(T,ID,load(_)),state(T,truck_load(ID,L)),truck_capacity(ID,C),L<C.
state(T+1,warehouse_load(ID,L-1)) :- do(T,TR,load(ID)), state(T,warehouse_load(ID,L)).

% unload

% truck should have load.
:- do(T,TR,unload(_)), state(T, truck_load(TR,0)).
% delivery point should need more items.
:- do(T,TR,unload(_)), state(T,delivery_point_demand(I,0)).

state(T+1, truck_load(TR,L-1)) :- do(T,TR,unload(_)), state(T,truck_load(TR,L)).
state(T+1,delivery_point_demand(I,D-1)) :- do(T,TR,unload(I)), state(T,delivery_point_demand(I,D)).

% If no load/unload happened

state(T+1,truck_load(TR,L)) :-  state(T,truck_load(TR,L)), do(T,TR,move(_,_)).
state(T+1,truck_load(TR,L)) :-  state(T,truck_load(TR,L)), do(T,TR,wait).
state(T+1,truck_load(TR,L)) :-  state(T,truck_load(TR,L)), do(T,TR,charge(_)).
state(T+1,delivery_point_demand(I,D)) :- state(T,delivery_point_demand(I,D)), do(T,_,_) , not do(T,_,unload(I)).
state(T+1,warehouse_load(ID,L)) :-  state(T,warehouse_load(ID,L)),do(T,_,_) , not do(T,_,load(ID)).



%initial state of battery.
state(1,truck_charge_level(TR,L)) :- truck_charge_level(TR,L).

:- do(T,TR,move(_,_)), state(T,truck_charge_level(TR,0)).

% NO TRUCK ON THE SAME EDGE.
% I think the first one is not needed.
:- do(T,ID,move(X,Y)),do(T,ID2,move(X,Y)), ID!=ID2.
:- do(T,ID,move(X,Y)),do(T,ID2,move(Y,X)), ID!=ID2.

% NO TRUCK ON THE SAME NODE
:- state(T,truck_at(ID,X)), state(T,truck_at(ID2,X)), ID != ID2.



goal_reached(T-1) :-  state(T,_);
  state(T, delivery_point_demand(I,0)) : delivery_point(I);
  state(T, truck_at(_,L)) : charging_point(L);
  state(T, truck_at(TR,_)) :truck(TR);
  state(T,truck_load(Z,0)):truck(Z).

  
:- max_time(M), not goal_reached(M).
:- max_time(M), goal_reached(T), time(T), T < M.
#minimize { 1,T : state(T,_) }.

#show do/3.
#show state/2.
#show goal_reached/1.