class cfgPatches 
{
    class D37_cram
    {
        units[] = {};
		weapons[] = {};
		requiredVersion = 0.1;
		requiredAddons[] = {"A3_Static_F_Jets_AAA_System_01"};
    };
};

class cfgFunctions {
	class CRAM37 {
		tag = "CRAM37";
		file = "D37_cram\functions";
		class scripts {
			class handleCRAM {};
		};
	};
};

class cfgVehicles {
    //B_AAA_System_01_F
	//["AAA_System_01_base_F","StaticMGWeapon","StaticWeapon","LandVehicle","Land","AllVehicles","All"]
	
	class AllVehicles;
	class Land: AllVehicles {};
	class LandVehicle: Land {};
	class StaticWeapon: LandVehicle {};
	class StaticMGWeapon: StaticWeapon {};
	class AAA_System_01_base_F: StaticMGWeapon{
		class EventHandlers;
	};
	class B_AAA_System_01_F:AAA_System_01_base_F {
		class EventHandlers: EventHandlers {
			class CRAM37 {
				init = "[_this select 0, 2500, 2] spawn CRAM37_fnc_handleCRAM;"
			};
		};
	};
};