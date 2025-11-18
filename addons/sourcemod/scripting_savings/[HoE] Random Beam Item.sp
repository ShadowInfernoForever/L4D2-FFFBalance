/**
// ====================================================================================================
Change Log:

1.0.2 (04-October-2021)
    - Fixed carryable items not restoring beam on drop after being picked up.

1.0.1 (12-September-2021)
    - Added new commands to manually add/remove beam.
    - Added support to model/targetname based config in the data file.
    - Halo changed to disabled by default.

1.0.0 (29-August-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Random Beam Item"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Gives a random beam to items on the map"
#define PLUGIN_VERSION                "1.0.2"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=334110"

// ====================================================================================================
// Plugin Info
// ====================================================================================================
public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

// ====================================================================================================
// Includes
// ====================================================================================================
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// ====================================================================================================
// Pragmas
// ====================================================================================================
#pragma semicolon 1
#pragma newdecls required

// ====================================================================================================
// Cvar Flags
// ====================================================================================================
#define CVAR_FLAGS                    FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION     FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

// ====================================================================================================
// Filenames
// ====================================================================================================
#define CONFIG_FILENAME               "l4d_random_beam_item"
#define DATA_FILENAME                 "l4d_random_beam_item"

// ====================================================================================================
// Defines
// ====================================================================================================
#define MODEL_MELEE_FIREAXE           "models/weapons/melee/w_fireaxe.mdl"
#define MODEL_MELEE_FRYING_PAN        "models/weapons/melee/w_frying_pan.mdl"
#define MODEL_MELEE_MACHETE           "models/weapons/melee/w_machete.mdl"
#define MODEL_MELEE_BASEBALL_BAT      "models/weapons/melee/w_bat.mdl"
#define MODEL_MELEE_CROWBAR           "models/weapons/melee/w_crowbar.mdl"
#define MODEL_MELEE_CRICKET_BAT       "models/weapons/melee/w_cricket_bat.mdl"
#define MODEL_MELEE_TONFA             "models/weapons/melee/w_tonfa.mdl"
#define MODEL_MELEE_KATANA            "models/weapons/melee/w_katana.mdl"
#define MODEL_MELEE_ELECTRIC_GUITAR   "models/weapons/melee/w_electric_guitar.mdl"
#define MODEL_MELEE_KNIFE             "models/w_models/weapons/w_knife_t.mdl"
#define MODEL_MELEE_GOLFCLUB          "models/weapons/melee/w_golfclub.mdl"
#define MODEL_MELEE_PITCHFORK         "models/weapons/melee/w_pitchfork.mdl"
#define MODEL_MELEE_SHOVEL            "models/weapons/melee/w_shovel.mdl"
#define MODEL_MELEE_RIOTSHIELD        "models/weapons/melee/w_riotshield.mdl"

#define MODEL_GNOME                   "models/props_junk/gnome.mdl"
#define MODEL_COLA                    "models/w_models/weapons/w_cola.mdl"

#define MODEL_GASCAN                  "models/props_junk/gascan001a.mdl"
#define MODEL_PROPANECANISTER         "models/props_junk/propanecanister001a.mdl"
#define MODEL_OXYGENTANK              "models/props_equipment/oxygentank01.mdl"
#define MODEL_FIREWORKS_CRATE         "models/props_junk/explosive_box001.mdl"

#define L4D2_WEPID_PISTOL             "1"
#define L4D2_WEPID_PISTOL_MAGNUM      "32"
#define L4D2_WEPID_SMG_UZI            "2"
#define L4D2_WEPID_SMG_SILENCED       "7"
#define L4D2_WEPID_SMG_MP5            "33"
#define L4D2_WEPID_PUMP_SHOTGUN       "3"
#define L4D2_WEPID_SHOTGUN_CHROME     "8"
#define L4D2_WEPID_RIFLE_M16          "5"
#define L4D2_WEPID_RIFLE_DESERT       "9"
#define L4D2_WEPID_RIFLE_AK47         "26"
#define L4D2_WEPID_RIFLE_SG552        "34"
#define L4D2_WEPID_AUTO_SHOTGUN       "4"
#define L4D2_WEPID_SHOTGUN_SPAS       "11"
#define L4D2_WEPID_HUNTING_RIFLE      "6"
#define L4D2_WEPID_SNIPER_MILITARY    "10"
#define L4D2_WEPID_SNIPER_SCOUT       "36"
#define L4D2_WEPID_SNIPER_AWP         "35"

#define L4D1_WEPID_PISTOL             "1"
#define L4D1_WEPID_SMG_UZI            "2"
#define L4D1_WEPID_PUMP_SHOTGUN       "3"
#define L4D1_WEPID_AUTO_SHOTGUN       "4"
#define L4D1_WEPID_RIFLE_M16          "5"
#define L4D1_WEPID_HUNTING_RIFLE      "6"
#define L4D1_WEPID_MOLOTOV            "9"
#define L4D1_WEPID_PIPE_BOMB          "10"
#define L4D1_WEPID_PAIN_PILLS         "12"
#define L4D1_WEPID_MACHINE_GUN        "29"

#define CONFIG_ENABLE                 0
#define CONFIG_RANDOM                 1
#define CONFIG_R                      2
#define CONFIG_G                      3
#define CONFIG_B                      4
#define CONFIG_LENGTH                 5
#define CONFIG_WIDTH                  6
#define CONFIG_HDR                    7
#define CONFIG_HALO                   8
#define CONFIG_ARRAYSIZE              9

#define MAXENTITIES                   2048

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_RemoveSpawner;
static ConVar g_hCvar_MinBrightness;
static ConVar g_hCvar_ScavengeGascan;
static ConVar g_hCvar_UseGlowColor;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bL4D2;
static bool   g_bConfigLoaded;
static bool   g_bEventsHooked;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_RemoveSpawner;
static bool   g_bCvar_ScavengeGascan;
static bool   g_bCvar_UseGlowColor;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iHalo = -1;
static int    g_iModel_Gascan = -1;
static int    g_iDefaultConfig[CONFIG_ARRAYSIZE];

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
static float  g_vAngles[3] = { 270.0 , 0.0 , 0.0 };
static float  g_fExtraPosZ = 1.2;
static float  g_fCvar_MinBrightness;

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
static bool   gc_bWeaponEquipPostHooked[MAXPLAYERS+1];

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
static bool   ge_bUsePostHooked[MAXENTITIES+1];
static bool   ge_bTurnOn[MAXENTITIES+1];
static int    ge_iParentEntRef[MAXENTITIES+1] = { INVALID_ENT_REFERENCE, ... };
static int    ge_iChildEntRef[MAXENTITIES+1] = { INVALID_ENT_REFERENCE, ... };

// ====================================================================================================
// StringMap - Plugin Variables
// ====================================================================================================
static StringMap g_smWeaponIdToClassname;
static StringMap g_smMeleeModelToName;
static StringMap g_smPropModelToClassname;
static StringMap g_smClassnameConfig;
static StringMap g_smMeleeConfig;
static StringMap g_smTargetnameConfig;
static StringMap g_smModelConfig;

// ====================================================================================================
// ArrayList - Plugin Variables
// ====================================================================================================
static ArrayList g_alPluginEntities;

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" and \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }

    g_bL4D2 = (engine == Engine_Left4Dead2);

    g_smWeaponIdToClassname = new StringMap();
    g_smMeleeModelToName = new StringMap();
    g_smPropModelToClassname = new StringMap();
    g_smClassnameConfig = new StringMap();
    g_smMeleeConfig = new StringMap();
    g_smTargetnameConfig = new StringMap();
    g_smModelConfig = new StringMap();
    g_alPluginEntities = new ArrayList();

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    BuildMaps();

    CreateConVar("l4d_random_beam_item_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled          = CreateConVar("l4d_random_beam_item_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_RemoveSpawner    = CreateConVar("l4d_random_beam_item_remove_spawner", "1", "Delete *_spawn entities when its count reaches 0.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_MinBrightness    = CreateConVar("l4d_random_beam_item_min_brightness", "0.5", "Algorithm value to detect the beam minimum brightness for a random color (not accurate).", CVAR_FLAGS, true, 0.0, true, 1.0);
    if (g_bL4D2)
    {
        g_hCvar_ScavengeGascan = CreateConVar("l4d_random_beam_item_scavenge_gascan", "0", "(L4D2 only) Apply beam to scavenge gascans.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
        g_hCvar_UseGlowColor = CreateConVar("l4d_random_beam_item_use_glow_color", "1", "(L4D2 only) Apply the same color from glow.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    }

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_RemoveSpawner.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MinBrightness.AddChangeHook(Event_ConVarChanged);
    if (g_bL4D2)
    {
        g_hCvar_ScavengeGascan.AddChangeHook(Event_ConVarChanged);
        g_hCvar_UseGlowColor.AddChangeHook(Event_ConVarChanged);
    }

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_beaminfo", CmdInfo, ADMFLAG_ROOT, "Outputs to the chat the beam info about the entity at your crosshair.");
    RegAdminCmd("sm_beamreload", CmdReload, ADMFLAG_ROOT, "Reload the beam configs.");
    RegAdminCmd("sm_beamremove", CmdRemove, ADMFLAG_ROOT, "Remove plugin beam from entity at crosshair.");
    RegAdminCmd("sm_beamremoveall", CmdRemoveAll, ADMFLAG_ROOT, "Remove all beams created by the plugin.");
    RegAdminCmd("sm_beamadd", CmdAdd, ADMFLAG_ROOT, "Add a beam (with default config) to entity at crosshair.");
    RegAdminCmd("sm_print_cvars_l4d_random_beam_item", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void BuildMaps()
{
    if (g_bL4D2)
    {
        g_smWeaponIdToClassname.Clear();
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_PISTOL, "weapon_pistol");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_PISTOL_MAGNUM, "weapon_pistol_magnum");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_SMG_UZI, "weapon_smg");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_SMG_SILENCED, "weapon_smg_silenced");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_SMG_MP5, "weapon_smg_mp5");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_PUMP_SHOTGUN, "weapon_pumpshotgun");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_SHOTGUN_CHROME, "weapon_shotgun_chrome");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_RIFLE_M16, "weapon_rifle");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_RIFLE_DESERT, "weapon_rifle_desert");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_RIFLE_AK47, "weapon_rifle_ak47");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_RIFLE_SG552, "weapon_rifle_sg552");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_AUTO_SHOTGUN, "weapon_autoshotgun");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_SHOTGUN_SPAS, "weapon_shotgun_spas");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_HUNTING_RIFLE, "weapon_hunting_rifle");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_SNIPER_MILITARY, "weapon_sniper_military");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_SNIPER_SCOUT, "weapon_sniper_scout");
        g_smWeaponIdToClassname.SetString(L4D2_WEPID_SNIPER_AWP, "weapon_sniper_awp");

        g_smMeleeModelToName.Clear();
        g_smMeleeModelToName.SetString(MODEL_MELEE_FIREAXE, "fireaxe");
        g_smMeleeModelToName.SetString(MODEL_MELEE_FRYING_PAN, "frying_pan");
        g_smMeleeModelToName.SetString(MODEL_MELEE_MACHETE, "machete");
        g_smMeleeModelToName.SetString(MODEL_MELEE_BASEBALL_BAT, "baseball_bat");
        g_smMeleeModelToName.SetString(MODEL_MELEE_CROWBAR, "crowbar");
        g_smMeleeModelToName.SetString(MODEL_MELEE_CRICKET_BAT, "cricket_bat");
        g_smMeleeModelToName.SetString(MODEL_MELEE_TONFA, "tonfa");
        g_smMeleeModelToName.SetString(MODEL_MELEE_KATANA, "katana");
        g_smMeleeModelToName.SetString(MODEL_MELEE_ELECTRIC_GUITAR, "electric_guitar");
        g_smMeleeModelToName.SetString(MODEL_MELEE_KNIFE, "knife");
        g_smMeleeModelToName.SetString(MODEL_MELEE_GOLFCLUB, "golfclub");
        g_smMeleeModelToName.SetString(MODEL_MELEE_PITCHFORK, "pitchfork");
        g_smMeleeModelToName.SetString(MODEL_MELEE_SHOVEL, "shovel");
        g_smMeleeModelToName.SetString(MODEL_MELEE_RIOTSHIELD, "riotshield");

        g_smPropModelToClassname.Clear();
        g_smPropModelToClassname.SetString(MODEL_GNOME, "weapon_gnome");
        g_smPropModelToClassname.SetString(MODEL_COLA, "weapon_cola_bottles");
        g_smPropModelToClassname.SetString(MODEL_GASCAN, "weapon_gascan");
        g_smPropModelToClassname.SetString(MODEL_PROPANECANISTER, "weapon_propanetank");
        g_smPropModelToClassname.SetString(MODEL_OXYGENTANK, "weapon_oxygentank");
        g_smPropModelToClassname.SetString(MODEL_FIREWORKS_CRATE, "weapon_fireworkcrate");
    }
    else
    {
        g_smWeaponIdToClassname.Clear();
        g_smWeaponIdToClassname.SetString(L4D1_WEPID_PISTOL, "weapon_pistol");
        g_smWeaponIdToClassname.SetString(L4D1_WEPID_SMG_UZI, "weapon_smg");
        g_smWeaponIdToClassname.SetString(L4D1_WEPID_PUMP_SHOTGUN, "weapon_pumpshotgun");
        g_smWeaponIdToClassname.SetString(L4D1_WEPID_RIFLE_M16, "weapon_rifle");
        g_smWeaponIdToClassname.SetString(L4D1_WEPID_AUTO_SHOTGUN, "weapon_autoshotgun");
        g_smWeaponIdToClassname.SetString(L4D1_WEPID_HUNTING_RIFLE, "weapon_hunting_rifle");

        g_smPropModelToClassname.Clear();
        g_smPropModelToClassname.SetString(MODEL_GASCAN, "weapon_gascan");
        g_smPropModelToClassname.SetString(MODEL_PROPANECANISTER, "weapon_propanetank");
        g_smPropModelToClassname.SetString(MODEL_OXYGENTANK, "weapon_oxygentank");
    }
}

/****************************************************************************************************/

public void OnMapStart()
{
    g_iHalo = PrecacheModel("materials/sprites/light_glow02_add_noz.vmt");
    g_iModel_Gascan = PrecacheModel(MODEL_GASCAN, true);
}

/****************************************************************************************************/

public void OnMapEnd()
{
    g_bConfigLoaded = false;
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    g_bConfigLoaded = true;

    LateLoad();

    HookEvents();
}

/****************************************************************************************************/

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    OnPluginEnd();

    LateLoad();

    HookEvents();
}

/****************************************************************************************************/

public void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_bCvar_RemoveSpawner = g_hCvar_RemoveSpawner.BoolValue;
    g_fCvar_MinBrightness = g_hCvar_MinBrightness.FloatValue;
    if (g_bL4D2)
    {
        g_bCvar_ScavengeGascan = g_hCvar_ScavengeGascan.BoolValue;
        g_bCvar_UseGlowColor = g_hCvar_UseGlowColor.BoolValue;
    }
}

/****************************************************************************************************/

void LoadConfigs()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "data/%s.cfg", DATA_FILENAME);

    if (!FileExists(path))
    {
        SetFailState("Missing required data file on \"data/%s.cfg\", please re-download.", DATA_FILENAME);
        return;
    }

    KeyValues kv = new KeyValues(DATA_FILENAME);
    kv.ImportFromFile(path);

    g_smClassnameConfig.Clear();
    g_smMeleeConfig.Clear();
    g_smTargetnameConfig.Clear();
    g_smModelConfig.Clear();

    int default_enable;
    int default_random;
    char default_color[16];
    int default_length;
    int default_width;
    int default_hdr;
    int default_halo;

    int iColor[3];

    if (kv.JumpToKey("default"))
    {
        default_enable = kv.GetNum("enable", 0);
        default_random = kv.GetNum("random", 0);
        kv.GetString("color", default_color, sizeof(default_color), "255 255 255");
        default_length = kv.GetNum("length", 0);
        default_width = kv.GetNum("width", 0);
        default_hdr = kv.GetNum("hdr", 0);
        default_halo = kv.GetNum("halo", 0);

        iColor = ConvertRGBToIntArray(default_color);

        g_iDefaultConfig[CONFIG_ENABLE] = default_enable;
        g_iDefaultConfig[CONFIG_RANDOM] = default_random;
        g_iDefaultConfig[CONFIG_R] = iColor[0];
        g_iDefaultConfig[CONFIG_G] = iColor[1];
        g_iDefaultConfig[CONFIG_B] = iColor[2];
        g_iDefaultConfig[CONFIG_LENGTH] = default_length;
        g_iDefaultConfig[CONFIG_WIDTH] = default_width;
        g_iDefaultConfig[CONFIG_HDR] = default_hdr;
        g_iDefaultConfig[CONFIG_HALO] = default_halo;
    }

    kv.Rewind();

    char section[64];
    int enable;
    int random;
    char color[16];
    int length;
    int width;
    int hdr;
    int halo;

    int config[CONFIG_ARRAYSIZE];

    if (kv.JumpToKey("classnames"))
    {
        if (kv.GotoFirstSubKey())
        {
            do
            {
                kv.GetSectionName(section, sizeof(section));
                TrimString(section);
                StringToLowerCase(section);

                enable = kv.GetNum("enable", default_enable);
                random = kv.GetNum("random", default_random);
                kv.GetString("color", color, sizeof(color), default_color);
                length = kv.GetNum("length", default_length);
                width = kv.GetNum("width", default_width);
                hdr = kv.GetNum("hdr", default_hdr);
                halo = kv.GetNum("halo", default_halo);

                iColor = ConvertRGBToIntArray(color);

                if (enable == 0)
                    continue;

                config[CONFIG_ENABLE] = enable;
                config[CONFIG_RANDOM] = random;
                config[CONFIG_R] = iColor[0];
                config[CONFIG_G] = iColor[1];
                config[CONFIG_B] = iColor[2];
                config[CONFIG_LENGTH] = length;
                config[CONFIG_WIDTH] = width;
                config[CONFIG_HDR] = hdr;
                config[CONFIG_HALO] = halo;

                g_smClassnameConfig.SetArray(section, config, sizeof(config));
            } while (kv.GotoNextKey());
        }
    }

    kv.Rewind();

    if (kv.JumpToKey("melees"))
    {
        if (kv.GotoFirstSubKey())
        {
            do
            {
                kv.GetSectionName(section, sizeof(section));
                TrimString(section);
                StringToLowerCase(section);

                enable = kv.GetNum("enable", default_enable);
                random = kv.GetNum("random", default_random);
                kv.GetString("color", color, sizeof(color), default_color);
                length = kv.GetNum("length", default_length);
                width = kv.GetNum("width", default_width);
                hdr = kv.GetNum("hdr", default_hdr);
                halo = kv.GetNum("halo", default_halo);

                iColor = ConvertRGBToIntArray(color);

                if (enable == 0)
                    continue;

                config[CONFIG_ENABLE] = enable;
                config[CONFIG_RANDOM] = random;
                config[CONFIG_R] = iColor[0];
                config[CONFIG_G] = iColor[1];
                config[CONFIG_B] = iColor[2];
                config[CONFIG_LENGTH] = length;
                config[CONFIG_WIDTH] = width;
                config[CONFIG_HDR] = hdr;
                config[CONFIG_HALO] = halo;

                g_smMeleeConfig.SetArray(section, config, sizeof(config));
            } while (kv.GotoNextKey());
        }
    }

    kv.Rewind();

    if (kv.JumpToKey("targetname"))
    {
        if (kv.GotoFirstSubKey())
        {
            do
            {
                kv.GetSectionName(section, sizeof(section));
                TrimString(section);
                StringToLowerCase(section);

                enable = kv.GetNum("enable", default_enable);
                random = kv.GetNum("random", default_random);
                kv.GetString("color", color, sizeof(color), default_color);
                length = kv.GetNum("length", default_length);
                width = kv.GetNum("width", default_width);
                hdr = kv.GetNum("hdr", default_hdr);
                halo = kv.GetNum("halo", default_halo);

                iColor = ConvertRGBToIntArray(color);

                if (enable == 0)
                    continue;

                config[CONFIG_ENABLE] = enable;
                config[CONFIG_RANDOM] = random;
                config[CONFIG_R] = iColor[0];
                config[CONFIG_G] = iColor[1];
                config[CONFIG_B] = iColor[2];
                config[CONFIG_LENGTH] = length;
                config[CONFIG_WIDTH] = width;
                config[CONFIG_HDR] = hdr;
                config[CONFIG_HALO] = halo;

                g_smTargetnameConfig.SetArray(section, config, sizeof(config));
            } while (kv.GotoNextKey());
        }
    }

    kv.Rewind();

    char modelname[PLATFORM_MAX_PATH];
    if (kv.JumpToKey("models"))
    {
        if (kv.GotoFirstSubKey())
        {
            do
            {
                kv.GetSectionName(modelname, sizeof(modelname));
                TrimString(modelname);
                StringToLowerCase(modelname);

                enable = kv.GetNum("enable", default_enable);
                random = kv.GetNum("random", default_random);
                kv.GetString("color", color, sizeof(color), default_color);
                length = kv.GetNum("length", default_length);
                width = kv.GetNum("width", default_width);
                hdr = kv.GetNum("hdr", default_hdr);
                halo = kv.GetNum("halo", default_halo);

                iColor = ConvertRGBToIntArray(color);

                if (enable == 0)
                    continue;

                config[CONFIG_ENABLE] = enable;
                config[CONFIG_RANDOM] = random;
                config[CONFIG_R] = iColor[0];
                config[CONFIG_G] = iColor[1];
                config[CONFIG_B] = iColor[2];
                config[CONFIG_LENGTH] = length;
                config[CONFIG_WIDTH] = width;
                config[CONFIG_HDR] = hdr;
                config[CONFIG_HALO] = halo;

                g_smModelConfig.SetArray(modelname, config, sizeof(config));
            } while (kv.GotoNextKey());
        }
    }

    kv.Rewind();

    delete kv;
}

/****************************************************************************************************/

public void HookEvents()
{
    if (g_bCvar_Enabled && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        if (g_bL4D2)
            HookEvent("weapon_drop", Event_WeaponDrop);

        return;
    }

    if (!g_bCvar_Enabled && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        if (g_bL4D2)
            UnhookEvent("weapon_drop", Event_WeaponDrop);

        return;
    }
}

/****************************************************************************************************/

public void LateLoad()
{
    LoadConfigs();

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        OnClientPutInServer(client);

        int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        OnWeaponEquipPost(client, weapon);
    }

    int entity;
    char classname[64];

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT_REFERENCE)
    {
        if (entity < 0)
            continue;

        GetEntityClassname(entity, classname, sizeof(classname));
        OnEntityCreated(entity, classname);
    }
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_bWeaponEquipPostHooked[client] = false;
}

/****************************************************************************************************/

public void OnClientPutInServer(int client)
{
    if (!g_bConfigLoaded)
        return;

    if (gc_bWeaponEquipPostHooked[client])
        return;

    gc_bWeaponEquipPostHooked[client] = true;
    SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}

/****************************************************************************************************/

public void OnWeaponEquipPost(int client, int weapon)
{
    if (!g_bL4D2)
        return;

    if (!g_bCvar_Enabled)
        return;

    if (!IsValidEntity(weapon))
        return;

    int entity;

    for (int i = 0; i < g_alPluginEntities.Length; i++)
    {
        entity = EntRefToEntIndex(g_alPluginEntities.Get(i));

        if (entity == INVALID_ENT_REFERENCE)
            continue;

        if (ge_iParentEntRef[entity] == EntIndexToEntRef(weapon))
        {
            AcceptEntityInput(entity, "Kill");
            break;
        }
    }
}

/****************************************************************************************************/

public void Event_WeaponDrop(Event event, const char[] name, bool dontBroadcast)
{
    int entity = event.GetInt("propid");
    char classname[64];
    GetEntityClassname(entity, classname, sizeof(classname));
    OnEntityCreated(entity, classname);
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (!IsValidEntityIndex(entity))
        return;

    ge_bUsePostHooked[entity] = false;
    ge_bTurnOn[entity] = false;
    ge_iParentEntRef[entity] = INVALID_ENT_REFERENCE;

    if (ge_iChildEntRef[entity] != INVALID_ENT_REFERENCE)
    {
        int child = EntRefToEntIndex(ge_iChildEntRef[entity]);
        if (child != INVALID_ENT_REFERENCE)
            AcceptEntityInput(child, "Kill");

        ge_iChildEntRef[entity] = INVALID_ENT_REFERENCE;
    }

    int find = g_alPluginEntities.FindValue(EntIndexToEntRef(entity));
    if (find != -1)
        g_alPluginEntities.Erase(find);
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!g_bConfigLoaded)
        return;

    if (!IsValidEntityIndex(entity))
        return;

    if (classname[0] == 'b' && StrEqual(classname, "beam_spotlight")) // prevent loops
        return;

    if (g_bCvar_UseGlowColor)
        RequestFrame(OnNextFrameGlow, EntIndexToEntRef(entity));
    else
        RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
}

/****************************************************************************************************/

public void OnNextFrameGlow(int entityRef)
{
    RequestFrame(OnNextFrame, entityRef);
}

/****************************************************************************************************/

public void OnNextFrame(int entityRef)
{
    if (!g_bCvar_Enabled)
        return;

    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    if (g_bL4D2)
    {
        if (!HasEntProp(entity, Prop_Send, "m_isCarryable")) // CPhysicsProp
        {
            if (HasEntProp(entity, Prop_Send, "m_hOwnerEntity") && GetEntProp(entity, Prop_Send, "m_hOwnerEntity") != INVALID_ENT_REFERENCE)
                return;
        }

        if (HasEntProp(entity, Prop_Send, "m_nModelIndex") && GetEntProp(entity, Prop_Send, "m_nModelIndex") == g_iModel_Gascan)
        {
            if (!g_bCvar_ScavengeGascan && IsScavengeGascan(entity))
                return;
        }
    }

    char modelname[PLATFORM_MAX_PATH];
    GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
    StringToLowerCase(modelname);

    char classname[64];
    GetEntityClassname(entity, classname, sizeof(classname));

    char targetname[64];
    GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
    StringToLowerCase(targetname);

    if (HasEntProp(entity, Prop_Send, "m_isCarryable")) // CPhysicsProp
        g_smPropModelToClassname.GetString(modelname, classname, sizeof(classname));

    bool isMelee;
    char melee[16];

    if (StrContains(classname, "weapon_melee") == 0)
    {
        isMelee = true;

        if (StrEqual(classname, "weapon_melee"))
            GetEntPropString(entity, Prop_Data, "m_strMapSetScriptName", melee, sizeof(melee));
        else //weapon_melee_spawn
            g_smMeleeModelToName.GetString(modelname, melee, sizeof(melee));
    }

    if (StrEqual(classname, "weapon_spawn"))
    {
        int weaponId = GetEntProp(entity, Prop_Data, "m_weaponID");
        char sWeaponId[3];
        IntToString(weaponId, sWeaponId, sizeof(sWeaponId));

        if (!g_smWeaponIdToClassname.GetString(sWeaponId, classname, sizeof(classname)))
            return;
    }

    if (classname[0] == 'w')
        ReplaceString(classname, sizeof(classname), "_spawn", "");

    int config[CONFIG_ARRAYSIZE];

    if (config[CONFIG_ENABLE] == 0)
       g_smTargetnameConfig.GetArray(targetname, config, sizeof(config));

    if (config[CONFIG_ENABLE] == 0)
       g_smModelConfig.GetArray(modelname, config, sizeof(config));

    if (isMelee && config[CONFIG_ENABLE] == 0)
        g_smMeleeConfig.GetArray(melee, config, sizeof(config));

    if (config[CONFIG_ENABLE] == 0)
        g_smClassnameConfig.GetArray(classname, config, sizeof(config));

    if (config[CONFIG_ENABLE] == 0)
        return;

    if (g_bCvar_UseGlowColor && HasEntProp(entity, Prop_Send, "m_glowColorOverride") && GetEntProp(entity, Prop_Send, "m_glowColorOverride") != 0)
    {
        int glowColor = GetEntProp(entity, Prop_Send, "m_glowColorOverride");
        config[CONFIG_R] = ((glowColor >> 00) & 0xFF);
        config[CONFIG_G] = ((glowColor >> 08) & 0xFF);
        config[CONFIG_B] = ((glowColor >> 16) & 0xFF);
    }
    else if (config[CONFIG_RANDOM] == 1)
    {
        int colorRandom[3];
        do
        {
            colorRandom[0] = GetRandomInt(0, 255);
            colorRandom[1] = GetRandomInt(0, 255);
            colorRandom[2] = GetRandomInt(0, 255);
        }
        while (GetRGB_Brightness(colorRandom) < g_fCvar_MinBrightness);

        config[CONFIG_R] = colorRandom[0];
        config[CONFIG_G] = colorRandom[1];
        config[CONFIG_B] = colorRandom[2];
    }

    if (HasEntProp(entity, Prop_Data, "m_itemCount")) // *_spawn entities
    {
        if (!ge_bUsePostHooked[entity])
        {
            ge_bUsePostHooked[entity] = true;
            SDKHook(entity, SDKHook_UsePost, OnUsePostSpawner);
        }
    }

    CreateBeam(entity, config);
}

/****************************************************************************************************/

public void CreateBeam(int target, int[] config)
{
    int entity = CreateEntityByName("beam_spotlight");
    DispatchKeyValue(entity, "targetname", "l4d_random_beam_item");
    DispatchKeyValue(entity, "spawnflags", "3");
    DispatchKeyValueVector(entity, "angles", g_vAngles);

    SetEntProp(entity, Prop_Send, "m_clrRender", config[CONFIG_R] + (config[CONFIG_G] * 256) + (config[CONFIG_B] * 65536));
    SetEntPropFloat(entity, Prop_Send, "m_flSpotlightMaxLength", float(config[CONFIG_LENGTH]));
    SetEntPropFloat(entity, Prop_Send, "m_flSpotlightGoalWidth", float(config[CONFIG_WIDTH]));
    SetEntPropFloat(entity, Prop_Send, "m_flHDRColorScale", config[CONFIG_HDR]/10.0);

    float vPos[3];
    GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", vPos);
    vPos[2] += g_fExtraPosZ;
    TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

    DispatchSpawn(entity);

    SetEntProp(entity, Prop_Send, "m_nHaloIndex", config[CONFIG_HALO] == 1 ? g_iHalo : -1); // After dispatch spawn otherwise won't work

    if (g_alPluginEntities.FindValue(EntIndexToEntRef(entity)) == -1)
        g_alPluginEntities.Push(EntIndexToEntRef(entity));

    ge_bTurnOn[entity] = true;
    ge_iParentEntRef[entity] = EntIndexToEntRef(target);
    ge_iChildEntRef[target] = EntIndexToEntRef(entity);
}

/****************************************************************************************************/

public void OnUsePostSpawner(int entity, int activator, int caller, UseType type, float value)
{
    if (!g_bCvar_Enabled)
        return;

    if (!g_bCvar_RemoveSpawner)
        return;

    if (GetEntProp(entity, Prop_Data, "m_itemCount") == 0)
        AcceptEntityInput(entity, "Kill");
}

/****************************************************************************************************/

public void OnGameFrame()
{
    static int entity;
    static int target;

    static bool turnOff;
    static bool turnOn;

    static float vPos[3];

    for (int i = 0; i < g_alPluginEntities.Length; i++)
    {
        entity = EntRefToEntIndex(g_alPluginEntities.Get(i));

        if (entity == INVALID_ENT_REFERENCE)
            continue;

        target = EntRefToEntIndex(ge_iParentEntRef[entity]);

        if (target == INVALID_ENT_REFERENCE)
            continue;

        GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", vPos);
        vPos[2] += g_fExtraPosZ;
        TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

        if (g_bL4D2)
            continue;

        if (HasEntProp(entity, Prop_Send, "m_isCarryable")) // CPhysicsProp
            continue;

        // Fixes L4D1 picked up/dropped weapons
        if (ge_bTurnOn[entity])
        {
            turnOff = false;

            if (HasEntProp(target, Prop_Send, "m_hOwnerEntity") && GetEntProp(target, Prop_Send, "m_hOwnerEntity") != INVALID_ENT_REFERENCE)
                turnOff = true;

            if (turnOff)
            {
                ge_bTurnOn[entity] = false;
                AcceptEntityInput(entity, "LightOff");
            }
        }
        else
        {
            turnOn = false;

            if (HasEntProp(target, Prop_Send, "m_hOwnerEntity") && GetEntProp(target, Prop_Send, "m_hOwnerEntity") == INVALID_ENT_REFERENCE)
                turnOn = true;

            if (turnOn)
            {
                ge_bTurnOn[entity] = true;
                AcceptEntityInput(entity, "LightOn");
            }
        }
    }
}

/****************************************************************************************************/

public void OnPluginEnd()
{
    int entity;
    char targetname[21];

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "beam_spotlight")) != INVALID_ENT_REFERENCE)
    {
        GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
        if (StrEqual(targetname, "l4d_random_beam_item"))
            AcceptEntityInput(entity, "Kill");
    }
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdInfo(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    int parent = GetClientAimTarget(client, false);

    if (!IsValidEntity(parent))
    {
        PrintToChat(client, "\x04Invalid target.");
        return Plugin_Handled;
    }

    bool find;
    int entity;
    int parentRef = EntIndexToEntRef(parent);

    for (int i = 0; i < g_alPluginEntities.Length; i++)
    {
        entity = EntRefToEntIndex(g_alPluginEntities.Get(i));

        if (entity == INVALID_ENT_REFERENCE)
            continue;

        if (ge_iParentEntRef[entity] == parentRef)
        {
            find = true;
            break;
        }
    }

    if (!find)
    {
        PrintToChat(client, "\x04Target entity has no beam.");
        return Plugin_Handled;
    }

    float length = GetEntPropFloat(entity, Prop_Send, "m_flSpotlightMaxLength");
    float width = GetEntPropFloat(entity, Prop_Send, "m_flSpotlightGoalWidth");
    float hdrColorScale = GetEntPropFloat(entity, Prop_Send, "m_flHDRColorScale");

    int color = GetEntProp(entity, Prop_Send, "m_clrRender");
    int rgb[3];
    rgb[0] = ((color >> 00) & 0xFF);
    rgb[1] = ((color >> 08) & 0xFF);
    rgb[2] = ((color >> 16) & 0xFF);

    char classname[64];
    GetEntityClassname(parent, classname, sizeof classname);

    char modelname[PLATFORM_MAX_PATH];
    GetEntPropString(parent, Prop_Data, "m_ModelName", modelname, sizeof modelname);

    PrintToChat(client, "\x05Beam Index: \x03%i \x05Parent Index: \x03%i \x05Classname: \x03%s \x05Model: \x03%s \x05Glow Color (RGB|Integer): \x03%i %i %i|%i \x05Brightness: \x03%.1f \x05Length: \x03%i \x05Width: \x03%i \x05HDR Color Scale: \x03%.1f", entity, parent, classname, modelname, rgb[0], rgb[1], rgb[2], color, GetRGB_Brightness(rgb), RoundFloat(length), RoundFloat(width), hdrColorScale);

    return Plugin_Handled;
}

/****************************************************************************************************/

public Action CmdReload(int client, int args)
{
    OnPluginEnd();

    LateLoad();

    if (IsValidClient(client))
        PrintToChat(client, "\x04Beam configs reloaded.");

    return Plugin_Handled;
}

/****************************************************************************************************/

public Action CmdRemove(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    int parent = GetClientAimTarget(client, false);

    if (!IsValidEntity(parent))
    {
        PrintToChat(client, "\x04Invalid target.");
        return Plugin_Handled;
    }

    bool find;
    int entity;
    int parentRef = EntIndexToEntRef(parent);

    for (int i = 0; i < g_alPluginEntities.Length; i++)
    {
        entity = EntRefToEntIndex(g_alPluginEntities.Get(i));

        if (entity == INVALID_ENT_REFERENCE)
            continue;

        if (ge_iParentEntRef[entity] == parentRef)
        {
            find = true;
            break;
        }
    }

    if (find)
    {
        AcceptEntityInput(entity, "Kill");
        PrintToChat(client, "\x04Removed target entity plugin beam.");
    }
    else
    {
        PrintToChat(client, "\x04Target entity has no beam.");
    }

    return Plugin_Handled;
}

/****************************************************************************************************/

public Action CmdRemoveAll(int client, int args)
{
    OnPluginEnd();

    if (IsValidClient(client))
        PrintToChat(client, "\x04Removed all beams created by the plugin.");

    return Plugin_Handled;
}

/****************************************************************************************************/

public Action CmdAdd(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    int parent = GetClientAimTarget(client, false);

    if (!IsValidEntity(parent))
    {
        PrintToChat(client, "\x04Invalid target.");
        return Plugin_Handled;
    }

    char classname[64];
    char modelname[PLATFORM_MAX_PATH];

    if (!IsValidEntityIndex(parent))
    {
        PrintToChat(client, "\x04Invalid target index to add beam.");
        return Plugin_Handled;
    }

    GetEntityClassname(parent, classname, sizeof(classname));

    if (classname[0] == 'b' && StrEqual(classname, "beam_spotlight")) // prevent loops
    {
        PrintToChat(client, "\x04Invalid target classname to add beam.");
        return Plugin_Handled;
    }

    GetEntPropString(parent, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
    StringToLowerCase(modelname);

    if (modelname[0] != 'm') // invalid model
    {
        PrintToChat(client, "\x04Invalid target model to add beam.");
        return Plugin_Handled;
    }

    bool find;
    int entity;
    int parentRef = EntIndexToEntRef(parent);

    for (int i = 0; i < g_alPluginEntities.Length; i++)
    {
        entity = EntRefToEntIndex(g_alPluginEntities.Get(i));

        if (entity == INVALID_ENT_REFERENCE)
            continue;

        if (ge_iParentEntRef[entity] == parentRef)
        {
            find = true;
            break;
        }
    }

    if (find)
        AcceptEntityInput(entity, "Kill");

    if (g_bCvar_UseGlowColor && HasEntProp(parent, Prop_Send, "m_glowColorOverride") && GetEntProp(parent, Prop_Send, "m_glowColorOverride") != 0)
    {
        int glowColor = GetEntProp(parent, Prop_Send, "m_glowColorOverride");
        g_iDefaultConfig[CONFIG_R] = ((glowColor >> 00) & 0xFF);
        g_iDefaultConfig[CONFIG_G] = ((glowColor >> 08) & 0xFF);
        g_iDefaultConfig[CONFIG_B] = ((glowColor >> 16) & 0xFF);
    }
    else if (g_iDefaultConfig[CONFIG_RANDOM] == 1)
    {
        int colorRandom[3];
        do
        {
            colorRandom[0] = GetRandomInt(0, 255);
            colorRandom[1] = GetRandomInt(0, 255);
            colorRandom[2] = GetRandomInt(0, 255);
        }
        while (GetRGB_Brightness(colorRandom) < g_fCvar_MinBrightness);

        g_iDefaultConfig[CONFIG_R] = colorRandom[0];
        g_iDefaultConfig[CONFIG_G] = colorRandom[1];
        g_iDefaultConfig[CONFIG_B] = colorRandom[2];
    }

    CreateBeam(parent, g_iDefaultConfig);

    PrintToChat(client, "\x04Beam added to target entity.");

    return Plugin_Handled;
}

/****************************************************************************************************/

public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------- Plugin Cvars (l4d_random_beam_item) -----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_random_beam_item_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_random_beam_item_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_random_beam_item_remove_spawner : %b (%s)", g_bCvar_RemoveSpawner, g_bCvar_RemoveSpawner ? "true" : "false");
    PrintToConsole(client, "l4d_random_beam_item_min_brightness : %.1f", g_fCvar_MinBrightness);
    if (g_bL4D2) PrintToConsole(client, "l4d_random_beam_item_scavenge_gascan : %b (%s)", g_bCvar_ScavengeGascan, g_bCvar_ScavengeGascan ? "true" : "false");
    if (g_bL4D2) PrintToConsole(client, "l4d_random_beam_item_use_glow_color : %b (%s)", g_bCvar_UseGlowColor, g_bCvar_UseGlowColor ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
/**
 * Validates if is a valid client index.
 *
 * @param client          Client index.
 * @return                True if client index is valid, false otherwise.
 */
bool IsValidClientIndex(int client)
{
    return (1 <= client <= MaxClients);
}

/****************************************************************************************************/

/**
 * Validates if is a valid client.
 *
 * @param client          Client index.
 * @return                True if client index is valid and client is in game, false otherwise.
 */
bool IsValidClient(int client)
{
    return (IsValidClientIndex(client) && IsClientInGame(client));
}

/****************************************************************************************************/

/**
 * Validates if is a valid entity index (between MaxClients+1 and 2048).
 *
 * @param entity        Entity index.
 * @return              True if entity index is valid, false otherwise.
 */
bool IsValidEntityIndex(int entity)
{
    return (MaxClients+1 <= entity <= GetMaxEntities());
}

/****************************************************************************************************/

/**
 * Returns if is a scavenge gascan based on its skin.
 * Works in L4D2 only.
 *
 * @param entity        Entity index.
 * @return              True if gascan skin is greater than 0 (default).
 */
bool IsScavengeGascan(int entity)
{
    int skin = GetEntProp(entity, Prop_Send, "m_nSkin");

    return skin > 0;
}

/****************************************************************************************************/

/**
 * Converts the string to lower case.
 *
 * @param input         Input string.
 */
void StringToLowerCase(char[] input)
{
    for (int i = 0; i < strlen(input); i++)
    {
        input[i] = CharToLower(input[i]);
    }
}

/****************************************************************************************************/

/**
 * Returns the integer array value of a RGB string.
 * Format: Three values between 0-255 separated by spaces. "<0-255> <0-255> <0-255>"
 * Example: "255 255 255"
 *
 * @param sColor        RGB color string.
 * @return              Integer array (int[3]) value of the RGB string or {0,0,0} if not in specified format.
 */
int[] ConvertRGBToIntArray(char[] sColor)
{
    int color[3];

    if (sColor[0] == 0)
        return color;

    char sColors[3][4];
    int count = ExplodeString(sColor, " ", sColors, sizeof(sColors), sizeof(sColors[]));

    switch (count)
    {
        case 1:
        {
            color[0] = StringToInt(sColors[0]);
        }
        case 2:
        {
            color[0] = StringToInt(sColors[0]);
            color[1] = StringToInt(sColors[1]);
        }
        case 3:
        {
            color[0] = StringToInt(sColors[0]);
            color[1] = StringToInt(sColors[1]);
            color[2] = StringToInt(sColors[2]);
        }
    }

    return color;
}

/****************************************************************************************************/

/**
 * Source: https://stackoverflow.com/a/12216661
 * Returns the RGB brightness of a RGB integer array value.
 *
 * @param rgb           RGB integer array (int[3]).
 * @return              Brightness float value between 0.0 and 1.0.
 */
public float GetRGB_Brightness(int[] rgb)
{
    int r = rgb[0];
    int g = rgb[1];
    int b = rgb[2];

    int cmax = (r > g) ? r : g;
    if (b > cmax) cmax = b;
    return cmax / 255.0;
}