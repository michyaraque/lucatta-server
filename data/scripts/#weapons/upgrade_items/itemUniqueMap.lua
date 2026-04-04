-- =============================================================================
-- ITEM UNIQUE MAP - Crypto-themed unique item names
-- =============================================================================
-- Maps item names to possible unique names that can drop from monsters
-- Each item can have one or more unique names to randomly choose from

ITEM_UNIQUE_MAP = {
    -- =============================================================================
    -- SWORDS
    -- =============================================================================
    ["sword"]              = {"Faketoshi"},
    ["spike sword"]        = {"Blue Chip"},
    ["two handed sword"]   = {"Acyclic Graph"},
    ["serpent sword"]      = {"Volcanic Miner"},
    ["bright sword"]       = {"Satoshi's Nephew"},
    ["fire sword"]         = {"Saylormoon"},
    ["ice rapier"]         = {"Broccolish Fury"},
    ["giant sword"]        = {"Inevitable"},
    ["magic sword"]        = {"Non Fungible Token"},
    ["havoc blade"]        = {"The Grandfather"},
    ["templar sword"]      = {"Panic Sell"},
    ["dragon slayer"]      = {"Balerion the Black Dread"},
    ["mystic blade"]       = {"Moon Boy"},
    ["christmas sword"]    = {"HO HO HO"},
    ["crystal sword"]      = {"The Maximalist"},
    
    -- =============================================================================
    -- AXES
    -- =============================================================================
    ["axe"]                = {"NonDisclosure Agreement"},
    ["battle axe"]         = {"Block Latte"},
    ["halberd"]            = {"Feeless Cutter"},
    ["great axe"]          = {"PoS4QoS"},
    ["headchopper"]        = {"Peer to Peer Digital Cash"},
    ["knight axe"]         = {"Blue Moon"},
    ["fire axe"]           = {"Trustable"},
    ["stonecutter axe"]    = {"crypto 4 year cycle"},
    ["christmas axe"]      = {"Candy cane"},
    ["noble axe"]          = {"Wind Turbine"},
    
    -- =============================================================================
    -- CLUBS / MACES
    -- =============================================================================
    ["club"]               = {"Mining at a loss"},
    ["mace"]               = {"$€Ӿ¥!"},
    ["battle hammer"]      = {"Self Custody"},
    ["thunder hammer"]     = {"return to Dust"},
    ["war hammer"]         = {"dark face"},
    ["clerical mace"]      = {"Eggnog"},
    ["cranial basher"]     = {"WAGMI"},
    ["blessed sceptre"]    = {"Ethereum Killer"},
    ["christmas mace"]     = {"Midnight"},
    
    -- =============================================================================
    -- DAGGERS
    -- =============================================================================
    ["dagger"]             = {"Long-term Security"},
    ["throwing knife"]     = {"Satoshi Nakamoto"},
    ["assassin dagger"]    = {"Least Error & Latency will Win"},
    
    -- =============================================================================
    -- HELMETS
    -- =============================================================================
    ["leather helmet"]     = {"Point of Sale"},
    ["chain helmet"]       = {"Bull Run"},
    ["steel helmet"]       = {"Roadmap"},
    ["brass helmet"]       = {"Community"},
    ["golden helmet"]      = {"IOU"},
    ["viking helmet"]      = {"This is Huge"},
    ["horned helmet"]      = {"Only Up From Here"},
    ["crusader helmet"]    = {"Human Psychology"},
    ["crown helmet"]       = {"New Listing"},
    ["royal helmet"]       = {"Code Proposal"},
    ["demon helmet"]       = {"10 Cents on the Dollar"},
    ["dragon scale helmet"]= {"Captcha Distribution"},
    ["devil helmet"]       = {"Debt Ceiling"},
    ["skull helmet"]       = {"Return on Investment"},
    ["warrior helmet"]     = {"Gingerbread"},
    ["dark helmet"]        = {"Chapter 9"},
    ["mystic turban"]      = {"Crystal Ball"},
    ["winged helmet"]      = {"Update The System"},
    ["amazon helmet"]      = {"Safe Heaven"},
    ["bonelord helmet"]    = {"Clownbase"},
    ["strange helmet"]     = {"CVE-2023-40234"},
    
    -- =============================================================================
    -- ARMORS
    -- =============================================================================
    ["leather armor"]      = {"Representative"},
    ["chain armor"]        = {"ForeX Guard"},
    ["plate armor"]        = {"Green Alternative"},
    ["scale armor"]        = {"Appia's Road"},
    ["golden armor"]       = {"Store of Value"},
    ["knight armor"]       = {"Firano's Hide"},
    ["noble armor"]        = {"RaiBlocks"},
    ["crown armor"]        = {"Wall of Encrypted Energy"},
    ["blue robe"]          = {"Zero-knowledge Proof"},
    ["dragon scale mail"]  = {"Jungle Warcry"},
    ["demon armor"]        = {"133 Club"},
    ["magic plate armor"]  = {"BlackRock"},
    ["dwarven armor"]      = {"To The Moon Mars"},
    ["paladin armor"]      = {"Santa Claus"},
    ["dark armor"]         = {"Explorer's Block"},
    ["amazon armor"]       = {"Rug Pull"},
    ["fire armor"]         = {"Fear Of Missing Out (FOMO)"},
    ["ice armor"]          = {"Deploying More Capital"},
    
    -- =============================================================================
    -- SHIELDS
    -- =============================================================================
    ["wooden shield"]      = {"Liquidity Provider"},
    ["studded shield"]     = {"Bearer Token"},
    ["plate shield"]       = {"King Louie"},
    ["brass shield"]       = {"Marstronaut"},
    ["golden shield"]      = {"1 Ban = 1 Ban"},
    ["battle shield"]      = {"Cold Storage"},
    ["tower shield"]       = {"Do Klost"},
    ["castle shield"]      = {"Probably Nothing"},
    ["medusa shield"]      = {"Diamond Hands"},
    ["amazon shield"]      = {"PermaBear"},
    ["vampire shield"]     = {"Inverse Cramer"},
    ["crown shield"]       = {"NanoStrategy"},
    ["dragon shield"]      = {"Airdrop"},
    ["dark shield"]        = {"Fear Uncertainty Doubt (FUD)"},
    ["blessed shield"]     = {"Snowflake"},
    ["mastermind shield"]  = {"Developer Fund"},
    ["demon shield"]       = {"ORV > POW"},
    ["guardian shield"]    = {"Vote Hinting"},
    ["great shield"]       = {"Mining Farms"},
    
    -- =============================================================================
    -- CAPES / ACCESSORIES
    -- =============================================================================
    ["red cape"]           = {"Cloak of Levitation"},
    
    -- =============================================================================
    -- BELTS / LEGS
    -- =============================================================================
    ["leather legs"]       = {"Proof of Wear"},
    ["plate legs"]         = {"Hodler"},
    ["brass legs"]         = {"Spam Resistor"},
    ["crown legs"]         = {"Dee-Fye"},
    ["knight legs"]        = {"Election scheduler"},
    ["golden legs"]        = {"TaaC"},
    ["dragon scale legs"]  = {"CBDC"},
    ["demon legs"]         = {"Attack Vector"},
    ["amazon legs"]        = {"99 on Huobi"},
    ["blue legs"]          = {"Commercial Grade"},
    ["zaoan legs"]         = {"1000 CPS"},
    ["dwarven legs"]       = {"Horizontal Scaling"},
    ["paladin legs"]       = {"Slava Ukraini"},
    ["magma legs"]         = {"Zero Inflation"},
    ["grasshopper legs"]   = {"Goldwrap"},
}

-- =============================================================================
-- CONFIGURATION
-- =============================================================================
ITEM_UNIQUE_CONFIG = {
    ENABLED = true,              -- Enable/disable the system
    DROP_CHANCE = 500,           -- 1 in X chance for an item to become unique (500 = 0.2%)
    ANNOUNCE_UNIQUE = true,      -- Announce to spectators when a unique drops
    ANNOUNCE_MESSAGE = "Unique item discovered!",
}
