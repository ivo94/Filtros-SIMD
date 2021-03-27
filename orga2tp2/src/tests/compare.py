#!/usr/bin/env python3

import subprocess
from libtest import *
import statistics as st
import seaborn as sns
import matplotlib.pyplot as plt
import pandas as pd

DATADIR = "./data"
ALUMNOSDIR = DATADIR + "/resultados_nuestros"
TP2ALU = "../build/tp2"

archivos = ['Misery.32x16.bmp','Misery.64x32.bmp','Misery.128x64.bmp','Misery.256x128.bmp','Misery.400x300.bmp','Misery.512x256.bmp'
			'Misery.800x600.bmp','Misery.1600x1200.bmp','SweetNovemeber.32x16.bmp','SweetNovemeber.64x32.bmp','SweetNovemeber.128x64.bmp',
			'SweetNovemeber.256x128.bmp','SweetNovemeber.400x300.bmp','SweetNovemeber.512x256.bmp'
			'SweetNovemeber.800x600.bmp','SweetNovemeber.1600x1200.bmp',]



def correrFiltro(filtro,implementacion,extra_params):
	#filtro = input()
	#extra_params = input()
	#implementacion = input()
	comando = TP2CAT + " " + filtro
	archivo_in = 'Misery.800x600.bmp'
	argumentos = " -i " + implementacion + " -o " + CATEDRADIR + "/ " + TESTINDIR + "/" + archivo_in + ' ' + extra_params
	for i in range(0,999):
		subprocess.call(comando + argumentos, shell=True)
		#archivo_out = subprocess.check_output(comando + ' -n ' + argumentos, shell=True)
		#print(archivo_out)
		#print(archivo_out[0:5])
		#print(string[0:25])




def calcularPromedio():
	res = 0
	with open('prueba.txt') as file:
		lines = file.readlines()
		count = 0
		for i in range(8,len(lines),10):
			res = res + int(lines[i][38:])
			count += 1
	print(res/count)

# def calcularPromedio():
# 	res = ""
# 	with open('prueba.txt') as file:
# 		lines = file.readlines()
# 		count = 0
# 		for i in range(8,len(lines),10):
# 			res = res + lines[i][38:]
# 			count += 1
# 	print(res)


#correrFiltro("ImagenFantasma","c","1 1")
#calcularPromedio()

datos1 = [1402433,1429262]
datosReforzarBrillo = [1612774,1652963]
datos2 = [6064899,7307614]


#graph = sns.catplot(x="Versión",kind="Cantidad de ticks",data=datos)
#plt.hist(datos)
#plt.show()

# data = {'apple': 10, 'orange': 15, 'lemon': 5, 'lime': 20}
# names = list(data.keys())
# values = list(data.values())

names = ["Utilizando registros","Accediendo a memoria"]

fig = plt.bar(names,datos2)
#axs[1].scatter(names, values)
#axs[2].plot(names, values)
#fig.suptitle('Categorical Plotting')
plt.title("Comparación entre distintas versiones ASM")
plt.xlabel("Implementaciones del filtro ReforzarBrillo")
plt.ylabel("Cantidad de ticks")
plt.show()