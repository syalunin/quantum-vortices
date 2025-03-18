# Export colormaps from Python to a text file

import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt
import colorcet as cc

namelist = ['coolwarm','inferno','magma','gnuplot','bwr','hsv','gray','binary_r']
for name in namelist:
	cmap = mpl.colormaps.get_cmap(name)
	num = cmap.N
	print(f'Colormap {name} contains {num} entries')
	f = open(f'{name}.txt', 'w')
	f.write(f'{num}\n')
	for i in range(0, num):
		r = round( cmap(i)[0], 5);
		g = round( cmap(i)[1], 5);
		b = round( cmap(i)[2], 5);
		f.write(f'{r:.5f}  {g:.5f}  {b:.5f}\n')
	f.close()


import colorcet as cc
namelist = ['cet_CET_C6','cet_CET_R2']
for name in namelist:
	cmap = mpl.colormaps.get_cmap(name)
	num = cmap.N
	print(f'Colormap {name} contains {num} entries')
	if name=='cet_CET_C6':
		f = open('cyclic.txt','w')
	if name=='cet_CET_R2':
		f = open('rainbow.txt','w')
	if name=='m_gray':
		f = open('m_gray.txt','w')
	f.write(f'{num}\n')
	for i in range(0, num):
		r = round( cmap(i)[0], 5);
		g = round( cmap(i)[1], 5);
		b = round( cmap(i)[2], 5);
		f.write(f'{r:.5f}  {g:.5f}  {b:.5f}\n')
	f.close()


cmap = cc.m_gray
num = cmap.N
print(f'Colormap {name} contains {num} entries')
f = open('m_gray.txt','w')
f.write(f'{num}\n')
for i in range(0, num):
	r = round( cmap(i)[0], 5);
	g = round( cmap(i)[1], 5);
	b = round( cmap(i)[2], 5);
	f.write(f'{r:.5f}  {g:.5f}  {b:.5f}\n')
f.close()


x = np.linspace(-3, 3, 500)
y = np.linspace(-3, 3, 500)
x,y = np.meshgrid(x, y)
z = np.exp(-np.sqrt(x*x + y*y))
plt.imshow(z, cmap=mpl.colormaps.get_cmap('cet_CET_R2'))
plt.colorbar(label="Intensity")
plt.show()

