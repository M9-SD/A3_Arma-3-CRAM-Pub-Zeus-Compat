//Optimized version of the shells initialization script 
private _entities = param[0];

private _initializedShells = missionNamespace getVariable ["_initializedShells", []];
private _outArray = _initializedShells;
{
	//Placed here because two crams may initialize the same entity twice
	if(_x in _initializedShells) then {continue};
	_outArray pushback _x;
	
	_x spawn {
		_x = _this;

		//Detection loop
		while {alive _x} do {
			_entities = (_x nearObjects ["BulletBase", 5]);
			_entities append (_x nearObjects ["MissileBase", 30]);
			if(count _entities > 0) then {
				_mine = createMine ["APERSMine", getPosATL _x, [], 0];
				_mine setDamage 1;

				//Cleanup
				_initializedShells = missionNamespace getVariable ["_initializedShells", []];
				_initializedShells deleteAt (_initializedShells find _x);
				missionNamespace setVariable ["_initializedShells", _initializedShells];

				deletevehicle _x;
			};
			sleep 0.02;
		};
	};
}foreach _entities;

missionNamespace setVariable ["_initializedShells", _outArray];
true;