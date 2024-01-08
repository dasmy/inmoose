# distutils: language = c++
#-----------------------------------------------------------------------------
# Copyright (C) 2008-2022 Yunshun Chen, Aaron TL Lun, Davis J McCarthy, Matthew E Ritchie, Belinda Phipson, Yifang Hu, Xiaobei Zhou, Mark D Robinson, Gordon K Smyth
# Copyright (C) 2022-2024 Maximilien Colange

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#-----------------------------------------------------------------------------

# This file contains Cython ports of the original C++ code from various files of
# the Bioconductor edgeR package (version 3.38.4):
# - 'src/nbdev.cpp' and 'src/R_compute_nbdev.cpp' (function
#   `compute_unit_nb_deviance`)

import numpy as np
cimport cython
from libcpp.cmath cimport log
from scipy.linalg.cython_lapack cimport dormqr, dgeqrf, dtrtrs, dpotrf, dpotrs, dsytrf
from scipy.linalg.cython_blas cimport dgemv

cdef public object make_levenberg_result "make_levenberg_result"(
        ndarray[double, ndim=2] coefficients,
        ndarray[double, ndim=2] fitted_values,
        vector.vector[double] deviance,
        vector.vector[long] iter,
        vector.vector[char] failed):
    return (coefficients, fitted_values, deviance, iter, failed)

cdef public ndarray[double, ndim=1] vector2ndarray "vector2ndarray"(const vector.vector[double]& data):
    return np.asarray(data, order='F')

cdef char side = b'L'
cdef char trans_ormqr = b'T'
cdef char uplo = b'U'
cdef char trans_trtrs = b'N'
cdef char diag = b'N'
cdef int unity = 1

cdef public void build_QRdecomposition(QRdecomposition* self):
    # Setting up the workspace for dgeqrf
    cdef double tmpwork
    dgeqrf(&self.NR, &self.NC, self.Xcopy.data(), &self.NR, self.tau.data(), &tmpwork, &self.lwork_geqrf, &self.info)

    # Loading up the optimal WORK
    self.lwork_geqrf = <int>(tmpwork + 0.5)
    if self.lwork_geqrf < 1:
        self.lwork_geqrf = 1
    self.work_geqrf.resize(self.lwork_geqrf)

    # Repeating for dormqr
    dormqr(&side, &trans_ormqr, &self.NR, &unity, &self.NC, self.Xcopy.data(), &self.NR, self.tau.data(), self.effects.data(), &self.NR, &tmpwork, &self.lwork_ormqr, &self.info)

    self.lwork_ormqr = <int>(tmpwork + 0.5)
    if self.lwork_ormqr < 1:
        self.lwork_ormqr = 1
    self.work_ormqr.resize(self.lwork_ormqr)

cdef void decompose_QRdecomposition(QRdecomposition* self):
    dgeqrf(&self.NR, &self.NC, self.Xcopy.data(), &self.NR, self.tau.data(), self.work_geqrf.data(), &self.lwork_geqrf, &self.info)

cdef void solve_QRdecomposition(QRdecomposition* self):
    dormqr(&side, &trans_ormqr, &self.NR, &unity, &self.NC, self.Xcopy.data(), &self.NR, self.tau.data(), self.effects.data(), &self.NR, self.work_ormqr.data(), &self.lwork_ormqr, &self.info)
    if self.info:
        raise RuntimeError("Q**T multiplication failed")

    dtrtrs(&uplo, &trans_trtrs, &diag, &self.NC, &unity, self.Xcopy.data(), &self.NR, self.effects.data(), &self.NR, &self.info)
    if self.info:
        raise RuntimeError("failed to solve the triangular system")

cdef public void f77_dgemv "f77_dgemv"(const char *trans, const int *m, const int *n, const double *alpha, const double *a, const int *lda, const double *x, const int *incx, const double *beta, double *y, const int *incy) nogil:
    dgemv(<char*>trans, <int*>m, <int*>n, <double*>alpha, <double*>a, <int*>lda, <double*>x, <int*>incx, <double*>beta, y, <int*>incy)
cdef public void f77_dpotrf "f77_dpotrf"(const char *uplo, const int *n, double *a, const int *lda, int *info) nogil:
    dpotrf(<char*>uplo, <int*>n, a, <int*>lda, info)
cdef public void f77_dpotrs "f77_dpotrs"(const char *uplo, const int *n, const int *nrhs, const double *a, const int *lda, double *b, const int *ldb, int *info) nogil:
    dpotrs(<char*>uplo, <int*>n, <int*>nrhs, <double*>a, <int*>lda, b, <int*>ldb, info)
cdef public void f77_dsytrf "f77_dsytrf"(const char *uplo, const int *n, double *a, const int *lda, int *ipiv, double *work, const int *lwork, int *info) nogil:
    dsytrf(<char*>uplo, <int*>n, a, <int*>lda, ipiv, work, <int*>lwork, info)


cdef double mildly_low_value = 1e-8
@cython.ufunc
@cython.cdivision(True)
cdef double compute_unit_nb_deviance(double y, double mu, double phi):
    """
    Calculate the deviance of a negative binomial fit

    Note the protection for very large mu*phi (where we use a Gamma instead) or
    very small mu*phi (where we use a Poisson instead). This approximation
    protects against numerical instability introduced by subtracting a very
    large log value in (log mu) with another very large logarithm (log mu+1/phi).
    We need to consider the phi as the approximation is only good when the
    product is very big or very small.

    Arguments
    ---------
    y : array_like
        counts matrix
    mu : array_like
        expected means matrix (broadcastable to the shape of :code:`y`)
    phi : array_like
        dispersion matrix (broadcastable to the shape of :code:`y`)

    Returns
    -------
    ndarray
        matrix of deviances (same shape as :code:`y`)
    """
    # add a small value to protect against zero during division and log
    y = y + mildly_low_value
    mu = mu + mildly_low_value

    # Calculating the deviance using either the Poisson (small phi*mu), the
    # Gamma (large phi*mu) or NB (everything else). Some additional work is
    # put in to make the transitiosn between families smooth
    resid = y - mu
    product = mu * phi

    if phi < 1e-4:
        return 2 * (y * log(y/mu) - resid - 0.5*resid*resid*phi*(1+phi*(2/3*resid-y)))
    elif product > 1e6:
        return 2 * (resid/mu - log(y/mu)) * mu/(1+product)
    else:
        return 2 * (y * log(y/mu) + (y + 1/phi) * log((mu + 1/phi)/(y + 1/phi)))
