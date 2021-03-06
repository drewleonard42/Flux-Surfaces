from __future__ import division
import numpy as np
from itertools import product
import sys
from astropy import units as u
from sacconfig import SACConfig
import fredatmos2 as atm


def prod(sequence):
    """Quick and dirty function to return integer size of domain for given dimensions"""
    product = 1
    for x in sequence:
        product *= x
    return product


cfg = SACConfig()
mpic = cfg.mpi_config
print cfg.grid_size, mpic

outname = '/fastdata/sm1ajl/inidata/fredatmos_{}.ini'.format(mpic)
header0 = 'fred-atmosphere_mhd33\n'
n_dims = 3
dims = ['x', 'y', 'z']
vars = ['h', 'm1', 'm2', 'm3', 'e', 'b1', 'b2', 'b3', 'eb', 'rhob', 'bg1', 'bg2', 'bg3']
varnames = {'rhob': 'density',
            'eb': 'energy',
            'bg1': 'magnetic_field_x',
            'bg2': 'magnetic_field_y',
            'bg3': 'magnetic_field_z'}
eqpars = ['gamma', 'eta', 'grav0', 'grav1', 'grav2', 'grav3', 'nu']
eqparvals = [1.4, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0]

for nam, dat in atm.data.iteritems():
    print nam, dat.shape, dat.mean()

# Define domain
#full_domain_size = [int(i)-8 for i in cfg.grid_size.split(',')] #[120, 120, 120]
full_domain_size = list(map(int, cfg.grid_size.split(','))) * np.array([int(mpic[2:4]), int(mpic[4:6]), int(mpic[6:])]) # 128, 128, 128
print(full_domain_Size)
full_mini = [0, 0, 0]
full_maxi = full_domain_size

# Get dimensions of process distribution and fiddle some things
procs_index0 = outname.find('_np')+3
print outname
nprocs = [int(outname[i:i+2]) for i in range(procs_index0, procs_index0+(2*n_dims), 2)]
print nprocs
domain_size = [int(full_domain_size[i]/nprocs[i]) for i in range(len(full_domain_size))]
mini = product(*tuple([np.arange(full_mini[dim], full_maxi[dim], (full_maxi[dim] - full_mini[dim])/p) for dim, p in enumerate(nprocs)]))
mini = np.array([i for i in mini])
maxi = mini + np.array([(full_maxi[dim] - full_mini[dim])/p for dim, p in enumerate(nprocs)])

print domain_size
print mini
print maxi

#procid = 0
#for lwr, upr in zip(mini, maxi):
for procid in range(nprocs):
    full_nx = [full_domain_size[2], full_domain_size[0], full_domain_size[1]]
    header['nx'] = full_nx
    print '..', procid, '..', nx, '..', full_nx, '..', vfile.x.shape
    coords = np.zeros(3)
    if procid < n0:
        coords[0] = procid
    elif (procid == n0):
        coords[1] = 1
    elif procid < (n0 + n1):
        coords[0] = procid - n0
        coords[1] = procid - n1
    else:
        coords[2] = procid / (n0 * n1)
        procid2 = procid - (coords[2] * n2)
    
        if procid2 < n0:
            coords[0] = procid2
        elif procid2 == n0:
            coords[1] = 1
        elif procid2 < (n0 + n0):
            coords[0] = procid2 - n0
            coords[1] = procid2 - n1
    
    print lwr, upr
    # Define file preamble
    header = header0 + ' {: 6} {: .5E} {: 1} {: 1} {: 1}\n'.format(0, 0.0, n_dims, len(eqpars), len(vars))
    for x in domain_size: header += ' {}'.format(x)
    header += '\n'
    for x in eqparvals: header += ' {: .5E}'.format(x)
    header += '\n'
    for x in dims + vars + eqpars: header += '{} '.format(x)

    print domain_size, prod(domain_size), len(dims + vars)
    # Shorthands. These indices may well be wrong
    print '====', procid, 
    x = atm.x[lwr[0]:upr[0], lwr[1]:upr[1], lwr[2]:upr[2]].flatten().to(u.m)
    y = atm.y[lwr[0]:upr[0], lwr[1]:upr[1], lwr[2]:upr[2]].flatten().to(u.m)
    z = atm.z[lwr[0]:upr[0], lwr[1]:upr[1], lwr[2]:upr[2]].flatten().to(u.m)

    # Arrange values in array for output
    outdata = np.zeros(shape=(prod(domain_size), len(dims + vars)))
    for i, thisdim in enumerate([z, x, y]):
        outdata[:, i] = thisdim
    
    for thisvar in varnames:
        thisdata = atm.data[varnames[thisvar]]
        thisdata = thisdata[lwr[0]:upr[0], lwr[1]:upr[1], lwr[2]:upr[2]].flatten()
        outdata[:, n_dims+vars.index(thisvar)] = thisdata
    
    # Sort ini array so first coordinate changes fastest
    outdata = outdata[np.lexsort((z, x, y))]
    
    # Output ini info
    ext = '_{:03}.ini'.format(procid)
    np.savetxt(outname.replace('.ini', ext), outdata, header=header, comments="")#, fmt='% .10E')
    #procid += 1
