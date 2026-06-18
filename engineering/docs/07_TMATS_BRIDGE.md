# 07 — The T-MATS Bridge: shared thermodynamic & numerical methods

This repository pairs the NASA **T-MATS** toolbox (gas-turbine / thermodynamic
system modeling) with a near-space **ballooning** toolkit. At first glance these
are different domains — turbofans vs. weather balloons — but they are built on
the **same engineering methods**. This document makes that mapping explicit, so
the repo reads as one coherent thermodynamic-systems portfolio rather than two
unrelated projects.

> T-MATS is documented in **NASA/TM—2014-216638**, *Toolbox for the Modeling and
> Analysis of Thermodynamic Systems (T-MATS) User's Guide* (Chapman, Lavelle,
> May, Litt, Guo — NASA Glenn Research Center). The toolbox source lives in this
> repo at `../../T-MATS/T-MATS/Trunk/`.

## Method correspondence

| Method | In T-MATS (turbomachinery) | In `nearspace` (ballooning) |
|---|---|---|
| **Perfect-gas thermodynamics** | `Thermo_TMATS` blocks: T↔h, P-T↔s, property lookups for combustion gas | `lift_gas.py`, `atmosphere.py`: ideal-gas ρ = PM/R\*T for air & lift gas |
| **First-law energy balance** | `HeatSoak`, `1-D conduction` (`HeatXfer_TMATS_*`) heat-soak of casings/metal | `thermal.py`: radiative/convective steady-state payload balance |
| **Hydrostatics / ambient model** | `Turbo_TMATS_Amb` ambient/inlet conditions vs. altitude (USSA) | `atmosphere.py`: full USSA-1976 P, T, ρ, a profile |
| **Component "maps" / lookup tables** | compressor & turbine performance maps (`*.map`) | balloon burst-diameter & parachute Cd tables (`data/*.csv`) |
| **Iterative solver w/ Jacobian** | `Solver_TMATS` Newton-Raphson w/ numeric Jacobian to converge cycle | `lift_gas.moles_for_free_lift` inversion; `thermal` quartic bisection |
| **Mass/force balance to steady state** | shaft power balance, flow continuity at convergence | buoyancy = drag (ascent), weight = drag (descent) steady states |
| **Public, nonproprietary data** | NPSS-derived public maps & constants | NOAA/NIST/FAA public reference data |

## Same equations, different vehicle

**Gas properties.** T-MATS' `Thermo` blocks evaluate enthalpy, entropy, and
specific heats of air and combustion products from public correlations. The
ballooning toolkit uses the same perfect-gas foundation — `ρ = PM/(R\*T)` — for
the lift gas and the surrounding air. Both freeze on NIST molar masses.

**Energy balance.** A T-MATS `HeatSoak` block integrates the first law on a
lump of engine metal exchanging heat with a gas path:
`m·c·dT/dt = Σ Q̇`. The balloon payload `thermal.py` solves the *steady* version
of the same first law, `Σ Q̇_in = Σ Q̇_out`, with the gas-path convection term
replaced by radiation to space and conduction to thin air — the regime simply
shifts from convection-dominated (inside an engine) to radiation-dominated (at
30 km), which the model captures via `h(z) → 0` as density falls.

**Ambient model.** Both toolkits need atmospheric conditions vs. altitude.
T-MATS' ambient/inlet block and `nearspace.atmosphere` implement the *same*
U.S. Standard Atmosphere — the ballooning side just exercises it to 35 km
instead of typical flight-envelope altitudes.

**Maps & solvers.** A gas-turbine cycle is closed by iterating guesses (e.g.,
compressor R-line, turbine pressure ratio) until mass, energy, and work balances
are satisfied — T-MATS does this with a Newton-Raphson solver and a numerically
estimated Jacobian (`Solver_TMATS`, see
`../../T-MATS/T-MATS/Trunk/TMATS_Library/TMATS_Support/Solver_TMATS_NEr.html`).
The ballooning toolkit performs the analogous root-finding at smaller scale:
inverting the buoyancy relation for fill volume, and solving the quartic
radiative balance for equilibrium temperature.

## Why pair them in one repo

For a NASA-ASCEND student team, this pairing is pedagogically deliberate:

1. **T-MATS** teaches rigorous, validated, public-source thermodynamic system
   modeling at professional (NASA Glenn) quality.
2. The **ballooning toolkit** applies the *same discipline* to a system the team
   actually builds, launches, and recovers — closing theory to hardware.
3. The **ASCEND-S26 MATLAB suite** (`../../matlab_ASCEND_S26/`) then reconstructs
   the real flight from recovered data, completing the
   model → predict → fly → measure → validate loop.

## Pointers into the T-MATS source

| Concept | File in this repo |
|---|---|
| Newton-Raphson solver guide | `T-MATS/T-MATS/Trunk/TMATS_Library/TMATS_Support/Solver_TMATS_NEr.html` |
| Heat-soak block | `.../TMATS_Support/HeatXfer_TMATS_*.html` |
| Thermo property blocks | `.../TMATS_Support/Thermo_TMATS_*.html` |
| Ambient / inlet | `.../TMATS_Support/Turbo_TMATS_Amb.html`, `Turbo_TMATS_Inlet.html` |
| Full user guide (PDF) | `T-MATS/T-MATS/Trunk/TMATS_Users_Guide_TM-2014-216638.pdf` |
| Worked turbofan example | `.../TMATS_Examples/AGTF30/` |
