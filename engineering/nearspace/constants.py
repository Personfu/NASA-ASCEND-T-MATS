"""
Physical constants and standard reference values for near-space engineering.

All values are taken from authoritative public/government sources and are
nonproprietary. Citations are inline so every number is traceable.

Primary sources
---------------
* NIST CODATA 2018 Recommended Values of the Fundamental Physical Constants
  (https://physics.nist.gov/cuu/Constants/)
* U.S. Standard Atmosphere, 1976 (NOAA / NASA / USAF, NASA-TM-X-74335).
* NIST Chemistry WebBook, SRD 69 (gas molar masses).
* WGS-84 (NIMA TR8350.2) Earth model parameters.

Note on R*: the U.S. Standard Atmosphere 1976 fixes the universal gas constant
at 8.31432 J/(mol*K) and the sea-level mean molar mass of air at
0.0289644 kg/mol. To reproduce the *standard* atmosphere tables exactly we use
those frozen 1976 values inside atmosphere.py; elsewhere we use modern CODATA.
"""

from __future__ import annotations

# ----------------------------------------------------------------------------
# Universal / fundamental constants (NIST CODATA 2018)
# ----------------------------------------------------------------------------
R_UNIVERSAL = 8.314462618          # J/(mol*K)  universal gas constant (CODATA)
N_AVOGADRO = 6.02214076e23         # 1/mol      Avogadro constant (exact, SI 2019)
K_BOLTZMANN = 1.380649e-23         # J/K        Boltzmann constant (exact, SI 2019)
STEFAN_BOLTZMANN = 5.670374419e-8  # W/(m^2*K^4) Stefan-Boltzmann constant (CODATA)
C_LIGHT = 299_792_458.0            # m/s        speed of light (exact, SI)
T0_KELVIN = 273.15                 # K          0 degC in kelvin (exact)
G_EARTH_STD = 9.80665              # m/s^2      standard gravity (CGPM/USSA1976)

# ----------------------------------------------------------------------------
# U.S. Standard Atmosphere 1976 frozen constants (USSA-1976, Sec. 1.2.x)
# ----------------------------------------------------------------------------
USSA_R_STAR = 8.31432              # J/(mol*K)  gas constant used by USSA-1976
USSA_M0_AIR = 0.0289644            # kg/mol     sea-level mean molar mass of air
USSA_G0 = 9.80665                  # m/s^2      reference acceleration of gravity
USSA_T0 = 288.15                   # K          sea-level standard temperature
USSA_P0 = 101325.0                 # Pa         sea-level standard pressure
USSA_RHO0 = 1.2250                 # kg/m^3     sea-level standard density
# Effective Earth radius for the geopotential <-> geometric conversion
# (USSA-1976 uses r0 = 6356766 m).
USSA_EARTH_RADIUS = 6_356_766.0    # m

# Specific gas constant of dry air, R / M0
R_AIR = USSA_R_STAR / USSA_M0_AIR  # ~287.0528 J/(kg*K)

# ----------------------------------------------------------------------------
# WGS-84 Earth model (NIMA TR8350.2)
# ----------------------------------------------------------------------------
WGS84_A = 6_378_137.0              # m   semi-major axis
WGS84_F = 1.0 / 298.257223563      # -   flattening
WGS84_B = WGS84_A * (1.0 - WGS84_F)  # m semi-minor axis
WGS84_E2 = WGS84_F * (2.0 - WGS84_F)  # first eccentricity squared
EARTH_MEAN_RADIUS = 6_371_000.0    # m  IUGG mean radius (used for great-circle)

# ----------------------------------------------------------------------------
# Lift / fill gases (molar mass kg/mol, NIST Chemistry WebBook)
# ----------------------------------------------------------------------------
M_HELIUM = 0.0040026               # kg/mol  helium-4
M_HYDROGEN = 0.00201588            # kg/mol  H2
M_AIR = USSA_M0_AIR                # kg/mol  dry air (sea-level mean)
M_WATER = 0.01801528               # kg/mol  H2O

# Specific gas constants R/M  [J/(kg*K)]
RS_HELIUM = R_UNIVERSAL / M_HELIUM
RS_HYDROGEN = R_UNIVERSAL / M_HYDROGEN
RS_AIR = R_UNIVERSAL / M_AIR

# ----------------------------------------------------------------------------
# Solar / radiation environment
# ----------------------------------------------------------------------------
SOLAR_CONSTANT = 1361.0            # W/m^2  total solar irradiance at 1 AU
                                   # (NASA SORCE/TIM, Kopp & Lean 2011)
ALBEDO_EARTH = 0.30                # -      planetary Bond albedo (NASA Earth fact sheet)
EARTH_IR_FLUX = 240.0             # W/m^2  outgoing longwave radiation (global mean)

# ----------------------------------------------------------------------------
# Conversions
# ----------------------------------------------------------------------------
FT_PER_M = 3.280839895
M_PER_FT = 0.3048
KM_PER_MI = 1.609344
KT_PER_MPS = 1.943844          # knots per m/s
PA_PER_PSI = 6894.757
DEG2RAD = 0.017453292519943295
RAD2DEG = 57.29577951308232
