#' Centers and scales a matrix robustly for the purpose of covariance estimation.
#'
#' Centers each column on its median, and scales each column by its median
#' absolute deviation (MAD). If any column MAD is zero, its values become zero
#' and a warning is raised. If all MADs are zero, an error is raised.
#'
#' @param mat A numerical matrix.
#'
#' @return The input matrix centered and scaled.
#'
#' @importFrom robustbase rowMedians
scale_med <- function(mat){
  TOL <- 1e-8

  # Transpose.
  mat <- t(mat)

  #	Center.
  mat <- mat - c(rowMedians(mat, na.rm=TRUE))

  # Scale.
  mad <- 1.4826 * rowMedians(abs(mat), na.rm=TRUE)
  const_mask <- mad < TOL
  if(any(const_mask)){
    if(all(const_mask)){
    stop("All voxels are zero-variance.\n")
    } else {
      warning(paste0("Warning: ", sum(const_mask),
      " constant voxels (out of ", length(const_mask),
      " ). These will be removed for estimation of the covariance.\n"))
    }
  }
  mad <- mad[!const_mask]
  mat <- mat[!const_mask,]
  mat <- mat/c(mad)

  # Revert transpose.
  mat <- t(mat)

  list(mat=mat, const_mask=const_mask)
}

#' Estimates the parameters of the F distribution of MCD distances.
#'
#' This estimates the parameters c and m required to determine the distribution
#'  of robust MCD distances as derived by Hardin and Rocke (2005), The
#'  Distribution of Robust Distances.
#'
#' @param Q The number of variables in dataset used to compute MCD distances.
#' @param n The total number of observations.
#' @param h The number of observations included in estimation of MCD center and
#'  scale.
#'
#' @return A list containing the estimated F distribution's c, m, and df.
#' @export
fit.F <- function(Q, n, h){
  # Estimate c.
  c <- pchisq(q=qchisq(df=Q, p=h/n), df=Q+2)/(h/n)

  # Estimate asymptotic m.
  alpha <- (n-h)/n
  q_alpha <- qchisq(p=1-alpha, df=Q)
  c_alpha <- (1-alpha)/(pchisq(df=Q+2, q=q_alpha))
  c2 <- -1*pchisq(df=Q+2, q=q_alpha)/2
  c3 <- -1*pchisq(df=Q+4, q=q_alpha)/2
  c4 <- 3*c3
  b1 <- c_alpha*(c3-c4)/(1-alpha)
  b2 <- 0.5 + (c_alpha/(1-alpha))*(c3-q_alpha/Q*(c2 + (1-alpha)/2))
  v1 <- (1-alpha)*b1^2*(alpha*(c_alpha*q_alpha/Q - 1)^2 - 1) -
    2*c3*c_alpha^2*(3*(b1-Q*b2)^2 + (Q+2)*b2*(2*b1-Q*b2))
  v2 <- n*(b1*(b1-Q*b2)*(1-alpha))^2*c_alpha^2
  v <- v1/v2
  m <- 2/(c_alpha^2*v)

  # Corrected m for finite samples.
  m <- m * exp(0.725 - 0.00663*Q - 0.078*log(n))
  df <- c(Q, m-Q+1)

  result <- list(c=c, m=m, df=df)
  return(result)
}


#' Estimates the trend of \code{ts} using a robust discrete cosine transform.
#'
#' @param ts A numeric vector to detrend.
#' @param robust Should a robust linear model be used? Default FALSE.
#'
#' @return The estimated trend.
#'
#' @importFrom stats mad
#' @importFrom robustbase lmrob
#' @importFrom robustbase lmrob.control
#' @export
est_trend <- function(ts, robust=TRUE){
  TOL <- 1e-8
  if(mad(ts) < TOL){ return(ts) }

  df <- data.frame(
    index=1:length(ts),
    ts=ts
  )

  i_scaled <- 2*(df$index-1)/(length(df$index)-1) - 1 #range on [-1, 1]

  df['p1'] <- cos(2*pi*(i_scaled/4 - .25)) #cosine on [-1/2, 0]*2*pi
  df['p2'] <- cos(2*pi*(i_scaled/2 - .5)) #cosine on [-1, 0]*2*pi
  df['p3'] <- cos(2*pi*(i_scaled*3/4  -.75)) # [-1.5, 0]*2*pi
  df['p4'] <- cos(2*pi*(i_scaled - 1)) # [2, 0]*2*pi

  if(robust){
    control <- lmrob.control(scale.tol=1e-3, refine.tol=1e-2) # increased tol.
    # later: warn.limit.reject=NULL
    trend <- lmrob(ts~p1+p2+p3+p4, df, control=control)$fitted.values
  } else {
    trend <- lm(ts~p1+p2+p3+p4, df)$fitted.values
  }

  trend
}
