all: fx_solver

fx_solver: fx_solver.cpp
	clang++ -std=c++0x -I/usr/include/coin -o fx_solver fx_solver.cpp -lClp

# Install CLP:
# sudo apt-get install coinor-libclp0 coinor-libclp-doc