# This file wraps scipy.stats functions into R-like functions

import numpy as np
from scipy.stats import norm, gamma, nbinom

def rbinom(n, size, prob=None, mu=None, seed=None):
    if prob is None and mu is None:
        raise ValueError("exactly one of prob and mu must be provided")
    if prob is not None and mu is not None:
        raise ValueError("exactly one of prob and mu must be provided")

    if prob is None:
        prob = size / (size+mu)

    return nbinom.rvs(size, prob, size=n, random_state=seed)

def pnbinom(q, size, prob=None, mu=None, lower_tail=True):
    """
    Distribution function of the negative binomial distribution.

    Parameters
    ----------
    q           vector of quantiles
    size        dispersion parameter. Must be strictly positive but not necessarily an integer
    prob        probablity of success in each trial. 0 < prob <= 1
    mu          mean (alternative characterization)
    lower_tail  if True, probabilities are P[X <= x], otherwise P[X > x]
    """
    if prob is None and mu is None:
        raise ValueError("exactly one of prob and mu must be provided")
    if prob is not None and mu is not None:
        raise ValueError("exactly one of prob and mu must be provided")

    if prob is None:
        prob = size / (size+mu)

    if lower_tail:
        return nbinom.cdf(q, size, prob)
    else:
        return nbinom.sf(q, size, prob)

def qnbinom(p, size, prob=None, mu=None, lower_tail=True):
    """
    Quantile function of the negative binomial distribution.

    Parameters
    ----------
    p           vector of probabilities
    size        dispersion parameter. Must be strictly positive but not necessarily an integer
    prob        probablity of success in each trial. 0 < prob <= 1
    mu          mean (alternative characterization)
    lower_tail  if True, probabilities are P[X <= x], otherwise P[X > x]
    """
    if prob is None and mu is None:
        raise ValueError("exactly one of prob and mu must be provided")
    if prob is not None and mu is not None:
        raise ValueError("exactly one of prob and mu must be provided")

    if prob is None:
        prob = size / (size+mu)

    if lower_tail:
        return nbinom.ppf(p, size, prob)
    else:
        return nbinom.isf(p, size, prob)


def pnorm(q, mean=0, sd=1, lower_tail=True, log_p=False):
    """
    Distribution function of the normal distribution.

    Parameters
    ----------
    q           vector of quantiles
    mean        vector of means
    sd          vector of standard deviations
    log_p       if True, probabilities are given in log
    lower_tail  if True, probabilities are P[X <= x], otherwise P[X > x]
    """
    if lower_tail and log_p:
        f = norm.logcdf
    elif lower_tail and not log_p:
        f = norm.cdf
    elif not lower_tail and log_p:
        f = norm.logsf
    elif not lower_tail and not log_p:
        f = norm.sf

    return f(q, loc=mean, scale=sd)

def qnorm(p, mean=0, sd=1, lower_tail=True, log_p=False):
    """
    Quantile function of the normal distribution.

    Parameters
    ----------
    p           vector of probabilities
    mean        vector of means
    sd          vector of standard deviations
    log_p       if True, probabilities are given in log
    lower_tail  if True, probabilities are P[X <= x], otherwise P[X > x]
    """
    if log_p:
        p = np.exp(p)

    if lower_tail:
        return norm.ppf(p, loc=mean, scale=sd)
    else:
        return norm.isf(p, loc=mean, scale=sd)

def pgamma(q, shape, scale=1, lower_tail=True, log_p=False):
    """
    Distribution function of the gamma distribution.

    Parameters
    ----------
    q           vector of quantiles
    shape       vector of shapes (must be positive)
    scale       vector of scales (must be strictly positive)
    log_p       if True, probabilities are given in log
    lower_tail  if True, probabilities are P[X <= x], otherwise P[X > x]
    """
    if lower_tail and log_p:
        f = gamma.logcdf
    elif lower_tail and not log_p:
        f = gamma.cdf
    elif not lower_tail and log_p:
        f = gamma.logsf
    elif not lower_tail and not log_p:
        f = gamma.sf

    return f(q, shape, scale=scale)

def qgamma(p, shape, scale=1, lower_tail=True, log_p=False):
    """
    Quantile function of the gamma distribution.

    Parameters
    ----------
    p           vector of probabilities
    shape       vector of shapes (must be positive)
    scale       vector of scales (must be strictly positive)
    log_p       if True, probabilities are given in log
    lower_tail  if True, probabilities are P[X <= x], otherwise P[X > x]
    """
    if log_p:
        p = np.exp(p)

    if lower_tail:
        return gamma.ppf(p, shape, scale=scale)
    else:
        return gamma.isf(p, shape, scale=scale)
