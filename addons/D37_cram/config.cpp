#include "BIS_AddonInfo.hpp"
class cfgPatches 
{
    class D37_cram
    {
        units[] = {"CRAM_Fake_PlaneTGT"};
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
			class initShells {};
			class pickTarget {};
		};
	};
};

class CfgSounds
{
	class CRAMALARM
	{
		name = "CRAM_Alarm";
		sound[] = {"D37_cram\Sound\CRAM_ALARM.ogg", 1.0, 1.0};
		titles[] = {0, ""};
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

		class Turrets {
			class MainTurret;
		};
	};
	class B_AAA_System_01_F:AAA_System_01_base_F {
		class EventHandlers: EventHandlers {
			class CRAM37 {
				init = "[_this select 0, 2800, 2] spawn CRAM37_fnc_handleCRAM;";
			};
		};

		class Turrets: Turrets {
			class MainTurret: MainTurret {
				magazines[] = {"magazine_Cannon_Phalanx_x1550","magazine_Cannon_Phalanx_x1550","magazine_Cannon_Phalanx_x1550"};
			};
		};
	};

	//["Plane_Fighter_01_Base_F","Plane_Base_F","Plane","Air","AllVehicles","All"]
	class Air: AllVehicles {};
	class Plane: Air {};
	class Plane_Base_F: Plane {};
	class Plane_Fighter_01_Base_F: Plane_Base_F {};
	class B_Plane_Fighter_01_F: Plane_Fighter_01_Base_F {
		class EventHandlers {};
	};

	class CRAM_Fake_PlaneTGT: B_Plane_Fighter_01_F {
		//model = "\A3\Structures_F\Mil\Helipads\HelipadEmpty_F.p3d";
		class EventHandlers: EventHandlers {
			init = "(_this select 0) hideObjectGlobal true;";
		};
		scope = 1;
	};
};