clc;
clear;
close all;

%% =============================================================
% DESIGN PARAMETERS
% =============================================================

% Range study
Range = [ 200, 220, 240, 260, 280];     % nm

% Lift-to-drag ratio study
Lift_to_drag = [ 10.5, 11, 11.5, 12, 12.5];

% Battery excluded from empty-weight definition
Empty_weight_fraction = [0.45, .5];


%% =============================================================
% REQUIREMENTS
% =============================================================

Specific_energy = 400;                  % Wh/kg

Weight_Payload = 320;                % kg

% 4 = passenger count
% 93 kg = passenger + baggage allowance per person

Propeller_efficiency = 0.80;

system_efficiency = 0.90;

% system_efficiency represents motor + inverter +
% electrical-system efficiency.
%
% Propeller efficiency is kept separate.


%% =============================================================
% CONSTANTS
% =============================================================

gravity = 9.81;                         % m/s^2

kg_to_lb = 2.20462;                     % lb/kg


%% =============================================================
% UNIT CONVERSIONS
% =============================================================

% Specific energy:
%
% Wh/kg --> J/kg

Specific_energy_Jkg = ...
    Specific_energy * 3600;


%% =============================================================
% CREATE RANGE / L-D GRID
% =============================================================

[Range_grid, LD_grid] = ...
    meshgrid(Range, Lift_to_drag);

% Convert nautical miles to meters

Range_grid_m = ...
    Range_grid * 1852;


%% =============================================================
% SIZING EQUATIONS
%
% Electric range equation:
%
% R = eta_system * eta_prop * (L/D) *
%     (Specific Energy/g) * (W_batt/W0)
%
% Therefore:
%
%                        R*g
% W_batt/W0 = ----------------------------
%             eta_sys*eta_prop*(L/D)*e
%
%
% Total aircraft mass:
%
% W0 = We + Wb + Wpayload
%
% Empty Weight Fraction:
%
% EWF = We/W0
%
% Therefore:
%
%                  Wpayload
% W0 = --------------------------------
%       1 - We/W0 - Wb/W0
%
% =============================================================


%% =============================================================
% FIRST CARPET STUDY
%
% Vary:
%
%   Range
%   L/D
%
% Hold Empty Weight Fraction constant for each figure.
% =============================================================


%% -------------------------------------------------------------
% CARPET PLOT SETTINGS
% --------------------------------------------------------------

offset = 12;

% Artificial / cheater coordinate:
%
% X_cheat = Range + offset*(L/D)
%
% The numerical horizontal coordinate is only used to spread
% the two parameter families apart visually.


%% -------------------------------------------------------------
% COLORS
% --------------------------------------------------------------

% Dark turquoise = constant L/D

LD_color = [0.00, 0.45, 0.50];

% Orange = constant Range

Range_color = [0.85, 0.33, 0.10];


%% =============================================================
% CREATE ONE RANGE / L-D CARPET FOR EACH EWF
% =============================================================

for i = 1:length(Empty_weight_fraction)

    %% ---------------------------------------------------------
    % CURRENT EMPTY WEIGHT FRACTION
    % ----------------------------------------------------------

    EWF = Empty_weight_fraction(i);


    %% ---------------------------------------------------------
    % BATTERY WEIGHT FRACTION
    % ----------------------------------------------------------

    Battery_weight_fraction = ...
        (Range_grid_m .* gravity) ./ ...
        (system_efficiency .* ...
         Propeller_efficiency .* ...
         LD_grid .* ...
         Specific_energy_Jkg);


    %% ---------------------------------------------------------
    % MAXIMUM TAKEOFF MASS
    % ----------------------------------------------------------

    Max_Take_off_weight_kg = ...
        Weight_Payload ./ ...
        (1 - EWF - Battery_weight_fraction);


    %% ---------------------------------------------------------
    % EMPTY MASS
    % ----------------------------------------------------------

    Empty_weight_kg = ...
        EWF .* Max_Take_off_weight_kg;


    %% ---------------------------------------------------------
    % BATTERY MASS
    % ----------------------------------------------------------

    Battery_weight_kg = ...
        Battery_weight_fraction .* ...
        Max_Take_off_weight_kg;


    %% ---------------------------------------------------------
    % CHECK FOR PHYSICALLY INVALID COMBINATIONS
    %
    % Empty fraction + battery fraction cannot equal or exceed 1.
    % ----------------------------------------------------------

    invalid = ...
        (EWF + Battery_weight_fraction) >= 1;

    Max_Take_off_weight_kg(invalid) = NaN;

    Empty_weight_kg(invalid) = NaN;

    Battery_weight_kg(invalid) = NaN;


    %% ---------------------------------------------------------
    % CONVERT MASSES TO POUNDS
    % ----------------------------------------------------------

    Max_Take_off_weight_lb = ...
        Max_Take_off_weight_kg * kg_to_lb;
    Empty_weight_lb = ...
        Empty_weight_kg * kg_to_lb;
    Battery_weight_lb = ...
        Battery_weight_kg * kg_to_lb;


    %% ---------------------------------------------------------
    % CREATE CHEATER AXIS
    % ----------------------------------------------------------

    X_cheat = ...
        Range_grid + ...
        LD_grid .* offset;


    %% ---------------------------------------------------------
    % FIND VALID DATA RANGES
    % ----------------------------------------------------------

    valid_mask = ...
        isfinite(Max_Take_off_weight_lb);

    valid_MTOW_lb = ...
        Max_Take_off_weight_lb(valid_mask);

    valid_X = ...
        X_cheat(valid_mask);

    x_min = ...
        min(valid_X);

    x_max = ...
        max(valid_X);

    y_min_lb = ...
        min(valid_MTOW_lb);

    y_max_lb = ...
        max(valid_MTOW_lb);

    x_span = ...
        x_max - x_min;

    y_span_lb = ...
        y_max_lb - y_min_lb;


    %% =========================================================
    % CREATE RANGE / L-D CARPET PLOT
    % ==========================================================

    figure;

    hold on;


    %% ---------------------------------------------------------
    % CONSTANT L/D LINES
    %
    % Dark turquoise lines.
    %
    % Range changes along each line.
    % ----------------------------------------------------------

    LD_label_x_offset = ...
        0.02 * x_span;

    LD_label_y_offset = ...
        0.02 * y_span_lb;

    for j = 1:length(Lift_to_drag)

        plot( ...
            X_cheat(j,:), ...
            Max_Take_off_weight_lb(j,:), ...
            '-', ...
            'Color', LD_color, ...
            'LineWidth', 2.0);

        text( ...
            X_cheat(j,end) + LD_label_x_offset, ...
            Max_Take_off_weight_lb(j,end) + LD_label_y_offset, ...
            sprintf('L/D = %.1f', Lift_to_drag(j)), ...
            'Color', LD_color, ...
            'FontSize', 10, ...
            'FontWeight', 'bold', ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle');

    end


    %% ---------------------------------------------------------
    % CONSTANT RANGE LINES
    %
    % Orange lines.
    %
    % L/D changes along each line.
    % ----------------------------------------------------------

    range_label_offset = ...
        -0.025 * y_span_lb;

    for j = 1:length(Range)

        plot( ...
            X_cheat(:,j), ...
            Max_Take_off_weight_lb(:,j), ...
            '-', ...
            'Color', Range_color, ...
            'LineWidth', 2.0);

        text( ...
            X_cheat(end,j), ...
            Max_Take_off_weight_lb(end,j) + range_label_offset, ...
            sprintf('Range = %.0f nm', Range(j)), ...
            'Color', Range_color, ...
            'FontSize', 8, ...
            'FontWeight', 'bold', ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle');

    end


    %% ---------------------------------------------------------
    % PLOT FORMATTING
    %
    % The only axis title shown is MTOW in pounds.
    %
    % No horizontal-axis title is displayed because the
    % horizontal coordinate is an artificial carpet-plot
    % coordinate rather than an independent physical variable.
    %
    % No kilogram axis is displayed.
    % ----------------------------------------------------------

    grid on;

    box on;

    ylabel('MTOW (lb)');


    %% ---------------------------------------------------------
    % X-AXIS LIMITS
    % ----------------------------------------------------------

    x_padding = ...
        0.09 * x_span;

    xlim([ ...
        x_min - x_padding, ...
        x_max + 2*x_padding]);

    xticks([]);


    %% ---------------------------------------------------------
    % Y-AXIS LIMITS
    %
    % Figure displayed only in pounds.
    % ----------------------------------------------------------

    y_padding_lb = ...
        0.09 * y_span_lb;

    y_limits_lb = [ ...
        max(0, y_min_lb - y_padding_lb), ...
        y_max_lb + y_padding_lb];

    ylim(y_limits_lb);


    %% ---------------------------------------------------------
    % AXIS APPEARANCE
    % ----------------------------------------------------------

    ax = gca;

    ax.XColor = 'k';

    ax.YColor = 'k';


    %% ---------------------------------------------------------
    % COMMAND WINDOW OUTPUT
    %
    % Both kilograms and pounds are retained here even though
    % the graphical output is displayed only in pounds.
    % ----------------------------------------------------------

    fprintf('\n');

    fprintf('=================================================\n');

    fprintf('Empty Weight Fraction = %.2f\n', EWF);

    fprintf('=================================================\n');


    fprintf('\nMaximum Takeoff Mass (kg):\n');

    disp(Max_Take_off_weight_kg);


    fprintf('\nMaximum Takeoff Mass (lb):\n');

    disp(Max_Take_off_weight_lb);


    fprintf('\nBattery Mass (kg):\n');

    disp(Battery_weight_kg);


    fprintf('\nBattery Mass (lb):\n');

    disp(Battery_weight_lb);


    fprintf('\nEmpty Mass (kg):\n');

    disp(Empty_weight_kg);


    fprintf('\nEmpty Mass (lb):\n');

    disp(Empty_weight_lb);


    hold off;

end


%% =============================================================
% SECOND CARPET STUDY
%
% FIXED RANGE = 200 NM
%
% Vary:
%
%   Empty Weight Fraction
%   L/D
%
% Response:
%
%   Maximum Takeoff Weight
%
% =============================================================


%% -------------------------------------------------------------
% DESIGN VARIABLES
% --------------------------------------------------------------

Range_fixed = 200;                      % nm

% Five equally spaced Empty Weight Fraction values
%
% 0.3000
% 0.3375
% 0.3750
% 0.4125
% 0.4500

EWF_200 = ...
    linspace(0.30, 0.5, 5);


% Five equally spaced L/D values
%
% 8.5
% 9.0
% 9.5
% 10.0
% 10.5

LD_200 = ...
    linspace(10.5, 12.5, 5);


%% -------------------------------------------------------------
% CONVERT FIXED RANGE TO METERS
% --------------------------------------------------------------

Range_fixed_m = ...
    Range_fixed * 1852;


%% -------------------------------------------------------------
% CREATE EWF / L-D GRID
% --------------------------------------------------------------

[EWF_grid_200, LD_grid_200] = ...
    meshgrid(EWF_200, LD_200);


%% -------------------------------------------------------------
% BATTERY WEIGHT FRACTION
%
% Because range is fixed, battery fraction changes with
% L/D but does not directly depend on Empty Weight Fraction.
% --------------------------------------------------------------

Battery_weight_fraction_200 = ...
    (Range_fixed_m .* gravity) ./ ...
    (system_efficiency .* ...
     Propeller_efficiency .* ...
     LD_grid_200 .* ...
     Specific_energy_Jkg);


%% -------------------------------------------------------------
% MAXIMUM TAKEOFF MASS
%
%                   Wpayload
% W0 = --------------------------------
%       1 - We/W0 - Wb/W0
% --------------------------------------------------------------

MTOW_kg_200 = ...
    Weight_Payload ./ ...
    (1 - EWF_grid_200 - ...
     Battery_weight_fraction_200);


%% -------------------------------------------------------------
% EMPTY MASS
% --------------------------------------------------------------

Empty_weight_kg_200 = ...
    EWF_grid_200 .* ...
    MTOW_kg_200;


%% -------------------------------------------------------------
% BATTERY MASS
% --------------------------------------------------------------

Battery_weight_kg_200 = ...
    Battery_weight_fraction_200 .* ...
    MTOW_kg_200;


%% -------------------------------------------------------------
% CHECK FOR PHYSICALLY INVALID DESIGNS
% --------------------------------------------------------------

invalid_200 = ...
    (EWF_grid_200 + ...
     Battery_weight_fraction_200) >= 1;

MTOW_kg_200(invalid_200) = NaN;

Empty_weight_kg_200(invalid_200) = NaN;

Battery_weight_kg_200(invalid_200) = NaN;


%% -------------------------------------------------------------
% CONVERT TO POUNDS
% --------------------------------------------------------------

MTOW_lb_200 = ...
    MTOW_kg_200 * kg_to_lb;

Empty_weight_lb_200 = ...
    Empty_weight_kg_200 * kg_to_lb;

Battery_weight_lb_200 = ...
    Battery_weight_kg_200 * kg_to_lb;


%% =============================================================
% CREATE EWF / L-D CARPET-PLOT CHEATER AXIS
%
% Artificial plotting coordinate:
%
% X = EWF + offset*(L/D)
%
% This coordinate is only used to visually separate the
% two parameter families.
% =============================================================

offset_200 = 0.12;

X_cheat_200 = ...
    EWF_grid_200 + ...
    offset_200 .* LD_grid_200;


%% -------------------------------------------------------------
% FIND VALID PLOT LIMITS
% --------------------------------------------------------------

valid_mask_200 = ...
    isfinite(MTOW_lb_200);

valid_X_200 = ...
    X_cheat_200(valid_mask_200);

valid_MTOW_200 = ...
    MTOW_lb_200(valid_mask_200);

x_min_200 = ...
    min(valid_X_200);

x_max_200 = ...
    max(valid_X_200);

y_min_200 = ...
    min(valid_MTOW_200);

y_max_200 = ...
    max(valid_MTOW_200);

x_span_200 = ...
    x_max_200 - x_min_200;

y_span_200 = ...
    y_max_200 - y_min_200;


%% =============================================================
% CREATE FIXED-RANGE EWF / L-D CARPET PLOT
% =============================================================

figure;

hold on;


%% -------------------------------------------------------------
% COLORS
% --------------------------------------------------------------

% Dark turquoise = constant L/D

LD_color_200 = ...
    [0.00, 0.45, 0.50];

% Orange = constant EWF

EWF_color_200 = ...
    [0.85, 0.33, 0.10];


%% -------------------------------------------------------------
% CONSTANT L/D LINES
%
% Each row corresponds to one constant L/D.
%
% Empty Weight Fraction changes along each line.
% --------------------------------------------------------------

LD_x_offset_200 = ...
    0.02 * x_span_200;

LD_y_offset_200 = ...
    0.015 * y_span_200;

for j = 1:length(LD_200)

    plot( ...
        X_cheat_200(j,:), ...
        MTOW_lb_200(j,:), ...
        '-', ...
        'Color', LD_color_200, ...
        'LineWidth', 2.0);

    text( ...
        X_cheat_200(j,end) + LD_x_offset_200, ...
        MTOW_lb_200(j,end) + LD_y_offset_200, ...
        sprintf('L/D = %.1f', LD_200(j)), ...
        'Color', LD_color_200, ...
        'FontSize', 10, ...
        'FontWeight', 'bold', ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'middle');

end


%% -------------------------------------------------------------
% CONSTANT EMPTY-WEIGHT-FRACTION LINES
%
% Each column corresponds to one constant EWF.
%
% L/D changes along each line.
% --------------------------------------------------------------

EWF_y_offset_200 = ...
    -0.02 * y_span_200;

for j = 1:length(EWF_200)

    plot( ...
        X_cheat_200(:,j), ...
        MTOW_lb_200(:,j), ...
        '-', ...
        'Color', EWF_color_200, ...
        'LineWidth', 2.0);

    text( ...
        X_cheat_200(end,j), ...
        MTOW_lb_200(end,j) + EWF_y_offset_200, ...
        sprintf('EWF = %.4f', EWF_200(j)), ...
        'Color', EWF_color_200, ...
        'FontSize', 9, ...
        'FontWeight', 'bold', ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'middle');

end


%% -------------------------------------------------------------
% PLOT FORMATTING
%
% The only axis title displayed is MTOW in pounds.
%
% No horizontal-axis title is displayed because the
% horizontal coordinate is an artificial carpet-plot
% coordinate.
%
% No kilogram axis is displayed.
% --------------------------------------------------------------

grid on;

box on;

ylabel('MTOW (lb)');


%% -------------------------------------------------------------
% X-AXIS LIMITS
% --------------------------------------------------------------

x_padding_200 = ...
    0.10 * x_span_200;

xlim([ ...
    x_min_200 - x_padding_200, ...
    x_max_200 + 2*x_padding_200]);

xticks([]);


%% -------------------------------------------------------------
% Y-AXIS LIMITS
%
% Figure displayed only in pounds.
% --------------------------------------------------------------

y_padding_200 = ...
    0.10 * y_span_200;

y_limits_lb_200 = [ ...
    max(0, y_min_200 - y_padding_200), ...
    y_max_200 + y_padding_200];

ylim(y_limits_lb_200);


%% -------------------------------------------------------------
% AXIS APPEARANCE
% --------------------------------------------------------------

ax = gca;

ax.XColor = 'k';

ax.YColor = 'k';


%% =============================================================
% COMMAND WINDOW OUTPUT
%
% Both SI and English-unit values are retained for checking.
%
% The graphical output itself is displayed only in pounds.
% =============================================================

fprintf('\n');

fprintf('=====================================================\n');

fprintf('FIXED RANGE EWF / L-D STUDY\n');

fprintf('Range = %.0f nm\n', Range_fixed);

fprintf('=====================================================\n');


fprintf('\nEmpty Weight Fractions:\n');

disp(EWF_200);


fprintf('\nL/D Values:\n');

disp(LD_200);


fprintf('\nBattery Weight Fraction:\n');

disp(Battery_weight_fraction_200);


fprintf('\nMaximum Takeoff Mass (kg):\n');

disp(MTOW_kg_200);


fprintf('\nMaximum Takeoff Mass (lb):\n');

disp(MTOW_lb_200);


fprintf('\nBattery Mass (kg):\n');

disp(Battery_weight_kg_200);


fprintf('\nBattery Mass (lb):\n');

disp(Battery_weight_lb_200);


fprintf('\nEmpty Mass (kg):\n');

disp(Empty_weight_kg_200);


fprintf('\nEmpty Mass (lb):\n');

disp(Empty_weight_lb_200);


hold off;

%% =============================================================
% ADDITIONAL SENSITIVITY CARPET PLOTS
%
% Nominal design point:
%   L/D = 12.5
%   EWF = 0.45
%   Range = 200 nm
%   Specific energy = 400 Wh/kg
%
% The black dot on each carpet is the nominal design point.
% =============================================================

%% -------------------------------------------------------------
% NOMINAL VALUES
% --------------------------------------------------------------

LD_nominal = 12.5;

EWF_nominal = 0.45;

Range_nominal = 200;                    % nm

Specific_energy_nominal = 400;          % Wh/kg

Range_nominal_m = Range_nominal * 1852;

%% =============================================================
% THIRD CARPET PLOT
%
% Vary:
%   Specific energy
%   Range
%
% Hold fixed:
%   L/D = 12.5
%   EWF = 0.45
%
% Response:
%   MTOW
% =============================================================

Range_SE_Range = [180, 200, 220, 240, 260];          % nm

Specific_energy_SE_Range = ...
    [300, 350, 400, 450, 500];                       % Wh/kg

[Range_grid_SE_Range, Specific_energy_grid_SE_Range] = ...
    meshgrid(Range_SE_Range, Specific_energy_SE_Range);

Range_grid_SE_Range_m = ...
    Range_grid_SE_Range * 1852;

Specific_energy_grid_SE_Range_Jkg = ...
    Specific_energy_grid_SE_Range * 3600;

Battery_weight_fraction_SE_Range = ...
    (Range_grid_SE_Range_m .* gravity) ./ ...
    (system_efficiency .* ...
     Propeller_efficiency .* ...
     LD_nominal .* ...
     Specific_energy_grid_SE_Range_Jkg);

MTOW_kg_SE_Range = ...
    Weight_Payload ./ ...
    (1 - EWF_nominal - ...
     Battery_weight_fraction_SE_Range);

invalid_SE_Range = ...
    (EWF_nominal + ...
     Battery_weight_fraction_SE_Range) >= 1;

MTOW_kg_SE_Range(invalid_SE_Range) = NaN;

MTOW_lb_SE_Range = ...
    MTOW_kg_SE_Range * kg_to_lb;

% Artificial carpet-plot coordinate only
offset_SE_Range = 0.40;

X_cheat_SE_Range = ...
    Range_grid_SE_Range + ...
    offset_SE_Range .* Specific_energy_grid_SE_Range;

plot_carpet_mtow( ...
    X_cheat_SE_Range, ...
    MTOW_lb_SE_Range, ...
    Specific_energy_SE_Range, ...
    Range_SE_Range, ...
    'Specific energy = %.0f Wh/kg', ...
    'Range = %.0f nm', ...
    [0.00, 0.45, 0.50], ...
    [0.85, 0.33, 0.10], ...
    3, ...
    3);

%% =============================================================
% FOURTH CARPET PLOT
%
% Vary:
%   Specific energy
%   L/D
%
% Hold fixed:
%   Range = 200 nm
%   EWF = 0.45
%
% Response:
%   MTOW
% =============================================================

LD_SE_LD = ...
    [11.5, 12.0, 12.5, 13.0, 13.5];

Specific_energy_SE_LD = ...
    [300, 350, 400, 450, 500];                       % Wh/kg

[LD_grid_SE_LD, Specific_energy_grid_SE_LD] = ...
    meshgrid(LD_SE_LD, Specific_energy_SE_LD);

Specific_energy_grid_SE_LD_Jkg = ...
    Specific_energy_grid_SE_LD * 3600;

Battery_weight_fraction_SE_LD = ...
    (Range_nominal_m .* gravity) ./ ...
    (system_efficiency .* ...
     Propeller_efficiency .* ...
     LD_grid_SE_LD .* ...
     Specific_energy_grid_SE_LD_Jkg);

MTOW_kg_SE_LD = ...
    Weight_Payload ./ ...
    (1 - EWF_nominal - ...
     Battery_weight_fraction_SE_LD);

invalid_SE_LD = ...
    (EWF_nominal + ...
     Battery_weight_fraction_SE_LD) >= 1;

MTOW_kg_SE_LD(invalid_SE_LD) = NaN;

MTOW_lb_SE_LD = ...
    MTOW_kg_SE_LD * kg_to_lb;

% Artificial carpet-plot coordinate only
offset_SE_LD = 0.010;

X_cheat_SE_LD = ...
    LD_grid_SE_LD + ...
    offset_SE_LD .* Specific_energy_grid_SE_LD;

plot_carpet_mtow( ...
    X_cheat_SE_LD, ...
    MTOW_lb_SE_LD, ...
    Specific_energy_SE_LD, ...
    LD_SE_LD, ...
    'Specific energy = %.0f Wh/kg', ...
    'L/D = %.1f', ...
    [0.00, 0.45, 0.50], ...
    [0.85, 0.33, 0.10], ...
    3, ...
    3);

%% =============================================================
% FIFTH CARPET PLOT
%
% Vary:
%   Empty weight fraction
%   Range
%
% Hold fixed:
%   L/D = 12.5
%   Specific energy = 400 Wh/kg
%
% Response:
%   MTOW
% =============================================================

Range_EWF_Range = ...
    [160, 180, 200, 220, 240];                       % nm

EWF_EWF_Range = ...
    [0.35, 0.40, 0.45, 0.50, 0.55];

[Range_grid_EWF_Range, EWF_grid_EWF_Range] = ...
    meshgrid(Range_EWF_Range, EWF_EWF_Range);

Range_grid_EWF_Range_m = ...
    Range_grid_EWF_Range * 1852;

Specific_energy_nominal_Jkg = ...
    Specific_energy_nominal * 3600;

Battery_weight_fraction_EWF_Range = ...
    (Range_grid_EWF_Range_m .* gravity) ./ ...
    (system_efficiency .* ...
     Propeller_efficiency .* ...
     LD_nominal .* ...
     Specific_energy_nominal_Jkg);

MTOW_kg_EWF_Range = ...
    Weight_Payload ./ ...
    (1 - EWF_grid_EWF_Range - ...
     Battery_weight_fraction_EWF_Range);

invalid_EWF_Range = ...
    (EWF_grid_EWF_Range + ...
     Battery_weight_fraction_EWF_Range) >= 1;

MTOW_kg_EWF_Range(invalid_EWF_Range) = NaN;

MTOW_lb_EWF_Range = ...
    MTOW_kg_EWF_Range * kg_to_lb;

% Artificial carpet-plot coordinate only
offset_EWF_Range = 400;

X_cheat_EWF_Range = ...
    Range_grid_EWF_Range + ...
    offset_EWF_Range .* EWF_grid_EWF_Range;

plot_carpet_mtow( ...
    X_cheat_EWF_Range, ...
    MTOW_lb_EWF_Range, ...
    EWF_EWF_Range, ...
    Range_EWF_Range, ...
    'EWF = %.2f', ...
    'Range = %.0f nm', ...
    [0.00, 0.45, 0.50], ...
    [0.85, 0.33, 0.10], ...
    3, ...
    3);

%% =============================================================
% LOCAL FUNCTION:
% CLEAN CARPET-PLOT FORMATTING
%
% Keep this function at the absolute end of the script.
% =============================================================

function plot_carpet_mtow( ...
    X_cheat, ...
    MTOW_lb, ...
    row_values, ...
    column_values, ...
    row_label_format, ...
    column_label_format, ...
    row_color, ...
    column_color, ...
    nominal_row, ...
    nominal_column)

    valid_mask = isfinite(MTOW_lb);

    valid_X = X_cheat(valid_mask);

    valid_MTOW_lb = MTOW_lb(valid_mask);

    x_min = min(valid_X);

    x_max = max(valid_X);

    y_min_lb = min(valid_MTOW_lb);

    y_max_lb = max(valid_MTOW_lb);

    x_span = x_max - x_min;

    y_span_lb = y_max_lb - y_min_lb;

    figure;

    hold on;

    % Constant row-value lines
    for j = 1:length(row_values)

        plot( ...
            X_cheat(j,:), ...
            MTOW_lb(j,:), ...
            '-', ...
            'Color', row_color, ...
            'LineWidth', 2.0);

        last_valid_column = ...
            find(isfinite(MTOW_lb(j,:)), 1, 'last');

        if ~isempty(last_valid_column)

            text( ...
                X_cheat(j,last_valid_column) + 0.02 * x_span, ...
                MTOW_lb(j,last_valid_column) + 0.015 * y_span_lb, ...
                sprintf(row_label_format, row_values(j)), ...
                'Color', row_color, ...
                'FontSize', 9, ...
                'FontWeight', 'bold', ...
                'HorizontalAlignment', 'left', ...
                'VerticalAlignment', 'middle');

        end

    end

    % Constant column-value lines
    for j = 1:length(column_values)

        plot( ...
            X_cheat(:,j), ...
            MTOW_lb(:,j), ...
            '-', ...
            'Color', column_color, ...
            'LineWidth', 2.0);

        last_valid_row = ...
            find(isfinite(MTOW_lb(:,j)), 1, 'last');

        if ~isempty(last_valid_row)

            text( ...
                X_cheat(last_valid_row,j), ...
                MTOW_lb(last_valid_row,j) - 0.025 * y_span_lb, ...
                sprintf(column_label_format, column_values(j)), ...
                'Color', column_color, ...
                'FontSize', 8, ...
                'FontWeight', 'bold', ...
                'HorizontalAlignment', 'left', ...
                'VerticalAlignment', 'middle');

        end

    end

    % Nominal design-point marker
    plot( ...
        X_cheat(nominal_row,nominal_column), ...
        MTOW_lb(nominal_row,nominal_column), ...
        'ko', ...
        'MarkerFaceColor', 'k', ...
        'MarkerSize', 6);

    text( ...
        X_cheat(nominal_row,nominal_column) + 0.015 * x_span, ...
        MTOW_lb(nominal_row,nominal_column) + 0.035 * y_span_lb, ...
        'Nominal design point', ...
        'Color', 'k', ...
        'FontSize', 9, ...
        'FontWeight', 'bold');

    grid on;

    box on;

    ylabel('MTOW (lb)');

    x_padding = 0.10 * x_span;

    xlim([ ...
        x_min - x_padding, ...
        x_max + 2 * x_padding]);

    xticks([]);

    y_padding_lb = 0.10 * y_span_lb;

    ylim([ ...
        max(0, y_min_lb - y_padding_lb), ...
        y_max_lb + y_padding_lb]);

    ax = gca;

    ax.XColor = 'k';

    ax.YColor = 'k';

    hold off;

end