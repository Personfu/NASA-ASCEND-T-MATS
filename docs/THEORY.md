# ASCEND Spring 2026 - Theory & Equations

> Authored by *Personfu* for Phoenix College NASA ASCEND.
> All models below are implemented 1:1 in `src/models/`.

---

## 1. Atmosphere - US Standard 1976

Geopotential altitude:

\[ H = \frac{R_E h}{R_E + h}, \qquad R_E = 6,356,766\text{ m} \]

In each layer with lapse rate \( L_b \):

- If \( L_b \neq 0 \):
  \[ T = T_b + L_b (H - H_b) \]
  \[ p = p_b \left( \frac{T_b}{T} \right)^{ \frac{g_0 M}{R^* L_b} } \]
- If \( L_b = 0 \):
  \[ T = T_b \]
  \[ p = p_b \exp\!\left( -\frac{g_0 M (H - H_b)}{R^* T_b} \right) \]

Density: \( \rho = pM/(R^* T) \). Speed of sound: \( a = \sqrt{\gamma R T} \).
Sutherland viscosity:
\[ \mu = \mu_0 \frac{T_0 + S}{T + S}\left( \frac{T}{T_0}\right)^{3/2}, \quad \mu_0 = 1.716\!\times\!10^{-5}, S = 110.4 \]

Implemented in `atm_us1976.m`.

---

## 2. Balloon ascent (1-D and 3-D)

Ideal-gas mole conservation of helium:
\[ n = \frac{p_0 V_0}{R^* T_0} \quad \Rightarrow \quad V(h) = \frac{n R^* T(h)}{p(h)} \]
\[ D(h) = \left(\frac{6 V}{\pi}\right)^{1/3} \]

Net free lift:
\[ F_{\text{buoy}} = (\rho_{\text{air}} - \rho_{\text{He}}) V g(\phi) \]
\[ \rho_{\text{He}} = \frac{p M_{\text{He}}}{R^* T} \]

Latitude gravity (Somigliana 1980):
\[ g(\phi) = 9.7803267715 \frac{1 + 0.001931851353\sin^2\phi}{\sqrt{1 - 0.0066943800229\sin^2\phi}} \]

Drag (sphere + box):
\[ \mathbf F_{\text{drag}} = -\tfrac12 \rho_{\text{air}} C_d A |v_{\text{rel}}| v_{\text{rel}} \]

Apparent (virtual) mass for a sphere accelerating in air:
\[ m_{\text{app}} = \tfrac12 \rho_{\text{air}} V \]

The 3-D form (`simulate_3d_ascent.m`) integrates ENU coordinates with
data-derived horizontal wind \( (U(h), V(h)) \) so that
\( \mathbf v_{\text{rel}} = \mathbf v - (U, V, 0) \).

Burst criterion: either prescribed burst altitude *or* balloon diameter
exceeding the manufacturer rating (Kaymont 1500g ~ 7.86 m).

---

## 3. Parachute descent and opening shock

Pflanz-style canopy filling (constant-velocity assumption):
\[ C_d A(t) = C_d A_\infty \left( \frac{t - t_{\text{open}}}{t_{\text{fill}}} \right)^p, \quad t_{\text{fill}} = n \frac{D_p}{|v_{\text{rel}}|} \]

For a hemispherical chute, \( n \approx 8 \) and \( p = 2 \) approximate
the canopy filling profile observed in HAB telemetry.

Opening-shock force estimate (Knacke):
\[ F_x = \tfrac12 \rho V^2 C_d A_\infty C_x \]
where \( C_x \) is the opening-shock factor (~1.0 for slow apparent-mass
canopies).

Implemented in `simulate_3d_descent.m`.

---

## 4. Cosmic ray dose - Pfotzer-Regener

Atmospheric depth: \( X = p / g \) (g/cm^2)

Regener-Pfotzer profile (parametric log-normal in atmospheric depth):
\[ R(h) = R_{\text{gnd}} + (R_{\text{peak}} - R_{\text{gnd}})
\exp\!\left( -\frac{(\ln X - \ln X_{\text{peak}})^2}{2 \sigma^2} \right) \]

Typical values: \( X_{\text{peak}} \approx 100 \) g/cm^2 (~20 km altitude),
\( \sigma \approx 0.6 \), \( R_{\text{peak}} \approx 5\,\mu\text{Sv/h} \) at solar
minimum / mid-latitudes.

GMC-320+ tube counts: \( \text{CPM} \approx 153 \cdot R[\mu\text{Sv/h}] \).

---

## 5. UV / Ozone radiative transfer

Beer-Lambert with ozone column above altitude:
\[ I(\lambda, h) = I_0(\lambda) \exp\!\left[ -\sigma_{O_3}(\lambda) N_{O_3}(>h) m(\theta) \right] \]
Ozone column above altitude h estimated from US-1976 \( O_3 \) profile,
DU normalised. Air-mass factor:
\[ m(\theta) = \frac{1}{\cos\theta + 0.50572 (96.07995 - \theta)^{-1.6364}} \]
(Kasten-Young).

---

## 6. Thermal model (lumped capacitance)

\[ m c_p \frac{dT}{dt} = Q_{\text{sun}} + Q_{\text{albedo}} + Q_{\text{IR,Earth}}
   - Q_{\text{IR,box}} - Q_{\text{conv}} + Q_{\text{int}} + Q_{\text{heater}} \]

- \( Q_{\text{sun}} = \alpha A_{\perp} S \cos\theta \)
- \( Q_{\text{IR,box}} = \varepsilon \sigma A_{\text{tot}} T^4 \)
- \( Q_{\text{conv}} = h A_{\text{tot}} (T - T_\infty) \) with
  \( h = \mathrm{Nu}\, k / L \), \( \mathrm{Nu} = 0.664\,\mathrm{Re}^{1/2}\mathrm{Pr}^{1/3} \)
- Heater hysteresis: ON below -11 C, OFF above -9 C.

---

## 7. Power model

L91 lithium primary AA, 2S4P pack:
\[ V_{\text{nom}} = 6.0 \text{ V}, \quad C = 14 \text{ Ah}, \quad E = 84 \text{ Wh} \]

Coulomb counting:
\[ E_{\text{used}}(t) = \int_0^t P(\tau) d\tau, \quad \text{DoD} = E_{\text{used}}/E \]

Cold derating from datasheet: -20% capacity at -20 C.

---

## 8. Geomagnetic environment - IGRF-13

Centered-dipole approximation (2026.0 epoch):
\( g_1^0 = -29350,\; g_1^1 = -1410,\; h_1^1 = +4545 \) nT.

Field components:
\[ B_r = 2\left(\frac{a}{r}\right)^3 [g_1^0\cos\theta + (g_1^1\cos\phi + h_1^1\sin\phi)\sin\theta] \]
\[ B_\theta = \left(\frac{a}{r}\right)^3 [g_1^0\sin\theta - (g_1^1\cos\phi + h_1^1\sin\phi)\cos\theta] \]
\[ B_\phi   = \left(\frac{a}{r}\right)^3 [g_1^1\sin\phi - h_1^1\cos\phi] \]
Then NED conversion: \( B_N = -B_\theta, B_E = B_\phi, B_D = -B_r \).

---

## 9. Madgwick 9-DOF attitude filter

Orientation quaternion update:
\[ \dot{\mathbf q} = \tfrac12 \mathbf q \otimes \omega - \beta \frac{\nabla J}{\|\nabla J\|} \]
where \( J \) is the cost function combining accelerometer (gravity) and
magnetometer (reference field) constraints. Filter gain \( \beta \approx 0.041 \)
balances drift suppression vs measurement trust.

---

## 10. APRS Link Budget

\[ \text{FSPL}(d, f) = 20\log_{10}(d_{\text{km}}) + 20\log_{10}(f_{\text{MHz}}) + 32.45 \]
\[ P_{\text{rx}} = P_{\text{tx}} + G_{\text{tx}} + G_{\text{rx}} - L_{\text{cable}} - \text{FSPL} - L_{\text{atm}} \]
\[ \text{SNR} = P_{\text{rx}} - (kT + 10\log_{10}\!B + \text{NF}) \]

Threshold for AFSK 1200 baud Bell-202: SNR ~10 dB at BER 1e-3.

Line-of-sight horizon (4/3 Earth):
\[ d_{\text{hzn}} = \sqrt{2 \cdot \tfrac{4}{3} R_E h} \]

---

## 11. Monte Carlo dispersion

Sampling distributions:
- \( V_0 \sim \mathcal N(\bar V_0, 2\%) \)
- \( m \sim \mathcal N(\bar m, 1\%) \)
- \( C_d^{\text{chute}} \sim \mathcal N(1.5, 0.10) \)
- Wind speed scale \( k \sim \mathcal N(1, 15\%) \)
- Wind direction bias \( \delta \sim \mathcal N(0, 8^\circ) \)
- Burst altitude \( h_b \sim \mathcal N(\bar h_b, 1.5\text{ km}) \)

CEP definitions used:
- \( \text{CEP}_{50} \): median radial miss
- \( \text{CEP}_{95} \): 95th percentile radial miss
- 1-sigma covariance ellipse: eigen-decomposition of sample covariance

---

## 12. Geodesy - Vincenty

Inverse problem solves great-ellipsoidal distance and forward azimuth on
WGS-84 (a=6378137 m, f=1/298.257223563). The implementation iterates
\( \lambda \) until convergence (1e-12 rad), then evaluates:

\[ s = b A (\sigma - \Delta\sigma), \quad \alpha_1 = \arctan2(\cos U_2 \sin\lambda,\, \dots) \]

Used both for ground-track reconstruction and wind profile derivation
(by differencing consecutive APRS fixes).

---

*End of THEORY.md*
