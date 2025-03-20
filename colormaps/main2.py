# Export colormaps from Python to a text file

import numpy as np
import matplotlib as mpl

import colorcet as cc
namelist = ['cet_CET_C6','cet_CET_R2','cet_CET_D09']
for name in namelist:
	cmap = mpl.colormaps.get_cmap(name)
	num = cmap.N
	print(f'Colormap {name} contains {num} entries')
	if name=='cet_CET_C6':
		f = open('cyclic.txt','w')
	if name=='cet_CET_R2':
		f = open('rainbow.txt','w')
	if name=='cet_CET_D09':
		f = open('cet_CET_D09','w')
	f.write(f'{num}\n')
	for i in range(0, num):
		r = round( cmap(i)[0], 5);
		g = round( cmap(i)[1], 5);
		b = round( cmap(i)[2], 5);
		f.write(f'{r:.5f}  {g:.5f}  {b:.5f}\n')
	f.close()


import matplotlib.pyplot as plt
import numpy as np
import colorcet as cc

x = np.linspace(-3, 3, 500)
y = np.linspace(-3, 3, 500)
x,y = np.meshgrid(x, y)
z = np.exp(-np.sqrt(x*x + y*y))

#plt.imshow(z, cmap=cc.m_gray)
plt.imshow(z, cmap="m_gray")
plt.colorbar(label="Intensity")
plt.title("Perceptually Uniform Grayscale (m_gray)")
plt.show()


# import matplotlib.pyplot as plt
# import numpy as np
# import colorcet as cc

# # Выбираем палитру
# palette = cc.m_gray  # Перцептуально равномерная серая палитра

# # Создаем градиент для визуализации
# gradient = np.linspace(0, 1, 256).reshape(1, -1)  # Один ряд данных

# # Визуализация палитры
# plt.figure(figsize=(8, 2))
# plt.imshow(gradient, aspect="auto", cmap=palette)
# plt.title("Perceptually Uniform Grayscale (m_gray)")
# plt.axis("off")
# plt.show()
