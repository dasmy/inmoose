// Copyright (C) 2008-2022 Yunshun Chen, Aaron TL Lun, Davis J McCarthy, Matthew E Ritchie, Belinda Phipson, Yifang Hu, Xiaobei Zhou, Mark D Robinson, Gordon K Smyth
// Copyright (C) 2022-2024 Maximilien Colange
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// This file is based on the file 'src/objects.cpp' of the Bioconductor edgeR package (version 3.38.4).


#include "objects.h"
#include "numpy/ndarraytypes.h"
#include <algorithm>
#include <sstream>
#include <stdexcept>
#include <type_traits>
#include <vector>

#include "edgepy_cpp.h"

// debug
#include <iostream>


// helper function to check whether an array contains int or double
bool
is_integer_array(PyArrayObject* arr)
{
  if (PyArray_TYPE(arr) == NPY<long>::typenum)
  {
    return true;
  }
  else if (PyArray_TYPE(arr) == NPY<double>::typenum)
  {
    return false;
  }
  else
  {
    PyErr_SetString(PyExc_RuntimeError, "array dtype is neither 'int' nor 'double'");
    return false;
  }
}

