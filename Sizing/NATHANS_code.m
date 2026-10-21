clc; clear; close all;

% Requirements and assumptions (English engineering units)
range_nm = 250;                         % nautical miles
range_ft = range_nm * 6076.11549;       % ft

payload_lbf = 2 * 250;                  % two passengers, 250 lb each

altitude_takeoff_ft = 2200;             % ft
altitude_cruise_ft = 10000;             % ft

battery_specific_energy_Wh_kg = 500 * 0.80; % Wh/kg
Wh_kg_to_ft2_s2 = 3600 * (3.280839895^2);
Cbat_ft2_s2 = battery_specific_energy_Wh_kg * Wh_kg_to_ft2_s2;               

Eff_prop = 0.80;                        % propeller efficiency
Eff_engine = 0.95;                      % motor/engine efficiency
LD = 11;
EWF = 0.50;                             % non-battery empty-weight fraction of MTOW

takeoff_distance_ft = 1500;             % ft; not used by the range-only method
landing_distance_ft = takeoff_distance_ft;
CL_max_takeoff = 1.6;                   % not used by the range-only method
CL_max_landing = 2.0;                   % not used by the range-only method

g_ft_s2 = 32.174;                       % ft/s^2

cruise_kt = 100;                          % knots
cruise_fps = cruise_kt * 1.68780986;      % ft/s
Cf = 0.005;
oswald = 0.85;
AR = 12;

delta_T_F = 100 - 51.15; %average hot day las vegas temp, and the 51.15 is the standard density at 2200

[rho_takeoff_slug_ft3, a_takeoff_fts, T_takeoff_R, P_takeoff_psf,~,~,   sigma_takeoff] = atmos(altitude_takeoff_ft, 'units', 'US');
[rho_cruise_slug_ft3, a_cruise_fts, T_cruise_R, P_cruise_psf] = atmos(altitude_cruise_ft, 'units', 'US');
rho_landing = rho_takeoff_slug_ft3;

range_capability_ft = Eff_engine * Eff_prop * LD * (Cbat_ft2_s2 / g_ft_s2);

required_battery_fraction = range_ft / range_capability_ft;

mtow_denominator = 1 - EWF - required_battery_fraction;


MTOW_lbf = payload_lbf / mtow_denominator

empty_weight_lbf = EWF * MTOW_lbf

battery_weight_lbf = MTOW_lbf - empty_weight_lbf - payload_lbf


% Takeoff power loading
% Empirical takeoff-distance relation:
% distance (ft) = a*TOP^2 + b*TOP
a = 0.0149;
b = 8.134;
TOP = (-b + sqrt(b^2 + 4*a*takeoff_distance_ft)) / (2*a);

wingLoading = linspace(5, 40, 300);      % lbf/ft^2

% Power loading, P/W, in hp/lbf using the empirical TOP relation
P_W_takeoff = wingLoading ./(TOP * sigma_takeoff * CL_max_takeoff);

% Landing wing-loading limit
V_stall_landing_kts = sqrt(landing_distance_ft / 0.5136); %need to be ground distance, and where u get the .5136, i have something difference 
V_stall_landing_fts = V_stall_landing_kts * 1.68781;


% q*CL gives wing loading in lbf/ft^2 when rho is slug/ft^3
WS_landing = 0.5 * rho_landing * V_stall_landing_fts^2* CL_max_landing;


% Cruise power loading

q_cruise = 0.5 * rho_cruise_slug_ft3 * cruise_fps^2; % lbf/ft^2



% Empirical wetted-area estimate; correlation expects weight in lbf
S_wet_ft2 = 10^(1.08892 + 0.5147 * log10(MTOW_lbf));
S_ref_ft2 = MTOW_lbf ./ wingLoading;

CD0 = Cf .* (S_wet_ft2 ./ S_ref_ft2);


% In level cruise, CL = (W/S)/q
CL_cruise = wingLoading ./ q_cruise;
CD = CD0 + CL_cruise.^2 ./ (pi * oswald * AR);

% Shaft power required divided by weight, hp/lbf
P_W_cruise = (CD .* q_cruise .* cruise_fps) ./ (wingLoading * 550*Eff_prop); % 550


% Feasible wing-loading range: below the landing maximum
valid = wingLoading <= WS_landing;
WS_feasible = wingLoading(valid);

% Required P/W is the larger of the takeoff and cruise requirements
PW_required = max(P_W_takeoff(valid), P_W_cruise(valid));

% Top of the shaded area is just the plot limit; your constraints
% do not set a maximum P/W.
yTop = 0.12;

figure
hold on
grid on

% Shade feasible region
fill([WS_feasible, fliplr(WS_feasible)], ...
     [PW_required, yTop * ones(size(PW_required))], ...
     [0.65 0.85 1.00], ...
     'FaceAlpha', 0.35, 'EdgeColor', 'none', ...
     'DisplayName', 'Feasible region');

% Plot constraint boundaries over the shading
plot(wingLoading, P_W_takeoff, 'b', 'LineWidth', 1.5, ...
    'DisplayName', 'Takeoff');
plot(wingLoading, P_W_cruise, 'Color', [0.85 0.33 0.10], ...
    'LineWidth', 1.5, 'DisplayName', 'Cruise');
xline(WS_landing, 'r--', 'Landing limit', 'LineWidth', 2, ...
    'DisplayName', 'Landing limit');

xlabel('W/S (lbf/ft^2)')
ylabel('P/W (hp/lbf)')
xlim([wingLoading(1), wingLoading(end)])
ylim([0, yTop])
legend('Location', 'best')

%% Back solve 

wing_loading = 18.46; %lbf/ft^2
power_loading = .08456; %hp/lbf

wing_area = (1/wing_loading) * MTOW_lbf
power_required = power_loading * MTOW_lbf
span = sqrt(AR*wing_area)
chord = wing_area / span 


%% Climb-gradient constraint

CGR_required = 0.083;       % Required climb gradient: 8.3%
CL_climb = 1.0;             % Assumed CL during climb — replace
LD_climb = 11;              % Assumed climb L/D — replace

% Climb gradient parameter
CGRP_required = (CGR_required + 1 / LD_climb) ...
               / sqrt(CL_climb);

% Required shaft power/weight across existing wing-loading range
P_W_climb = CGRP_required .* sqrt(wingLoading) ...
            ./ (18.97 * Eff_prop * sqrt(sigma_takeoff));

% Add to the existing P/W constraint diagram
hold on;
plot(wingLoading, P_W_climb, 'm-', 'LineWidth', 2, ...
     'DisplayName', 'Climb gradient: 8.3%');
legend('show');
grid on;

% Update required power to include the climb constraint
PW_required = max([P_W_takeoff(valid); ...
                   P_W_cruise(valid); ...
                   P_W_climb(valid)], [], 1);

