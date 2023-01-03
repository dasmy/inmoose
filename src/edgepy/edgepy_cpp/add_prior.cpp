#include "add_prior.h"

add_prior::add_prior(PyArrayObject* priors, PyArrayObject* offsets, bool login, bool logout) :
        allp(priors), allo(offsets), logged_in(login), logged_out(logout),
        nrow(allp.get_nrow()), ncol(allp.get_ncol()),
        adj_prior(ncol), adj_libs(ncol), filled(false) {
    return;
}

void add_prior::compute(size_t index) {
    if (same_across_rows() && filled) {
        // Skipping if all rows are the same, and we've already filled it in once.
        return;
    }

    auto optr2=allo.row(index);
    for (size_t lib=0; lib<ncol; ++lib) {
        if (logged_in) { // unlogging to get library sizes, if they were originally logged offsets.
            adj_libs[lib]=std::exp(optr2[lib]);
        } else {
            adj_libs[lib]=optr2[lib];
        }
    }
    double ave_lib=std::accumulate(adj_libs.begin(), adj_libs.end(), 0.0)/ncol;

    // Computing the adjusted prior count for each library.
    auto pptr2=allp.row(index);
    for (size_t lib=0; lib<ncol; ++lib) {
        adj_prior[lib]=pptr2[lib]*adj_libs[lib]/ave_lib;
    }

    // Adding it twice back to the library size, and log-transforming.
    for (size_t lib=0; lib<ncol; ++lib) {
        double& curval=adj_libs[lib];
        curval+=2*adj_prior[lib];
        if (logged_out) {
            curval=std::log(curval);
        }
    }

    filled=true;
    return;
}

const double* add_prior::get_priors() const { return adj_prior.data(); }

const double* add_prior::get_offsets()  const { return adj_libs.data(); }

const bool add_prior::same_across_rows() const {
    return (allp.is_row_repeated() && allo.is_row_repeated());
}

size_t add_prior::get_nrow() const { return nrow; }

size_t add_prior::get_ncol() const { return ncol; }

/* Function to check its dimensions. */

void check_AP_dims(const add_prior& AP, size_t nr, size_t nc, const char* msg) {
    if (AP.get_nrow()!=nr || AP.get_ncol()!=nc) {
        std::stringstream err;
        err << "dimensions of " << msg << " and offset/prior matrices are not consistent";
        throw std::runtime_error(err.str().c_str());
    }
    return;
}


