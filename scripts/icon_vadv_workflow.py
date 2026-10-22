#!/usr/bin/env python3
"""
Calculate instantaneous vertical advection from NetCDF file
Vertical Advection = -w * (dq/dz)
"""

import numpy as np
import xarray as xr
# import matplotlib.pyplot as plt
import os
os.environ['QT_QPA_PLATFORM'] = 'offscreen'

# Physical constants
g = 9.81  # gravitational acceleration (m/s²)
R = 287.0  # specific gas constant for dry air (J/kg/K)
cp = 1004.0  # specific heat at constant pressure (J/kg/K)
# Dry adiabatic lapse rate
gamma_d = g / cp  # ≈ 0.0098 K/m or 9.8 K/km

filename=os.environ['filename']
def calculate_vertical_gradient(q, z, z_axis=1, boundary_method='one_sided'):
    """
    Calculate vertical gradient dq/dz using finite differences
    
    Parameters:
    -----------
    q : array-like
        Scalar field (e.g., specific humidity, potential temperature)
    z : array-like
        Height coordinate (1D array)
    z_axis : int
        Axis along which to compute the vertical gradient (default: -1, last axis)
    boundary_method : str
        Method for boundary treatment:
        - 'one_sided': forward/backward differences at boundaries (default)
        - 'zero': set boundary gradients to zero
        - 'extrapolate': extrapolate from interior points
    
    Returns:
    --------
    dqdz : array-like
        Vertical gradient dq/dz
    """
    dqdz = np.zeros_like(q)
    
    # Get the number of vertical levels
    nz = q.shape[z_axis]
    
    if nz < 2:
        raise ValueError("Need at least 2 vertical levels to calculate gradient")
    
    # Handle different input shapes using numpy's advanced indexing
    if q.ndim == 1:
        # 1D profile
        if nz > 2:
            # Centered differences for interior points
            dqdz[1:-1] = (q[2:] - q[:-2]) / (z[2:] - z[:-2])
        
        # Handle boundaries based on method
        if boundary_method == 'one_sided':
            dqdz[0] = (q[1] - q[0]) / (z[1] - z[0])
            dqdz[-1] = (q[-1] - q[-2]) / (z[-1] - z[-2])
        elif boundary_method == 'zero':
            dqdz[0] = 0.0
            dqdz[-1] = 0.0
        elif boundary_method == 'extrapolate':
            if nz > 2:
                dqdz[0] = dqdz[1]
                dqdz[-1] = dqdz[-2]
            else:
                dqdz[0] = (q[1] - q[0]) / (z[1] - z[0])
                dqdz[-1] = (q[-1] - q[-2]) / (z[-1] - z[-2])
                
    elif q.ndim == 2:
        # 2D field - could be (time, lev) or (horizontal, lev)
        if z_axis == -1 or z_axis == 1:
            # Vertical is last dimension: (time, lev)
            if nz > 2:
                # Centered differences for interior points
                dqdz[:, 1:-1] = (q[:, 2:] - q[:, :-2]) / (z[2:] - z[:-2])
            
            # Handle boundaries
            if boundary_method == 'one_sided':
                dqdz[:, 0] = (q[:, 1] - q[:, 0]) / (z[1] - z[0])
                dqdz[:, -1] = (q[:, -1] - q[:, -2]) / (z[-1] - z[-2])
            elif boundary_method == 'zero':
                dqdz[:, 0] = 0.0
                dqdz[:, -1] = 0.0
            elif boundary_method == 'extrapolate':
                if nz > 2:
                    dqdz[:, 0] = dqdz[:, 1]
                    dqdz[:, -1] = dqdz[:, -2]
                else:
                    dqdz[:, 0] = (q[:, 1] - q[:, 0]) / (z[1] - z[0])
                    dqdz[:, -1] = (q[:, -1] - q[:, -2]) / (z[-1] - z[-2])
                    
        elif z_axis == 0:
            # Vertical is first dimension: (lev, horizontal)
            if nz > 2:
                # Centered differences for interior points
                dqdz[1:-1, :] = (q[2:, :] - q[:-2, :]) / (z[2:] - z[:-2])[:, np.newaxis]
            
            # Handle boundaries
            if boundary_method == 'one_sided':
                dqdz[0, :] = (q[1, :] - q[0, :]) / (z[1] - z[0])
                dqdz[-1, :] = (q[-1, :] - q[-2, :]) / (z[-1] - z[-2])
            elif boundary_method == 'zero':
                dqdz[0, :] = 0.0
                dqdz[-1, :] = 0.0
            elif boundary_method == 'extrapolate':
                if nz > 2:
                    dqdz[0, :] = dqdz[1, :]
                    dqdz[-1, :] = dqdz[-2, :]
                else:
                    dqdz[0, :] = (q[1, :] - q[0, :]) / (z[1] - z[0])
                    dqdz[-1, :] = (q[-1, :] - q[-2, :]) / (z[-1] - z[-2])
        
    elif q.ndim >= 3:
       if z_axis == -1 or z_axis == 1:
            # Vertical is last dimension: (time, lev)
            # z = z.reshape(1, 77, 1, 1)
            if nz > 2:
                # Centered differences for interior points
                dqdz[:, 1:-1,:,:] = (q[:, 2:,:,:] - q[:, :-2,:,:]) / (z[2:] - z[:-2])[np.newaxis, :, np.newaxis, np.newaxis]
            
            # Handle boundaries
            if boundary_method == 'one_sided':
                dqdz[:, 0,:,:] = (q[:, 1,:,:] - q[:, 0,:,:]) / (z[1] - z[0])
                dqdz[:, -1,:,:] = (q[:, -1,:,:] - q[:, -2,:,:]) / (z[-1] - z[-2])
            elif boundary_method == 'zero':
                dqdz[:, 0,:,:] = 0.0
                dqdz[:, -1,:,:] = 0.0
            elif boundary_method == 'extrapolate':
                if nz > 2:
                    dqdz[:, 0,:,:] = dqdz[:, 1,:,:]
                    dqdz[:, -1,:,:] = dqdz[:, -2,:,:]
                else:
                    dqdz[:, 0,:,:] = (q[:, 1,:,:] - q[:, 0,:,:]) / (z[1] - z[0])
                    dqdz[:, -1,:,:] = (q[:, -1,:,:] - q[:, -2,:,:]) / (z[-1] - z[-2])
                    
        # Multi-dimensional field - use numpy's gradient function for flexibility
        # This handles arbitrary dimensions and axis positions
        # if nz > 2:
        #     # Use numpy's gradient with centered differences
        #     grad_all = np.gradient(q, axis=z_axis)
        #     z_spacing = np.gradient(z)
            
        #     # Create broadcasting shape for z_spacing
        #     broadcast_shape = [1] * q.ndim
        #     broadcast_shape[z_axis] = len(z_spacing)
        #     z_spacing_bc = z_spacing.reshape(broadcast_shape)
            
        #     dqdz = grad_all / z_spacing_bc
            
        #     # Apply boundary method if needed
        #     if boundary_method == 'zero':
        #         # Set boundary gradients to zero
        #         idx_first = [slice(None)] * q.ndim
        #         idx_last = [slice(None)] * q.ndim
        #         idx_first[z_axis] = 0
        #         idx_last[z_axis] = -1
        #         dqdz[tuple(idx_first)] = 0.0
        #         dqdz[tuple(idx_last)] = 0.0
        # else:
        #     # Only 2 levels - use simple difference
        #     idx_diff = [slice(None)] * q.ndim
        #     idx_first = [slice(None)] * q.ndim
        #     idx_last = [slice(None)] * q.ndim
            
        #     idx_diff[z_axis] = slice(1, None)
        #     idx_first[z_axis] = slice(None, -1)
        #     idx_last[z_axis] = slice(1, None)
            
        #     diff_q = q[tuple(idx_last)] - q[tuple(idx_first)]
        #     diff_z = z[1] - z[0]
            
        #     dqdz[tuple(idx_first)] = diff_q / diff_z
        #     dqdz[tuple(idx_last)] = diff_q / diff_z
    
    return dqdz

def calculate_vertical_advection(nc_file, q_var, qhadv_var,w_var, z_var, time_idx=None, boundary_method='one_sided'):
    """
    Calculate vertical advection from NetCDF file
    
    Parameters:
    -----------
    nc_file : str
        Path to NetCDF file
    q_var : str
        Variable name for scalar field (default: 'q')
    w_var : str
        Variable name for vertical velocity (default: 'w')
    z_var : str
        Variable name for height coordinate (default: 'z')
    time_idx : int or None
        Time index to use (default: None, processes all times)
        Set to specific index to process only one time step
    boundary_method : str
        Method for boundary treatment (default: 'one_sided')
        Options: 'one_sided', 'zero', 'extrapolate'
    
    Returns:
    --------
    vertical_advection : xarray.DataArray
        Calculated vertical advection
    """
    
    # Open the NetCDF file
    print(f"Opening NetCDF file: {nc_file}")
    ds = xr.open_dataset(nc_file,decode_cf=False, drop_variables=['t0'])
    
    # Print available variables
    print("Available variables in the file:")
    print(list(ds.variables.keys()))
    
    # Extract variables
    try:
        q = ds[q_var]
        w = ds[w_var]
        z = ds[z_var]
        
        print(f"\nVariable shapes:")
        print(f"{q_var}: {q.shape} - dimensions: {list(q.dims)}")
        print(f"{w_var}: {w.shape} - dimensions: {list(w.dims)}")
        print(f"{z_var}: {z.shape} - dimensions: {list(z.dims)}")
        
        # Check if z is 1D coordinate variable
        if z.ndim == 1 and len(z.dims) == 1:
            print(f"✓ {z_var} is a 1D coordinate variable")
        else:
            print(f"⚠ Warning: {z_var} is not 1D. Shape: {z.shape}")
            
        # Check if q and w have same dimensions
        if q.dims == w.dims:
            print(f"✓ {q_var} and {w_var} have matching dimensions")
        else:
            print(f"⚠ Warning: dimension mismatch between {q_var} {q.dims} and {w_var} {w.dims}")
        
    except KeyError as e:
        print(f"Error: Variable {e} not found in the file")
        print("Please check variable names and update the function call")
        return None
    
    # Handle time selection - for 2D (time, lev) data, we can process all times or select one
    if 'time' in q.dims and q.sizes['time'] > 1:
        if time_idx is not None:
            if time_idx < q.sizes['time']:
                q = q.isel(time=time_idx)
                w = w.isel(time=time_idx)
                print(f"Selected time index: {time_idx}")
            else:
                print(f"Warning: time_idx {time_idx} >= number of time steps {q.sizes['time']}")
                print("Processing all time steps")
        else:
            print(f"Processing all {q.sizes['time']} time steps")
    
    # Convert to numpy arrays for calculation
    q_vals = q.values
    w_vals = w.values
    z_vals = z.values
    
    print(f"\nArray shapes for calculation:")
    print(f"q_vals: {q_vals.shape}")
    print(f"w_vals: {w_vals.shape}")
    print(f"z_vals: {z_vals.shape}")
    
    # Verify shapes are compatible
    if q_vals.shape != w_vals.shape:
        raise ValueError(f"Shape mismatch: q {q_vals.shape} vs w {w_vals.shape}")
    
    # For 2D (time, lev) data, z should be 1D (lev)
    if q_vals.ndim == 2 and z_vals.ndim == 1:
        if q_vals.shape[-1] != len(z_vals):
            raise ValueError(f"Vertical dimension mismatch: q has {q_vals.shape[-1]} levels, z has {len(z_vals)} levels")
    
    # Determine which axis is the vertical dimension
    z_axis = None
    for i, dim in enumerate(q.dims):
        if dim in ['z', 'lev', 'level', 'height', 'altitude', 'plev']:
            z_axis = i
            break
    
    if z_axis is None:
        print("Warning: Could not automatically identify vertical dimension.")
        print(f"Available dimensions: {list(q.dims)}")
        # Assume last dimension is vertical
        z_axis = -1
        print(f"Assuming dimension index {z_axis} is vertical")
    else:
        print(f"Identified vertical dimension: {list(q.dims)[z_axis]} (axis {z_axis})")
    
    # Calculate vertical gradient dq/dz
    print(f"Calculating vertical gradient dq/dz using '{boundary_method}' boundary method...")
    dqdz = calculate_vertical_gradient(q_vals, z_vals, z_axis=z_axis, boundary_method=boundary_method)
    
    # Calculate vertical advection: -w * (dq/dz)
    print("Calculating vertical advection...")
    vertical_advection = -w_vals * dqdz
    if q_var == "ta_forc":
        vertical_advection =vertical_advection - (w_vals * gamma_d)
    
    # Create xarray DataArray with same coordinates as input
    coords = {}
    dims = []
    
    # Handle coordinates properly for the result
    for dim in q.dims:
        coords[dim] = q.coords[dim]
        dims.append(dim)
    
    vadv_da = xr.DataArray(
        vertical_advection,
        coords=coords,
        dims=dims,
        name='vertical_advection for '+q_var,
        attrs={
            'long_name': f'Vertical advection of {q_var}',
            'units': f'{q.attrs.get("units", "unknown")}/s',
            'description': f'Vertical advection calculated as -w * d{q_var}/dz',
            'boundary_method': boundary_method
        }
    )

    # total_advection = vertical_advection + ds["tnqv_adv"]

    hadv_da = ds[qhadv_var]
    return vadv_da, hadv_da


# Main execution
if __name__ == "__main__":
    # Example usage - UPDATE THESE PATHS AND VARIABLE NAMES FOR YOUR DATA
    nc_file = filename  # Replace with your NetCDF file path
    
    # Common atmospheric variable names - adjust based on your file
    q_variable = "qv_nud"          # Specific humidity, potential temp, etc.
                              # Could be: 'q', 'qv', 'theta', 'temp', 'rh'
    t_variable = "ta_forc"
    ua_variable = "ua_nudging"                          
    va_variable = "va_nudging" 
    w_variable = "wa"          # Vertical velocity  
                              # Could be: 'w', 'omega', 'wa', 'vertical_velocity'
    z_variable = "lev"        # Vertical coordinate (1D)
                              # Could be: 'lev', 'level', 'plev', 'pressure_level'
    
    print("=== Vertical Advection Calculator ===")
    print("For 2D atmospheric data: q(time,lev), w(time,lev), z(lev)")
    print("")
    
    try:
        # Calculate vertical advection
        qv_vadv, qv_hadv = calculate_vertical_advection(
            nc_file, 
            q_var=q_variable,
            qhadv_var="tnqv_adv",
            w_var=w_variable, 
            z_var=z_variable,
            time_idx=None,  # Process all time steps (use specific index like 0 for single time)
            boundary_method='one_sided'
        )

        ta_vadv, ta_hadv = calculate_vertical_advection(
            nc_file, 
            q_var=t_variable,
            qhadv_var="tnta_adv",
            w_var=w_variable, 
            z_var=z_variable,
            time_idx=None,  # Process all time steps (use specific index like 0 for single time)
            boundary_method='one_sided'
        )

        ua_vadv, ua_hadv = calculate_vertical_advection(
            nc_file, 
            q_var=ua_variable,
            qhadv_var="tnua_adv",
            w_var=w_variable, 
            z_var=z_variable,
            time_idx=None,  # Process all time steps (use specific index like 0 for single time)
            boundary_method='one_sided'
        )

        va_vadv, va_hadv = calculate_vertical_advection(
            nc_file, 
            q_var=va_variable,
            qhadv_var="tnva_adv",
            w_var=w_variable, 
            z_var=z_variable,
            time_idx=None,  # Process all time steps (use specific index like 0 for single time)
            boundary_method='one_sided'
        )

        rv_vadv, rv_hadv = calculate_vertical_advection(
            nc_file, 
            q_var="rv_nud",
            qhadv_var="tnrv_adv",
            w_var=w_variable, 
            z_var=z_variable,
            time_idx=None,  # Process all time steps (use specific index like 0 for single time)
            boundary_method='one_sided'
        )

        rt_vadv, rt_hadv = calculate_vertical_advection(
            nc_file, 
            q_var='rt_nud',
            qhadv_var="tnrt_adv",
            w_var=w_variable, 
            z_var=z_variable,
            time_idx=None,  # Process all time steps (use specific index like 0 for single time)
            boundary_method='one_sided'
        )

        qt_vadv, qt_hadv = calculate_vertical_advection(
            nc_file, 
            q_var='qt_nud',
            qhadv_var="tnqt_adv",
            w_var=w_variable, 
            z_var=z_variable,
            time_idx=None,  # Process all time steps (use specific index like 0 for single time)
            boundary_method='one_sided'
        )

        theta_vadv, theta_hadv = calculate_vertical_advection(
            nc_file, 
            q_var='theta_nud',
            qhadv_var="tntheta_adv",
            w_var=w_variable, 
            z_var=z_variable,
            time_idx=None,  # Process all time steps (use specific index like 0 for single time)
            boundary_method='one_sided'
        )
        thetal_vadv, thetal_hadv = calculate_vertical_advection(
            nc_file, 
            q_var='thetal_nud',
            qhadv_var="tnthetal_adv",
            w_var=w_variable, 
            z_var=z_variable,
            time_idx=None,  # Process all time steps (use specific index like 0 for single time)
            boundary_method='one_sided'
        )

        # ta_vadv, ta_hadv = calculate_vertical_advection(
        #     nc_file, 
        #     q_var=t_variable,
        #     qhadv_var="tnta_adv",
        #     w_var=w_variable, 
        #     z_var=z_variable,
        #     time_idx=None,  # Process all time steps (use specific index like 0 for single time)
        #     boundary_method='one_sided'
        # )


        
        if qv_vadv is not None:
            # print(f"\nVertical advection calculated successfully!")
            # print(f"Shape: {vadv.shape}")
            # print(f"Units: {vadv.attrs.get('units', 'unknown')}")
            # print(f"Min value: {vadv.min().values:.2e}")
            # print(f"Max value: {vadv.max().values:.2e}")
            # print(f"Mean value: {vadv.mean().values:.2e}")
            
            # Save results to new NetCDF file
            output_file = "total_advection_"+filename
            # vadv.to_netcdf(output_file)
            # Create a dataset with both variables
            ds = xr.Dataset({
               'qv_vadv': qv_vadv,
               'qv_hadv': qv_hadv,
               'ta_vadv': ta_vadv,
               'ta_hadv': ta_hadv,
               'ua_vadv': ua_vadv,
               'ua_hadv': ua_hadv,
               'va_vadv': va_vadv,
               'va_hadv': va_hadv,
               'qt_vadv': qt_vadv,
               'qt_hadv': qt_hadv,
               'rt_vadv': rt_vadv,
               'rt_hadv': rt_hadv,
               'theta_vadv': theta_vadv,
               'theta_hadv': theta_hadv,
               'thetal_vadv': thetal_vadv,
               'thetal_hadv': thetal_hadv,
            })
            ds.to_netcdf(output_file)
            print(f"\nResults saved to: {output_file}")
            
            # Plot if data is suitable
            # try:
            #     z_coord = dataset[z_variable]
            #     # For 2D (time, lev) data, offer both time-averaged and time-series plots
            #     if vadv.ndim == 2 and 'time' in vadv.dims:
            #         print("\nCreating plots for 2D (time, level) data...")
            #         plot_vertical_profile(vadv,hadv, z_coord, f"Vertical Advection of {q_variable}", time_avg=True)
            #         # plot_vertical_profile(vadv, hadv,z_coord, f"Vertical Advection of {q_variable}", time_avg=False)
            #     else:
            #         plot_vertical_profile(vadv, hadv, z_coord, f"Vertical Advection of {q_variable}")
            # except Exception as e:
            #     print(f"Could not create plot: {e}")
        
        # Close dataset
        ds.close()
        
    except FileNotFoundError:
        print(f"Error: File '{nc_file}' not found.")
        print("Please update the 'nc_file' variable with the correct path to your NetCDF file.")
    except Exception as e:
        print(f"An error occurred: {e}")
        print("\nTroubleshooting tips:")
        print("1. Check that the file path is correct")
        print("2. Verify variable names match those in your NetCDF file")
        print("3. Ensure the file contains the required variables (q, w, z)")
        print("4. Check that vertical coordinate is properly defined")
