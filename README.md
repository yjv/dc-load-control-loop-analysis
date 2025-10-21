# Specific Control Loop Analysis Tool

This MATLAB project provides comprehensive analysis and visualization tools for a specific analog control loop consisting of:
- **OPA210** operational amplifier
- **INA296** current sense amplifier  
- **MAX5719GSD+** DAC
- **MSC017SMA120B4N** MOSFET
- **0.0047Ω** current sense resistor

The tool analyzes stability and frequency response for this exact hardware configuration, with the only variable components being the additional gate resistor/capacitor and the load impedance at the FET output.

## 🚀 Quick Start

### Prerequisites
- MATLAB R2019b or later
- Control System Toolbox
- Symbolic Math Toolbox

### Getting Started
1. Clone or download this repository
2. Open MATLAB and navigate to the project directory
3. Run one of the main entry point functions:

```matlab
% Interactive control loop analysis
interactive_control_loop();

% Interactive margin visualization
interactive_control_loop_margin_plot();
```

## 📋 Main Features

### 🎛️ Interactive Control Loop Analysis (`interactive_control_loop.m`)
- **Real-time parameter adjustment** with interactive sliders for the specific OPA210+INA296+MAX5719GSD++MSC017SMA120B4N+0.0047Ω control loop
- **Bode plot visualization** for set-point gain, output transient response, and loop gain transfer functions
- **Stability margin analysis** with gain and phase margin calculations
- **Root locus and pole-zero plots** for detailed stability analysis
- **Step response characteristics** (peak, rise time, settling time)

### 📊 Interactive Margin Visualization (`interactive_control_loop_margin_plot.m`)
- **2D surface plots** of gain and phase margins vs MSC017SMA120B4N operating points
- **Stability boundary contours** (0 dB, -6 dB gain margin; 0°, 40° phase margin)
- **Operational current range visualization** showing max I_s operating limit
- **Progress dialog** for long computations
- **Interactive parameter adjustment** for real-time analysis

## 🏗️ Project Structure

### Main Entry Points
- `interactive_control_loop.m` - Primary interactive analysis tool
- `interactive_control_loop_margin_plot.m` - Margin visualization tool

### Core Analysis Functions
- `control_loop.m` - Main control loop transfer function calculation (set-point gain, transient response, loop gain)
- `margins_from_loop_gain.m` - Stability margin calculations with proper gain/phase margin interpretation
- `fet_small_signal.m` - MOSFET small-signal model (input transconductance, output transconductance)
- `drain_curves.m` - MOSFET drain current characteristics from FET datasheet
- `fet_capacitances.m` - MOSFET capacitance model from FET datasheet plots

### Component Models
- `derive_opa210_gain.m` - OPA210 operational amplifier gain model from datasheet (both magnitude and phase data)
- `derive_opa210_zo.m` - OPA210 output impedance model from datasheet (magnitude only)
- `derive_opa210_zi.m` - OPA210 input impedance model using KCL analysis
- `derive_ina296_gain.m` - INA296 current sense amplifier gain model from datasheet (magnitude only)
- `derive_ina296_zo.m` - INA296 output impedance model from datasheet (magnitude only)
- `derive_ina826_gain.m` - INA826 instrumentation amplifier gain model (not used in main loop)
- `derive_ina826_zo.m` - INA826 instrumentation amplifier output impedance model (not used in main loop)

### Utility Functions
- `normalize_tf.m` - Transfer function normalization to prevent numerical overflow from large coefficient magnitudes
- `normalize_tf_from_sym.m` - Symbolic transfer function normalization to prevent numerical overflow from large coefficient magnitudes
- `normalize_tf_from_numden.m` - Numerator/denominator normalization to prevent numerical overflow from large coefficient magnitudes
- `tf_from_sym.m` - Symbolic to MATLAB transfer function conversion
- `limit_tf_to_frequencies.m` - Transfer function simplification by limiting poles/zeros to frequency range
- `numden_coeffs.m` - Extract numerator and denominator coefficients from symbolic transfer functions

## 📖 Usage Examples

### Basic Control Loop Analysis
```matlab
% Start with default parameters
interactive_control_loop();

% Start with specific operating point
interactive_control_loop(50, 12, 1e6, 10, 100, 100e-12);
```

### Margin Visualization
```matlab
% Analyze stability margins across operating points
interactive_control_loop_margin_plot();
```

### Programmatic Analysis
```matlab
% Calculate transfer functions for specific operating point
[H, H_transient, H_loop_gain] = control_loop(60, 10, 1e9, 5, 0, 0, 1, 1, 800);

% Calculate stability margins
[mag, phase] = bode(H_loop_gain, w);
[gain_margin, phase_margin] = margins_from_loop_gain(mag, phase, f);
```

### MOSFET Characterization
```matlab
% Visualize drain current characteristics
drain_curves();

% Extract small-signal parameters
[g_m, r_o, vds, vgs, id] = drain_curves(1, 1, 800);

% Get capacitances at specific Vds
[C_iss, C_oss, C_rss] = fet_capacitances(60);
```

## 🔧 Parameter Descriptions

### Control Loop Parameters
- **vds_dc**: MSC017SMA120B4N drain-source DC voltage (V)
- **vgs_dc**: MSC017SMA120B4N gate-source DC voltage (V)
- **Z_o_p_r**: Parallel source impedance at FET output (Ω)
- **Z_o_s_r**: Series source impedance at FET output (Ω)
- **r_g**: Additional gate resistance (external to FET) (Ω)
- **c_g**: Additional gate capacitance (external to FET) (F)

### Stability Criteria
- **Gain margin < 0 dB**: Stable (negative gain margin)
- **Gain margin > 0 dB**: Unstable (positive gain margin)
- **Phase margin > 0°**: Stable (positive phase margin)
- **Phase margin < 0°**: Unstable (negative phase margin)
- **Marginal stability**: f_0dB < f_-180° (unity gain before -180° phase)
- **Good stability**: Gain margin ≤ -6 dB, Phase margin ≥ 40°

## 📁 Data Files

### MOSFET Characterization (MSC017SMA120B4N)
- `MSC025SMA120B4/MSC025SMA120B4_drain_curves_2d.csv` - Drain current characteristics
- `MSC025SMA120B4/MSC025SMA120B4_drain_curves.json` - Drain curves data
- `MSC025SMA120B4/MSC025SMA120B4-FET-Characteristics.txt` - FET characteristics

### Visualization Data
- `Drain Curves/` - Drain curve visualization files
- `images/` - Generated analysis plots and comparisons

## 🛠️ Dependencies

### Required Toolboxes
- **Control System Toolbox** - Transfer function analysis
- **Symbolic Math Toolbox** - Symbolic transfer function manipulation


## 🔍 Troubleshooting

### Common Issues
1. **Missing data files**: Ensure all CSV and JSON files are in the correct directories
2. **Toolbox errors**: Verify Control System Toolbox and Symbolic Math Toolbox are installed
3. **Memory issues**: Reduce resolution parameters (vds_divisor, vgs_divisor) for large datasets
4. **Slow computation**: Use progress dialogs to monitor long-running calculations or reduce resolution parameters (vds_divisor, vgs_divisor) for large datasets

## 📝 Notes

- This tool is specifically designed for the OPA210+INA296+MAX5719GSD++MSC017SMA120B4N+0.0047Ω control loop
- All transfer functions are normalized to prevent Inf and NaN due to large coefficient magnitudes
- MOSFET characteristics are interpolated from MSC017SMA120B4N characterization data from FET datasheet
- Component models are based on datasheet information for the specific parts
- Only variable components are additional gate R/C and load impedance at FET output
- `derive_*` functions plot data when called with no arguments (`~nargin`), return transfer functions when called with arguments
- Most `derive_*` functions only fit magnitude data (phase data not available in datasheets)
- Operational current limit (max I_s) represents the maximum current the control loop will operate at, not a constraint

---

**Author**: Yosef Deray  
**Date**: 2025  
**Version**: 1.0
