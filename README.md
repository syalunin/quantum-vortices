[![Fortran](https://img.shields.io/badge/Fortran-2003-blue)](https://en.wikipedia.org/wiki/Fortran_2003)
[![C++](https://img.shields.io/badge/C%2B%2B-11-blue)](https://en.cppreference.com/w/cpp/11)
[![GLFW](https://img.shields.io/badge/GLFW-3.4-blue)](https://www.glfw.org)
[![OpenGL](https://img.shields.io/badge/OpenGL-4.1-blue)](https://www.opengl.org/)
[![MKL](https://img.shields.io/badge/Intel%20MKL-2023.2-blue)](https://software.intel.com/content/www/us/en/develop/tools/math-kernel-library.html)
[![arpack-ng](https://img.shields.io/badge/arpack-ng-blue?logo=github)](https://github.com/opencollab/arpack-ng)


# Quantum vortices

This repository provides tools for solving the nonlinear Schrödinger equation arising in a wide range of applications, ranging from Bose-Einstein condensation of ultracold atoms and superconductivity to superfluid-related cosmic phenomena.

## Features
- Real and imaginary time evolution
- Calculation of eigenvalues and eigenvectors

### Installation
To build this project from the source code in this repository you need to have the following:
- Intel Fortran and C++ compilers
- GLFW version 3.4 or newer
- OpenGL version 4.1
- Intel MKL
- Arpack-ng

### Building
To generate the executables, run the 'make' command in the root directory.

## Gallery

Here are some pictures to illustrate the project: (top) formation of a hexagonal lattice of vortices in the Bose Einstein condensate and (bottom) the eigenstates of a harmonic oscillator.

![alt text](images/vortices.png)
<p>
  <img src="images/vortices.png" alt="Image 1" width="960">
  <img src="images/oscillator.png" alt="Image 2" width="480">
</p>
