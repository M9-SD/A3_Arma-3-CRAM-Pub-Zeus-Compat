_unit       = param[0];
_distance   = param[1, 2800];
_tgtLogic 	= param[2, 0];
_typeArray 	= param[3, ["ShellBase","RocketBase","MissileBase"]];
_ignored	= param[4, ["ammo_Missile_rim116"]];

if(!isServer) exitWith {};

if(_unit getVariable ["init",false]) exitWith {};
_unit setVariable ["init", true];

//_unit setVehicleRadar 1;
_unit setVariable ["alarmEnabled", true];
//Toggle incoming alarm
_unit addAction ["Toggle alarm", {
	params ["_target", "_caller", "_actionId", "_arguments"];
	_state = !(_target getVariable ["alarmEnabled", true]);
	_target setVariable ["alarmEnabled", _state];

	_out = "";
	if(_state) then {
		_out = "ON";
	} else {
		_out = "OFF";
	};

	_id = owner _caller;
	["Alarm state: " + _out] remoteExec ["hint", _id];

}, nil, 9, false, false, "", "!(_this in _target)", 10];

//Change logic
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

//Makes it better... I think
{
	_x setSkill 1;
}foreach crew _unit;

//Performance optimizations
_emptyLoops = 0;
_delay = 0.1;

//Main loop
_loops = ((count _typeArray) - 1);
while {alive _unit} do {
	_tgtLogic = _unit getVariable ["_tgtLogic", 0];

	_entities = [];
	for "_i" from 0 to _loops do {
		_near = _unit nearObjects [_typeArray select _i, _distance];
		_entities append _near;
	};

	_entities = _entities select {!(typeOf _x in _ignored)};
	//_entities = _entities select {alive _x};
	
	if(count _entities > 0) then {
		_emptyLoops = 0;
		_delay = 0.05;

		if(_unit getVariable ["alarmEnabled",false]) then {
			if (!(_unit getVariable ["alarmplaying",false])) then {
				_unit setVariable ["alarmplaying",true,true];
				_unit say3D ["CRAMALARM",1000,1,false,0];
				_unit spawn {
					sleep 10;
					_this setVariable ["alarmplaying",false,true];
				};
			};
		};

		//Init all the entities
		//Maximum priority, avoids overlapping
		isNil {[_entities] call CRAM37_fnc_initshells;};
		_target = [_entities, _unit, _tgtLogic] call CRAM37_fnc_pickTarget;

		if(!isNull _target) then {
			_target allowdamage false;

			//No model?
			_fake = "CRAM_Fake_PlaneTGT" createVehicle [0,0,100];
			_fake allowdamage false;
			_fake attachTo [_target, [0,5,0]];	
			_unit reveal _fake; 

			//Clean up for safety
			_fake spawn {
				sleep 30;
				if(!isNull _this) then {	
					detach _this;
					deletevehicle _this;
				};
			};

			if(!isNull _fake) then {
				_wep = currentweapon _unit;
				_unit doTarget _fake;
				_time = time;
				waitUntil{_unit aimedAtTarget [_fake, _wep] > 0.2 or (time - _time) > 2};

				for "_i" from 1 to 100 do {
					if(!alive _target) exitWith {};
					if(isNull _fake) exitWith {};
					//Every 20 steps in case the AI goes dumb
					if((_i % 20) == 0) then {
						_unit doTarget _fake;
					};

					if(_unit aimedAtTarget [_fake, _wep] > 0.2) then {
						[_unit, _wep, [0]] call BIS_fnc_fire;
					};					
					
					sleep 0.013; //75 rounds per second
				};

				detach _fake;
				deletevehicle _fake;
			};
		};
	} else {
		//Lowers the amount of checks per second when nothing is found
		_delay = 0.1;
		_emptyLoops = (_emptyLoops + 1);
		if(_emptyLoops == 100) then {
			_delay = 0.5;
			_unit doTarget objNull;
		};
	};
	sleep _delay;
};

removeallActions _unit;