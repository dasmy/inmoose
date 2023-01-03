import numpy as np
from math import ceil, floor
from warnings import warn

def movingAverageByCol(x, width=5, full_length=True):
    """
    Moving average smoother for columns of a matrix
    """
    x = np.asanyarray(x, order='F')
    width = int(width)
    if width <= 1:
        return x
    (n,m) = x.shape
    if width > n:
        width = n
        warn("reducing moving average width to x.shape[0]")

    if full_length:
        half1 = ceil(width/2)
        half2 = floor(width/2)
        x = np.vstack([np.zeros((half1, m)), x, np.zeros((half2, m))])
    else:
        if width == n:
            return x.mean(axis=0).reshape((1,m))
        x = np.vstack([np.zeros((1,m)), x])

    n2 = x.shape[0]
    x = x.cumsum(axis=0)
    x = x[width:n2] - x[0:(n2-width)]
    n3 = x.shape[0]
    w = np.full((n3,), width)
    if full_length:
        if half1 > 1:
            w[0:half1-1] = np.array([width - i for i in range(half1-1, 0, -1)])
        w[(n3-half2):n3] = np.array([width - i for i in range(1, half2+1)])
    return x / w.reshape((n3,1))

