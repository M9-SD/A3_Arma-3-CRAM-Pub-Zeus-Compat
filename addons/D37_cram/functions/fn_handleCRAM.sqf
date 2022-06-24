_unit       = param[0];
_distance   = param[1, 2500];
_tgtLogic 	= param[2, 0];
_typeArray 	= param[3, ["ShellBase","RocketBase","MissileBase"]];
_ignored	= param[4, ["ammo_Missile_rim116"]];

if(_unit getVariable ["init",false]) exitWith {};
_unit setVariable ["init", true];

_unit setVariable ["_tgtLogic", _tgtLogic];
_unit addAction ["Change targeting mode", {
	params ["_target", "_caller", "_actionId", "_arguments"];
	_tgtLogic = _target getVariable ["_tgtLogic", 0];

	_tgtLogic = _tgtLogic + 1;
	if(_tgtLogic > 3) then {
		_tgtLogic = 0;
	};

	_out = "";
	switch (_tgtLogic) do {
		case 0: {
			_out = "Random selection";
		};
		case 1: {
			_out = "Distance/Speed bias";
		};
		case 2: {
			_out = "Threat bias";
		};
		default {_out = "No targeting"};
	};

	_id = owner _caller;
	["Logic changed to: " + _out] remoteExec ["hint", _id];

	_target setVariable	["_tgtLogic", _tgtLogic];
}, nil, 10, false, false, "", "!(_this in _target)", 10];

//Makes it better 
{
	_x setSkill 1;
}foreach crew _unit;

//Main loop
_loops = ((count _typeArray) - 1);
scopeName "start";
while {alive _unit} do {
	_tgtLogic = _unit getVariable ["_tgtLogic", 0];

	_entities = [];
	for "_i" from 0 to _loops do {
		_near = _unit nearObjects [_typeArray select _i, _distance];
		_entities append _near;
	};

	_entities = _entities select {!(typeOf _x in _ignored)};
	//_entities = _entities select {((getPosATL _x) select 2) > 25};
	_entities = _entities select {alive _x};
	
	if(count _entities > 0) then {
		//Init all the entities
		{
			if(_x getVariable ["toInit",true]) then {
				_x setVariable ["toInit",false];
				[_x] spawn {
					_x = _this select 0;
					while {alive _x} do {
						_entities = (_x nearObjects ["BulletBase", 5]);
						if(count _entities > 0) then {
							_mine = createMine ["APERSMine", getPosATL _x, [], 0];
							_mine setDamage 1;
							deletevehicle _x;
						};
						sleep 0.02;
					};
					_fake = (_x getVariable ["attachedObject", objNull]);
					detach _fake;
					deletevehicle _fake;
				};
			};
		}foreach _entities;
		//Pick one
		_target = objNull;
		_fake = objNull;

		_p = -1;
		_lastP = _p;
		_first = true;
		_wep = currentWeapon _unit;
		_g = 9.81;
		{
			switch (_tgtLogic) do {
				//Pure random
				case 0: {
					_target = selectRandom _entities;
				};
				//Distance/Speed bias + direction
				case 1: {
					_vel = velocity _x;
					_dist = _unit distance _x;
					_aimQuality = _unit aimedAtTarget [_x, _wep];
					_p = abs((_dist / _distance) -(_vel select 2)/100 + _aimQuality*2);

					if(_p > _lastP or _first) then {
						_target = _x;
						_lastP = _p;
						_first = false;
					};
				};
				//Threat bias
				case 2: {
					_vel = velocity _x;
					_pos = getPosASL _x;
					_alt = _pos select 2;
					_v0 = -(_vel select 2); //Negative when going up
					_root = ((_v0 ^ 2) - 2 * _g * (-_alt));
					if(_root < 0) then {continue};

					//Time to impact 
					_t = round((-_v0 + sqrt(_root)) / _g);
					
					//Space travelled - approximation!!!
					_spaceX = ((_pos select 0) + (_vel select 0) * _t);
					_spaceY = ((_pos select 1) + (_vel select 1) * _t);

					_nPos = [_spaceX, _spaceY, 0];
					_p = (_unit distance2d _nPos) + (_t * 10);

					if(_p < _lastP or {_first}) then {
						_target = _x;
						_lastP = _p;
						_first = false;
						/*
						systemChat (str _x);
						systemChat ("p:" + str _p);
						systemChat ("t:" + str _t);
						*/
					};
				};
				default {_target = objNull;};
			};
		}foreach _entities;
		if(isNull _target) then {breakTo "start";};
		
		_target allowdamage false;
		_fake = (_target getVariable ["attachedObject", objNull]);
		if(isNull _fake) then {
			_fake = "B_Plane_Fighter_01_Stealth_F" createVehicle [0,0,100];
			_fake hideObjectGlobal true;
			_fake allowdamage false;
			_fake attachTo [_target, [0,5,0]];
			_target setVariable ["attachedObject", _fake];
		};

		_unit reveal _fake;
		(side driver _unit) reportRemoteTarget [_fake, 3600]; 
		_fake confirmSensorTarget [west, true]; 
		

		if(!isNull _fake) then {
			_unit doTarget _fake;
			_time = time;
			waitUntil{_unit aimedAtTarget [_fake, _wep] > 0.2 or (time - _time) > 2};

			for "_i" from 1 to 100 do {
				if(!alive _target) exitWith {};
				if(isNull _fake) exitWith {};
				//Every 10 steps 
				if((_i % 10) == 0) then {
					_unit doTarget _fake;
				};

				if((_unit weaponDirection _wep) select 2 > 0.1) then {
					if(_unit aimedAtTarget [_fake, _wep] > 0.33) then {
						[_unit, _wep, [0]] call BIS_fnc_fire;
					};
				};
				
				sleep 0.013; //75 rounds per second
			};
			//sleep 1;

			detach _fake;
			deletevehicle _fake;
			_target setVariable ["attachedObject", objNull];
		};
	};
	sleep 0.1;
};

removeallActions _unit;