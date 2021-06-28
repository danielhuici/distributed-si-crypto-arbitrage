#include <ClpSimplex.hpp>
#include <vector>
#include <iostream>
#include <string>

int main( int argc, const char *argv[])
{
  ClpSimplex model;
  int status;

  // Read the linear program description
  if (argc < 2) {
    status = model.readLp( "fx_arbitrage.lp");
  } else {
    status = model.readLp( argv[1] );
  }

  if ( !status ) {
    // Perform the optimization
    model.primal();
  }

  // Print the solution
  auto nCol = model.numberColumns();
  auto colSolution = model.getColSolution();
  for(int i=0; i<nCol; i++ ) {
    std::cout << model.getColumnName(i) 
              << ": " << colSolution[i] << std::endl;
  }
  
  return 0;
}
